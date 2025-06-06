// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/redundancy_elimination.h"

#include <functional>
#include <utility>

#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/loops.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/flags.h"
#include "vm/kernel_isolate.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static void NoopNative(Dart_NativeArguments args) {}

static Dart_NativeFunction NoopNativeLookup(Dart_Handle name,
                                            int argument_count,
                                            bool* auto_setup_scope) {
  ASSERT(auto_setup_scope != nullptr);
  *auto_setup_scope = false;
  return NoopNative;
}

// Flatten all non-captured LocalVariables from the given scope and its children
// and siblings into the given array based on their environment index.
static void FlattenScopeIntoEnvironment(FlowGraph* graph,
                                        LocalScope* scope,
                                        GrowableArray<LocalVariable*>* env) {
  for (intptr_t i = 0; i < scope->num_variables(); i++) {
    auto var = scope->VariableAt(i);
    if (var->is_captured()) {
      continue;
    }

    auto index = graph->EnvIndex(var);
    env->EnsureLength(index + 1, nullptr);
    (*env)[index] = var;
  }

  if (scope->sibling() != nullptr) {
    FlattenScopeIntoEnvironment(graph, scope->sibling(), env);
  }
  if (scope->child() != nullptr) {
    FlattenScopeIntoEnvironment(graph, scope->child(), env);
  }
}

// Run TryCatchAnalyzer optimization on the function foo from the given script
// and check that the only variables from the given list are synchronized
// on catch entry.
static void TryCatchOptimizerTest(
    Thread* thread,
    const char* script_chars,
    std::initializer_list<const char*> synchronized) {
  // Load the script and exercise the code once.
  const auto& root_library =
      Library::Handle(LoadTestScript(script_chars, &NoopNativeLookup));
  Invoke(root_library, "main");

  // Build the flow graph.
  std::initializer_list<CompilerPass::Id> passes = {
      CompilerPass::kComputeSSA,      CompilerPass::kTypePropagation,
      CompilerPass::kApplyICData,     CompilerPass::kSelectRepresentations,
      CompilerPass::kTypePropagation, CompilerPass::kCanonicalize,
  };
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* graph = pipeline.RunPasses(passes);

  // Finally run TryCatchAnalyzer on the graph (in AOT mode).
  OptimizeCatchEntryStates(graph, /*is_aot=*/true);

  EXPECT_EQ(1, graph->try_entries().length());
  auto scope = graph->parsed_function().scope();

  GrowableArray<LocalVariable*> env;
  FlattenScopeIntoEnvironment(graph, scope, &env);

  for (intptr_t i = 0; i < env.length(); i++) {
    bool found = false;
    for (auto name : synchronized) {
      if (env[i]->name().Equals(name)) {
        found = true;
        break;
      }
    }
    if (!found) {
      env[i] = nullptr;
    }
  }

  CatchBlockEntryInstr* catch_entry = graph->GetCatchBlockByTryIndex(0);

  // We should only synchronize state for variables from the synchronized list.
  for (auto defn : *catch_entry->initial_definitions()) {
    if (ParameterInstr* param = defn->AsParameter()) {
      if (param->location().IsRegister()) {
        EXPECT(param->location().Equals(LocationExceptionLocation()) ||
               param->location().Equals(LocationStackTraceLocation()));
        continue;
      }

      EXPECT(0 <= param->env_index() && param->env_index() < env.length());
      EXPECT(env[param->env_index()] != nullptr);
      if (env[param->env_index()] == nullptr) {
        OS::PrintErr("something is wrong with %s\n", param->ToCString());
      }
    }
  }
}

//
// Tests for TryCatchOptimizer.
//

ISOLATE_UNIT_TEST_CASE(TryCatchOptimizer_DeadParameterElimination_Simple1) {
  const char* script_chars = R"(
      @pragma("vm:external-name", "BlackholeNative")
      external dynamic blackhole([dynamic val]);
      foo(int p) {
        var a = blackhole(), b = blackhole();
        try {
          blackhole([a, b]);
        } catch (e) {
          // nothing is used
        }
      }
      main() {
        foo(42);
      }
  )";

  TryCatchOptimizerTest(thread, script_chars, /*synchronized=*/{});
}

ISOLATE_UNIT_TEST_CASE(TryCatchOptimizer_DeadParameterElimination_Simple2) {
  const char* script_chars = R"(
      @pragma("vm:external-name", "BlackholeNative")
      external dynamic blackhole([dynamic val]);
      foo(int p) {
        var a = blackhole(), b = blackhole();
        try {
          blackhole([a, b]);
        } catch (e) {
          // a should be synchronized
          blackhole(a);
        }
      }
      main() {
        foo(42);
      }
  )";

  TryCatchOptimizerTest(thread, script_chars, /*synchronized=*/{"a"});
}

ISOLATE_UNIT_TEST_CASE(TryCatchOptimizer_DeadParameterElimination_Cyclic1) {
  const char* script_chars = R"(
      @pragma("vm:external-name", "BlackholeNative")
      external dynamic blackhole([dynamic val]);
      foo(int p) {
        var a = blackhole(), b;
        for (var i = 0; i < 42; i++) {
          b = blackhole();
          try {
            blackhole([a, b]);
          } catch (e) {
            // a and i should be synchronized
          }
        }
      }
      main() {
        foo(42);
      }
  )";

  TryCatchOptimizerTest(thread, script_chars, /*synchronized=*/{"a", "i"});
}

ISOLATE_UNIT_TEST_CASE(TryCatchOptimizer_DeadParameterElimination_Cyclic2) {
  const char* script_chars = R"(
      @pragma("vm:external-name", "BlackholeNative")
      external dynamic blackhole([dynamic val]);
      foo(int p) {
        var a = blackhole(), b = blackhole();
        for (var i = 0; i < 42; i++) {
          try {
            blackhole([a, b]);
          } catch (e) {
            // a, b and i should be synchronized
          }
        }
      }
      main() {
        foo(42);
      }
  )";

  TryCatchOptimizerTest(thread, script_chars, /*synchronized=*/{"a", "b", "i"});
}

// LoadOptimizer tests

// This family of tests verifies behavior of load forwarding when alias for an
// allocation A is created by creating a redefinition for it and then
// letting redefinition escape.
static void TestAliasingViaRedefinition(
    Thread* thread,
    bool make_it_escape,
    std::function<Definition*(CompilerState* S, FlowGraph*, Definition*)>
        make_redefinition) {
  const char* script_chars = R"(
    @pragma("vm:external-name", "BlackholeNative")
    external dynamic blackhole([a, b, c, d, e, f]);
    class K {
      var field;
    }
  )";
  const Library& lib =
      Library::Handle(LoadTestScript(script_chars, NoopNativeLookup));

  const Class& cls = Class::ZoneHandle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "K"))));
  const Error& err = Error::Handle(cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  const Field& original_field = Field::Handle(
      cls.LookupField(String::Handle(Symbols::New(thread, "field"))));
  EXPECT(!original_field.IsNull());
  const Field& field = Field::Handle(original_field.CloneFromOriginal());

  const Function& blackhole =
      Function::ZoneHandle(GetFunction(lib, "blackhole"));

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  // We are going to build the following graph:
  //
  // B0[graph_entry]
  // B1[function_entry]:
  //   v0 <- AllocateObject(class K)
  //   v1 <- LoadField(v0, K.field)
  //   v2 <- make_redefinition(v0)
  //   MoveArgument(v1)
  // #if make_it_escape
  //   MoveArgument(v2)
  // #endif
  //   v3 <- StaticCall(blackhole, v1, v2)
  //   v4 <- LoadField(v2, K.field)
  //   Return v4

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();
  AllocateObjectInstr* v0;
  LoadFieldInstr* v1;
  StaticCallInstr* call;
  LoadFieldInstr* v4;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    auto& slot = Slot::Get(field, &H.flow_graph()->parsed_function());
    v0 = builder.AddDefinition(
        new AllocateObjectInstr(InstructionSource(), cls, S.GetNextDeoptId()));
    v1 = builder.AddDefinition(
        new LoadFieldInstr(new Value(v0), slot, InstructionSource()));
    auto v2 = builder.AddDefinition(make_redefinition(&S, H.flow_graph(), v0));
    InputsArray args(2);
    args.Add(new Value(v1));
    if (make_it_escape) {
      args.Add(new Value(v2));
    }
    call = builder.AddInstruction(new StaticCallInstr(
        InstructionSource(), blackhole, 0, Array::empty_array(),
        std::move(args), S.GetNextDeoptId(), 0, ICData::RebindRule::kStatic));
    v4 = builder.AddDefinition(
        new LoadFieldInstr(new Value(v2), slot, InstructionSource()));
    ret = builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(v4), S.GetNextDeoptId()));
  }
  H.FinishGraph();
  DominatorBasedCSE::Optimize(H.flow_graph());

  if (make_it_escape) {
    // Allocation must be considered aliased.
    EXPECT_PROPERTY(v0, !it.Identity().IsNotAliased());
  } else {
    // Allocation must be considered not-aliased.
    EXPECT_PROPERTY(v0, it.Identity().IsNotAliased());
  }

  // v1 should have been removed from the graph and replaced with constant_null.
  EXPECT_PROPERTY(v1, it.next() == nullptr && it.previous() == nullptr);
  EXPECT_PROPERTY(call, it.ArgumentAt(0) == H.flow_graph()->constant_null());

  if (make_it_escape) {
    // v4 however should not be removed from the graph, because v0 escapes into
    // blackhole.
    EXPECT_PROPERTY(v4, it.next() != nullptr && it.previous() != nullptr);
    EXPECT_PROPERTY(ret, it.value()->definition() == v4);
  } else {
    // If v0 it not aliased then v4 should also be removed from the graph.
    EXPECT_PROPERTY(v4, it.next() == nullptr && it.previous() == nullptr);
    EXPECT_PROPERTY(
        ret, it.value()->definition() == H.flow_graph()->constant_null());
  }
}

