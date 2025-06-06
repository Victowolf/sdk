// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:meta/meta.dart';

typedef CodeActionWithPriority = ({CodeAction action, int priority});

typedef CodeActionWithPriorityAndIndex =
    ({CodeAction action, int priority, int index});

/// A base for classes that produce [CodeAction]s for the LSP handler.
abstract class AbstractCodeActionsProducer
    with RequestHandlerMixin<LspAnalysisServer> {
  final File file;
  final LineInfo lineInfo;
  final int offset;
  final int length;
  final bool Function(CodeActionKind?) shouldIncludeKind;
  final LspClientCapabilities capabilities;

  final AnalysisOptions analysisOptions;

  @override
  final LspAnalysisServer server;

  AbstractCodeActionsProducer(
    this.server,
    this.file,
    this.lineInfo, {
    required this.offset,
    required this.length,
    required this.shouldIncludeKind,
    required this.capabilities,
    required this.analysisOptions,
  });

  String get name;

  String get path => file.path;

  Set<DiagnosticTag> get supportedDiagnosticTags => capabilities.diagnosticTags;

  bool get supportsApplyEdit => capabilities.applyEdit;

  bool get supportsCodeDescription => capabilities.diagnosticCodeDescription;

  bool get supportsLiterals => capabilities.literalCodeActions;

  /// Creates a CodeAction to apply this assist. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  @protected
  CodeAction createAssistAction(
    protocol.SourceChange change,
    String? loggedAssistId,
    String path,
    LineInfo lineInfo,
  ) {
    return CodeAction(
      title: change.message,
      kind: toCodeActionKind(change.id, CodeActionKind.Refactor),
      diagnostics: const [],
      command: createLogActionCommand(loggedAssistId),
      edit: createWorkspaceEdit(
        server,
        capabilities,
        change,
        allowSnippets: true,
        filePath: path,
        lineInfo: lineInfo,
      ),
    );
  }

  /// Create an LSP [Diagnostic] for [error].
  @protected
  Diagnostic createDiagnostic(
    LineInfo lineInfo,
    engine.ErrorsResultImpl result,
    AnalysisError error,
  ) {
    return pluginToDiagnostic(
      server.uriConverter,
      (_) => lineInfo,
      protocol.newAnalysisError_fromEngine(result, error),
      supportedTags: supportedDiagnosticTags,
      clientSupportsCodeDescription: supportsCodeDescription,
    );
  }

  /// Creates a CodeAction to apply this fix. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  @protected
  CodeAction createFixAction(
    protocol.SourceChange change,
    String? loggedFixId,
    Diagnostic diagnostic,
    String path,
    LineInfo lineInfo,
  ) {
    return CodeAction(
      title: change.message,
      kind: toCodeActionKind(change.id, CodeActionKind.QuickFix),
      diagnostics: [diagnostic],
      command: createLogActionCommand(loggedFixId),
      edit: createWorkspaceEdit(
        server,
        capabilities,
        change,
        allowSnippets: true,
        filePath: path,
        lineInfo: lineInfo,
      ),
    );
  }

  /// Creates a command to log that a CodeAction was selected.
  ///
  /// Code Actions that provide their edits inline (and not via a command) do
  /// not normally call back to the server when an action is selected so this
  /// provides some visibility of them being chosen.
  Command? createLogActionCommand(String? action) {
    if (action == null) {
      return null;
    }

    return Command(
      command: Commands.logAction,
      title: 'Log Action',
      arguments: [
        {'action': action},
      ],
    );
  }

  @protected
  engine.ErrorsResultImpl createResult(
    AnalysisSession session,
    LineInfo lineInfo,
    List<AnalysisError> errors,
  ) {
    return engine.ErrorsResultImpl(
      session: session,
      file: file,
      content: file.readAsStringSync(),
      uri: server.uriConverter.toClientUri(path),
      lineInfo: lineInfo,
      isLibrary: true,
      isPart: false,
      errors: errors,
      analysisOptions: analysisOptions,
    );
  }

  Future<List<CodeActionWithPriority>> getAssistActions({
    OperationPerformanceImpl? performance,
  });

  Future<List<CodeActionWithPriority>> getFixActions(
    OperationPerformance? performance,
  );

  Future<List<Either2<CodeAction, Command>>> getRefactorActions(
    OperationPerformance? performance,
  );

  Future<List<Either2<CodeAction, Command>>> getSourceActions();

  /// Return the contents of the [file], or `null` if the file does not exist or
  /// cannot be read.
  @protected
  String? safelyRead(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }
}
