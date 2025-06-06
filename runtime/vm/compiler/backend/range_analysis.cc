// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/range_analysis.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"

namespace dart {

DEFINE_FLAG(bool,
            array_bounds_check_elimination,
            true,
            "Eliminate redundant bounds checks.");
DEFINE_FLAG(bool, trace_range_analysis, false, "Trace range analysis progress");
DEFINE_FLAG(bool,
            trace_integer_ir_selection,
            false,
            "Print integer IR selection optimization pass.");
DECLARE_FLAG(bool, trace_constant_propagation);

// Quick access to the locally defined zone() method.
#define Z (zone())

#define TRACE_RANGE_ANALYSIS(statement)                                        \
  if (FLAG_support_il_printer && FLAG_trace_range_analysis &&                  \
      CompilerState::ShouldTrace()) {                                          \
    statement;                                                                 \
  }

#if defined(DEBUG)
static void CheckRangeForRepresentation(const Assert& assert,
                                        const Instruction* instr,
                                        const Range* range,
                                        Representation rep) {
  const Range other = Range::Full(rep);
  if (!RangeUtils::IsWithin(range, &other)) {
    assert.Fail(
        "During range analysis for:\n  %s\n"
        "expected range containing only %s-representable values, but got %s",
        instr->ToCString(), RepresentationUtils::ToCString(rep),
        Range::ToCString(range));
  }
}

#define ASSERT_VALID_RANGE_FOR_REPRESENTATION(instr, range, representation)    \
  do {                                                                         \
    CheckRangeForRepresentation(dart::Assert(__FILE__, __LINE__), instr,       \
                                range, representation);                        \
  } while (false)
#else
#define ASSERT_VALID_RANGE_FOR_REPRESENTATION(instr, range, representation)    \
  do {                                                                         \
    USE(instr);                                                                \
    USE(range);                                                                \
    USE(representation);                                                       \
  } while (false)
#endif

void RangeAnalysis::Analyze() {
  CollectValues();
  InsertConstraints();
  flow_graph_->GetLoopHierarchy().ComputeInduction();
  InferRanges();
  EliminateRedundantBoundsChecks();
  MarkUnreachableBlocks();

  NarrowInt64OperationsToInt32();

  IntegerInstructionSelector iis(flow_graph_);
  iis.Select();

  RemoveConstraints();
}

// Helper method to chase to a constrained definition.
static Definition* UnwrapConstraint(Definition* defn) {
  while (defn->IsConstraint()) {
    defn = defn->AsConstraint()->value()->definition();
  }
  return defn;
}

void RangeAnalysis::CollectValues() {
  auto graph_entry = flow_graph_->graph_entry();

  auto& initial = *graph_entry->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* current = initial[i];
    if (IsIntegerDefinition(current)) {
      values_.Add(current);
    }
  }

  for (intptr_t i = 0; i < graph_entry->SuccessorCount(); ++i) {
    auto successor = graph_entry->SuccessorAt(i);
    if (auto entry = successor->AsBlockEntryWithInitialDefs()) {
      const auto& initial = *entry->initial_definitions();
      for (intptr_t j = 0; j < initial.length(); ++j) {
        Definition* current = initial[j];
        if (IsIntegerDefinition(current)) {
          values_.Add(current);
        }
      }
    }
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != nullptr) {
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* current = phi_it.Current();
        if (current->Type()->IsInt()) {
          values_.Add(current);
        }
      }
    }

    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if (defn != nullptr) {
        if (defn->HasSSATemp() && IsIntegerDefinition(defn)) {
          values_.Add(defn);
          if (auto bin_op = defn->AsBinaryInt64Op()) {
            binary_int64_ops_.Add(bin_op);
          }
        }
      }
      if (auto check = current->AsCheckBoundBase()) {
        bounds_checks_.Add(check);
      }
      ComparisonInstr* comparison = nullptr;
      if (auto branch = current->AsBranch()) {
        comparison = branch->condition()->AsComparison();
      } else if (auto if_then_else = current->AsIfThenElse()) {
        comparison = if_then_else->condition()->AsComparison();
      } else if (auto check_condition = current->AsCheckCondition()) {
        comparison = check_condition->condition()->AsComparison();
      } else {
        comparison = current->AsComparison();
      }
      if ((comparison != nullptr) &&
          (comparison->input_representation() == kUnboxedInt64)) {
        int64_comparisons_.Add(comparison);
      }
    }
  }
}

// Given a boundary (right operand) and a comparison operation return
// a symbolic range constraint for the left operand of the comparison assuming
// that it evaluated to true.
// For example for the comparison a < b symbol a is constrained with range
// [min, b - 1].
Range* RangeAnalysis::ConstraintRange(Token::Kind op,
                                      Definition* boundary,
                                      const Range& full_range) {
  switch (op) {
    case Token::kEQ:
      return new (Z) Range(RangeBoundary::FromDefinition(boundary),
                           RangeBoundary::FromDefinition(boundary));
    case Token::kNE:
      return new (Z) Range(full_range);
    case Token::kLT:
      return new (Z)
          Range(full_range.min(), RangeBoundary::FromDefinition(boundary, -1));
    case Token::kGT:
      return new (Z)
          Range(RangeBoundary::FromDefinition(boundary, 1), full_range.max());
    case Token::kLTE:
      return new (Z)
          Range(full_range.min(), RangeBoundary::FromDefinition(boundary));
    case Token::kGTE:
      return new (Z)
          Range(RangeBoundary::FromDefinition(boundary), full_range.max());
    default:
      UNREACHABLE();
      return nullptr;
  }
}

ConstraintInstr* RangeAnalysis::InsertConstraintFor(Value* use,
                                                    Definition* defn,
                                                    Range* constraint_range,
                                                    Instruction* after) {
  // No need to constrain constants.
  if (defn->IsConstant()) return nullptr;

  // Check if the value is already constrained to avoid inserting duplicated
  // constraints.
  ConstraintInstr* constraint = after->next()->AsConstraint();
  while (constraint != nullptr) {
    if ((constraint->value()->definition() == defn) &&
        constraint->constraint()->Equals(constraint_range)) {
      return nullptr;
    }
    constraint = constraint->next()->AsConstraint();
  }

  constraint = new (Z) ConstraintInstr(use->CopyWithType(), constraint_range,
                                       defn->representation());

  flow_graph_->InsertAfter(after, constraint, nullptr, FlowGraph::kValue);
  FlowGraph::RenameDominatedUses(defn, constraint, constraint);
  constraints_.Add(constraint);
  return constraint;
}

bool RangeAnalysis::ConstrainValueAfterBranch(Value* use, Definition* defn) {
  BranchInstr* branch = use->instruction()->AsBranch();
  RelationalOpInstr* rel_op = branch->condition()->AsRelationalOp();
  if ((rel_op != nullptr) && !rel_op->IsFloatingPoint()) {
    // Found comparison of two integers. Constrain defn at true and false
    // successors using the other operand as a boundary.
    Definition* boundary;
    Token::Kind op_kind;
    if (use->use_index() == 0) {  // Left operand.
      boundary = rel_op->InputAt(1)->definition();
      op_kind = rel_op->kind();
    } else {
      ASSERT(use->use_index() == 1);  // Right operand.
      boundary = rel_op->InputAt(0)->definition();
      // InsertConstraintFor assumes that defn is left operand of a
      // comparison if it is right operand flip the comparison.
      op_kind = Token::FlipComparison(rel_op->kind());
    }
    const Representation representation = rel_op->input_representation();
    Range full_range;
    if (representation == kTagged) {
      full_range = Range::Smi();
    } else {
      ASSERT(RepresentationUtils::IsUnboxedInteger(representation));
      // Can only create symbolic boundaries based on Smi values.
      if (!Definition::IsLengthLoad(boundary)) {
        return false;
      }
      full_range = Range::Full(representation);
    }

    // Constrain definition at the true successor.
    ConstraintInstr* true_constraint = InsertConstraintFor(
        use, defn, ConstraintRange(op_kind, boundary, full_range),
        branch->true_successor());
    if (true_constraint != nullptr) {
      true_constraint->set_target(branch->true_successor());
    }

    // Constrain definition with a negated condition at the false successor.
    ConstraintInstr* false_constraint = InsertConstraintFor(
        use, defn,
        ConstraintRange(Token::NegateComparison(op_kind), boundary, full_range),
        branch->false_successor());
    if (false_constraint != nullptr) {
      false_constraint->set_target(branch->false_successor());
    }

    return true;
  }

  return false;
}

void RangeAnalysis::InsertConstraintsFor(Definition* defn) {
  for (Value* use = defn->input_use_list(); use != nullptr;
       use = use->next_use()) {
    if (auto branch = use->instruction()->AsBranch()) {
      if (ConstrainValueAfterBranch(use, defn)) {
        Value* other_value = branch->InputAt(1 - use->use_index());
        if (!IsIntegerDefinition(other_value->definition())) {
          ConstrainValueAfterBranch(other_value, other_value->definition());
        }
      }
    } else if (auto check = use->instruction()->AsCheckBoundBase()) {
      ConstrainValueAfterCheckBound(use, check, defn);
    }
  }
}

void RangeAnalysis::ConstrainValueAfterCheckBound(Value* use,
                                                  CheckBoundBaseInstr* check,
                                                  Definition* defn) {
  const intptr_t use_index = use->use_index();

  Range* constraint_range = nullptr;
  if (use_index == CheckBoundBaseInstr::kIndexPos) {
    Definition* length = check->length()->definition();
    constraint_range = new (Z) Range(RangeBoundary::FromConstant(0),
                                     RangeBoundary::FromDefinition(length, -1));
  } else {
    ASSERT(use_index == CheckBoundBaseInstr::kLengthPos);
    Definition* index = check->index()->definition();
    constraint_range = new (Z)
        Range(RangeBoundary::FromDefinition(index, 1), RangeBoundary::MaxSmi());
  }
  InsertConstraintFor(use, defn, constraint_range, check);
}

void RangeAnalysis::InsertConstraints() {
  for (intptr_t i = 0; i < values_.length(); i++) {
    InsertConstraintsFor(values_[i]);
  }

  for (intptr_t i = 0; i < constraints_.length(); i++) {
    InsertConstraintsFor(constraints_[i]);
  }
}

static bool AreEqualDefinitions(Definition* a, Definition* b) {
  a = UnwrapConstraint(a);
  b = UnwrapConstraint(b);
  return (a == b) || (a->AllowsCSE() && b->AllowsCSE() && a->Equals(*b));
}

static bool DependOnSameSymbol(const RangeBoundary& a, const RangeBoundary& b) {
  return a.IsSymbol() && b.IsSymbol() &&
         AreEqualDefinitions(a.symbol(), b.symbol());
}

// Given the current range of a phi and a newly computed range check
// if it is growing towards negative infinity, if it does widen it to
// MinSmi.
static RangeBoundary WidenMin(const Range* range,
                              const Range* new_range,
                              const Range& full_range) {
  RangeBoundary min = range->min();
  RangeBoundary new_min = new_range->min();

  if (min.IsSymbol()) {
    if (min.LowerBound().Overflowed(full_range)) {
      return full_range.min();
    } else if (DependOnSameSymbol(min, new_min)) {
      return min.offset() <= new_min.offset() ? min : full_range.min();
    } else if (min.UpperBound(full_range) <= new_min.LowerBound(full_range)) {
      return min;
    }
  }

  min = Range::ConstantMin(range, full_range);
  new_min = Range::ConstantMin(new_range, full_range);

  return (min.ConstantValue() <= new_min.ConstantValue()) ? min
                                                          : full_range.min();
}

// Given the current range of a phi and a newly computed range check
// if it is growing towards positive infinity, if it does widen it to
// MaxSmi.
static RangeBoundary WidenMax(const Range* range,
                              const Range* new_range,
                              const Range& full_range) {
  RangeBoundary max = range->max();
  RangeBoundary new_max = new_range->max();

  if (max.IsSymbol()) {
    if (max.UpperBound().Overflowed(full_range)) {
      return full_range.max();
    } else if (DependOnSameSymbol(max, new_max)) {
      return max.offset() >= new_max.offset() ? max : full_range.max();
    } else if (max.LowerBound(full_range) >= new_max.UpperBound(full_range)) {
      return max;
    }
  }

  max = Range::ConstantMax(range, full_range);
  new_max = Range::ConstantMax(new_range, full_range);

  return (max.ConstantValue() >= new_max.ConstantValue()) ? max
                                                          : full_range.max();
}

// Given the current range of a phi and a newly computed range check
// if we can perform narrowing: use newly computed minimum to improve precision
// of the computed range. We do it only if current minimum was widened and is
// equal to MinSmi.
// Newly computed minimum is expected to be greater or equal than old one as
// we are running after widening phase.
static RangeBoundary NarrowMin(const Range* range,
                               const Range* new_range,
                               const Range& full_range) {
  const RangeBoundary min = Range::ConstantMin(range, full_range);
  const RangeBoundary new_min = Range::ConstantMin(new_range, full_range);
  if (min.ConstantValue() > new_min.ConstantValue()) return range->min();

  // TODO(vegorov): consider using negative infinity to indicate widened bound.
  return range->min().IsLessOrEqual(full_range.min()) ? new_range->min()
                                                      : range->min();
}

// Given the current range of a phi and a newly computed range check
// if we can perform narrowing: use newly computed maximum to improve precision
// of the computed range. We do it only if current maximum was widened and is
// equal to MaxSmi.
// Newly computed maximum is expected to be less or equal than old one as
// we are running after widening phase.
static RangeBoundary NarrowMax(const Range* range,
                               const Range* new_range,
                               const Range& full_range) {
  const RangeBoundary max = Range::ConstantMax(range, full_range);
  const RangeBoundary new_max = Range::ConstantMax(new_range, full_range);
  if (max.ConstantValue() < new_max.ConstantValue()) return range->max();

  // TODO(vegorov): consider using positive infinity to indicate widened bound.
  return range->max().IsGreaterOrEqual(full_range.max()) ? new_range->max()
                                                         : range->max();
}

