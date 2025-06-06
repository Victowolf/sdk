// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryImportElementTest_keepLinking);
    defineReflectiveTests(LibraryImportElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryImportElementTest extends ElementsBaseTest {
  test_import_configurations_useDefault() async {
    declaredVariables = {
      'dart.library.io': 'false',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        class B @104
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
''');

    var typeA = library.getClass2('B')!.supertype!;
    var fragmentA = typeA.element3.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo.dart');
  }

  test_import_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_io.dart
      classes
        class B @104
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: package:test/foo_io.dart::<fragment>::@class::A::@constructor::new#element
''');

    var typeA = library.getClass2('B')!.supertype!;
    var fragmentA = typeA.element3.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_io.dart');
  }

  test_import_configurations_useFirst_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_io.dart
      classes
        class B @124
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: package:test/foo_io.dart::<fragment>::@class::A::@constructor::new#element
''');

    var typeA = library.getClass2('B')!.supertype!;
    var fragmentA = typeA.element3.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_io.dart');
  }

  test_import_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_html.dart
      classes
        class B @104
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: package:test/foo_html.dart::<fragment>::@class::A::@constructor::new#element
''');

    var typeA = library.getClass2('B')!.supertype!;
    var fragmentA = typeA.element3.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_html.dart');
  }

  test_import_configurations_useSecond_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_html.dart
      classes
        class B @124
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: package:test/foo_html.dart::<fragment>::@class::A::@constructor::new#element
''');

    var typeA = library.getClass2('B')!.supertype!;
    var fragmentA = typeA.element3.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_html.dart');
  }

  test_import_dartCore_explicit() async {
    var library = await buildLibrary('''
import 'dart:core';
import 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core
        dart:math
''');
  }

  test_import_dartCore_implicit() async {
    var library = await buildLibrary('''
import 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
''');
  }

  test_import_deferred() async {
    newFile('$testPackageLibPath/a.dart', 'f() {}');
    var library = await buildLibrary('''
import 'a.dart' deferred as p;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart deferred as p @28
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @28
''');
  }

  test_import_export() async {
    var library = await buildLibrary('''
import 'dart:async' as i1;
export 'dart:math';
import 'dart:async' as i2;
export 'dart:math';
import 'dart:async' as i3;
export 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as i1 @23
        dart:async as i2 @70
        dart:async as i3 @117
      prefixes
        <testLibraryFragment>::@prefix2::i1
          fragments: @23
        <testLibraryFragment>::@prefix2::i2
          fragments: @70
        <testLibraryFragment>::@prefix2::i3
          fragments: @117
''');
  }

  test_import_hide() async {
    var library = await buildLibrary('''
import 'dart:async' hide Stream, Completer; Future f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        f @51
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: Future<dynamic>
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: Future<dynamic>
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: Future<dynamic>
      returnType: void
''');
  }

  test_import_hide_offsetEnd() async {
    var library = await buildLibrary('''
import "dart:math" hide e, pi;
''');
    var import = library.definingCompilationUnit.libraryImports[0];
    var combinator = import.combinators[0] as HideElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_invalidUri_metadata() async {
    var library = await buildLibrary('''
@foo
import 'ht:';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: foo @1
        element: <null>
        staticType: null
      element2: <null>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        relativeUri 'ht:'
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                element: <null>
                staticType: null
              element2: <null>
''');
  }

  test_import_multiple_combinators() async {
    var library = await buildLibrary('''
import "dart:async" hide Stream show Future;
Future f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        f @52
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: Future<dynamic>
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: Future<dynamic>
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: Future<dynamic>
      returnType: void