static Definition* MakeCheckNull(CompilerState* S,
                                 FlowGraph* flow_graph,
                                 Definition* defn) {
  return new CheckNullInstr(new Value(defn), String::ZoneHandle(),
                            S->GetNextDeoptId(), InstructionSource());
}

static Definition* MakeRedefinition(CompilerState* S,
                                    FlowGraph* flow_graph,
                                    Definition* defn) {
  return new RedefinitionInstr(new Value(defn));
}

static Definition* MakeAssertAssignable(CompilerState* S,
                                        FlowGraph* flow_graph,
                                        Definition* defn) {
  const auto& dst_type = AbstractType::ZoneHandle(Type::ObjectType());
  return new AssertAssignableInstr(InstructionSource(), new Value(defn),
                                   new Value(flow_graph->GetConstant(dst_type)),
                                   new Value(flow_graph->constant_null()),
                                   new Value(flow_graph->constant_null()),
                                   Symbols::Empty(), S->GetNextDeoptId());
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedefinitionAliasing_CheckNull_NoEscape) {
  TestAliasingViaRedefinition(thread, /*make_it_escape=*/false, MakeCheckNull);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedefinitionAliasing_CheckNull_Escape) {
  TestAliasingViaRedefinition(thread, /*make_it_escape=*/true, MakeCheckNull);
}

ISOLATE_UNIT_TEST_CASE(
    LoadOptimizer_RedefinitionAliasing_Redefinition_NoEscape) {
  TestAliasingViaRedefinition(thread, /*make_it_escape=*/false,
                              MakeRedefinition);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedefinitionAliasing_Redefinition_Escape) {
  TestAliasingViaRedefinition(thread, /*make_it_escape=*/true,
                              MakeRedefinition);
}

ISOLATE_UNIT_TEST_CASE(
    LoadOptimizer_RedefinitionAliasing_AssertAssignable_NoEscape) {
  TestAliasingViaRedefinition(thread, /*make_it_escape=*/false,
                              MakeAssertAssignable);
}

ISOLATE_UNIT_TEST_CASE(
    LoadOptimizer_RedefinitionAliasing_AssertAssignable_Escape) {
  TestAliasingViaRedefinition(thread, /*make_it_escape=*/true,
                              MakeAssertAssignable);
}

// This family of tests verifies behavior of load forwarding when alias for an
// allocation A is created by storing it into another object B and then
// either loaded from it ([make_it_escape] is true) or object B itself
// escapes ([make_host_escape] is true).
// We insert redefinition for object B to check that use list traversal
// correctly discovers all loads and stores from B.
static void TestAliasingViaStore(
    Thread* thread,
    bool make_it_escape,
    bool make_host_escape,
    std::function<Definition*(CompilerState* S, FlowGraph*, Definition*)>
        make_redefinition) {
  const char* script_chars = R"(
    @pragma("vm:external-name", "BlackholeNative")
    external dynamic blackhole([a, b, c, d, e, f]);
    class K {
      var field;
    }
  )";
  const Library& lib =
      Library::Handle(LoadTestScript(script_chars, NoopNativeLookup));

  const Class& cls = Class::ZoneHandle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "K"))));
  const Error& err = Error::Handle(cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  const Field& original_field = Field::Handle(
      cls.LookupField(String::Handle(Symbols::New(thread, "field"))));
  EXPECT(!original_field.IsNull());
  const Field& field = Field::Handle(original_field.CloneFromOriginal());

  const Function& blackhole =
      Function::ZoneHandle(GetFunction(lib, "blackhole"));

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  // We are going to build the following graph:
  //
  // B0[graph_entry]
  // B1[function_entry]:
  //   v0 <- AllocateObject(class K)
  //   v5 <- AllocateObject(class K)
  // #if !make_host_escape
  //   StoreField(v5 . K.field = v0)
  // #endif
  //   v1 <- LoadField(v0, K.field)
  //   v2 <- REDEFINITION(v5)
  //   MoveArgument(v1)
  // #if make_it_escape
  //   v6 <- LoadField(v2, K.field)
  //   MoveArgument(v6)
  // #elif make_host_escape
  //   StoreField(v2 . K.field = v0)
  //   MoveArgument(v5)
  // #endif
  //   v3 <- StaticCall(blackhole, v1, v6)
  //   v4 <- LoadField(v0, K.field)
  //   Return v4

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();
  AllocateObjectInstr* v0;
  AllocateObjectInstr* v5;
  LoadFieldInstr* v1;
  StaticCallInstr* call;
  LoadFieldInstr* v4;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    auto& slot = Slot::Get(field, &H.flow_graph()->parsed_function());
    v0 = builder.AddDefinition(
        new AllocateObjectInstr(InstructionSource(), cls, S.GetNextDeoptId()));
    v5 = builder.AddDefinition(
        new AllocateObjectInstr(InstructionSource(), cls, S.GetNextDeoptId()));
    if (!make_host_escape) {
      builder.AddInstruction(
          new StoreFieldInstr(slot, new Value(v5), new Value(v0),
                              kEmitStoreBarrier, InstructionSource()));
    }
    v1 = builder.AddDefinition(
        new LoadFieldInstr(new Value(v0), slot, InstructionSource()));
    auto v2 = builder.AddDefinition(make_redefinition(&S, H.flow_graph(), v5));
    InputsArray args(2);
    args.Add(new Value(v1));
    if (make_it_escape) {
      auto v6 = builder.AddDefinition(
          new LoadFieldInstr(new Value(v2), slot, InstructionSource()));
      args.Add(new Value(v6));
    } else if (make_host_escape) {
      builder.AddInstruction(
          new StoreFieldInstr(slot, new Value(v2), new Value(v0),
                              kEmitStoreBarrier, InstructionSource()));
      args.Add(new Value(v5));
    }
    call = builder.AddInstruction(new StaticCallInstr(
        InstructionSource(), blackhole, 0, Array::empty_array(),
        std::move(args), S.GetNextDeoptId(), 0, ICData::RebindRule::kStatic));
    v4 = builder.AddDefinition(
        new LoadFieldInstr(new Value(v0), slot, InstructionSource()));
    ret = builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(v4), S.GetNextDeoptId()));
  }
  H.FinishGraph();
  DominatorBasedCSE::Optimize(H.flow_graph());

  if (make_it_escape || make_host_escape) {
    // Allocation must be considered aliased.
    EXPECT_PROPERTY(v0, !it.Identity().IsNotAliased());
  } else {
    // Allocation must not be considered aliased.
    EXPECT_PROPERTY(v0, it.Identity().IsNotAliased());
  }

  if (make_host_escape) {
    EXPECT_PROPERTY(v5, !it.Identity().IsNotAliased());
  } else {
    EXPECT_PROPERTY(v5, it.Identity().IsNotAliased());
  }

  // v1 should have been removed from the graph and replaced with constant_null.
  EXPECT_PROPERTY(v1, it.next() == nullptr && it.previous() == nullptr);
  EXPECT_PROPERTY(call, it.ArgumentAt(0) == H.flow_graph()->constant_null());

  if (make_it_escape || make_host_escape) {
    // v4 however should not be removed from the graph, because v0 escapes into
    // blackhole.
    EXPECT_PROPERTY(v4, it.next() != nullptr && it.previous() != nullptr);
    EXPECT_PROPERTY(ret, it.value()->definition() == v4);
  } else {
    // If v0 it not aliased then v4 should also be removed from the graph.
    EXPECT_PROPERTY(v4, it.next() == nullptr && it.previous() == nullptr);
    EXPECT_PROPERTY(
        ret, it.value()->definition() == H.flow_graph()->constant_null());
  }
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaStore_CheckNull_NoEscape) {
  TestAliasingViaStore(thread, /*make_it_escape=*/false,
                       /* make_host_escape= */ false, MakeCheckNull);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaStore_CheckNull_Escape) {
  TestAliasingViaStore(thread, /*make_it_escape=*/true,
                       /* make_host_escape= */ false, MakeCheckNull);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaStore_CheckNull_EscapeViaHost) {
  TestAliasingViaStore(thread, /*make_it_escape=*/false,
                       /* make_host_escape= */ true, MakeCheckNull);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaStore_Redefinition_NoEscape) {
  TestAliasingViaStore(thread, /*make_it_escape=*/false,
                       /* make_host_escape= */ false, MakeRedefinition);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaStore_Redefinition_Escape) {
  TestAliasingViaStore(thread, /*make_it_escape=*/true,
                       /* make_host_escape= */ false, MakeRedefinition);
}