char RangeAnalysis::OpPrefix(JoinOperator op) {
  switch (op) {
    case WIDEN:
      return 'W';
    case NARROW:
      return 'N';
    case NONE:
      return 'I';
  }
  UNREACHABLE();
  return ' ';
}

static Range FullRangeForPhi(Definition* phi) {
  ASSERT(phi->IsPhi());
  if (phi->Type()->ToCid() == kSmiCid) {
    return Range::Smi();
  }
  const Representation rep = phi->representation();
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    return Range::Full(rep);
  }
  ASSERT(rep == kTagged);
  if (phi->Type()->IsInt()) {
    return Range::Int64();
  } else {
    UNREACHABLE();
  }
}

bool RangeAnalysis::InferRange(JoinOperator op,
                               Definition* defn,
                               intptr_t iteration) {
  Range range;
  defn->InferRange(this, &range);

  if (!Range::IsUnknown(&range)) {
    if (!Range::IsUnknown(defn->range()) && defn->IsPhi()) {
      const Range full_range = FullRangeForPhi(defn);
      if (op == WIDEN) {
        range = Range(WidenMin(defn->range(), &range, full_range),
                      WidenMax(defn->range(), &range, full_range));
      } else if (op == NARROW) {
        range = Range(NarrowMin(defn->range(), &range, full_range),
                      NarrowMax(defn->range(), &range, full_range));
      }
    }

    if (!range.Equals(defn->range())) {
#ifndef PRODUCT
      TRACE_RANGE_ANALYSIS(THR_Print("%c [%" Pd "] %s:  %s => %s\n",
                                     OpPrefix(op), iteration, defn->ToCString(),
                                     Range::ToCString(defn->range()),
                                     Range::ToCString(&range)));
#endif  // !PRODUCT
      defn->set_range(range);
      return true;
    }
  }

  return false;
}

void RangeAnalysis::CollectDefinitions(BitVector* set) {
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != nullptr) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        if (set->Contains(phi->ssa_temp_index())) {
          definitions_.Add(phi);
        }
      }
    }

    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Definition* defn = it.Current()->AsDefinition();
      if ((defn != nullptr) && defn->HasSSATemp() &&
          set->Contains(defn->ssa_temp_index())) {
        definitions_.Add(defn);
      }
    }
  }
}

void RangeAnalysis::Iterate(JoinOperator op, intptr_t max_iterations) {
  // TODO(vegorov): switch to worklist if this becomes performance bottleneck.
  intptr_t iteration = 0;
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < definitions_.length(); i++) {
      Definition* defn = definitions_[i];
      if (InferRange(op, defn, iteration)) {
        changed = true;
      }
    }

    iteration++;
  } while (changed && (iteration < max_iterations));
}

void RangeAnalysis::InferRanges() {
  Zone* zone = flow_graph_->zone();
  // Initialize bitvector for quick filtering of int values.
  BitVector* set =
      new (zone) BitVector(zone, flow_graph_->current_ssa_temp_index());
  for (intptr_t i = 0; i < values_.length(); i++) {
    set->Add(values_[i]->ssa_temp_index());
  }
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    set->Add(constraints_[i]->ssa_temp_index());
  }

  // Collect integer definitions (including constraints) in the reverse
  // postorder. This improves convergence speed compared to iterating
  // values_ and constraints_ array separately.
  auto graph_entry = flow_graph_->graph_entry();
  const auto& initial = *graph_entry->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* definition = initial[i];
    if (set->Contains(definition->ssa_temp_index())) {
      definitions_.Add(definition);
    }
  }

  for (intptr_t i = 0; i < graph_entry->SuccessorCount(); ++i) {
    auto successor = graph_entry->SuccessorAt(i);
    if (auto function_entry = successor->AsFunctionEntry()) {
      const auto& initial = *function_entry->initial_definitions();
      for (intptr_t j = 0; j < initial.length(); ++j) {
        Definition* definition = initial[j];
        if (set->Contains(definition->ssa_temp_index())) {
          definitions_.Add(definition);
        }
      }
    }
  }

  CollectDefinitions(set);

  // Perform an iteration of range inference just propagating ranges
  // through the graph as-is without applying widening or narrowing.
  // This helps to improve precision of initial bounds.
  // We are doing 2 iterations to hit common cases where phi range
  // stabilizes quickly and yields a better precision than after
  // widening and narrowing.
  Iterate(NONE, 2);

  // Perform fix-point iteration of range inference applying widening
  // operator to phis to ensure fast convergence.
  // Widening simply maps growing bounds to the respective range bound.
  Iterate(WIDEN, kMaxInt32);

  // Perform fix-point iteration of range inference applying narrowing
  // to phis to compute more accurate range.
  // Narrowing only improves those boundaries that were widened up to
  // range boundary and leaves other boundaries intact.
  Iterate(NARROW, kMaxInt32);
}

void RangeAnalysis::AssignRangesRecursively(Definition* defn) {
  if (!Range::IsUnknown(defn->range())) {
    return;
  }

  if (!IsIntegerDefinition(defn)) {
    return;
  }

  for (intptr_t i = 0; i < defn->InputCount(); i++) {
    Definition* input_defn = defn->InputAt(i)->definition();
    if (!input_defn->HasSSATemp() || input_defn->IsConstant()) {
      AssignRangesRecursively(input_defn);
    }
  }

  Range new_range;
  defn->InferRange(this, &new_range);
  if (!Range::IsUnknown(&new_range)) {
    defn->set_range(new_range);
  }
}

// Scheduler is a helper class that inserts floating control-flow less
// subgraphs into the flow graph.
// It always attempts to schedule instructions into the loop preheader in the
// way similar to LICM optimization pass.
// Scheduler supports rollback - that is it keeps track of instructions it
// schedules and can remove all instructions it inserted from the graph.
class Scheduler {
 public:
  explicit Scheduler(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        loop_headers_(flow_graph->GetLoopHierarchy().headers()),
        pre_headers_(loop_headers_.length()) {
    for (intptr_t i = 0; i < loop_headers_.length(); i++) {
      pre_headers_.Add(loop_headers_[i]->ImmediateDominator());
    }
  }

  // Clear the list of emitted instructions.
  void Start() { emitted_.Clear(); }

  // Given the floating instruction attempt to schedule it into one of the
  // loop preheaders that dominates given post_dominator instruction.
  // Some of the instruction inputs can potentially be unscheduled as well.
  // Returns nullptr is the scheduling fails (e.g. inputs are not invariant for
  // any loop containing post_dominator).
  // Resulting schedule should be equivalent to one obtained by inserting
  // instructions right before post_dominator and running CSE and LICM passes.
  template <typename T>
  T* Emit(T* instruction, Instruction* post_dominator) {
    return static_cast<T*>(EmitRecursively(instruction, post_dominator));
  }

  // Undo all insertions recorded in the list of emitted instructions.
  void Rollback() {
    for (intptr_t i = emitted_.length() - 1; i >= 0; i--) {
      emitted_[i]->RemoveFromGraph();
    }
    emitted_.Clear();
  }

 private:
  Instruction* EmitRecursively(Instruction* instruction, Instruction* sink) {
    // Schedule all unscheduled inputs and unwrap all constrained inputs.
    for (intptr_t i = 0; i < instruction->InputCount(); i++) {
      Definition* defn = instruction->InputAt(i)->definition();

      // Instruction is not in the graph yet which means that none of
      // its input uses should be recorded at defn's use chains.
      // Verify this assumption to ensure that we are not going to
      // leave use-lists in an inconsistent state when we start
      // rewriting inputs via set_definition.
      ASSERT(instruction->InputAt(i)->IsSingleUse() &&
             !defn->HasOnlyInputUse(instruction->InputAt(i)));

      if (!defn->HasSSATemp()) {
        Definition* scheduled = Emit(defn, sink);
        if (scheduled == nullptr) {
          return nullptr;
        }
        instruction->InputAt(i)->set_definition(scheduled);
      } else if (defn->IsConstraint()) {
        instruction->InputAt(i)->set_definition(UnwrapConstraint(defn));
      }
    }

    // Attempt to find equivalent instruction that was already scheduled.
    // If the instruction is still in the graph (it could have been
    // un-scheduled by a rollback action) and it dominates the sink - use it.
    Instruction* emitted = map_.LookupValue(instruction);
    if (emitted != nullptr && !emitted->WasEliminated() &&
        sink->IsDominatedBy(emitted)) {
      return emitted;
    }

    // Attempt to find suitable pre-header. Iterate loop headers backwards to
    // attempt scheduling into the outermost loop first.
    for (intptr_t i = loop_headers_.length() - 1; i >= 0; i--) {
      BlockEntryInstr* header = loop_headers_[i];
      BlockEntryInstr* pre_header = pre_headers_[i];

      if (pre_header == nullptr) {
        continue;
      }

      if (!sink->IsDominatedBy(header)) {
        continue;
      }

      Instruction* last = pre_header->last_instruction();

      bool inputs_are_invariant = true;
      for (intptr_t j = 0; j < instruction->InputCount(); j++) {
        Definition* defn = instruction->InputAt(j)->definition();
        if (!last->IsDominatedBy(defn)) {
          inputs_are_invariant = false;
          break;
        }
      }

      if (inputs_are_invariant) {
        EmitTo(pre_header, instruction);
        return instruction;
      }
    }

    return nullptr;
  }

  void EmitTo(BlockEntryInstr* block, Instruction* instr) {
    GotoInstr* last = block->last_instruction()->AsGoto();
    flow_graph_->InsertBefore(
        last, instr, last->env(),
        instr->IsDefinition() ? FlowGraph::kValue : FlowGraph::kEffect);
    instr->CopyDeoptIdFrom(*last);

    map_.Insert(instr);
    emitted_.Add(instr);
  }

  FlowGraph* flow_graph_;
  PointerSet<Instruction> map_;
  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers_;
  GrowableArray<BlockEntryInstr*> pre_headers_;
  GrowableArray<Instruction*> emitted_;
};

// If bounds check 0 <= index < length is not redundant we attempt to
// replace it with a sequence of checks that guarantee
//
//           0 <= LowerBound(index) < UpperBound(index) < length
//
// and hoist all of those checks out of the enclosing loop.
//
// Upper/Lower bounds are symbolic arithmetic expressions with +, -, *
// operations.
class BoundsCheckGeneralizer {
 public:
  BoundsCheckGeneralizer(RangeAnalysis* range_analysis, FlowGraph* flow_graph)
      : range_analysis_(range_analysis),
        flow_graph_(flow_graph),
        scheduler_(flow_graph) {}

  void TryGeneralize(CheckArrayBoundInstr* check) {
    Definition* upper_bound =
        ConstructUpperBound(check->index()->definition(), check);
    if (upper_bound == UnwrapConstraint(check->index()->definition())) {
      // Unable to construct upper bound for the index.
      TRACE_RANGE_ANALYSIS(
          THR_Print("Failed to construct upper bound for %s index\n",
                    check->ToCString()));
      return;
    }

    // Re-associate subexpressions inside upper_bound to collect all constants
    // together. This will expose more redundancies when we are going to emit
    // upper bound through scheduler.
    if (!Simplify(&upper_bound, nullptr)) {
      TRACE_RANGE_ANALYSIS(THR_Print(
          "Failed to simplify upper bound for %s index\n", check->ToCString()));
      return;
    }
    upper_bound = ApplyConstraints(upper_bound, check);
    range_analysis_->AssignRangesRecursively(upper_bound);

    // We are going to constrain any symbols participating in + and * operations
    // to guarantee that they are positive. Find all symbols that need
    // constraining. If there is a subtraction subexpression with non-positive
    // range give up on generalization for simplicity.
    GrowableArray<Definition*> non_positive_symbols;
    if (!FindNonPositiveSymbols(&non_positive_symbols, upper_bound)) {
#ifndef PRODUCT
      TRACE_RANGE_ANALYSIS(
          THR_Print("Failed to generalize %s index to %s"
                    " (can't ensure positivity)\n",
                    check->ToCString(), IndexBoundToCString(upper_bound)));
#endif  // !PRODUCT
      return;
    }

    // Check that we can statically prove that lower bound of the index is
    // non-negative under the assumption that all potentially non-positive
    // symbols are positive.
    GrowableArray<ConstraintInstr*> positive_constraints(
        non_positive_symbols.length());
    Range* positive_range =
        new Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
    for (intptr_t i = 0; i < non_positive_symbols.length(); i++) {
      Definition* symbol = non_positive_symbols[i];
      positive_constraints.Add(new ConstraintInstr(
          new Value(symbol), positive_range, symbol->representation()));
    }

    Definition* lower_bound =
        ConstructLowerBound(check->index()->definition(), check);
    // No need to simplify lower bound before applying constraints as
    // we are not going to emit it.
    lower_bound = ApplyConstraints(lower_bound, check, &positive_constraints);
    range_analysis_->AssignRangesRecursively(lower_bound);

    if (!RangeUtils::IsPositive(lower_bound->range())) {
// Can't prove that lower bound is positive even with additional checks
// against potentially non-positive symbols. Give up.
#ifndef PRODUCT
      TRACE_RANGE_ANALYSIS(
          THR_Print("Failed to generalize %s index to %s"
                    " (lower bound is not positive)\n",
                    check->ToCString(), IndexBoundToCString(upper_bound)));
#endif  // !PRODUCT
      return;
    }

#ifndef PRODUCT
    TRACE_RANGE_ANALYSIS(THR_Print(
        "For %s computed index bounds [%s, %s]\n", check->ToCString(),
        IndexBoundToCString(lower_bound), IndexBoundToCString(upper_bound)));
#endif  // !PRODUCT

    // At this point we know that 0 <= index < UpperBound(index) under
    // certain preconditions. Start by emitting this preconditions.
    scheduler_.Start();

    // AOT should only see non-deopting GenericCheckBound.
    ASSERT(!CompilerState::Current().is_aot());

    ConstantInstr* max_smi = flow_graph_->GetConstant(
        Smi::Handle(Smi::New(compiler::target::kSmiMax)));
    for (intptr_t i = 0; i < non_positive_symbols.length(); i++) {
      CheckArrayBoundInstr* precondition = new CheckArrayBoundInstr(
          new Value(max_smi), new Value(non_positive_symbols[i]),
          DeoptId::kNone);
      precondition->mark_generalized();
      precondition = scheduler_.Emit(precondition, check);
      if (precondition == nullptr) {
        TRACE_RANGE_ANALYSIS(
            THR_Print("  => failed to insert positivity constraint\n"));
        scheduler_.Rollback();
        return;
      }
    }

    CheckArrayBoundInstr* new_check = new CheckArrayBoundInstr(
        new Value(UnwrapConstraint(check->length()->definition())),
        new Value(upper_bound), DeoptId::kNone);
    new_check->mark_generalized();
    if (new_check->IsRedundant()) {
      TRACE_RANGE_ANALYSIS(THR_Print("  => generalized check is redundant\n"));
      RemoveGeneralizedCheck(check);
      return;
    }

    new_check = scheduler_.Emit(new_check, check);
    if (new_check != nullptr) {
      TRACE_RANGE_ANALYSIS(
          THR_Print("  => generalized check was hoisted into B%" Pd "\n",
                    new_check->GetBlock()->block_id()));
      RemoveGeneralizedCheck(check);
    } else {
      TRACE_RANGE_ANALYSIS(
          THR_Print("  => generalized check can't be hoisted\n"));
      scheduler_.Rollback();
    }
  }