''');
  }

  test_import_prefixed() async {
    newFile('$testPackageLibPath/a.dart', 'library a; class C {}');
    var library = await buildLibrary('import "a.dart" as a; a.C c;');

    var prefixElement =
        library.definingCompilationUnit.libraryImports[0].prefix!.element;
    expect(prefixElement.nameOffset, 19);

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a @19
      prefixes
        <testLibraryFragment>::@prefix2::a
          fragments: @19
      topLevelVariables
        c @26
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
''');
  }

  test_import_prefixed_missingName() async {
    var library = await buildLibrary(r'''
import 'dart:math' as;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math as <null-name> (offset=21)
      prefixes
        <testLibraryFragment>::@prefix2::1
          fragments: @null
''');
  }

  test_import_self() async {
    var library = await buildLibrary('''
import 'test.dart' as p;
class C {}
class D extends p.C {} // Prevent "unused import" warning
''');
    var libraryImports = library.definingCompilationUnit.libraryImports;
    expect(libraryImports, hasLength(2));
    expect(libraryImports[0].importedLibrary!.location, library.location);
    expect(libraryImports[1].importedLibrary!.isDartCore, true);
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/test.dart as p @22
      prefixes
        <testLibraryFragment>::@prefix2::p
          fragments: @22
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
        class D @42
          reference: <testLibraryFragment>::@class::D
          element: <testLibrary>::@class::D
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibrary>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
          superConstructor: <testLibraryFragment>::@class::C::@constructor::new#element
''');
  }

  test_import_show() async {
    var library = await buildLibrary('''
import "dart:async" show Future, Stream;
Future f;
Stream s;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      topLevelVariables
        f @48
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
        s @58
          reference: <testLibraryFragment>::@topLevelVariable::s
          element: <testLibrary>::@topLevelVariable::s
          getter2: <testLibraryFragment>::@getter::s
          setter2: <testLibraryFragment>::@setter::s
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
        synthetic get s
          reference: <testLibraryFragment>::@getter::s
          element: <testLibraryFragment>::@getter::s#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
        synthetic set s
          reference: <testLibraryFragment>::@setter::s
          element: <testLibraryFragment>::@setter::s#element
          formalParameters
            _s
              element: <testLibraryFragment>::@setter::s::@parameter::_s#element
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: Future<dynamic>
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
    s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: <testLibraryFragment>::@topLevelVariable::s
      type: Stream<dynamic>
      getter: <testLibraryFragment>::@getter::s#element
      setter: <testLibraryFragment>::@setter::s#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
      returnType: Future<dynamic>
    synthetic static get s
      firstFragment: <testLibraryFragment>::@getter::s
      returnType: Stream<dynamic>
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: Future<dynamic>
      returnType: void
    synthetic static set s
      firstFragment: <testLibraryFragment>::@setter::s
      formalParameters
        requiredPositional _s
          type: Stream<dynamic>
      returnType: void
''');
  }

  test_import_show_offsetEnd() async {
    var library = await buildLibrary('''
import "dart:math" show e, pi;
''');
    var import = library.definingCompilationUnit.libraryImports[0];
    var combinator = import.combinators[0] as ShowElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_uri() async {
    var library = await buildLibrary('''
import 'foo.dart';
''');

    var libraryImports = library.definingCompilationUnit.libraryImports;
    var uri = libraryImports[0].uri as DirectiveUriWithLibrary;
    expect(uri.relativeUriString, 'foo.dart');
  }

  test_imports() async {
    newFile('$testPackageLibPath/a.dart', 'library a; class C {}');
    newFile('$testPackageLibPath/b.dart', 'library b; class D {}');
    var library =
        await buildLibrary('import "a.dart"; import "b.dart"; C c; D d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      topLevelVariables
        c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          element: <testLibrary>::@topLevelVariable::c
          getter2: <testLibraryFragment>::@getter::c
          setter2: <testLibraryFragment>::@setter::c
        d @41
          reference: <testLibraryFragment>::@topLevelVariable::d
          element: <testLibrary>::@topLevelVariable::d
          getter2: <testLibraryFragment>::@getter::d
          setter2: <testLibraryFragment>::@setter::d
      getters
        synthetic get c
          reference: <testLibraryFragment>::@getter::c
          element: <testLibraryFragment>::@getter::c#element
        synthetic get d
          reference: <testLibraryFragment>::@getter::d
          element: <testLibraryFragment>::@getter::d#element
      setters
        synthetic set c
          reference: <testLibraryFragment>::@setter::c
          element: <testLibraryFragment>::@setter::c#element
          formalParameters
            _c
              element: <testLibraryFragment>::@setter::c::@parameter::_c#element
        synthetic set d
          reference: <testLibraryFragment>::@setter::d
          element: <testLibraryFragment>::@setter::d#element
          formalParameters
            _d
              element: <testLibraryFragment>::@setter::d::@parameter::_d#element
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: <testLibraryFragment>::@topLevelVariable::c
      type: C
      getter: <testLibraryFragment>::@getter::c#element
      setter: <testLibraryFragment>::@setter::c#element
    d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: <testLibraryFragment>::@topLevelVariable::d
      type: D
      getter: <testLibraryFragment>::@getter::d#element
      setter: <testLibraryFragment>::@setter::d#element
  getters
    synthetic static get c
      firstFragment: <testLibraryFragment>::@getter::c
      returnType: C
    synthetic static get d
      firstFragment: <testLibraryFragment>::@getter::d
      returnType: D
  setters
    synthetic static set c
      firstFragment: <testLibraryFragment>::@setter::c
      formalParameters
        requiredPositional _c
          type: C
      returnType: void
    synthetic static set d
      firstFragment: <testLibraryFragment>::@setter::d
      formalParameters
        requiredPositional _d
          type: D
      returnType: void
''');
  }

  test_library_imports_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