ISOLATE_UNIT_TEST_CASE(
    LoadOptimizer_AliasingViaStore_Redefinition_EscapeViaHost) {
  TestAliasingViaStore(thread, /*make_it_escape=*/false,
                       /* make_host_escape= */ true, MakeRedefinition);
}

ISOLATE_UNIT_TEST_CASE(
    LoadOptimizer_AliasingViaStore_AssertAssignable_NoEscape) {
  TestAliasingViaStore(thread, /*make_it_escape=*/false,
                       /* make_host_escape= */ false, MakeAssertAssignable);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaStore_AssertAssignable_Escape) {
  TestAliasingViaStore(thread, /*make_it_escape=*/true,
                       /* make_host_escape= */ false, MakeAssertAssignable);
}

ISOLATE_UNIT_TEST_CASE(
    LoadOptimizer_AliasingViaStore_AssertAssignable_EscapeViaHost) {
  TestAliasingViaStore(thread, /*make_it_escape=*/false,
                       /* make_host_escape= */ true, MakeAssertAssignable);
}

// This is a regression test for
// https://github.com/flutter/flutter/issues/48114.
ISOLATE_UNIT_TEST_CASE(LoadOptimizer_AliasingViaTypedDataAndUntaggedTypedData) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  const auto& lib = Library::Handle(Library::TypedDataLibrary());
  const Class& cls = Class::Handle(lib.LookupClass(Symbols::Uint32List()));
  const Error& err = Error::Handle(cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  const Function& function = Function::ZoneHandle(
      cls.LookupFactory(String::Handle(String::New("Uint32List."))));
  EXPECT(!function.IsNull());

  auto zone = H.flow_graph()->zone();

  // We are going to build the following graph:
  //
  //   B0[graph_entry] {
  //     vc0 <- Constant(0)
  //     vc42 <- Constant(42)
  //   }
  //
  //   B1[function_entry] {
  //   }
  //   array <- StaticCall(...) {_Uint32List}
  //   v1 <- LoadIndexed(array)
  //   v2 <- LoadField(array, Slot::PointerBase_data())
  //   StoreIndexed(v2, index=vc0, value=vc42)
  //   v3 <- LoadIndexed(array)
  //   return v3
  // }

  auto vc0 = H.flow_graph()->GetConstant(Integer::Handle(Integer::New(0)));
  auto vc42 = H.flow_graph()->GetConstant(Integer::Handle(Integer::New(42)));
  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  StaticCallInstr* array;
  LoadIndexedInstr* v1;
  LoadFieldInstr* v2;
  StoreIndexedInstr* store;
  LoadIndexedInstr* v3;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);

    //   array <- StaticCall(...) {_Uint32List}
    array = builder.AddDefinition(new StaticCallInstr(
        InstructionSource(), function, 0, Array::empty_array(), InputsArray(),
        DeoptId::kNone, 0, ICData::kNoRebind));
    array->UpdateType(CompileType::FromCid(kTypedDataUint32ArrayCid));
    array->SetResultType(zone, CompileType::FromCid(kTypedDataUint32ArrayCid));
    array->set_is_known_list_constructor(true);

    //   v1 <- LoadIndexed(array)
    v1 = builder.AddDefinition(new LoadIndexedInstr(
        new Value(array), new Value(vc0), /*index_unboxed=*/false, 1,
        kTypedDataUint32ArrayCid, kAlignedAccess, DeoptId::kNone,
        InstructionSource()));

    //   v2 <- LoadField(array, Slot::PointerBase_data())
    //   StoreIndexed(v2, index=0, value=42)
    v2 = builder.AddDefinition(new LoadFieldInstr(
        new Value(array), Slot::PointerBase_data(),
        InnerPointerAccess::kMayBeInnerPointer, InstructionSource()));
    store = builder.AddInstruction(new StoreIndexedInstr(
        new Value(v2), new Value(vc0), new Value(vc42), kNoStoreBarrier,
        /*index_unboxed=*/false, 1, kTypedDataUint32ArrayCid, kAlignedAccess,
        DeoptId::kNone, InstructionSource()));

    //   v3 <- LoadIndexed(array)
    v3 = builder.AddDefinition(new LoadIndexedInstr(
        new Value(array), new Value(vc0), /*index_unboxed=*/false, 1,
        kTypedDataUint32ArrayCid, kAlignedAccess, DeoptId::kNone,
        InstructionSource()));

    //   return v3
    ret = builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(v3), S.GetNextDeoptId()));
  }
  H.FinishGraph();

  DominatorBasedCSE::Optimize(H.flow_graph());
  {
    Instruction* sc = nullptr;
    Instruction* li = nullptr;
    Instruction* lf = nullptr;
    Instruction* s = nullptr;
    Instruction* li2 = nullptr;
    Instruction* r = nullptr;
    ILMatcher cursor(H.flow_graph(), b1, true);
    RELEASE_ASSERT(cursor.TryMatch({
        kMatchAndMoveFunctionEntry,
        {kMatchAndMoveStaticCall, &sc},
        {kMatchAndMoveLoadIndexed, &li},
        {kMatchAndMoveLoadField, &lf},
        {kMatchAndMoveStoreIndexed, &s},
        {kMatchAndMoveLoadIndexed, &li2},
        {kMatchDartReturn, &r},
    }));
    EXPECT(array == sc);
    EXPECT(v1 == li);
    EXPECT(v2 == lf);
    EXPECT(store == s);
    EXPECT(v3 == li2);
    EXPECT(ret == r);
  }
}

// This test ensures that a LoadNativeField of the PointerBase data field for
// a newly allocated TypedData object does not have tagged null forwarded to it,
// as that's wrong for two reasons: it's an unboxed field, and it is initialized
// during the allocation stub.
ISOLATE_UNIT_TEST_CASE(LoadOptimizer_LoadDataFieldOfNewTypedData) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto zone = H.flow_graph()->zone();

  // We are going to build the following graph:
  //
  //   B0[graph_entry] {
  //     vc42 <- Constant(42)
  //   }
  //
  //   B1[function_entry] {
  //   }
  //   array <- AllocateTypedData(kTypedDataUint8ArrayCid, vc42)
  //   view <- AllocateObject(kTypedDataUint8ArrayViewCid)
  //   v1 <- LoadNativeField(array, Slot::PointerBase_data())
  //   StoreNativeField(Slot::PointerBase_data(), view, v1, kNoStoreBarrier,
  //                    kInitalizing)
  //   return view
  // }

  const auto& lib = Library::Handle(zone, Library::TypedDataLibrary());
  EXPECT(!lib.IsNull());
  const Class& view_cls = Class::ZoneHandle(
      zone, lib.LookupClassAllowPrivate(Symbols::_Uint8ArrayView()));
  EXPECT(!view_cls.IsNull());
  const Error& err = Error::Handle(zone, view_cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  auto vc42 = H.flow_graph()->GetConstant(Integer::Handle(Integer::New(42)));
  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  AllocateTypedDataInstr* array;
  AllocateObjectInstr* view;
  LoadFieldInstr* v1;
  StoreFieldInstr* store;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);

    //   array <- AllocateTypedData(kTypedDataUint8ArrayCid, vc42)
    array = builder.AddDefinition(
        new AllocateTypedDataInstr(InstructionSource(), kTypedDataUint8ArrayCid,
                                   new (zone) Value(vc42), DeoptId::kNone));

    //   view <- AllocateObject(kTypedDataUint8ArrayViewCid, vta)
    view = builder.AddDefinition(
        new AllocateObjectInstr(InstructionSource(), view_cls, DeoptId::kNone));

    //   v1 <- LoadNativeField(array, Slot::PointerBase_data())
    v1 = builder.AddDefinition(new LoadFieldInstr(
        new (zone) Value(array), Slot::PointerBase_data(),
        InnerPointerAccess::kMayBeInnerPointer, InstructionSource()));

    //   StoreNativeField(Slot::PointerBase_data(), view, v1, kNoStoreBarrier,
    //                    kInitalizing)
    store = builder.AddInstruction(new StoreFieldInstr(
        Slot::PointerBase_data(), new (zone) Value(view), new (zone) Value(v1),
        kNoStoreBarrier, InnerPointerAccess::kMayBeInnerPointer,
        InstructionSource(), StoreFieldInstr::Kind::kInitializing));

    //   return view
    ret = builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(view), S.GetNextDeoptId()));
  }
  H.FinishGraph();

  DominatorBasedCSE::Optimize(H.flow_graph());
  {
    Instruction* alloc_array = nullptr;
    Instruction* alloc_view = nullptr;
    Instruction* lf = nullptr;
    Instruction* sf = nullptr;
    Instruction* r = nullptr;
    ILMatcher cursor(H.flow_graph(), b1, true);
    RELEASE_ASSERT(cursor.TryMatch({
        kMatchAndMoveFunctionEntry,
        {kMatchAndMoveAllocateTypedData, &alloc_array},
        {kMatchAndMoveAllocateObject, &alloc_view},
        {kMatchAndMoveLoadField, &lf},
        {kMatchAndMoveStoreField, &sf},
        {kMatchDartReturn, &r},
    }));
    EXPECT(array == alloc_array);
    EXPECT(view == alloc_view);
    EXPECT(v1 == lf);
    EXPECT(store == sf);
    EXPECT(ret == r);
  }
}