  static void RemoveGeneralizedCheck(CheckArrayBoundInstr* check) {
    BinarySmiOpInstr* binary_op = check->index()->definition()->AsBinarySmiOp();
    if (binary_op != nullptr) {
      binary_op->set_can_overflow(false);
    }
    check->ReplaceUsesWith(check->index()->definition());
    check->RemoveFromGraph();
  }

 private:
  BinarySmiOpInstr* MakeBinaryOp(Token::Kind op_kind,
                                 Definition* left,
                                 Definition* right) {
    return new BinarySmiOpInstr(op_kind, new Value(left), new Value(right),
                                DeoptId::kNone);
  }

  BinarySmiOpInstr* MakeBinaryOp(Token::Kind op_kind,
                                 Definition* left,
                                 intptr_t right) {
    ConstantInstr* constant_right =
        flow_graph_->GetConstant(Smi::Handle(Smi::New(right)));
    return MakeBinaryOp(op_kind, left, constant_right);
  }

  Definition* RangeBoundaryToDefinition(const RangeBoundary& bound) {
    Definition* symbol = UnwrapConstraint(bound.symbol());
    if (bound.offset() == 0) {
      return symbol;
    } else {
      return MakeBinaryOp(Token::kADD, symbol, bound.offset());
    }
  }

  typedef Definition* (BoundsCheckGeneralizer::*PhiBoundFunc)(PhiInstr*,
                                                              LoopInfo*,
                                                              InductionVar*,
                                                              Instruction*);

  // Construct symbolic lower bound for a value at the given point.
  Definition* ConstructLowerBound(Definition* value, Instruction* point) {
    return ConstructBound(&BoundsCheckGeneralizer::InductionVariableLowerBound,
                          value, point);
  }

  // Construct symbolic upper bound for a value at the given point.
  Definition* ConstructUpperBound(Definition* value, Instruction* point) {
    return ConstructBound(&BoundsCheckGeneralizer::InductionVariableUpperBound,
                          value, point);
  }

  // Helper methods to implement "older" business logic.
  // TODO(ajcbik): generalize with new induction variable information

  // Only accept loops with a smi constraint on smi induction.
  LoopInfo* GetSmiBoundedLoop(PhiInstr* phi) {
    LoopInfo* loop = phi->GetBlock()->loop_info();
    if (loop == nullptr) {
      return nullptr;
    }
    ConstraintInstr* limit = loop->limit();
    if (limit == nullptr) {
      return nullptr;
    }
    Definition* def = UnwrapConstraint(limit->value()->definition());
    Range* constraining_range = limit->constraint();
    if (GetSmiInduction(loop, def) != nullptr &&
        constraining_range->min().Equals(RangeBoundary::MinSmi()) &&
        constraining_range->max().IsSymbol() &&
        def->IsDominatedBy(constraining_range->max().symbol())) {
      return loop;
    }
    return nullptr;
  }

  // Returns true if x is invariant and is either based on a Smi definition
  // or is a Smi constant.
  static bool IsSmiInvariant(const InductionVar* x) {
    return InductionVar::IsInvariant(x) && Smi::IsValid(x->offset()) &&
           Smi::IsValid(x->mult()) &&
           (x->mult() == 0 || x->def()->Type()->ToCid() == kSmiCid);
  }

  // Only accept smi linear induction with unit stride.
  InductionVar* GetSmiInduction(LoopInfo* loop, Definition* def) {
    if (loop != nullptr && def->Type()->ToCid() == kSmiCid) {
      InductionVar* induc = loop->LookupInduction(def);
      int64_t stride;
      if (induc != nullptr && InductionVar::IsLinear(induc, &stride) &&
          stride == 1 && IsSmiInvariant(induc->initial())) {
        return induc;
      }
    }
    return nullptr;
  }

  // Reconstruct invariant.
  Definition* GenerateInvariant(InductionVar* induc) {
    Definition* res = nullptr;
    if (induc->mult() == 0) {
      res =
          flow_graph_->GetConstant(Smi::ZoneHandle(Smi::New(induc->offset())));
    } else {
      res = induc->def();
      if (induc->mult() != 1) {
        res = MakeBinaryOp(Token::kMUL, res, induc->mult());
      }
      if (induc->offset() != 0) {
        res = MakeBinaryOp(Token::kADD, res, induc->offset());
      }
    }
    return res;
  }

  // Construct symbolic bound for a value at the given point:
  //
  //   1. if value is an induction variable use its bounds;
  //   2. if value is addition or multiplication construct bounds for left
  //      and right hand sides separately and use addition/multiplication
  //      of bounds as a bound (addition and multiplication are monotone
  //      operations for both operands);
  //   3. if value is a substraction then construct bound for the left hand
  //      side and use substraction of the right hand side from the left hand
  //      side bound as a bound for an expression (substraction is monotone for
  //      the left hand side operand).
  //
  Definition* ConstructBound(PhiBoundFunc phi_bound_func,
                             Definition* value,
                             Instruction* point) {
    value = UnwrapConstraint(value);
    if (value->IsPhi()) {
      PhiInstr* phi = value->AsPhi();
      LoopInfo* loop = GetSmiBoundedLoop(phi);
      InductionVar* induc = GetSmiInduction(loop, phi);
      if (induc != nullptr) {
        return (this->*phi_bound_func)(phi, loop, induc, point);
      }
    } else if (value->IsBinarySmiOp()) {
      BinarySmiOpInstr* bin_op = value->AsBinarySmiOp();
      if ((bin_op->op_kind() == Token::kADD) ||
          (bin_op->op_kind() == Token::kMUL) ||
          (bin_op->op_kind() == Token::kSUB)) {
        Definition* new_left =
            ConstructBound(phi_bound_func, bin_op->left()->definition(), point);
        Definition* new_right =
            (bin_op->op_kind() != Token::kSUB)
                ? ConstructBound(phi_bound_func, bin_op->right()->definition(),
                                 point)
                : UnwrapConstraint(bin_op->right()->definition());

        if ((new_left != UnwrapConstraint(bin_op->left()->definition())) ||
            (new_right != UnwrapConstraint(bin_op->right()->definition()))) {
          return MakeBinaryOp(bin_op->op_kind(), new_left, new_right);
        }
      }
    }
    return value;
  }

  Definition* InductionVariableUpperBound(PhiInstr* phi,
                                          LoopInfo* loop,
                                          InductionVar* induc,
                                          Instruction* point) {
    // Test if limit dominates given point.
    ConstraintInstr* limit = loop->limit();
    if (!point->IsDominatedBy(limit)) {
      return phi;
    }
    // Decide between direct or indirect bound.
    Definition* bounded_def = UnwrapConstraint(limit->value()->definition());
    if (bounded_def == phi) {
      // Given a smi bounded loop with smi induction variable
      //
      //          x <- phi(x0, x + 1)
      //
      // and a constraint x <= M that dominates the given
      // point we conclude that M is an upper bound for x.
      return RangeBoundaryToDefinition(limit->constraint()->max());
    } else {
      // Given a smi bounded loop with two smi induction variables
      //
      //          x <- phi(x0, x + 1)
      //          y <- phi(y0, y + 1)
      //
      // and a constraint x <= M that dominates the given
      // point we can conclude that
      //
      //          y <= y0 + (M - x0)
      //
      InductionVar* bounded_induc = GetSmiInduction(loop, bounded_def);
      Definition* x0 = GenerateInvariant(bounded_induc->initial());
      Definition* y0 = GenerateInvariant(induc->initial());
      Definition* m = RangeBoundaryToDefinition(limit->constraint()->max());
      BinarySmiOpInstr* loop_length =
          MakeBinaryOp(Token::kSUB, ConstructUpperBound(m, point),
                       ConstructLowerBound(x0, point));
      return MakeBinaryOp(Token::kADD, ConstructUpperBound(y0, point),
                          loop_length);
    }
  }

  Definition* InductionVariableLowerBound(PhiInstr* phi,
                                          LoopInfo* loop,
                                          InductionVar* induc,
                                          Instruction* point) {
    // Given a smi bounded loop with smi induction variable
    //
    //          x <- phi(x0, x + 1)
    //
    // we can conclude that LowerBound(x) == x0.
    return ConstructLowerBound(GenerateInvariant(induc->initial()), point);
  }

  // Try to re-associate binary operations in the floating DAG of operations
  // to collect all constants together, e.g. x + C0 + y + C1 is simplified into
  // x + y + (C0 + C1).
  bool Simplify(Definition** defn, intptr_t* constant) {
    if ((*defn)->IsBinarySmiOp()) {
      BinarySmiOpInstr* binary_op = (*defn)->AsBinarySmiOp();
      Definition* left = binary_op->left()->definition();
      Definition* right = binary_op->right()->definition();

      intptr_t c = 0;
      if (binary_op->op_kind() == Token::kADD) {
        intptr_t left_const = 0;
        intptr_t right_const = 0;
        if (!Simplify(&left, &left_const) || !Simplify(&right, &right_const)) {
          return false;
        }

        c = left_const + right_const;
        if (Utils::WillAddOverflow(left_const, right_const) ||
            !compiler::target::IsSmi(c)) {
          return false;  // Abort.
        }

        if (constant != nullptr) {
          *constant = c;
        }

        if ((left == nullptr) && (right == nullptr)) {
          if (constant != nullptr) {
            *defn = nullptr;
          } else {
            *defn = flow_graph_->GetConstant(Smi::Handle(Smi::New(c)));
          }
          return true;
        }

        if (left == nullptr) {
          if ((constant != nullptr) || (c == 0)) {
            *defn = right;
            return true;
          } else {
            left = right;
            right = nullptr;
          }
        }

        if (right == nullptr) {
          if ((constant != nullptr) || (c == 0)) {
            *defn = left;
            return true;
          } else {
            right = flow_graph_->GetConstant(Smi::Handle(Smi::New(c)));
            c = 0;
          }
        }
      } else if (binary_op->op_kind() == Token::kSUB) {
        intptr_t left_const = 0;
        intptr_t right_const = 0;
        if (!Simplify(&left, &left_const) || !Simplify(&right, &right_const)) {
          return false;
        }

        c = (left_const - right_const);
        if (Utils::WillSubOverflow(left_const, right_const) ||
            !compiler::target::IsSmi(c)) {
          return false;  // Abort.
        }

        if (constant != nullptr) {
          *constant = c;
        }

        if ((left == nullptr) && (right == nullptr)) {
          if (constant != nullptr) {
            *defn = nullptr;
          } else {
            *defn = flow_graph_->GetConstant(Smi::Handle(Smi::New(c)));
          }
          return true;
        }

        if (left == nullptr) {
          left = flow_graph_->GetConstant(Object::smi_zero());
        }

        if (right == nullptr) {
          if ((constant != nullptr) || (c == 0)) {
            *defn = left;
            return true;
          } else {
            right = flow_graph_->GetConstant(Smi::Handle(Smi::New(-c)));
            c = 0;
          }
        }
      } else if (binary_op->op_kind() == Token::kMUL) {
        if (!Simplify(&left, nullptr) || !Simplify(&right, nullptr)) {
          return false;
        }
      } else {
        // Don't attempt to simplify any other binary operation.
        return true;
      }

      ASSERT(left != nullptr);
      ASSERT(right != nullptr);

      const bool left_changed = (left != binary_op->left()->definition());
      const bool right_changed = (right != binary_op->right()->definition());
      if (left_changed || right_changed) {
        if (!(*defn)->HasSSATemp()) {
          if (left_changed) binary_op->left()->set_definition(left);
          if (right_changed) binary_op->right()->set_definition(right);
          *defn = binary_op;
        } else {
          *defn = MakeBinaryOp(binary_op->op_kind(), UnwrapConstraint(left),
                               UnwrapConstraint(right));
        }
      }

      if ((c != 0) && (constant == nullptr)) {
        *defn = MakeBinaryOp(Token::kADD, *defn, c);
      }
    } else if ((*defn)->IsConstant()) {
      ConstantInstr* constant_defn = (*defn)->AsConstant();
      if ((constant != nullptr) && constant_defn->IsSmi()) {
        *defn = nullptr;
        *constant = Smi::Cast(constant_defn->value()).Value();
      }
    }

    return true;
  }