import '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        noRelativeUriString
''');
  }

  test_library_imports_prefix_importedLibraries() async {
    var library = await buildLibrary(r'''
import 'dart:async' as p1;
import 'dart:collection' as p2;
import 'dart:math' as p1;
''');
    var p1 = library.definingCompilationUnit.libraryImportPrefixes
        .singleWhere((prefix) => prefix.name == 'p1');
    var libraryImports = library.definingCompilationUnit.libraryImports;
    var import_async = libraryImports[0];
    var import_math = libraryImports[2];
    expect(p1.imports, unorderedEquals([import_async, import_math]));
  }

  test_library_imports_syntheticDartCore() async {
    var library = await buildLibrary('');
    configuration.withSyntheticDartCoreImport = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core synthetic
''');
  }

  test_library_imports_withRelativeUri_emptyUriSelf() async {
    var library = await buildLibrary(r'''
import '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/test.dart
''');
  }

  test_library_imports_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
import 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        relativeUri 'foo:bar'
''');
  }

  test_library_imports_withRelativeUri_notExists() async {
    var library = await buildLibrary(r'''
import 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
''');
  }

  test_library_imports_withRelativeUri_notLibrary_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of other.lib;
''');
    var library = await buildLibrary(r'''
import 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        source 'package:test/a.dart'
''');
  }

  test_library_imports_withRelativeUriString() async {
    var library = await buildLibrary(r'''
import ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        relativeUriString ':'
''');
  }

  test_library_prefixes() async {
    var library = await buildLibrary(r'''
import 'dart:async' as p1;
import 'dart:collection' as p2;
import 'dart:math' as p1;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as p1 @23
        dart:collection as p2 @55
        dart:math as p1 @81
      prefixes
        <testLibraryFragment>::@prefix2::p1
          fragments: @23 @81
        <testLibraryFragment>::@prefix2::p2
          fragments: @55
''');
  }

  test_metadata_importDirective() async {
    var library = await buildLibrary('''
@a
import "dart:math";
const a = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element2: <testLibraryFragment>::@getter::a#element
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @29
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @33
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
''');
  }

  test_metadata_importDirective_hasShow() async {
    var library = await buildLibrary(r'''
@a
import "dart:math" show Random;

const a = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibraryFragment>::@getter::a#element
        staticType: null
      element2: <testLibraryFragment>::@getter::a#element
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        hasInitializer a @42
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @46
              staticType: int
          getter2: <testLibraryFragment>::@getter::a
      getters
        synthetic get a
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::a
        expression: expression_0
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
      returnType: int
''');
  }

  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    if (resourceProvider.pathContext.separator != '/') {
      return;
    }

    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', 'export "/a.dart";');
    var library = await buildLibrary('''
import 'a.dart';
import 'b.dart';
A v = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      topLevelVariables
        hasInitializer v @36
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
      returnType: A
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: A
      returnType: void
''');
  }

  test_unresolved_import() async {
    var library = await buildLibrary("import 'foo.dart';");
    var libraryImports = library.definingCompilationUnit.libraryImports;
    var importedLibrary = libraryImports[0].importedLibrary!;
    expect(importedLibrary.loadLibraryFunction, isNotNull);
    expect(importedLibrary.publicNamespace, isNotNull);
    expect(importedLibrary.exportNamespace, isNotNull);
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
''');
  }
}

@reflectiveTest
class LibraryImportElementTest_fromBytes extends LibraryImportElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryImportElementTest_keepLinking extends LibraryImportElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