// This test verifies that we correctly alias load/stores into typed array
// which use different element sizes. This is a regression test for
// a fix in 836c04f.
ISOLATE_UNIT_TEST_CASE(LoadOptimizer_TypedArrayViewAliasing) {
  const char* script_chars = R"(
    import 'dart:typed_data';

    class View {
      final Float64List data;
      View(this.data);
    }
  )";
  const Library& lib =
      Library::Handle(LoadTestScript(script_chars, NoopNativeLookup));

  const Class& view_cls = Class::ZoneHandle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "View"))));
  const Error& err = Error::Handle(view_cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  const Field& original_field = Field::Handle(
      view_cls.LookupField(String::Handle(Symbols::New(thread, "data"))));
  EXPECT(!original_field.IsNull());
  const Field& field = Field::Handle(original_field.CloneFromOriginal());

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  Definition* load;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    // array <- AllocateTypedData(1)
    const auto array = builder.AddDefinition(new AllocateTypedDataInstr(
        InstructionSource(), kTypedDataFloat64ArrayCid,
        new Value(H.IntConstant(1)), DeoptId::kNone));
    // view <- AllocateObject(View)
    const auto view = builder.AddDefinition(
        new AllocateObjectInstr(InstructionSource(), view_cls, DeoptId::kNone));
    // StoreField(view.data = array)
    builder.AddInstruction(new StoreFieldInstr(
        field, new Value(view), new Value(array),
        StoreBarrierType::kNoStoreBarrier, InstructionSource(),
        &H.flow_graph()->parsed_function()));
    // StoreIndexed(array <float64>, 0, 1.0)
    builder.AddInstruction(new StoreIndexedInstr(
        new Value(array), new Value(H.IntConstant(0)),
        new Value(H.DoubleConstant(1.0)), StoreBarrierType::kNoStoreBarrier,
        /*index_unboxed=*/false,
        /*index_scale=*/Instance::ElementSizeFor(kTypedDataFloat64ArrayCid),
        kTypedDataFloat64ArrayCid, AlignmentType::kAlignedAccess,
        DeoptId::kNone, InstructionSource()));
    // array_alias <- LoadField(view.data)
    const auto array_alias = builder.AddDefinition(new LoadFieldInstr(
        new Value(view), Slot::Get(field, &H.flow_graph()->parsed_function()),
        InstructionSource()));
    // StoreIndexed(array_alias <float32>, 1, 2.0)
    builder.AddInstruction(new StoreIndexedInstr(
        new Value(array_alias), new Value(H.IntConstant(1)),
        new Value(H.DoubleConstant(2.0)), StoreBarrierType::kNoStoreBarrier,
        /*index_unboxed=*/false,
        /*index_scale=*/Instance::ElementSizeFor(kTypedDataFloat32ArrayCid),
        kTypedDataFloat32ArrayCid, AlignmentType::kAlignedAccess,
        DeoptId::kNone, InstructionSource()));
    // load <- LoadIndexed(array <float64>, 0)
    load = builder.AddDefinition(new LoadIndexedInstr(
        new Value(array), new Value(H.IntConstant(0)), /*index_unboxed=*/false,
        /*index_scale=*/Instance::ElementSizeFor(kTypedDataFloat64ArrayCid),
        kTypedDataFloat64ArrayCid, AlignmentType::kAlignedAccess,
        DeoptId::kNone, InstructionSource()));
    // Return(load)
    ret = builder.AddReturn(new Value(load));
  }
  H.FinishGraph();
  DominatorBasedCSE::Optimize(H.flow_graph());

  // Check that we do not forward the load in question.
  EXPECT_PROPERTY(ret, it.value()->definition() == load);
}

static void CountLoadsStores(FlowGraph* flow_graph,
                             intptr_t* loads,
                             intptr_t* stores) {
  for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      if (it.Current()->IsLoadField()) {
        (*loads)++;
      } else if (it.Current()->IsStoreField()) {
        (*stores)++;
      }
    }
  }
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedundantStoresAndLoads) {
  const char* kScript = R"(
    class Bar {
      Bar() { a = null; }
      dynamic a;
    }

    Bar foo() {
      Bar bar = new Bar();
      bar.a = null;
      bar.a = bar;
      bar.a = bar.a;
      return bar.a;
    }

    main() {
      foo();
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyICData,
      CompilerPass::kInlining,
      CompilerPass::kTypePropagation,
      CompilerPass::kSelectRepresentations,
      CompilerPass::kCanonicalize,
      CompilerPass::kConstantPropagation,
  });

  ASSERT(flow_graph != nullptr);

  // Before CSE, we have 2 loads and 4 stores.
  intptr_t bef_loads = 0;
  intptr_t bef_stores = 0;
  CountLoadsStores(flow_graph, &bef_loads, &bef_stores);
  EXPECT_EQ(2, bef_loads);
  EXPECT_EQ(4, bef_stores);

  DominatorBasedCSE::Optimize(flow_graph);

  // After CSE, no load and only one store remains.
  intptr_t aft_loads = 0;
  intptr_t aft_stores = 0;
  CountLoadsStores(flow_graph, &aft_loads, &aft_stores);
  EXPECT_EQ(0, aft_loads);
  EXPECT_EQ(1, aft_stores);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedundantStaticFieldInitialization) {
  const char* kScript = R"(
    int getX() => 2;
    int x = getX();

    foo() => x + x;

    main() {
      foo();
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  ASSERT(flow_graph != nullptr);

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveFunctionEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveLoadStaticField,
      kMoveParallelMoves,
      kMatchAndMoveCheckSmi,
      kMoveParallelMoves,
      kMatchAndMoveBinarySmiOp,
      kMoveParallelMoves,
      kMatchDartReturn,
  }));
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedundantInitializerCallAfterIf) {
  const char* kScript = R"(
    int x = int.parse('1');

    @pragma('vm:never-inline')
    use(int arg) {}

    foo(bool condition) {
      if (condition) {
        x = 3;
      } else {
        use(x);
      }
      use(x);
    }

    main() {
      foo(true);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  ASSERT(flow_graph != nullptr);

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  LoadStaticFieldInstr* load_static_after_if = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      kMatchAndMoveGoto,
      kMatchAndMoveJoinEntry,
      kMoveParallelMoves,
      {kMatchAndMoveLoadStaticField, &load_static_after_if},
      kMoveGlob,
      kMatchDartReturn,
  }));
  EXPECT(!load_static_after_if->calls_initializer());
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedundantInitializerCallInLoop) {
  const char* kScript = R"(
    class A {
      late int x = int.parse('1');
      A? next;
    }

    @pragma('vm:never-inline')
    use(int arg) {}

    foo(A obj) {
      use(obj.x);
      for (;;) {
        use(obj.x);
        final next = obj.next;
        if (next == null) {
          break;
        }
        obj = next;
        use(obj.x);
      }
    }

    main() {
      foo(A()..next = A());
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  ASSERT(flow_graph != nullptr);

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  LoadFieldInstr* load_field_before_loop = nullptr;
  LoadFieldInstr* load_field_in_loop1 = nullptr;
  LoadFieldInstr* load_field_in_loop2 = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveLoadField, &load_field_before_loop},
      kMoveGlob,
      kMatchAndMoveGoto,
      kMatchAndMoveJoinEntry,
      kMoveGlob,
      {kMatchAndMoveLoadField, &load_field_in_loop1},
      kMoveGlob,
      kMatchAndMoveBranchFalse,
      kMoveGlob,
      {kMatchAndMoveLoadField, &load_field_in_loop2},
  }));

  EXPECT(load_field_before_loop->calls_initializer());
  EXPECT(!load_field_in_loop1->calls_initializer());
  EXPECT(load_field_in_loop2->calls_initializer());
}