  // If possible find a set of symbols that need to be non-negative to
  // guarantee that expression as whole is non-negative.
  bool FindNonPositiveSymbols(GrowableArray<Definition*>* symbols,
                              Definition* defn) {
    if (defn->IsConstant()) {
      const Object& value = defn->AsConstant()->value();
      return compiler::target::IsSmi(value) && (Smi::Cast(value).Value() >= 0);
    } else if (defn->HasSSATemp()) {
      if (!RangeUtils::IsPositive(defn->range())) {
        symbols->Add(defn);
      }
      return true;
    } else if (defn->IsBinarySmiOp()) {
      BinarySmiOpInstr* binary_op = defn->AsBinarySmiOp();
      ASSERT((binary_op->op_kind() == Token::kADD) ||
             (binary_op->op_kind() == Token::kSUB) ||
             (binary_op->op_kind() == Token::kMUL));

      if (RangeUtils::IsPositive(defn->range())) {
        // We can statically prove that this subexpression is always positive.
        // No need to inspect its subexpressions.
        return true;
      }

      if (binary_op->op_kind() == Token::kSUB) {
        // For addition and multiplication it's enough to ensure that
        // lhs and rhs are positive to guarantee that defn as whole is
        // positive. This does not work for substraction so just give up.
        return false;
      }

      return FindNonPositiveSymbols(symbols, binary_op->left()->definition()) &&
             FindNonPositiveSymbols(symbols, binary_op->right()->definition());
    }
    UNREACHABLE();
    return false;
  }

  // Find innermost constraint for the given definition dominating given
  // instruction.
  static Definition* FindInnermostConstraint(Definition* defn,
                                             Instruction* post_dominator) {
    for (Value* use = defn->input_use_list(); use != nullptr;
         use = use->next_use()) {
      ConstraintInstr* constraint = use->instruction()->AsConstraint();
      if ((constraint != nullptr) &&
          post_dominator->IsDominatedBy(constraint)) {
        return FindInnermostConstraint(constraint, post_dominator);
      }
    }
    return defn;
  }

  // Replace symbolic parts of the boundary with respective constraints
  // that hold at the given point in the flow graph signified by
  // post_dominator.
  // Constraints array allows to provide a set of additional floating
  // constraints that were not inserted into the graph.
  static Definition* ApplyConstraints(
      Definition* defn,
      Instruction* post_dominator,
      GrowableArray<ConstraintInstr*>* constraints = nullptr) {
    if (defn->HasSSATemp()) {
      defn = FindInnermostConstraint(defn, post_dominator);
      if (constraints != nullptr) {
        for (intptr_t i = 0; i < constraints->length(); i++) {
          ConstraintInstr* constraint = (*constraints)[i];
          if (constraint->value()->definition() == defn) {
            return constraint;
          }
        }
      }
      return defn;
    }

    for (intptr_t i = 0; i < defn->InputCount(); i++) {
      defn->InputAt(i)->set_definition(ApplyConstraints(
          defn->InputAt(i)->definition(), post_dominator, constraints));
    }

    return defn;
  }

#ifndef PRODUCT
  static void PrettyPrintIndexBoundRecursively(BaseTextBuffer* f,
                                               Definition* index_bound) {
    BinarySmiOpInstr* binary_op = index_bound->AsBinarySmiOp();
    if (binary_op != nullptr) {
      f->AddString("(");
      PrettyPrintIndexBoundRecursively(f, binary_op->left()->definition());
      f->Printf(" %s ", Token::Str(binary_op->op_kind()));
      PrettyPrintIndexBoundRecursively(f, binary_op->right()->definition());
      f->AddString(")");
    } else if (index_bound->IsConstant()) {
      f->Printf("%" Pd "",
                Smi::Cast(index_bound->AsConstant()->value()).Value());
    } else {
      f->Printf("v%" Pd "", index_bound->ssa_temp_index());
    }
    f->Printf(" {%s}", Range::ToCString(index_bound->range()));
  }

  static const char* IndexBoundToCString(Definition* index_bound) {
    char buffer[1024];
    BufferFormatter f(buffer, sizeof(buffer));
    PrettyPrintIndexBoundRecursively(&f, index_bound);
    return Thread::Current()->zone()->MakeCopyOfString(buffer);
  }
#endif  // !PRODUCT

  RangeAnalysis* range_analysis_;
  FlowGraph* flow_graph_;
  Scheduler scheduler_;
};

void RangeAnalysis::EliminateRedundantBoundsChecks() {
  if (FLAG_array_bounds_check_elimination) {
    const Function& function = flow_graph_->function();
    // Generalization only if we have not deoptimized on a generalized
    // check earlier and we are not compiling precompiled code
    // (no optimistic hoisting of checks possible)
    const bool try_generalization =
        !CompilerState::Current().is_aot() &&
        !function.ProhibitsBoundsCheckGeneralization();
    BoundsCheckGeneralizer generalizer(this, flow_graph_);
    for (CheckBoundBaseInstr* check : bounds_checks_) {
      if (check->IsRedundant(/*use_loops=*/true)) {
        check->ReplaceUsesWith(check->index()->definition());
        check->RemoveFromGraph();
      } else if (try_generalization) {
        if (auto jit_check = check->AsCheckArrayBound()) {
          generalizer.TryGeneralize(jit_check);
        }
      }
    }
  }
}

void RangeAnalysis::MarkUnreachableBlocks() {
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    if (Range::IsUnknown(constraints_[i]->range())) {
      TargetEntryInstr* target = constraints_[i]->target();
      if (target == nullptr) {
        // TODO(vegorov): replace Constraint with an unconditional
        // deoptimization and kill all dominated dead code.
        continue;
      }

      BranchInstr* branch =
          target->PredecessorAt(0)->last_instruction()->AsBranch();
      if (target == branch->true_successor()) {
        // True unreachable.
        if (FLAG_trace_constant_propagation && flow_graph_->should_print()) {
          THR_Print("Range analysis: True unreachable (B%" Pd ")\n",
                    branch->true_successor()->block_id());
        }
        branch->set_constant_target(branch->false_successor());
      } else {
        ASSERT(target == branch->false_successor());
        // False unreachable.
        if (FLAG_trace_constant_propagation && flow_graph_->should_print()) {
          THR_Print("Range analysis: False unreachable (B%" Pd ")\n",
                    branch->false_successor()->block_id());
        }
        branch->set_constant_target(branch->true_successor());
      }
    }
  }
}

void RangeAnalysis::RemoveConstraints() {
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    Definition* def = constraints_[i]->value()->definition();
    // Some constraints might be constraining constraints. Unwind the chain of
    // constraints until we reach the actual definition.
    while (def->IsConstraint()) {
      def = def->AsConstraint()->value()->definition();
    }
    constraints_[i]->ReplaceUsesWith(def);
    constraints_[i]->RemoveFromGraph();
  }
}

static void NarrowBinaryInt64Op(BinaryInt64OpInstr* int64_op) {
  if (Range::Fits(int64_op->range(), kUnboxedInt32) &&
      Range::Fits(int64_op->left()->definition()->range(), kUnboxedInt32) &&
      Range::Fits(int64_op->right()->definition()->range(), kUnboxedInt32) &&
      BinaryInt32OpInstr::IsSupported(int64_op->op_kind(), int64_op->left(),
                                      int64_op->right())) {
    BinaryInt32OpInstr* int32_op = new BinaryInt32OpInstr(
        int64_op->op_kind(), int64_op->left()->CopyWithType(),
        int64_op->right()->CopyWithType(), int64_op->DeoptimizationTarget());
    int32_op->set_range(*int64_op->range());
    int32_op->set_can_overflow(false);
    int64_op->ReplaceWith(int32_op, nullptr);
  }
}

#if defined(TARGET_ARCH_IS_32_BIT)
static void NarrowInt64ComparisonInstr(ComparisonInstr* int64_op) {
  if (Range::Fits(int64_op->left()->definition()->range(), kUnboxedInt32) &&
      Range::Fits(int64_op->right()->definition()->range(), kUnboxedInt32)) {
    int64_op->set_input_representation(kUnboxedInt32);
  }
}
#endif

void RangeAnalysis::NarrowInt64OperationsToInt32() {
  for (intptr_t i = 0; i < binary_int64_ops_.length(); i++) {
    NarrowBinaryInt64Op(binary_int64_ops_[i]);
  }
#if defined(TARGET_ARCH_IS_32_BIT)
  for (intptr_t i = 0; i < int64_comparisons_.length(); i++) {
    NarrowInt64ComparisonInstr(int64_comparisons_[i]);
  }
#endif
}

IntegerInstructionSelector::IntegerInstructionSelector(FlowGraph* flow_graph)
    : flow_graph_(flow_graph) {
  ASSERT(flow_graph_ != nullptr);
  zone_ = flow_graph_->zone();
  selected_uint32_defs_ =
      new (zone_) BitVector(zone_, flow_graph_->current_ssa_temp_index());
}

void IntegerInstructionSelector::Select() {
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("---- starting integer ir selection -------\n");
  }
  FindPotentialUint32Definitions();
  FindUint32NarrowingDefinitions();
  Propagate();
  NarrowUint32Uses();
  ReplaceInstructions();
  if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
    THR_Print("---- after integer ir selection -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }
}

bool IntegerInstructionSelector::IsPotentialUint32Definition(Definition* def) {
  // TODO(johnmccutchan): Consider Smi operations, to avoid unnecessary tagging
  // & untagged of intermediate results.
  // TODO(johnmccutchan): Consider phis.
  return def->IsBoxInt64() || def->IsUnboxInt64() ||
         (def->IsBinaryInt64Op() && BinaryUint32OpInstr::IsSupported(
                                        def->AsBinaryInt64Op()->op_kind())) ||
         (def->IsUnaryInt64Op() &&
          UnaryUint32OpInstr::IsSupported(def->AsUnaryInt64Op()->op_kind()));
}

void IntegerInstructionSelector::FindPotentialUint32Definitions() {
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("++++ Finding potential Uint32 definitions:\n");
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();

    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if ((defn != nullptr) && defn->HasSSATemp()) {
        if (IsPotentialUint32Definition(defn)) {
          if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
            THR_Print("Adding %s\n", current->ToCString());
          }
          potential_uint32_defs_.Add(defn);
        }
      }
    }
  }
}

// BinaryInt64Op masks and stores into unsigned typed arrays that truncate the
// value into a Uint32 range.
bool IntegerInstructionSelector::IsUint32NarrowingDefinition(Definition* def) {
  if (def->IsBinaryInt64Op()) {
    BinaryInt64OpInstr* op = def->AsBinaryInt64Op();
    // Must be a mask operation.
    if (op->op_kind() != Token::kBIT_AND) {
      return false;
    }
    return Range::Fits(op->range(), kUnboxedUint32);
  }
  // TODO(johnmccutchan): Add typed array stores.
  return false;
}

void IntegerInstructionSelector::FindUint32NarrowingDefinitions() {
  ASSERT(selected_uint32_defs_ != nullptr);
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("++++ Selecting Uint32 definitions:\n");
    THR_Print("++++ Initial set:\n");
  }
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (IsUint32NarrowingDefinition(defn)) {
      if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
        THR_Print("Adding %s\n", defn->ToCString());
      }
      selected_uint32_defs_->Add(defn->ssa_temp_index());
    }
  }
}

bool IntegerInstructionSelector::AllUsesAreUint32Narrowing(Value* list_head) {
  for (Value::Iterator it(list_head); !it.Done(); it.Advance()) {
    Value* use = it.Current();
    Definition* defn = use->instruction()->AsDefinition();
    if ((defn == nullptr) || !defn->HasSSATemp() ||
        !selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      return false;
    }
    // Right-hand side operand of shift BinaryInt64Op is not narrowing
    // (all its bits should be taken into account).
    if (auto op = defn->AsBinaryIntegerOp()) {
      if ((op->op_kind() == Token::kSHL) || (op->op_kind() == Token::kSHR) ||
          (op->op_kind() == Token::kUSHR)) {
        if (use == op->right()) {
          return false;
        }
      }
    }
  }
  return true;
}

bool IntegerInstructionSelector::CanBecomeUint32(Definition* def) {
  ASSERT(IsPotentialUint32Definition(def));
  if (def->IsBoxInt64()) {
    // If a BoxInt64's input is a candidate, the box is a candidate.
    Definition* box_input = def->AsBoxInt64()->value()->definition();
    return selected_uint32_defs_->Contains(box_input->ssa_temp_index());
  }
  if (auto op = def->AsBinaryInt64Op()) {
    // A shift with an rhs outside of Uint32 range cannot be converted.
    if ((op->op_kind() == Token::kSHL) || (op->op_kind() == Token::kSHR) ||
        (op->op_kind() == Token::kUSHR)) {
      if (!Range::Fits(op->right()->definition()->range(), kUnboxedUint32)) {
        return false;
      }
    }
    // A right shift with an lhs outside of Uint32 range cannot be converted
    // because we need the high bits.
    if ((op->op_kind() == Token::kSHR) || (op->op_kind() == Token::kUSHR)) {
      if (!Range::Fits(op->left()->definition()->range(), kUnboxedUint32)) {
        return false;
      }
    }
  }
  if (!def->HasUses()) {
    // No uses, skip.
    return false;
  }
  return AllUsesAreUint32Narrowing(def->input_use_list()) &&
         AllUsesAreUint32Narrowing(def->env_use_list());
}

void IntegerInstructionSelector::Propagate() {
  ASSERT(selected_uint32_defs_ != nullptr);
  bool changed = true;
  intptr_t iteration = 0;
  while (changed) {
    if (FLAG_trace_integer_ir_selection) {
      THR_Print("+++ Iteration: %" Pd "\n", iteration++);
    }
    changed = false;
    for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
      Definition* defn = potential_uint32_defs_[i];
      if (selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
        // Already marked as a candidate, skip.
        continue;
      }
      if (defn->IsConstant()) {
        // Skip constants.
        continue;
      }
      if (CanBecomeUint32(defn)) {
        if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
          THR_Print("Adding %s\n", defn->ToCString());
        }
        // Found a new candidate.
        selected_uint32_defs_->Add(defn->ssa_temp_index());
        // Haven't reached fixed point yet.
        changed = true;
      }
    }
  }
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("Reached fixed point\n");
  }
}