#if !defined(TARGET_ARCH_IA32)

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedundantInitializingStoreAOT) {
  const char* kScript = R"(
class Vec3 {
  final double x, y, z;

  @pragma('vm:prefer-inline')
  const Vec3(this.x, this.y, this.z);

  @override
  @pragma('vm:prefer-inline')
  String toString() => _vec3ToString(x, y, z);
}

@pragma('vm:never-inline')
String _vec3ToString(double x, double y, double z) => '';

// Boxed storage for Vec3.
// Fields are unboxed.
class Vec3Mut {
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  Vec3Mut(Vec3 v)
      : _x = v.x,
        _y = v.y,
        _z = v.z;

  @override
  String toString() => _vec3ToString(_x, _y, _z);

  @pragma('vm:prefer-inline')
  set vec(Vec3 v) {
      _x = v.x;
      _y = v.y;
      _z = v.z;
  }
}

Vec3Mut main() {
  final a = Vec3(3, 4, 5);
  final b = Vec3(8, 9, 10);
  final c = Vec3(18, 19, 20);
  final d = Vec3(180, 190, 200);
  final e = Vec3(1800, 1900, 2000);
  final v = Vec3Mut(a);
  v.vec = b;
  v.vec = c;
  v.vec = d;
  v.vec = e;
  return v;
}
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "main"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  auto entry = flow_graph->graph_entry()->normal_entry();

  AllocateObjectInstr* allocate;
  StoreFieldInstr* store1;
  StoreFieldInstr* store2;
  StoreFieldInstr* store3;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveAllocateObject, &allocate},
      {kMatchAndMoveStoreField, &store1},
      {kMatchAndMoveStoreField, &store2},
      {kMatchAndMoveStoreField, &store3},
      kMatchDartReturn,
  }));

  EXPECT(store1->instance()->definition() == allocate);
  EXPECT(store2->instance()->definition() == allocate);
  EXPECT(store3->instance()->definition() == allocate);
}

ISOLATE_UNIT_TEST_CASE(LoadOptimizer_RedundantStoreAOT) {
  const char* kScript = R"(
class Foo {
  int x = -1;

  toString() => "Foo x: $x";
}

class Bar {}

main() {
  final foo = Foo();
  foo.x = 11;
  new Bar();
  foo.x = 12;
  new Bar();
  foo.x = 13;
  return foo;
}
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");
  const auto& function = Function::Handle(GetFunction(root_library, "main"));
  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  auto entry = flow_graph->graph_entry()->normal_entry();

  AllocateObjectInstr* allocate;
  StoreFieldInstr* store1;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveAllocateObject, &allocate},
      {kMatchAndMoveStoreField, &store1},  // initializing store
      kMatchDartReturn,
  }));

  EXPECT(store1->instance()->definition() == allocate);
}

#endif  // !defined(TARGET_ARCH_IA32)

ISOLATE_UNIT_TEST_CASE(AllocationSinking_Arrays) {
  const char* kScript = R"(
import 'dart:typed_data';

class Vector2 {
  final Float64List _v2storage;

  @pragma('vm:prefer-inline')
  Vector2.zero() : _v2storage = Float64List(2);

  @pragma('vm:prefer-inline')
  factory Vector2(double x, double y) => Vector2.zero()..setValues(x, y);

  @pragma('vm:prefer-inline')
  factory Vector2.copy(Vector2 other) => Vector2.zero()..setFrom(other);

  @pragma('vm:prefer-inline')
  Vector2 clone() => Vector2.copy(this);

  @pragma('vm:prefer-inline')
  void setValues(double x_, double y_) {
    _v2storage[0] = x_;
    _v2storage[1] = y_;
  }

  @pragma('vm:prefer-inline')
  void setFrom(Vector2 other) {
    final otherStorage = other._v2storage;
    _v2storage[1] = otherStorage[1];
    _v2storage[0] = otherStorage[0];
  }

  @pragma('vm:prefer-inline')
  Vector2 operator +(Vector2 other) => clone()..add(other);

  @pragma('vm:prefer-inline')
  void add(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v2storage[0] = _v2storage[0] + argStorage[0];
    _v2storage[1] = _v2storage[1] + argStorage[1];
  }

  @pragma('vm:prefer-inline')
  double get x => _v2storage[0];

  @pragma('vm:prefer-inline')
  double get y => _v2storage[1];
}

@pragma('vm:never-inline')
String foo(double x) {
  // All allocations in this function are eliminated by the compiler,
  // except array allocation for string interpolation at the end.
  List v1 = List.filled(2, null);
  v1[0] = 1;
  v1[1] = 'hi';
  Vector2 v2 = new Vector2(1.0, 2.0);
  Vector2 v3 = v2 + Vector2(x, x);
  double sum = v3.x + v3.y;
  return "v1: [${v1[0]},${v1[1]}], v2: [${v2.x},${v2.y}], v3: [${v3.x},${v3.y}], sum: $sum";
}

main() {
  foo(42.0);
}
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  ASSERT(flow_graph != nullptr);

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  /* Flow graph to match:

  4:     CheckStackOverflow:8(stack=0, loop=0)
  5:     ParallelMove rax <- fp[2]
  6:     v291 <- Unbox:14(v2) double
  8:     ParallelMove xmm2 <- C
  8:     v208 <- BinaryDoubleOp:22(+, v297 T{_Double}, v291 T{_Double}) double
  9:     ParallelMove fp[-5] f64 <- xmm2
 10:     v214 <- BinaryDoubleOp:34(+, v291 T{_Double}, v298 T{_Double}) double
 11:     ParallelMove fp[-4] f64 <- xmm1
 12:     ParallelMove xmm0 <- xmm2
 12:     v15 <- BinaryDoubleOp:28(+, v208 T{_Double}, v214 T{_Double}) double
 13:     ParallelMove rbx <- C, r10 <- C, fp[-3] f64 <- xmm0
 14:     v17 <- CreateArray:30(v0, v16) T{_List}
 15:     ParallelMove rcx <- rax
 16:     StoreIndexed([_List] v17, v5, v18, NoStoreBarrier)
 18:     StoreIndexed([_List] v17, v6, v6, NoStoreBarrier)
 20:     StoreIndexed([_List] v17, v3, v20, NoStoreBarrier)
 22:     StoreIndexed([_List] v17, v21, v7, NoStoreBarrier)
 24:     StoreIndexed([_List] v17, v23, v24, NoStoreBarrier)
 26:     StoreIndexed([_List] v17, v25, v8 T{_Double}, NoStoreBarrier)
 28:     StoreIndexed([_List] v17, v27, v20, NoStoreBarrier)
 30:     StoreIndexed([_List] v17, v28, v9 T{_Double}, NoStoreBarrier)
 32:     StoreIndexed([_List] v17, v30, v31, NoStoreBarrier)
 33:     ParallelMove xmm0 <- fp[-5] f64
 34:     v295 <- Box(v208 T{_Double}) T{_Double}
 35:     ParallelMove rdx <- rcx, rax <- rax
 36:     StoreIndexed([_List] v17, v32, v295 T{_Double})
 38:     StoreIndexed([_List] v17, v34, v20, NoStoreBarrier)
 39:     ParallelMove xmm0 <- fp[-4] f64
 40:     v296 <- Box(v214 T{_Double}) T{_Double}
 41:     ParallelMove rdx <- rcx, rax <- rax
 42:     StoreIndexed([_List] v17, v35, v296 T{_Double})
 44:     StoreIndexed([_List] v17, v37, v38, NoStoreBarrier)
 45:     ParallelMove xmm0 <- fp[-3] f64
 46:     v292 <- Box(v15) T{_Double}
 47:     ParallelMove rdx <- rcx, rax <- rax
 48:     StoreIndexed([_List] v17, v39, v292 T{_Double})
 50:     MoveArgument(sp[0] <- v17)
 52:     v40 <- StaticCall:44( _interpolate@0150898<0> v17, recognized_kind = StringBaseInterpolate) T{String}
 54:     DartReturn:48(v40)
*/

  CreateArrayInstr* create_array = nullptr;
  StaticCallInstr* string_interpolate = nullptr;

  ILMatcher cursor(flow_graph, entry, /*trace=*/true,
                   ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveFunctionEntry,
      kMatchAndMoveCheckStackOverflow,
  }));
  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveUnbox,
      kMatchAndMoveBinaryDoubleOp,
      kMatchAndMoveBinaryDoubleOp,
      kMatchAndMoveBinaryDoubleOp,
      {kMatchAndMoveCreateArray, &create_array},
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveBox,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveBox,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveBox,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveMoveArgument,
      {kMatchAndMoveStaticCall, &string_interpolate},
      kMatchDartReturn,
  }));

  EXPECT(string_interpolate->ArgumentAt(0) == create_array);
}

ISOLATE_UNIT_TEST_CASE(AllocationSinking_Records) {
  const char* kScript = R"(

@pragma('vm:prefer-inline')
({int field1, String field2}) getRecord(int x, String y) =>
    (field1: x, field2: y);

@pragma('vm:never-inline')
String foo(int x, String y) {
  // All allocations in this function are eliminated by the compiler,
  // except array allocation for string interpolation at the end.
  (int, bool) r1 = (x, true);
  final r2 = getRecord(x, y);
  int sum = r1.$1 + r2.field1;
  return "r1: (${r1.$1}, ${r1.$2}), "
    "r2: (field1: ${r2.field1}, field2: ${r2.field2}), sum: $sum";
}

int count = 0;
main() {
  // Deoptimize on the 2nd run.
  return foo(count++ == 0 ? 42 : 9223372036854775807, 'hey');
}
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& result1 = Object::Handle(Invoke(root_library, "main"));
  EXPECT(result1.IsString());
  EXPECT_STREQ(result1.ToCString(),
               "r1: (42, true), r2: (field1: 42, field2: hey), sum: 84");
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  ASSERT(flow_graph != nullptr);

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  /* Flow graph to match:

  2: B1[function entry]:2 {
      v2 <- Parameter(0) [-9223372036854775808, 9223372036854775807] T{int}
      v3 <- Parameter(1) T{String}
}
  4:     CheckStackOverflow:8(stack=0, loop=0)
  5:     ParallelMove rax <- S+3
  6:     CheckSmi:16(v2)
  8:     ParallelMove rcx <- rax
  8:     v9 <- BinarySmiOp:16(+, v2 T{_Smi}, v2 T{_Smi}) [-4611686018427387904, 4611686018427387903] T{_Smi}
  9:     ParallelMove rbx <- C, r10 <- C, S-3 <- rcx
 10:     v11 <- CreateArray:18(v0, v10) T{_List}
 11:     ParallelMove rax <- rax
 12:     StoreIndexed(v11, v12, v13, NoStoreBarrier)
 13:     ParallelMove rcx <- S+3
 14:     StoreIndexed(v11, v14, v2 T{_Smi}, NoStoreBarrier)
 16:     StoreIndexed(v11, v16, v17, NoStoreBarrier)
 18:     StoreIndexed(v11, v18, v5, NoStoreBarrier)
 20:     StoreIndexed(v11, v20, v21, NoStoreBarrier)
 22:     StoreIndexed(v11, v22, v2 T{_Smi}, NoStoreBarrier)
 24:     StoreIndexed(v11, v24, v25, NoStoreBarrier)
 25:     ParallelMove rcx <- S+2
 26:     StoreIndexed(v11, v26, v3, NoStoreBarrier)
 28:     StoreIndexed(v11, v28, v29, NoStoreBarrier)
 29:     ParallelMove rcx <- S-3
 30:     StoreIndexed(v11, v30, v9, NoStoreBarrier)
 32:     MoveArgument(v11)
 34:     v31 <- StaticCall:20( _interpolate@0150898<0> v11, recognized_kind = StringBaseInterpolate) T{String}
 35:     ParallelMove rax <- rax
 36:     Return:24(v31)
*/

  ILMatcher cursor(flow_graph, entry, /*trace=*/true,
                   ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMatchAndMoveFunctionEntry,
      kMatchAndMoveCheckStackOverflow,
      kMatchAndMoveCheckSmi,
      kMatchAndMoveBinarySmiOp,
      kMatchAndMoveCreateArray,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveStoreIndexed,
      kMatchAndMoveMoveArgument,
      kMatchAndMoveStaticCall,
      kMatchDartReturn,
  }));

  Compiler::CompileOptimizedFunction(thread, function);
  const auto& result2 = Object::Handle(Invoke(root_library, "main"));
  EXPECT(result2.IsString());
  EXPECT_STREQ(result2.ToCString(),
               "r1: (9223372036854775807, true), r2: (field1: "
               "9223372036854775807, field2: hey), sum: -2");
}

#if !defined(TARGET_ARCH_IA32)

ISOLATE_UNIT_TEST_CASE(DelayAllocations_DelayAcrossCalls) {
  const char* kScript = R"(
    class A {
      dynamic x, y;
      A(this.x, this.y);
    }

    int count = 0;

    @pragma("vm:never-inline")
    dynamic foo(int i) => count++ < 2 ? i : '$i';

    @pragma("vm:never-inline")
    dynamic use(v) {}

    @pragma("vm:entry-point", "call")
    void test() {
      A a = new A(foo(1), foo(2));
      use(a);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  // Get fields to kDynamicCid guard
  Invoke(root_library, "test");
  Invoke(root_library, "test");

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  auto entry = flow_graph->graph_entry()->normal_entry();

  StaticCallInstr* call1;
  StaticCallInstr* call2;
  AllocateObjectInstr* allocate;
  StoreFieldInstr* store1;
  StoreFieldInstr* store2;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call1},
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call2},
      kMoveGlob,
      {kMatchAndMoveAllocateObject, &allocate},
      {kMatchAndMoveStoreField, &store1},
      {kMatchAndMoveStoreField, &store2},
  }));

  EXPECT(strcmp(call1->function().UserVisibleNameCString(), "foo") == 0);
  EXPECT(strcmp(call2->function().UserVisibleNameCString(), "foo") == 0);
  EXPECT(store1->instance()->definition() == allocate);
  EXPECT(!store1->ShouldEmitStoreBarrier());
  EXPECT(store2->instance()->definition() == allocate);
  EXPECT(!store2->ShouldEmitStoreBarrier());
}

ISOLATE_UNIT_TEST_CASE(DelayAllocations_DontDelayIntoLoop) {
  const char* kScript = R"(
    void test() {
      Object o = new Object();
      for (int i = 0; i < 10; i++) {
        use(o);
      }
    }

    @pragma('vm:never-inline')
    void use(Object o) {
      print(o.hashCode);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});
  auto entry = flow_graph->graph_entry()->normal_entry();

  AllocateObjectInstr* allocate;
  StaticCallInstr* call;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveAllocateObject, &allocate},
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      {kMatchAndMoveStaticCall, &call},
  }));

  EXPECT(strcmp(call->function().UserVisibleNameCString(), "use") == 0);
  EXPECT(call->Receiver()->definition() == allocate);
}