Definition* IntegerInstructionSelector::ConstructReplacementFor(
    Definition* def) {
  // Should only see mint definitions.
  ASSERT(IsPotentialUint32Definition(def));
  // Should not see constant instructions.
  ASSERT(!def->IsConstant());
  if (def->IsBinaryIntegerOp()) {
    BinaryIntegerOpInstr* op = def->AsBinaryIntegerOp();
    Token::Kind op_kind = op->op_kind();
    Value* left = op->left()->CopyWithType();
    Value* right = op->right()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    return BinaryIntegerOpInstr::Make(kUnboxedUint32, op_kind, left, right,
                                      deopt_id);
  } else if (def->IsBoxInt64()) {
    Value* value = def->AsBoxInt64()->value()->CopyWithType();
    return new (Z) BoxUint32Instr(value);
  } else if (def->IsUnboxInt64()) {
    UnboxInstr* unbox = def->AsUnboxInt64();
    Value* value = unbox->value()->CopyWithType();
    intptr_t deopt_id = unbox->DeoptimizationTarget();
    return new (Z) UnboxUint32Instr(value, deopt_id, unbox->value_mode());
  } else if (def->IsUnaryInt64Op()) {
    UnaryInt64OpInstr* op = def->AsUnaryInt64Op();
    Token::Kind op_kind = op->op_kind();
    Value* value = op->value()->CopyWithType();
    intptr_t deopt_id = op->DeoptimizationTarget();
    return new (Z) UnaryUint32OpInstr(op_kind, value, deopt_id);
  }
  UNREACHABLE();
  return nullptr;
}

bool IntegerInstructionSelector::IsUint32Use(Value* use) {
  Definition* defn = use->definition();
  if (selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
    return true;
  }
  if (use->BindsToConstant() && use->BoundConstant().IsInteger()) {
    const int64_t value = Integer::Cast(use->BoundConstant()).Value();
    return (value >= 0) && (value <= kMaxUint32);
  }
  return false;
}

void IntegerInstructionSelector::NarrowUint32Uses() {
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (!selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      continue;
    }

    for (Value::Iterator it(defn->input_use_list()); !it.Done(); it.Advance()) {
      Instruction* instr = it.Current()->instruction();
      // Convert Int64/Int32 comparisons to Uint32 if
      // both operands are either converted to Uint32 or constants.
      ComparisonInstr* comparison = nullptr;
      if (auto branch = instr->AsBranch()) {
        comparison = branch->condition()->AsComparison();
      } else {
        comparison = instr->AsComparison();
      }
      if ((comparison != nullptr) &&
          ((comparison->input_representation() == kUnboxedInt64) ||
           (comparison->input_representation() == kUnboxedInt32)) &&
          IsUint32Use(comparison->left()) && IsUint32Use(comparison->right())) {
        comparison->set_input_representation(kUnboxedUint32);
      }
    }
  }
}

void IntegerInstructionSelector::ReplaceInstructions() {
  if (FLAG_trace_integer_ir_selection) {
    THR_Print("++++ Replacing instructions:\n");
  }
  for (intptr_t i = 0; i < potential_uint32_defs_.length(); i++) {
    Definition* defn = potential_uint32_defs_[i];
    if (!selected_uint32_defs_->Contains(defn->ssa_temp_index())) {
      // Not a candidate.
      continue;
    }
    Definition* replacement = ConstructReplacementFor(defn);
    ASSERT(replacement != nullptr);
    if (!Range::IsUnknown(defn->range())) {
      if (defn->range()->IsPositive()) {
        replacement->set_range(*defn->range());
      } else {
        replacement->set_range(Range(RangeBoundary::FromConstant(0),
                                     RangeBoundary::FromConstant(kMaxUint32)));
      }
    }
    if (FLAG_support_il_printer && FLAG_trace_integer_ir_selection) {
      THR_Print("Replacing %s with %s\n", defn->ToCString(),
                replacement->ToCString());
    }
    defn->ReplaceWith(replacement, nullptr);
  }
}

RangeBoundary RangeBoundary::FromDefinition(Definition* defn, int64_t offs) {
  if (defn->IsConstant() && defn->AsConstant()->IsSmi()) {
    return FromConstant(Smi::Cast(defn->AsConstant()->value()).Value() + offs);
  }
  ASSERT(IsValidOffsetForSymbolicRangeBoundary(offs));
  return RangeBoundary(kSymbol, reinterpret_cast<intptr_t>(defn), offs);
}

RangeBoundary RangeBoundary::LowerBound() const {
  if (IsConstant()) return *this;
  return Add(Range::ConstantMinSmi(symbol()->range()),
             RangeBoundary::FromConstant(offset_));
}

RangeBoundary RangeBoundary::UpperBound() const {
  if (IsConstant()) return *this;

  return Add(Range::ConstantMaxSmi(symbol()->range()),
             RangeBoundary::FromConstant(offset_));
}

bool RangeBoundary::WillAddOverflow(const RangeBoundary& a,
                                    const RangeBoundary& b) {
  ASSERT(a.IsConstant() && b.IsConstant());
  return Utils::WillAddOverflow(a.ConstantValue(), b.ConstantValue());
}

RangeBoundary RangeBoundary::Add(const RangeBoundary& a,
                                 const RangeBoundary& b) {
  ASSERT(a.IsConstant() && b.IsConstant());
  ASSERT(!WillAddOverflow(a, b));
  const int64_t result = a.ConstantValue() + b.ConstantValue();
  return RangeBoundary::FromConstant(result);
}

bool RangeBoundary::WillSubOverflow(const RangeBoundary& a,
                                    const RangeBoundary& b) {
  ASSERT(a.IsConstant() && b.IsConstant());
  return Utils::WillSubOverflow(a.ConstantValue(), b.ConstantValue());
}

RangeBoundary RangeBoundary::Sub(const RangeBoundary& a,
                                 const RangeBoundary& b) {
  ASSERT(a.IsConstant() && b.IsConstant());
  ASSERT(!WillSubOverflow(a, b));
  const int64_t result = a.ConstantValue() - b.ConstantValue();
  return RangeBoundary::FromConstant(result);
}

bool RangeBoundary::SymbolicAdd(const RangeBoundary& a,
                                const RangeBoundary& b,
                                RangeBoundary* result) {
  if (a.IsSymbol() && b.IsConstant()) {
    if (Utils::WillAddOverflow(a.offset(), b.ConstantValue())) {
      return false;
    }

    const int64_t offset = a.offset() + b.ConstantValue();

    if (!IsValidOffsetForSymbolicRangeBoundary(offset)) {
      return false;
    }

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  } else if (b.IsSymbol() && a.IsConstant()) {
    return SymbolicAdd(b, a, result);
  }
  return false;
}

bool RangeBoundary::SymbolicSub(const RangeBoundary& a,
                                const RangeBoundary& b,
                                RangeBoundary* result) {
  if (a.IsSymbol() && b.IsConstant()) {
    if (Utils::WillSubOverflow(a.offset(), b.ConstantValue())) {
      return false;
    }

    const int64_t offset = a.offset() - b.ConstantValue();

    if (!IsValidOffsetForSymbolicRangeBoundary(offset)) {
      return false;
    }

    *result = RangeBoundary::FromDefinition(a.symbol(), offset);
    return true;
  }
  return false;
}

bool RangeBoundary::Equals(const RangeBoundary& other) const {
  if (IsConstant() && other.IsConstant()) {
    return ConstantValue() == other.ConstantValue();
  } else if (IsSymbol() && other.IsSymbol()) {
    return (offset() == other.offset()) && DependOnSameSymbol(*this, other);
  } else if (IsUnknown() && other.IsUnknown()) {
    return true;
  }
  return false;
}

bool RangeBoundary::WillShlOverflow(const RangeBoundary& value_boundary,
                                    int64_t shift_count) {
  ASSERT(value_boundary.IsConstant());
  ASSERT(shift_count >= 0);
  const int64_t value = value_boundary.ConstantValue();
  if (value == 0) {
    return false;
  }
  return (shift_count >= kBitsPerInt64) ||
         !Utils::IsInt(static_cast<int>(kBitsPerInt64 - shift_count), value);
}

RangeBoundary RangeBoundary::Shl(const RangeBoundary& value_boundary,
                                 int64_t shift_count) {
  ASSERT(value_boundary.IsConstant());
  ASSERT(!WillShlOverflow(value_boundary, shift_count));
  ASSERT(shift_count >= 0);
  int64_t value = value_boundary.ConstantValue();

  if (value == 0) {
    return RangeBoundary::FromConstant(0);
  } else {
    // Result stays in 64 bit range.
    const int64_t result = static_cast<uint64_t>(value) << shift_count;
    return RangeBoundary(result);
  }
}

RangeBoundary RangeBoundary::Shr(const RangeBoundary& value_boundary,
                                 int64_t shift_count) {
  ASSERT(value_boundary.IsConstant());
  ASSERT(shift_count >= 0);
  const int64_t value = static_cast<int64_t>(value_boundary.ConstantValue());
  const int64_t result = (shift_count <= 63)
                             ? (value >> shift_count)
                             : (value >= 0 ? 0 : -1);  // Dart semantics
  return RangeBoundary(result);
}

static RangeBoundary CanonicalizeBoundary(const RangeBoundary& a,
                                          const RangeBoundary& overflow) {
  if (a.IsConstant()) {
    return a;
  }

  int64_t offset = a.offset();
  Definition* symbol = a.symbol();

  bool changed;
  do {
    changed = false;
    if (symbol->IsConstraint()) {
      symbol = symbol->AsConstraint()->value()->definition();
      changed = true;
    } else if (auto* unbox = symbol->AsUnboxInt64()) {
      symbol = unbox->value()->definition();
      changed = true;
    } else if (symbol->IsBinarySmiOp()) {
      BinarySmiOpInstr* op = symbol->AsBinarySmiOp();
      Definition* left = op->left()->definition();
      Definition* right = op->right()->definition();
      switch (op->op_kind()) {
        case Token::kADD:
          if (right->IsConstant()) {
            int64_t rhs = Smi::Cast(right->AsConstant()->value()).Value();
            if (Utils::WillAddOverflow(offset, rhs)) {
              return overflow;
            }
            offset += rhs;
            symbol = left;
            changed = true;
          } else if (left->IsConstant()) {
            int64_t rhs = Smi::Cast(left->AsConstant()->value()).Value();
            if (Utils::WillAddOverflow(offset, rhs)) {
              return overflow;
            }
            offset += rhs;
            symbol = right;
            changed = true;
          }
          break;

        case Token::kSUB:
          if (right->IsConstant()) {
            int64_t rhs = Smi::Cast(right->AsConstant()->value()).Value();
            if (Utils::WillSubOverflow(offset, rhs)) {
              return overflow;
            }
            offset -= rhs;
            symbol = left;
            changed = true;
          }
          break;

        default:
          break;
      }
    }
  } while (changed);

  if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
    return overflow;
  }

  return RangeBoundary::FromDefinition(symbol, offset);
}

static bool CanonicalizeMaxBoundary(RangeBoundary* a) {
  if (!a->IsSymbol()) return false;

  Range* range = a->symbol()->range();
  if ((range == nullptr) || !range->max().IsSymbol()) return false;

  if (Utils::WillAddOverflow(range->max().offset(), a->offset())) {
    *a = RangeBoundary::MaxInt64();
    return true;
  }

  const int64_t offset = range->max().offset() + a->offset();

  if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
    *a = RangeBoundary::MaxInt64();
    return true;
  }

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->max().symbol(), offset),
      RangeBoundary::MaxInt64());

  return true;
}

static bool CanonicalizeMinBoundary(RangeBoundary* a) {
  if (!a->IsSymbol()) return false;

  Range* range = a->symbol()->range();
  if ((range == nullptr) || !range->min().IsSymbol()) return false;

  if (Utils::WillAddOverflow(range->min().offset(), a->offset())) {
    *a = RangeBoundary::MinInt64();
    return true;
  }

  const int64_t offset = range->min().offset() + a->offset();

  if (!RangeBoundary::IsValidOffsetForSymbolicRangeBoundary(offset)) {
    *a = RangeBoundary::MinInt64();
    return true;
  }

  *a = CanonicalizeBoundary(
      RangeBoundary::FromDefinition(range->min().symbol(), offset),
      RangeBoundary::MinInt64());

  return true;
}

typedef bool (*BoundaryOp)(RangeBoundary*);

static bool CanonicalizeForComparison(RangeBoundary* a,
                                      RangeBoundary* b,
                                      BoundaryOp op) {
  if (!a->IsSymbol() || !b->IsSymbol()) {
    return false;
  }

  RangeBoundary canonical_a = *a;
  RangeBoundary canonical_b = *b;

  do {
    if (DependOnSameSymbol(canonical_a, canonical_b)) {
      *a = canonical_a;
      *b = canonical_b;
      return true;
    }
  } while (op(&canonical_a) || op(&canonical_b));

  return false;
}

RangeBoundary RangeBoundary::JoinMin(RangeBoundary a,
                                     RangeBoundary b,
                                     const Range& full_range) {
  if (a.Equals(b)) {
    return b;
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMinBoundary)) {
    return (a.offset() <= b.offset()) ? a : b;
  }

  const int64_t inf_a = a.LowerBound(full_range);
  const int64_t inf_b = b.LowerBound(full_range);
  const int64_t sup_a = a.UpperBound(full_range);
  const int64_t sup_b = b.UpperBound(full_range);

  if ((sup_a <= inf_b) && !a.LowerBound().Overflowed(full_range)) {
    return a;
  } else if ((sup_b <= inf_a) && !b.LowerBound().Overflowed(full_range)) {
    return b;
  } else {
    return RangeBoundary::FromConstant(Utils::Minimum(inf_a, inf_b));
  }
}