ISOLATE_UNIT_TEST_CASE(CheckStackOverflowElimination_NoInterruptsPragma) {
  const char* kScript = R"(
    @pragma('vm:unsafe:no-interrupts')
    @pragma('vm:prefer-inline')
    int baz() {
      int result = 0;
      for (int i = 0; i < 10; i++) {
        print("");
        result ^= i;
      }
      return result;
    }

    int test() {
      return baz();
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  auto flow_graph = pipeline.RunPasses({});
  for (auto block : flow_graph->postorder()) {
    for (auto instr : block->instructions()) {
      EXPECT_PROPERTY(instr, !it.IsCheckStackOverflow() ||
                                 it.previous()->IsFunctionEntry());
    }
  }
}

// This test checks that CSE unwraps redefinitions when comparing all
// instructions except loads, which are handled specially.
ISOLATE_UNIT_TEST_CASE(CSE_Redefinitions) {
  const char* script_chars = R"(
    @pragma("vm:external-name", "BlackholeNative")
    external dynamic blackhole([a, b, c, d, e, f]);
    class K<T> {
      final T field;
      K(this.field);
    }
  )";
  const Library& lib =
      Library::Handle(LoadTestScript(script_chars, NoopNativeLookup));

  const Class& cls = Class::ZoneHandle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "K"))));
  const Error& err = Error::Handle(cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  const Field& original_field = Field::Handle(
      cls.LookupField(String::Handle(Symbols::New(thread, "field"))));
  EXPECT(!original_field.IsNull());
  const Field& field = Field::Handle(original_field.CloneFromOriginal());

  const Function& blackhole =
      Function::ZoneHandle(GetFunction(lib, "blackhole"));

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H(/*num_parameters=*/2);
  H.AddVariable("v0", AbstractType::ZoneHandle(Type::DynamicType()));
  H.AddVariable("v1", AbstractType::ZoneHandle(Type::DynamicType()));

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  BoxInstr* box0;
  BoxInstr* box1;
  LoadFieldInstr* load0;
  LoadFieldInstr* load1;
  LoadFieldInstr* load2;
  StaticCallInstr* call;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    auto& slot = Slot::Get(field, &H.flow_graph()->parsed_function());
    auto param0 = builder.AddParameter(0, kUnboxedDouble);
    auto param1 = builder.AddParameter(1, kTagged);
    auto redef0 =
        builder.AddDefinition(new RedefinitionInstr(new Value(param0)));
    auto redef1 =
        builder.AddDefinition(new RedefinitionInstr(new Value(param0)));
    box0 = builder.AddDefinition(
        BoxInstr::Create(kUnboxedDouble, new Value(redef0)));
    box1 = builder.AddDefinition(
        BoxInstr::Create(kUnboxedDouble, new Value(redef1)));

    auto redef2 =
        builder.AddDefinition(new RedefinitionInstr(new Value(param1)));
    auto redef3 =
        builder.AddDefinition(new RedefinitionInstr(new Value(param1)));
    load0 = builder.AddDefinition(
        new LoadFieldInstr(new Value(redef2), slot, InstructionSource()));
    load1 = builder.AddDefinition(
        new LoadFieldInstr(new Value(redef3), slot, InstructionSource()));
    load2 = builder.AddDefinition(
        new LoadFieldInstr(new Value(redef3), slot, InstructionSource()));

    InputsArray args(3);
    args.Add(new Value(load0));
    args.Add(new Value(load1));
    args.Add(new Value(load2));
    call = builder.AddInstruction(new StaticCallInstr(
        InstructionSource(), blackhole, 0, Array::empty_array(),
        std::move(args), S.GetNextDeoptId(), 0, ICData::RebindRule::kStatic));

    ret = builder.AddReturn(new Value(box1));
  }
  H.FinishGraph();

  // Running CSE without load optimization should eliminate redundant boxing
  // but keep loads intact if they don't  have exactly matching inputs.
  DominatorBasedCSE::Optimize(H.flow_graph(), /*run_load_optimization=*/false);

  EXPECT_PROPERTY(box1, it.WasEliminated());
  EXPECT_PROPERTY(ret, it.value()->definition() == box0);

  EXPECT_PROPERTY(load0, !it.WasEliminated());
  EXPECT_PROPERTY(load1, !it.WasEliminated());
  EXPECT_PROPERTY(load2, it.WasEliminated());

  EXPECT_PROPERTY(call, it.ArgumentAt(0) == load0);
  EXPECT_PROPERTY(call, it.ArgumentAt(1) == load1);
  EXPECT_PROPERTY(call, it.ArgumentAt(2) == load1);

  // Running load optimization pass should remove the second load but
  // insert a redefinition to prevent code motion because the field
  // has a generic type.
  DominatorBasedCSE::Optimize(H.flow_graph(), /*run_load_optimization=*/true);

  EXPECT_PROPERTY(load0, !it.WasEliminated());
  EXPECT_PROPERTY(load1, it.WasEliminated());
  EXPECT_PROPERTY(load2, it.WasEliminated());

  EXPECT_PROPERTY(call, it.ArgumentAt(0) == load0);
  EXPECT_PROPERTY(call, it.ArgumentAt(1)->IsRedefinition() &&
                            it.ArgumentAt(1)->OriginalDefinition() == load0);
  EXPECT_PROPERTY(call, it.ArgumentAt(2)->IsRedefinition() &&
                            it.ArgumentAt(2)->OriginalDefinition() == load0);
}

ISOLATE_UNIT_TEST_CASE(AllocationSinking_NoViewDataMaterialization) {
  auto* const kFunctionName = "unalignedUint16";
  auto* const kInvokeNoDeoptName = "no_deopt";
  auto* const kInvokeDeoptName = "deopt";
  CStringUniquePtr kScript(OS::SCreate(nullptr, R"(
        import 'dart:_internal';
        import 'dart:typed_data';

        @pragma("vm:never-inline")
        void check(int x, int y) {
          if (x != y) {
            throw "Doesn't match";
          }
        }

        @pragma("vm:never-inline")
        bool %s(num x) {
          var bytes = new ByteData(64);
          if (x is int) {
            for (var i = 2; i < 4; i++) {
              bytes.setUint16(i, x + 1, Endian.host);
              check(x + 1, bytes.getUint16(i, Endian.host));
            }
          } else {
            // Force a garbage collection after deoptimization. In DEBUG mode,
            // the scavenger tests that the view's data field was set correctly
            // during deoptimization before recomputing it.
            VMInternalsForTesting.collectAllGarbage();
          }
          // Make sure the array is also used on the non-int path.
          check(0, bytes.getUint16(0, Endian.host));
          return x is int;
        }

        @pragma("vm:entry-point", "call")
        bool %s() {
          return %s(0xABCC);
        }

        @pragma("vm:entry-point", "call")
        bool %s() {
          return %s(1.0);
        }
            )",
                                       kFunctionName, kInvokeNoDeoptName,
                                       kFunctionName, kInvokeDeoptName,
                                       kFunctionName));

  const auto& lib =
      Library::Handle(LoadTestScript(kScript.get(), NoopNativeLookup));
  EXPECT(!lib.IsNull());
  if (lib.IsNull()) return;

  const auto& function = Function::ZoneHandle(GetFunction(lib, kFunctionName));
  EXPECT(!function.IsNull());
  if (function.IsNull()) return;

  // Run the unoptimized code.
  auto& result = Object::Handle(Invoke(lib, kInvokeNoDeoptName));
  EXPECT(Bool::Cast(result).value());

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
      CompilerPass::kApplyICData,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyClassIds,
      CompilerPass::kInlining,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyClassIds,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyICData,
      CompilerPass::kCanonicalize,
      CompilerPass::kBranchSimplify,
      CompilerPass::kIfConvert,
      CompilerPass::kCanonicalize,
      CompilerPass::kConstantPropagation,
      CompilerPass::kOptimisticallySpecializeSmiPhis,
      CompilerPass::kTypePropagation,
      CompilerPass::kSelectRepresentations,
      CompilerPass::kCSE,
      CompilerPass::kCanonicalize,
      CompilerPass::kLICM,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSelectRepresentations,
      CompilerPass::kDSE,
      CompilerPass::kTypePropagation,
      CompilerPass::kSelectRepresentations,
      CompilerPass::kEliminateEnvironments,
      CompilerPass::kEliminateDeadPhis,
      CompilerPass::kDCE,
      CompilerPass::kCanonicalize,
      CompilerPass::kOptimizeBranches,
  });

  // Check for the soon-to-be-sunk ByteDataView allocation.

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  AllocateTypedDataInstr* alloc_typed_data = nullptr;
  AllocateObjectInstr* alloc_view = nullptr;
  StoreFieldInstr* store_view_typed_data = nullptr;
  StoreFieldInstr* store_view_offset_in_bytes = nullptr;
  StoreFieldInstr* store_view_length = nullptr;
  LoadFieldInstr* load_typed_data_payload = nullptr;
  StoreFieldInstr* store_view_payload = nullptr;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  EXPECT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveAllocateTypedData, &alloc_typed_data},
      {kMatchAndMoveAllocateObject, &alloc_view},
      {kMatchAndMoveStoreField, &store_view_typed_data},
      {kMatchAndMoveStoreField, &store_view_offset_in_bytes},
      {kMatchAndMoveStoreField, &store_view_length},
      {kMatchAndMoveLoadField, &load_typed_data_payload},
      {kMatchAndMoveStoreField, &store_view_payload},
  }));
  if (store_view_payload == nullptr) return;

  EXPECT_EQ(alloc_view, store_view_typed_data->instance()->definition());
  EXPECT(Slot::TypedDataView_typed_data().IsIdentical(
      store_view_typed_data->slot()));
  EXPECT_EQ(alloc_typed_data, store_view_typed_data->value()->definition());

  EXPECT_EQ(alloc_view, store_view_length->instance()->definition());
  EXPECT(Slot::TypedDataBase_length().IsIdentical(store_view_length->slot()));
  EXPECT_EQ(alloc_typed_data->num_elements()->definition(),
            store_view_length->value()->definition());

  EXPECT_EQ(alloc_view, store_view_offset_in_bytes->instance()->definition());
  EXPECT(Slot::TypedDataView_offset_in_bytes().IsIdentical(
      store_view_offset_in_bytes->slot()));
  EXPECT(store_view_offset_in_bytes->value()->BindsToSmiConstant());
  EXPECT_EQ(0, store_view_offset_in_bytes->value()->BoundSmiConstant());

  EXPECT_EQ(alloc_typed_data,
            load_typed_data_payload->instance()->definition());
  EXPECT(Slot::PointerBase_data().IsIdentical(load_typed_data_payload->slot()));

  EXPECT_EQ(alloc_view, store_view_payload->instance()->definition());
  EXPECT(Slot::PointerBase_data().IsIdentical(store_view_payload->slot()));
  EXPECT_EQ(load_typed_data_payload, store_view_payload->value()->definition());

  // Setting the view data field is the only use of the unsafe payload load.
  EXPECT(load_typed_data_payload->HasOnlyUse(store_view_payload->value()));

  pipeline.RunAdditionalPasses({
      CompilerPass::kAllocationSinking_Sink,
  });

  // After sinking, the view allocation has been removed from the flow graph.
  EXPECT_EQ(nullptr, alloc_view->previous());
  EXPECT_EQ(nullptr, alloc_view->next());
  // There is at least one MaterializeObject instruction created for the view.
  intptr_t mat_count = 0;
  for (auto block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      auto* const mat = it.Current()->AsMaterializeObject();
      if (mat == nullptr) continue;
      if (mat->allocation() == alloc_view) {
        ++mat_count;
        for (intptr_t i = 0; i < mat->InputCount(); i++) {
          // No slot of the materialization should correspond to the data field.
          EXPECT(mat->FieldOffsetAt(i) !=
                 Slot::PointerBase_data().offset_in_bytes());
          // No input of the materialization should be a load of the typed
          // data object's payload.
          if (auto* const load = mat->InputAt(i)->definition()->AsLoadField()) {
            if (load->instance()->definition() == alloc_typed_data) {
              EXPECT(!load->slot().IsIdentical(Slot::PointerBase_data()));
            }
          }
        }
      }
    }
  }
  EXPECT(mat_count > 0);
  // There are no uses of the original unsafe payload load. In particular, no
  // MaterializeObject instructions use it.
  EXPECT(!load_typed_data_payload->HasUses());

  pipeline.RunAdditionalPasses({
      CompilerPass::kEliminateDeadPhis,
      CompilerPass::kDCE,
      CompilerPass::kCanonicalize,
      CompilerPass::kTypePropagation,
      CompilerPass::kSelectRepresentations_Final,
      CompilerPass::kUseTableDispatch,
      CompilerPass::kEliminateStackOverflowChecks,
      CompilerPass::kCanonicalize,
      CompilerPass::kAllocationSinking_DetachMaterializations,
      CompilerPass::kEliminateWriteBarriers,
      CompilerPass::kLoweringAfterCodeMotionDisabled,
      CompilerPass::kFinalizeGraph,
      CompilerPass::kCanonicalize,
      CompilerPass::kReorderBlocks,
      CompilerPass::kAllocateRegisters,
      CompilerPass::kTestILSerialization,
  });

  // Finish the compilation and attach code so we can run it.
  pipeline.CompileGraphAndAttachFunction();

  // Can run optimized code fine without deoptimization.
  result = Invoke(lib, kInvokeNoDeoptName);
  EXPECT(function.HasOptimizedCode());
  EXPECT(Bool::Cast(result).value());

  // Can run code fine with deoptimization.
  result = Invoke(lib, kInvokeDeoptName);
  // Deoptimization has put us back to unoptimized code.
  EXPECT(!function.HasOptimizedCode());
  EXPECT(!Bool::Cast(result).value());
}

#endif  // !defined(TARGET_ARCH_IA32)

// Verify that temporary |Pointer| and |Struct| allocations are sunk away
// in JIT mode.
ISOLATE_UNIT_TEST_CASE(Ffi_StructSinking) {
  const char* kScript =
      R"(
      import 'dart:ffi';

      final class S extends Struct {
        @Int8()
        external int a;
      }

      @pragma('vm:entry-point')
      int test(int addr) =>
        Pointer<S>.fromAddress(addr)[0].a;
      )";

  const auto& lib = Library::Handle(LoadTestScript(kScript, NoopNativeLookup));
  EXPECT(!lib.IsNull());
  const auto& function = Function::ZoneHandle(GetFunction(lib, "test"));
  EXPECT(!function.IsNull());

  // Run the unoptimized code.
  uint8_t buffer[10] = {42};
  auto& result = Object::Handle(Invoke(
      lib, "test",
      Integer::Handle(Integer::New(reinterpret_cast<int64_t>(&buffer)))));
  EXPECT_EQ(42, Integer::Cast(result).Value());

  // Optimize 'test' function.
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  FlowGraphPrinter::PrintGraph("aaa", flow_graph);

  // Verify that it does not contain any allocations or calls.
  for (auto block : flow_graph->reverse_postorder()) {
    for (auto instr : block->instructions()) {
      EXPECT_PROPERTY(instr, !it.IsAllocateObject());
      EXPECT_PROPERTY(instr, !it.IsStaticCall() && !it.IsInstanceCall() &&
                                 !it.IsPolymorphicInstanceCall());
    }
  }
}

// Regression test for https://github.com/dart-lang/sdk/issues/51220.
// Verifies that deoptimization at the hoisted BinarySmiOp
// doesn't result in the infinite re-optimization loop.
ISOLATE_UNIT_TEST_CASE(LICM_Deopt_Regress51220) {
  CStringUniquePtr kScript(OS::SCreate(nullptr,
                                       R"(
        int n = int.parse('3');
        main() {
          int x = 0;
          for (int i = 0; i < n; ++i) {
            if (i > ((1 << %d)*1024)) {
              ++x;
            }
          }
          return x;
        }
      )",
                                       static_cast<int>(kSmiBits + 1 - 10)));

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
  const auto& function = Function::Handle(GetFunction(root_library, "main"));

  // Run unoptimized code.
  Invoke(root_library, "main");
  EXPECT(!function.HasOptimizedCode());

  Compiler::CompileOptimizedFunction(thread, function);
  EXPECT(function.HasOptimizedCode());

  // Only 2 rounds of deoptimization are allowed:
  // * the first round should disable LICM;
  // * the second round should disable BinarySmiOp.
  Invoke(root_library, "main");
  EXPECT(!function.HasOptimizedCode());
  //  EXPECT(function.ProhibitsInstructionHoisting());

  Compiler::CompileOptimizedFunction(thread, function);
  EXPECT(function.HasOptimizedCode());

  Invoke(root_library, "main");
  EXPECT(!function.HasOptimizedCode());
  //  EXPECT(function.ProhibitsInstructionHoisting());

  Compiler::CompileOptimizedFunction(thread, function);
  EXPECT(function.HasOptimizedCode());

  // Should not deoptimize.
  Invoke(root_library, "main");
  EXPECT(function.HasOptimizedCode());
}

// Regression test for https://github.com/dart-lang/sdk/issues/50245.
// Verifies that deoptimization at the hoisted GuardFieldClass
// doesn't result in the infinite re-optimization loop.
ISOLATE_UNIT_TEST_CASE(LICM_Deopt_Regress50245) {
  const char* kScript = R"(
    class A {
      List<int> foo;
      A(this.foo);
    }

    A obj = A([1, 2, 3]);
    int n = int.parse('3');

    main() {
      // Make sure A.foo= is compiled.
      obj.foo = [];
      int sum = 0;
      for (int i = 0; i < n; ++i) {
        if (int.parse('1') != 1) {
          // Field guard from this unreachable code is moved up
          // and causes repeated deoptimization.
          obj.foo = const [];
        }
        sum += i;
      }
      return sum;
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "main"));

  // Run unoptimized code.
  Invoke(root_library, "main");
  EXPECT(!function.HasOptimizedCode());

  Compiler::CompileOptimizedFunction(thread, function);
  EXPECT(function.HasOptimizedCode());

  // LICM should be disabled after the first round of deoptimization.
  Invoke(root_library, "main");
  EXPECT(!function.HasOptimizedCode());
  //  EXPECT(function.ProhibitsInstructionHoisting());

  Compiler::CompileOptimizedFunction(thread, function);
  EXPECT(function.HasOptimizedCode());

  // Should not deoptimize.
  Invoke(root_library, "main");
  EXPECT(function.HasOptimizedCode());
}

}  // namespace dart