RangeBoundary RangeBoundary::JoinMax(RangeBoundary a,
                                     RangeBoundary b,
                                     const Range& full_range) {
  if (a.Equals(b)) {
    return b;
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMaxBoundary)) {
    return (a.offset() >= b.offset()) ? a : b;
  }

  const int64_t inf_a = a.LowerBound(full_range);
  const int64_t inf_b = b.LowerBound(full_range);
  const int64_t sup_a = a.UpperBound(full_range);
  const int64_t sup_b = b.UpperBound(full_range);

  if ((sup_a <= inf_b) && !b.UpperBound().Overflowed(full_range)) {
    return b;
  } else if ((sup_b <= inf_a) && !a.UpperBound().Overflowed(full_range)) {
    return a;
  } else {
    return RangeBoundary::FromConstant(Utils::Maximum(sup_a, sup_b));
  }
}

RangeBoundary RangeBoundary::IntersectionMin(RangeBoundary a, RangeBoundary b) {
  ASSERT(!a.IsUnknown() && !b.IsUnknown());

  if (a.Equals(b)) {
    return a;
  }

  if (a.IsConstant() && b.IsConstant()) {
    return RangeBoundary(Utils::Maximum(a.ConstantValue(), b.ConstantValue()));
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMinBoundary)) {
    return (a.offset() >= b.offset()) ? a : b;
  }

  const int64_t inf_a = a.LowerBound().ConstantValue();
  const int64_t inf_b = b.LowerBound().ConstantValue();

  return (inf_a >= inf_b) ? a : b;
}

RangeBoundary RangeBoundary::IntersectionMax(RangeBoundary a, RangeBoundary b) {
  ASSERT(!a.IsUnknown() && !b.IsUnknown());

  if (a.Equals(b)) {
    return a;
  }

  if (a.IsConstant() && b.IsConstant()) {
    return RangeBoundary(Utils::Minimum(a.ConstantValue(), b.ConstantValue()));
  }

  if (CanonicalizeForComparison(&a, &b, &CanonicalizeMaxBoundary)) {
    return (a.offset() <= b.offset()) ? a : b;
  }

  const int64_t sup_a = a.UpperBound().ConstantValue();
  const int64_t sup_b = b.UpperBound().ConstantValue();

  return (sup_a <= sup_b) ? a : b;
}

RangeBoundary RangeBoundary::Clamp(const Range& full_range) const {
  if (IsConstant()) {
    const RangeBoundary range_min = full_range.min();
    const RangeBoundary range_max = full_range.max();

    if (ConstantValue() <= range_min.ConstantValue()) {
      return range_min;
    }
    if (ConstantValue() >= range_max.ConstantValue()) {
      return range_max;
    }
  }

  // If this range is a symbolic range, we do not clamp it.
  // This could lead to some imprecision later on.
  return *this;
}

int64_t RangeBoundary::ConstantValue() const {
  ASSERT(IsConstant());
  return value_;
}

Range Range::Full(Representation rep, TaggedMode tagged_mode) {
  if (rep == kTagged) {
    switch (tagged_mode) {
      case TaggedMode::kTaggedIsSmi:
        return Range::Smi();
      case TaggedMode::kTaggedNotAllowed:
        UNREACHABLE();
    }
  }
  ASSERT(RepresentationUtils::IsUnboxedInteger(rep));
  return Range(RangeBoundary::FromConstant(RepresentationUtils::MinValue(rep)),
               RangeBoundary::FromConstant(RepresentationUtils::MaxValue(rep)));
}

bool Range::IsPositive() const {
  return OnlyGreaterThanOrEqualTo(0);
}

bool Range::IsNegative() const {
  return OnlyLessThanOrEqualTo(-1);
}

bool Range::OnlyLessThanOrEqualTo(int64_t val) const {
  const RangeBoundary upper_bound = max().UpperBound();
  return upper_bound.ConstantValue() <= val;
}

bool Range::OnlyGreaterThanOrEqualTo(int64_t val) const {
  const RangeBoundary lower_bound = min().LowerBound();
  return lower_bound.ConstantValue() >= val;
}

// Inclusive.
bool Range::IsWithin(int64_t min_int, int64_t max_int) const {
  return OnlyGreaterThanOrEqualTo(min_int) && OnlyLessThanOrEqualTo(max_int);
}

bool Range::IsWithin(const Range* other) const {
  auto const lower_bound = other->min().LowerBound();
  auto const upper_bound = other->max().UpperBound();
  return IsWithin(other->min().ConstantValue(), other->max().ConstantValue());
}

bool Range::Overlaps(int64_t min_int, int64_t max_int) const {
  RangeBoundary lower = min().LowerBound();
  RangeBoundary upper = max().UpperBound();
  const int64_t this_min = lower.ConstantValue();
  const int64_t this_max = upper.ConstantValue();
  if ((this_min <= min_int) && (min_int <= this_max)) return true;
  if ((this_min <= max_int) && (max_int <= this_max)) return true;
  if ((min_int < this_min) && (max_int > this_max)) return true;
  return false;
}

bool Range::IsUnsatisfiable() const {
  // Constant case: For example [0, -1].
  if (Range::ConstantMin(this).ConstantValue() >
      Range::ConstantMax(this).ConstantValue()) {
    return true;
  }
  // Symbol case: For example [v+1, v].
  return DependOnSameSymbol(min(), max()) && min().offset() > max().offset();
}

void Range::Clamp(const Range& full_range) {
  min_ = min_.Clamp(full_range);
  max_ = max_.Clamp(full_range);
}

void Range::ClampToConstant(const Range& full_range) {
  min_ = min_.LowerBound().Clamp(full_range);
  max_ = max_.UpperBound().Clamp(full_range);
}

void Range::Shl(const Range* left,
                const Range* right,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left != nullptr);
  ASSERT(right != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);
  RangeBoundary left_max = Range::ConstantMax(left);
  RangeBoundary left_min = Range::ConstantMin(left);
  // A negative shift count always deoptimizes (and throws), so the minimum
  // shift count is zero.
  int64_t right_max = Utils::Maximum(Range::ConstantMax(right).ConstantValue(),
                                     static_cast<int64_t>(0));
  int64_t right_min = Utils::Maximum(Range::ConstantMin(right).ConstantValue(),
                                     static_cast<int64_t>(0));
  bool overflow = false;
  {
    const auto shift_amount =
        left_min.ConstantValue() > 0 ? right_min : right_max;
    if (RangeBoundary::WillShlOverflow(left_min, shift_amount)) {
      overflow = true;
    } else {
      *result_min = RangeBoundary::Shl(left_min, shift_amount);
    }
  }
  {
    const auto shift_amount =
        left_max.ConstantValue() > 0 ? right_max : right_min;
    if (RangeBoundary::WillShlOverflow(left_max, shift_amount)) {
      overflow = true;
    } else {
      *result_max = RangeBoundary::Shl(left_max, shift_amount);
    }
  }
  if (overflow) {
    *result_min = RangeBoundary::MinInt64();
    *result_max = RangeBoundary::MaxInt64();
  }
}

void Range::Shr(const Range* left,
                const Range* right,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  RangeBoundary left_max = Range::ConstantMax(left);
  RangeBoundary left_min = Range::ConstantMin(left);
  // A negative shift count always deoptimizes (and throws), so the minimum
  // shift count is zero.
  int64_t right_max = Utils::Maximum(Range::ConstantMax(right).ConstantValue(),
                                     static_cast<int64_t>(0));
  int64_t right_min = Utils::Maximum(Range::ConstantMin(right).ConstantValue(),
                                     static_cast<int64_t>(0));

  *result_min = RangeBoundary::Shr(
      left_min, left_min.ConstantValue() > 0 ? right_max : right_min);

  *result_max = RangeBoundary::Shr(
      left_max, left_max.ConstantValue() > 0 ? right_min : right_max);
}

static void ConvertRangeToUnsigned(int64_t a,
                                   int64_t b,
                                   uint64_t* ua,
                                   uint64_t* ub) {
  ASSERT(a <= b);
  if ((a < 0) && (b >= 0)) {
    // Range contains -1 and 0 and wraps-around as unsigned.
    *ua = 0;
    *ub = kMaxUint64;
  } else {
    // Range is fully in the negative or non-negative part
    // and doesn't wrap-around if interpreted as unsigned.
    *ua = static_cast<uint64_t>(a);
    *ub = static_cast<uint64_t>(b);
  }
}

static void ConvertRangeToSigned(uint64_t a,
                                 uint64_t b,
                                 int64_t* sa,
                                 int64_t* sb) {
  ASSERT(a <= b);
  if ((a <= static_cast<uint64_t>(kMaxInt64)) &&
      (b >= static_cast<uint64_t>(kMinInt64))) {
    // Range contains kMinInt64 and kMaxInt64 and wraps-around as signed.
    *sa = kMinInt64;
    *sb = kMaxInt64;
  } else {
    // Range is fully in the negative or non-negative part
    // and doesn't wrap-around if interpreted as signed.
    *sa = static_cast<int64_t>(a);
    *sb = static_cast<int64_t>(b);
  }
}

void Range::Ushr(const Range* left,
                 const Range* right,
                 RangeBoundary* result_min,
                 RangeBoundary* result_max) {
  const int64_t left_max = Range::ConstantMax(left).ConstantValue();
  const int64_t left_min = Range::ConstantMin(left).ConstantValue();
  // A negative shift count always deoptimizes (and throws), so the minimum
  // shift count is zero.
  const int64_t right_max = Utils::Maximum(
      Range::ConstantMax(right).ConstantValue(), static_cast<int64_t>(0));
  const int64_t right_min = Utils::Maximum(
      Range::ConstantMin(right).ConstantValue(), static_cast<int64_t>(0));

  uint64_t unsigned_left_min, unsigned_left_max;
  ConvertRangeToUnsigned(left_min, left_max, &unsigned_left_min,
                         &unsigned_left_max);

  const uint64_t unsigned_result_min =
      (right_max >= kBitsPerInt64)
          ? 0
          : unsigned_left_min >> static_cast<uint64_t>(right_max);
  const uint64_t unsigned_result_max =
      (right_min >= kBitsPerInt64)
          ? 0
          : unsigned_left_max >> static_cast<uint64_t>(right_min);

  int64_t signed_result_min, signed_result_max;
  ConvertRangeToSigned(unsigned_result_min, unsigned_result_max,
                       &signed_result_min, &signed_result_max);

  *result_min = RangeBoundary(signed_result_min);
  *result_max = RangeBoundary(signed_result_max);
}

void Range::And(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);

  if (Range::ConstantMin(right_range).ConstantValue() >= 0) {
    *result_min = RangeBoundary::FromConstant(0);
    *result_max = Range::ConstantMax(right_range);
    return;
  }

  if (Range::ConstantMin(left_range).ConstantValue() >= 0) {
    *result_min = RangeBoundary::FromConstant(0);
    *result_max = Range::ConstantMax(left_range);
    return;
  }

  BitwiseOp(left_range, right_range, result_min, result_max);
}

static int BitSize(const Range* range) {
  const int64_t min = Range::ConstantMin(range).ConstantValue();
  const int64_t max = Range::ConstantMax(range).ConstantValue();
  return Utils::Maximum(Utils::BitLength(min), Utils::BitLength(max));
}

void Range::BitwiseOp(const Range* left_range,
                      const Range* right_range,
                      RangeBoundary* result_min,
                      RangeBoundary* result_max) {
  const int bitsize = Utils::Maximum(BitSize(left_range), BitSize(right_range));

  if (left_range->IsPositive() && right_range->IsPositive()) {
    *result_min = RangeBoundary::FromConstant(0);
  } else {
    *result_min =
        RangeBoundary::FromConstant(-(static_cast<uint64_t>(1) << bitsize));
  }

  *result_max =
      RangeBoundary::FromConstant((static_cast<uint64_t>(1) << bitsize) - 1);
}

void Range::Add(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max,
                Definition* left_defn) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);

  RangeBoundary left_min = Definition::IsLengthLoad(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->min();

  RangeBoundary left_max = Definition::IsLengthLoad(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->max();

  bool overflow = false;
  if (!RangeBoundary::SymbolicAdd(left_min, right_range->min(), result_min)) {
    const auto left_min_bound = left_range->min().LowerBound();
    const auto right_min_bound = right_range->min().LowerBound();
    if (RangeBoundary::WillAddOverflow(left_min_bound, right_min_bound)) {
      overflow = true;
    } else {
      *result_min = RangeBoundary::Add(left_min_bound, right_min_bound);
    }
  }
  if (!RangeBoundary::SymbolicAdd(left_max, right_range->max(), result_max)) {
    const auto left_max_bound = left_range->max().UpperBound();
    const auto right_max_bound = right_range->max().UpperBound();
    if (RangeBoundary::WillAddOverflow(left_max_bound, right_max_bound)) {
      overflow = true;
    } else {
      *result_max = RangeBoundary::Add(left_max_bound, right_max_bound);
    }
  }
  if (overflow) {
    *result_min = RangeBoundary::MinInt64();
    *result_max = RangeBoundary::MaxInt64();
  }
}

void Range::Sub(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max,
                Definition* left_defn) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);

  RangeBoundary left_min = Definition::IsLengthLoad(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->min();

  RangeBoundary left_max = Definition::IsLengthLoad(left_defn)
                               ? RangeBoundary::FromDefinition(left_defn)
                               : left_range->max();

  bool overflow = false;
  if (!RangeBoundary::SymbolicSub(left_min, right_range->max(), result_min)) {
    const auto left_min_bound = left_range->min().LowerBound();
    const auto right_max_bound = right_range->max().UpperBound();
    if (RangeBoundary::WillSubOverflow(left_min_bound, right_max_bound)) {
      overflow = true;
    } else {
      *result_min = RangeBoundary::Sub(left_min_bound, right_max_bound);
    }
  }
  if (!RangeBoundary::SymbolicSub(left_max, right_range->min(), result_max)) {
    const auto left_max_bound = left_range->max().UpperBound();
    const auto right_min_bound = right_range->min().LowerBound();
    if (RangeBoundary::WillSubOverflow(left_max_bound, right_min_bound)) {
      overflow = true;
    } else {
      *result_max = RangeBoundary::Sub(left_max_bound, right_min_bound);
    }
  }
  if (overflow) {
    *result_min = RangeBoundary::MinInt64();
    *result_max = RangeBoundary::MaxInt64();
  }
}

void Range::Mul(const Range* left_range,
                const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);

  const int64_t left_max = ConstantAbsMax(left_range);
  const int64_t right_max = ConstantAbsMax(right_range);
  if ((left_max <= -compiler::target::kSmiMin) &&
      (right_max <= -compiler::target::kSmiMin) &&
      ((left_max == 0) || (right_max <= kMaxInt64 / left_max))) {
    // Product of left and right max values stays in 64 bit range.
    const int64_t mul_max = left_max * right_max;
    if (OnlyPositiveOrZero(*left_range, *right_range) ||
        OnlyNegativeOrZero(*left_range, *right_range)) {
      // If both ranges are of the same sign then the range of the result
      // is positive and is between multiplications of absolute minimums
      // and absolute maximums.
      const int64_t mul_min =
          ConstantAbsMin(left_range) * ConstantAbsMin(right_range);
      *result_min = RangeBoundary::FromConstant(mul_min);
      *result_max = RangeBoundary::FromConstant(mul_max);
    } else {
      // If ranges have mixed signs then use conservative approximation:
      // absolute value of the result is less or equal to multiplication
      // of absolute maximums.
      *result_min = RangeBoundary::FromConstant(-mul_max);
      *result_max = RangeBoundary::FromConstant(mul_max);
    }
    return;
  }

  *result_min = RangeBoundary::MinInt64();
  *result_max = RangeBoundary::MaxInt64();
}

void Range::TruncDiv(const Range* left_range,
                     const Range* right_range,
                     RangeBoundary* result_min,
                     RangeBoundary* result_max) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);

  if (left_range->OnlyGreaterThanOrEqualTo(0) &&
      right_range->OnlyGreaterThanOrEqualTo(1)) {
    const int64_t left_max = ConstantAbsMax(left_range);
    const int64_t left_min = ConstantAbsMin(left_range);
    const int64_t right_max = ConstantAbsMax(right_range);
    const int64_t right_min = ConstantAbsMin(right_range);

    *result_max = RangeBoundary::FromConstant(left_max / right_min);
    *result_min = RangeBoundary::FromConstant(left_min / right_max);
    return;
  }

  *result_min = RangeBoundary::MinInt64();
  *result_max = RangeBoundary::MaxInt64();
}

void Range::Mod(const Range* right_range,
                RangeBoundary* result_min,
                RangeBoundary* result_max) {
  ASSERT(right_range != nullptr);
  ASSERT(result_min != nullptr);
  ASSERT(result_max != nullptr);
  // Each modulo result is positive and bounded by one less than
  // the maximum of the right-hand-side (it is unlikely that the
  // left-hand-side further refines this in typical programs).
  // Note that x % MinInt can be MaxInt and x % 0 always throws.
  const int64_t kModMin = 0;
  int64_t mod_max = kMaxInt64;
  if (Range::ConstantMin(right_range).ConstantValue() != kMinInt64) {
    const int64_t right_max = ConstantAbsMax(right_range);
    mod_max = Utils::Maximum(right_max - 1, kModMin);
  }
  *result_min = RangeBoundary::FromConstant(kModMin);
  *result_max = RangeBoundary::FromConstant(mod_max);
}

// Both the a and b ranges are >= 0.
bool Range::OnlyPositiveOrZero(const Range& a, const Range& b) {
  return a.OnlyGreaterThanOrEqualTo(0) && b.OnlyGreaterThanOrEqualTo(0);
}

// Both the a and b ranges are <= 0.
bool Range::OnlyNegativeOrZero(const Range& a, const Range& b) {
  return a.OnlyLessThanOrEqualTo(0) && b.OnlyLessThanOrEqualTo(0);
}

// Return the maximum absolute value included in range.
int64_t Range::ConstantAbsMax(const Range* range) {
  if (range == nullptr) {
    return kMaxInt64;
  }
  const int64_t abs_min =
      Utils::AbsWithSaturation(Range::ConstantMin(range).ConstantValue());
  const int64_t abs_max =
      Utils::AbsWithSaturation(Range::ConstantMax(range).ConstantValue());
  return Utils::Maximum(abs_min, abs_max);
}

// Return the minimum absolute value included in range.
int64_t Range::ConstantAbsMin(const Range* range) {
  if (range == nullptr) {
    return 0;
  }
  const int64_t abs_min =
      Utils::AbsWithSaturation(Range::ConstantMin(range).ConstantValue());
  const int64_t abs_max =
      Utils::AbsWithSaturation(Range::ConstantMax(range).ConstantValue());
  return Utils::Minimum(abs_min, abs_max);
}

void Range::BinaryOp(const Token::Kind op,
                     const Range* left_range,
                     const Range* right_range,
                     Definition* left_defn,
                     Range* result) {
  ASSERT(left_range != nullptr);
  ASSERT(right_range != nullptr);

  RangeBoundary min;
  RangeBoundary max;
  ASSERT(min.IsUnknown() && max.IsUnknown());

  switch (op) {
    case Token::kADD:
      Range::Add(left_range, right_range, &min, &max, left_defn);
      break;

    case Token::kSUB:
      Range::Sub(left_range, right_range, &min, &max, left_defn);
      break;

    case Token::kMUL:
      Range::Mul(left_range, right_range, &min, &max);
      break;

    case Token::kTRUNCDIV:
      Range::TruncDiv(left_range, right_range, &min, &max);
      break;

    case Token::kMOD:
      Range::Mod(right_range, &min, &max);
      break;

    case Token::kSHL:
      Range::Shl(left_range, right_range, &min, &max);
      break;

    case Token::kSHR:
      Range::Shr(left_range, right_range, &min, &max);
      break;

    case Token::kUSHR:
      Range::Ushr(left_range, right_range, &min, &max);
      break;

    case Token::kBIT_AND:
      Range::And(left_range, right_range, &min, &max);
      break;

    case Token::kBIT_XOR:
    case Token::kBIT_OR:
      Range::BitwiseOp(left_range, right_range, &min, &max);
      break;

    default:
      *result = Range::Int64();
      return;
  }

  ASSERT(!min.IsUnknown() && !max.IsUnknown());

  // Sanity: avoid [l, u] with constants l > u.
  ASSERT(!min.IsConstant() || !max.IsConstant() ||
         min.ConstantValue() <= max.ConstantValue());

  *result = Range(min, max);
}

void Definition::set_range(const Range& range) {
  if (range_ == nullptr) {
    range_ = new Range();
  }
  *range_ = range;
}

void Definition::InferRange(RangeAnalysis* analysis, Range* range) {
  if (Type()->ToCid() == kSmiCid) {
    *range = Range::Smi();
  } else if (IsInt64Definition()) {
    *range = Range::Int64();
  } else if (IsInt32Definition()) {
    *range = Range::Full(kUnboxedInt32);
  } else if (Type()->IsInt()) {
    *range = Range::Int64();
  } else {
    // Only Smi and Mint supported.
    FATAL("Unsupported type in: %s", ToCString());
  }

  // If the representation also gives us range information, then refine
  // the range from the type by using the intersection of the two.
  if (RepresentationUtils::IsUnboxedInteger(representation())) {
    *range = Range::Full(representation()).Intersect(range);
  }
}

static bool DependsOnSymbol(const RangeBoundary& a, Definition* symbol) {
  return a.IsSymbol() && (UnwrapConstraint(a.symbol()) == symbol);
}

// Given the range and definition update the range so that
// it covers both original range and definitions range.
//
// The following should also hold:
//
//     [_|_, _|_] U a = a U [_|_, _|_] = a
//
static void Join(Range* range,
                 Definition* defn,
                 const Range* defn_range,
                 const Range& full_range) {
  if (Range::IsUnknown(defn_range)) {
    return;
  }

  if (Range::IsUnknown(range)) {
    *range = *defn_range;
    return;
  }

  Range other = *defn_range;

  // Handle patterns where range already depends on defn as a symbol:
  //
  //    (..., S+o] U range(S) and [S+o, ...) U range(S)
  //
  // To improve precision of the computed join use [S, S] instead of
  // using range(S). It will be canonicalized away by JoinMin/JoinMax
  // functions.
  Definition* unwrapped = UnwrapConstraint(defn);
  if (DependsOnSymbol(range->min(), unwrapped) ||
      DependsOnSymbol(range->max(), unwrapped)) {
    other = Range(RangeBoundary::FromDefinition(defn, 0),
                  RangeBoundary::FromDefinition(defn, 0));
  }

  // First try to compare ranges based on their upper and lower bounds.
  const int64_t inf_range = range->min().LowerBound(full_range);
  const int64_t inf_other = other.min().LowerBound(full_range);
  const int64_t sup_range = range->max().UpperBound(full_range);
  const int64_t sup_other = other.max().UpperBound(full_range);

  if (sup_range <= inf_other) {
    // The range is fully below defn's range. Keep the minimum and
    // expand the maximum.
    range->set_max(other.max());
  } else if (sup_other <= inf_range) {
    // The range is fully above defn's range. Keep the maximum and
    // expand the minimum.
    range->set_min(other.min());
  } else {
    // Can't compare ranges as whole. Join minimum and maximum separately.
    *range =
        Range(RangeBoundary::JoinMin(range->min(), other.min(), full_range),
              RangeBoundary::JoinMax(range->max(), other.max(), full_range));
  }
}

// A definition dominates a phi if its block dominates the phi's block
// and the two blocks are different.
static bool DominatesPhi(BlockEntryInstr* a, BlockEntryInstr* phi_block) {
  return a->Dominates(phi_block) && (a != phi_block);
}

// When assigning range to a phi we must take care to avoid self-reference
// cycles when phi's range depends on the phi itself.
// To prevent such cases we impose additional restriction on symbols that
// can be used as boundaries for phi's range: they must dominate
// phi's definition.
static RangeBoundary EnsureAcyclicSymbol(BlockEntryInstr* phi_block,
                                         const RangeBoundary& a,
                                         const RangeBoundary& limit) {
  if (!a.IsSymbol() || DominatesPhi(a.symbol()->GetBlock(), phi_block)) {
    return a;
  }

  // Symbol does not dominate phi. Try unwrapping constraint and check again.
  Definition* unwrapped = UnwrapConstraint(a.symbol());
  if ((unwrapped != a.symbol()) &&
      DominatesPhi(unwrapped->GetBlock(), phi_block)) {
    return RangeBoundary::FromDefinition(unwrapped, a.offset());
  }

  return limit;
}

static const Range* GetInputRange(Value* input, const Range* full_range) {
  Definition* defn = input->definition();
  const Range* range = defn->range();

  if ((range == nullptr) && !RangeAnalysis::IsIntegerDefinition(defn)) {
    // Type propagator determined that reaching type for this use is int.
    // However the definition itself is not a int-definition and
    // thus it will never have range assigned to it. Just return the widest
    // range possible for this value.
    // Note: that we can't return nullptr here because it is used as lattice's
    // bottom element to indicate that the range was not computed *yet*.
    return full_range;
  }

  return range;
}

void PhiInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range full_range = FullRangeForPhi(this);
  for (intptr_t i = 0; i < InputCount(); i++) {
    Value* input = InputAt(i);
    Join(range, input->definition(), GetInputRange(input, &full_range),
         full_range);
  }

  BlockEntryInstr* phi_block = GetBlock();
  range->set_min(
      EnsureAcyclicSymbol(phi_block, range->min(), RangeBoundary::MinSmi()));
  range->set_max(
      EnsureAcyclicSymbol(phi_block, range->max(), RangeBoundary::MaxSmi()));
}

void ConstantInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  if (value_.IsInteger()) {
    int64_t value = Integer::Cast(value_).Value();
    *range = Range(RangeBoundary::FromConstant(value),
                   RangeBoundary::FromConstant(value));
  } else {
    // Only integer constants supported.
    FATAL("Unexpected constant: %s\n", value_.ToCString());
  }
}

void ConstraintInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range full_range =
      Range::Full(representation_, TaggedMode::kTaggedIsSmi);
  const Range* value_range = GetInputRange(value(), &full_range);
  if (Range::IsUnknown(value_range)) {
    return;
  }

  // TODO(vegorov) check if precision of the analysis can be improved by
  // recognizing intersections of the form:
  //
  //       (..., S+x] ^ [S+x, ...) = [S+x, S+x]
  //
  Range result = value_range->Intersect(constraint());

  if (result.IsUnsatisfiable()) {
    return;
  }

  *range = result;
}

void LoadFieldInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  switch (slot().kind()) {
    case Slot::Kind::kArray_length:
    case Slot::Kind::kGrowableObjectArray_length:
      *range = Range(
          RangeBoundary::FromConstant(0),
          RangeBoundary::FromConstant(compiler::target::Array::kMaxElements));
      break;

    case Slot::Kind::kTypedDataBase_length:
    case Slot::Kind::kTypedDataView_offset_in_bytes:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;

    case Slot::Kind::kAbstractType_hash:
    case Slot::Kind::kTypeArguments_hash:
      *range = Range::Smi();
      break;

    case Slot::Kind::kTypeArguments_length:
      *range = Range(RangeBoundary::FromConstant(0),
                     RangeBoundary::FromConstant(
                         compiler::target::TypeArguments::kMaxElements));
      break;

    case Slot::Kind::kRecord_shape:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;

    case Slot::Kind::kString_length:
      *range = Range(
          RangeBoundary::FromConstant(0),
          RangeBoundary::FromConstant(compiler::target::String::kMaxElements));
      break;

    case Slot::Kind::kDartField:
    case Slot::Kind::kCapturedVariable:
    case Slot::Kind::kRecordField:
      // Use default value.
      Definition::InferRange(analysis, range);
      break;

    case Slot::Kind::kTypeArguments:
    case Slot::Kind::kTypeArgumentsIndex:
#define NATIVE_SLOT_CASE(ClassName, __, FieldName, ___, ____)                  \
  case Slot::Kind::k##ClassName##_##FieldName:
      NOT_INT_NATIVE_SLOTS_LIST(NATIVE_SLOT_CASE)
#undef NATIVE_SLOT_CASE
      // Not an integer valued field.
      UNREACHABLE();
      break;

    case Slot::Kind::kArrayElement:
      // Should not be used in LoadField instructions.
      UNREACHABLE();
      break;

#define UNBOXED_NATIVE_SLOT_CASE(Class, __, Field, ___, ____)                  \
  case Slot::Kind::k##Class##_##Field:
      UNBOXED_NATIVE_SLOTS_LIST(UNBOXED_NATIVE_SLOT_CASE)
#undef UNBOXED_NATIVE_SLOT_CASE
      *range = Range::Full(slot().representation());
      break;

    case Slot::Kind::kClosure_hash:
    case Slot::Kind::kLinkedHashBase_hash_mask:
    case Slot::Kind::kLinkedHashBase_used_data:
    case Slot::Kind::kLinkedHashBase_deleted_keys:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;

    case Slot::Kind::kArgumentsDescriptor_type_args_len:
    case Slot::Kind::kArgumentsDescriptor_positional_count:
    case Slot::Kind::kArgumentsDescriptor_count:
    case Slot::Kind::kArgumentsDescriptor_size:
      *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
      break;
  }
}

void LoadIndexedInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  // Use the precise array element representation instead of the returned
  // representation to avoid overapproximating the range for small elements.
  auto const rep =
      RepresentationUtils::RepresentationOfArrayElement(class_id());
  if (RepresentationUtils::IsUnboxed(rep)) {
    *range = Range::Full(rep);
  } else {
    Definition::InferRange(analysis, range);
  }
}

void LoadClassIdInstr::InferRange(uword* lower, uword* upper) {
  ASSERT(kIllegalCid == 0);
  *lower = 1;
  *upper = kClassIdTagMax;

  CompileType* ctype = object()->Type();
  intptr_t cid = ctype->ToCid();
  if (cid != kDynamicCid) {
    *lower = *upper = cid;
  } else if (CompilerState::Current().is_aot()) {
    IsolateGroup* isolate_group = IsolateGroup::Current();
    *upper = isolate_group->has_dynamically_extendable_classes()
                 ? kClassIdTagMax
                 : isolate_group->class_table()->NumCids();

    HierarchyInfo* hi = Thread::Current()->hierarchy_info();
    if (hi != nullptr) {
      const auto& type = *ctype->ToAbstractType();
      if (type.IsType() && !type.IsFutureOrType() && !ctype->is_nullable()) {
        const auto& type_class = Class::Handle(type.type_class());
        if (!type_class.has_dynamically_extendable_subtypes()) {
          const auto& ranges =
              hi->SubtypeRangesForClass(type_class, /*include_abstract=*/false,
                                        /*exclude_null=*/true);
          if (ranges.length() > 0) {
            *lower = ranges[0].cid_start;
            *upper = ranges[ranges.length() - 1].cid_end;
          }
        }
      }
    }
  }
}

void LoadClassIdInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  uword lower, upper;
  InferRange(&lower, &upper);
  *range = Range(RangeBoundary::FromConstant(lower),
                 RangeBoundary::FromConstant(upper));
}

void LoadCodeUnitsInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  ASSERT(IsStringClassId(class_id()));
  RangeBoundary zero = RangeBoundary::FromConstant(0);
  // Take the number of loaded characters into account when determining the
  // range of the result.
  ASSERT(element_count_ > 0);
  switch (class_id()) {
    case kOneByteStringCid:
      ASSERT(element_count_ <= 4);
      *range = Range(zero, RangeBoundary::FromConstant(
                               Utils::NBitMask(kBitsPerByte * element_count_)));
      break;
    case kTwoByteStringCid:
      ASSERT(element_count_ <= 2);
      *range = Range(zero, RangeBoundary::FromConstant(Utils::NBitMask(
                               2 * kBitsPerByte * element_count_)));
      break;
    default:
      UNREACHABLE();
      break;
  }
}

void Utf8ScanInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  // The input bytes given to the Utf8Scan instruction are in non-negative Smi
  // range and so is the resulting computed length.
  *range = Range(RangeBoundary::FromConstant(0), RangeBoundary::MaxSmi());
}

void IfThenElseInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const intptr_t min = Utils::Minimum(if_true_, if_false_);
  const intptr_t max = Utils::Maximum(if_true_, if_false_);
  *range =
      Range(RangeBoundary::FromConstant(min), RangeBoundary::FromConstant(max));
}

void BinaryIntegerOpInstr::InferRangeHelper(const Range* left_range,
                                            const Range* right_range,
                                            Range* range) {
  // TODO(vegorov): canonicalize BinaryIntegerOp to always have constant on the
  // right and a non-constant on the left.
  if (Range::IsUnknown(left_range) || Range::IsUnknown(right_range)) {
    return;
  }

  Range::BinaryOp(op_kind(), left_range, right_range, left()->definition(),
                  range);
  ASSERT(!Range::IsUnknown(range));

  // Calculate overflowed status before clamping if operation is
  // not truncating.
  if (!is_truncating()) {
    set_can_overflow(
        !Range::Fits(range, representation(), TaggedMode::kTaggedIsSmi));
  }

  range->Clamp(Range::Full(representation(), TaggedMode::kTaggedIsSmi));
}

static void CacheRange(Range** slot,
                       const Range* range,
                       const Range& full_range) {
  if (range != nullptr) {
    if (*slot == nullptr) {
      *slot = new Range();
    }
    **slot = *range;

    // Eliminate any symbolic dependencies from the range information.
    (*slot)->ClampToConstant(full_range);
  } else if (*slot != nullptr) {
    **slot = Range();  // Clear cached range information.
  }
}

void BinaryIntegerOpInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range left_range =
      Range::Full(RequiredInputRepresentation(0), TaggedMode::kTaggedIsSmi);
  const Range right_range =
      Range::Full(RequiredInputRepresentation(1), TaggedMode::kTaggedIsSmi);
  const Range* right_input_range = GetInputRange(right(), &right_range);
  if (op_kind() == Token::kSHL || op_kind() == Token::kSHR ||
      op_kind() == Token::kUSHR || op_kind() == Token::kMOD ||
      op_kind() == Token::kTRUNCDIV) {
    CacheRange(&right_range_, right_input_range, right_range);
  }
  InferRangeHelper(GetInputRange(left(), &left_range), right_input_range,
                   range);
}

void BoxIntegerInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* value_range = value()->definition()->range();
  if (Range::IsUnknown(value_range)) {
    *range = Range::Full(from_representation());
  } else {
    ASSERT_VALID_RANGE_FOR_REPRESENTATION(value()->definition(), value_range,
                                          from_representation());
    *range = *value_range;
  }
}

void UnboxIntegerInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  if (IsUnboxInt64() && Definition::IsLengthLoad(value()->definition())) {
    // Provide symbolic range to improve bounds check elimination.
    RangeBoundary v = RangeBoundary::FromDefinition(value()->definition(), 0);
    *range = Range(v, v);
    return;
  }
  Range* const value_range = value()->definition()->range();
  const Range to_range = Range::Full(representation());

  if (Range::IsUnknown(value_range)) {
    *range = to_range;
  } else if (value_range->IsWithin(&to_range)) {
    *range = *value_range;
  } else {
    ASSERT((representation() == kUnboxedInt32) ||
           (representation() == kUnboxedUint32));
    // In most cases any non-representable values means
    // no assumption can be made about the truncated value.
    *range = to_range;
  }
  ASSERT_VALID_RANGE_FOR_REPRESENTATION(this, range, representation());
}

void IntConverterInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  ASSERT(to() != kUntagged);  // Not an integer-valued definition.
  ASSERT(RepresentationUtils::IsUnboxedInteger(to()));
  ASSERT(from() == kUntagged || RepresentationUtils::IsUnboxedInteger(from()));

  const Range* const value_range = value()->definition()->range();
  const Range to_range = Range::Full(to());

  if (from() == kUntagged) {
    ASSERT(value_range == nullptr);  // Not an integer-valued definition.
    *range = to_range;
  } else if (Range::IsUnknown(value_range)) {
    *range = to_range;
  } else if (RepresentationUtils::ValueSize(to()) >
                 RepresentationUtils::ValueSize(from()) &&
             (!RepresentationUtils::IsUnsignedInteger(to()) ||
              RepresentationUtils::IsUnsignedInteger(from()))) {
    // All signed unboxed ints of larger sizes can represent all values for
    // signed or unsigned unboxed ints of smaller sizes, and all unsigned
    // unboxed ints of larger sizes can represent all values for unsigned
    // boxed ints of smaller sizes.
    *range = *value_range;
  } else {
    // Either the bits are being reinterpreted (if the two representations
    // are the same size) or a larger value is being truncated. That means
    // we need to determine whether or not the value range lies within the
    // range of numbers that have the same representation (modulo truncation).
    const Range common_range = Range::Full(from()).Intersect(&to_range);
    if (value_range->IsWithin(&common_range)) {
      *range = *value_range;
    } else {
      // In most cases, if there are non-representable values, then no
      // assumptions can be made about the converted value.
      *range = to_range;
    }
  }

  ASSERT_VALID_RANGE_FOR_REPRESENTATION(this, range, to());
}

void AssertAssignableInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* value_range = value()->definition()->range();
  if (!Range::IsUnknown(value_range)) {
    *range = *value_range;
  } else {
    *range = Range::Int64();
  }
}

void CheckBoundBaseInstr::InferRange(RangeAnalysis* analysis, Range* range) {
  const Range* length_range = length()->definition()->range();
  const auto checked_range =
      Range(RangeBoundary::FromConstant(0), Range::ConstantMax(length_range));
  const Range* index_range = index()->definition()->range();
  Range result;
  if (Range::IsUnknown(index_range)) {
    result = checked_range;
  } else {
    result = index_range->Intersect(&checked_range);
  }
  if (result.IsUnsatisfiable()) {
    return;
  }
  *range = result;
}

static bool IsRedundantBasedOnRangeInformation(Value* index, Value* length) {
  TRACE_RANGE_ANALYSIS(
      THR_Print("Checking if range check is redundant, index %s, length %s\n",
                index->ToCString(), length->ToCString()));
  if (index->BindsToSmiConstant() && length->BindsToSmiConstant()) {
    const auto index_val = index->BoundSmiConstant();
    const auto length_val = length->BoundSmiConstant();
    TRACE_RANGE_ANALYSIS(THR_Print("  ... constant index and length\n"));
    return (0 <= index_val && index_val < length_val);
  }

  // Range of the index is unknown can't decide if the check is redundant.
  Definition* index_defn = index->definition();
  Range* index_range = index_defn->range();
  if (index_range == nullptr) {
    if (!index->BindsToSmiConstant()) {
      TRACE_RANGE_ANALYSIS(THR_Print("  ... index without a range\n"));
      return false;
    }
    // index_defn itself is not necessarily the constant.
    index_defn = index_defn->OriginalDefinition();
    Range range;
    index_defn->InferRange(nullptr, &range);
    ASSERT(!Range::IsUnknown(&range));
    index_defn->set_range(range);
    index_range = index_defn->range();
  }

  // Range of the index is not positive. Check can't be redundant.
  if (Range::ConstantMinSmi(index_range).ConstantValue() < 0) {
    TRACE_RANGE_ANALYSIS(THR_Print("  ... index can be negative\n"));
    return false;
  }

  RangeBoundary max = RangeBoundary::FromDefinition(index_defn);
  RangeBoundary max_upper = max.UpperBound();
  RangeBoundary array_length =
      RangeBoundary::FromDefinition(length->definition());
  RangeBoundary length_lower = array_length.LowerBound();
  if (max_upper.OverflowedSmi() || length_lower.OverflowedSmi()) {
    TRACE_RANGE_ANALYSIS(
        THR_Print("  ... max index (%s) or min length (%s) overflows Smi\n",
                  max.ToCString(), array_length.ToCString()));
    return false;
  }

  // Try to compare constant boundaries.
  if (max_upper.ConstantValue() < length_lower.ConstantValue()) {
    TRACE_RANGE_ANALYSIS(THR_Print("  ... max index (%s) >= min length (%s)\n",
                                   max.ToCString(), array_length.ToCString()));
    return true;
  }

  RangeBoundary canonical_length =
      CanonicalizeBoundary(array_length, RangeBoundary::MaxInt64());
  if (canonical_length.OverflowedSmi()) {
    TRACE_RANGE_ANALYSIS(
        THR_Print("  ... canonical length boundary (%s) overflows Smi\n",
                  canonical_length.ToCString()));
    return false;
  }

  // Try symbolic comparison.
  do {
    if (DependOnSameSymbol(max, canonical_length)) {
      TRACE_RANGE_ANALYSIS(THR_Print(
          "  ... max index (%s) and length (%s) depend on the same symbol\n",
          max.ToCString(), canonical_length.ToCString()));
      return max.offset() < canonical_length.offset();
    }
  } while (CanonicalizeMaxBoundary(&max) ||
           CanonicalizeMinBoundary(&canonical_length));

  // Failed to prove that maximum is bounded with array length.
  TRACE_RANGE_ANALYSIS(THR_Print(
      "  ... max index (%s) and length (%s) depend on distinct symbols\n",
      max.ToCString(), canonical_length.ToCString()));
  return false;
}

bool CheckBoundBaseInstr::IsRedundant(bool use_loops) {
  // First, try to prove redundancy with the results of range analysis.
  if (IsRedundantBasedOnRangeInformation(index(), length())) {
    return true;
  } else if (!use_loops) {
    return false;
  }
  // Next, try to prove redundancy with the results of induction analysis.
  LoopInfo* loop = GetBlock()->loop_info();
  if (loop != nullptr) {
    return loop->IsInRange(this, index(), length());
  }
  return false;
}

}  // namespace dart
