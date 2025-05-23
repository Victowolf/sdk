// MIT License
//
// Copyright (c) Microsoft Corporation.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "tool/generate_all.dart".

// ignore_for_file: prefer_void_to_null

import 'protocol_common.dart';
import 'protocol_special.dart';

/// Arguments for `attach` request. Additional attributes are implementation
/// specific.
class AttachRequestArguments extends RequestArguments {
  /// Arbitrary data from the previous, restarted session.
  /// The data is sent as the `restart` attribute of the `terminated` event.
  /// The client should leave the data intact.
  final Object? restart;

  static AttachRequestArguments fromJson(Map<String, Object?> obj) =>
      AttachRequestArguments.fromMap(obj);

  AttachRequestArguments({
    this.restart,
  });

  AttachRequestArguments.fromMap(Map<String, Object?> obj)
      : restart = obj['__restart'];

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (restart != null) '__restart': restart,
      };
}

/// Response to `attach` request. This is just an acknowledgement, so no body
/// field is required.
class AttachResponse extends Response {
  static AttachResponse fromJson(Map<String, Object?> obj) =>
      AttachResponse.fromMap(obj);

  AttachResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  AttachResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Information about a breakpoint created in `setBreakpoints`,
/// `setFunctionBreakpoints`, `setInstructionBreakpoints`, or
/// `setDataBreakpoints` requests.
class Breakpoint {
  /// Start position of the source range covered by the breakpoint. It is
  /// measured in UTF-16 code units and the client capability `columnsStartAt1`
  /// determines whether it is 0- or 1-based.
  final int? column;

  /// End position of the source range covered by the breakpoint. It is measured
  /// in UTF-16 code units and the client capability `columnsStartAt1`
  /// determines whether it is 0- or 1-based.
  /// If no end line is given, then the end column is assumed to be in the start
  /// line.
  final int? endColumn;

  /// The end line of the actual range covered by the breakpoint.
  final int? endLine;

  /// The identifier for the breakpoint. It is needed if breakpoint events are
  /// used to update or remove breakpoints.
  final int? id;

  /// A memory reference to where the breakpoint is set.
  final String? instructionReference;

  /// The start line of the actual range covered by the breakpoint.
  final int? line;

  /// A message about the state of the breakpoint.
  /// This is shown to the user and can be used to explain why a breakpoint
  /// could not be verified.
  final String? message;

  /// The offset from the instruction reference.
  /// This can be negative.
  final int? offset;

  /// A machine-readable explanation of why a breakpoint may not be verified. If
  /// a breakpoint is verified or a specific reason is not known, the adapter
  /// should omit this property. Possible values include:
  ///
  /// - `pending`: Indicates a breakpoint might be verified in the future, but the adapter cannot verify it in the current state.
  ///  - `failed`: Indicates a breakpoint was not able to be verified, and the
  /// adapter does not believe it can be verified without intervention.
  final String? reason;

  /// The source where the breakpoint is located.
  final Source? source;

  /// If true, the breakpoint could be set (but not necessarily at the desired
  /// location).
  final bool verified;

  static Breakpoint fromJson(Map<String, Object?> obj) =>
      Breakpoint.fromMap(obj);

  Breakpoint({
    this.column,
    this.endColumn,
    this.endLine,
    this.id,
    this.instructionReference,
    this.line,
    this.message,
    this.offset,
    this.reason,
    this.source,
    required this.verified,
  });

  Breakpoint.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        id = obj['id'] as int?,
        instructionReference = obj['instructionReference'] as String?,
        line = obj['line'] as int?,
        message = obj['message'] as String?,
        offset = obj['offset'] as int?,
        reason = obj['reason'] as String?,
        source = obj['source'] == null
            ? null
            : Source.fromJson(obj['source'] as Map<String, Object?>),
        verified = obj['verified'] as bool;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['id'] is! int?) {
      return false;
    }
    if (obj['instructionReference'] is! String?) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    if (obj['message'] is! String?) {
      return false;
    }
    if (obj['offset'] is! int?) {
      return false;
    }
    if (obj['reason'] is! String?) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    if (obj['verified'] is! bool) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        if (id != null) 'id': id,
        if (instructionReference != null)
          'instructionReference': instructionReference,
        if (line != null) 'line': line,
        if (message != null) 'message': message,
        if (offset != null) 'offset': offset,
        if (reason != null) 'reason': reason,
        if (source != null) 'source': source,
        'verified': verified,
      };
}

/// Properties of a breakpoint location returned from the `breakpointLocations`
/// request.
class BreakpointLocation {
  /// The start position of a breakpoint location. Position is measured in
  /// UTF-16 code units and the client capability `columnsStartAt1` determines
  /// whether it is 0- or 1-based.
  final int? column;

  /// The end position of a breakpoint location (if the location covers a
  /// range). Position is measured in UTF-16 code units and the client
  /// capability `columnsStartAt1` determines whether it is 0- or 1-based.
  final int? endColumn;

  /// The end line of breakpoint location if the location covers a range.
  final int? endLine;

  /// Start line of breakpoint location.
  final int line;

  static BreakpointLocation fromJson(Map<String, Object?> obj) =>
      BreakpointLocation.fromMap(obj);

  BreakpointLocation({
    this.column,
    this.endColumn,
    this.endLine,
    required this.line,
  });

  BreakpointLocation.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        line = obj['line'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'line': line,
      };
}

/// Arguments for `breakpointLocations` request.
class BreakpointLocationsArguments extends RequestArguments {
  /// Start position within `line` to search possible breakpoint locations in.
  /// It is measured in UTF-16 code units and the client capability
  /// `columnsStartAt1` determines whether it is 0- or 1-based. If no column is
  /// given, the first position in the start line is assumed.
  final int? column;

  /// End position within `endLine` to search possible breakpoint locations in.
  /// It is measured in UTF-16 code units and the client capability
  /// `columnsStartAt1` determines whether it is 0- or 1-based. If no end column
  /// is given, the last position in the end line is assumed.
  final int? endColumn;

  /// End line of range to search possible breakpoint locations in. If no end
  /// line is given, then the end line is assumed to be the start line.
  final int? endLine;

  /// Start line of range to search possible breakpoint locations in. If only
  /// the line is specified, the request returns all possible locations in that
  /// line.
  final int line;

  /// The source location of the breakpoints; either `source.path` or
  /// `source.sourceReference` must be specified.
  final Source source;

  static BreakpointLocationsArguments fromJson(Map<String, Object?> obj) =>
      BreakpointLocationsArguments.fromMap(obj);

  BreakpointLocationsArguments({
    this.column,
    this.endColumn,
    this.endLine,
    required this.line,
    required this.source,
  });

  BreakpointLocationsArguments.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        line = obj['line'] as int,
        source = Source.fromJson(obj['source'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'line': line,
        'source': source,
      };
}

/// Response to `breakpointLocations` request.
/// Contains possible locations for source breakpoints.
class BreakpointLocationsResponse extends Response {
  static BreakpointLocationsResponse fromJson(Map<String, Object?> obj) =>
      BreakpointLocationsResponse.fromMap(obj);

  BreakpointLocationsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  BreakpointLocationsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A `BreakpointMode` is provided as a option when setting breakpoints on
/// sources or instructions.
class BreakpointMode {
  /// Describes one or more type of breakpoint this mode applies to.
  final List<BreakpointModeApplicability> appliesTo;

  /// A help text providing additional information about the breakpoint mode.
  /// This string is typically shown as a hover and can be translated.
  final String? description;

  /// The name of the breakpoint mode. This is shown in the UI.
  final String label;

  /// The internal ID of the mode. This value is passed to the `setBreakpoints`
  /// request.
  final String mode;

  static BreakpointMode fromJson(Map<String, Object?> obj) =>
      BreakpointMode.fromMap(obj);

  BreakpointMode({
    required this.appliesTo,
    this.description,
    required this.label,
    required this.mode,
  });

  BreakpointMode.fromMap(Map<String, Object?> obj)
      : appliesTo = (obj['appliesTo'] as List)
            .map((item) => item as BreakpointModeApplicability)
            .toList(),
        description = obj['description'] as String?,
        label = obj['label'] as String,
        mode = obj['mode'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['appliesTo'] is! List ||
        (obj['appliesTo']
            .any((item) => item is! BreakpointModeApplicability)))) {
      return false;
    }
    if (obj['description'] is! String?) {
      return false;
    }
    if (obj['label'] is! String) {
      return false;
    }
    if (obj['mode'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'appliesTo': appliesTo,
        if (description != null) 'description': description,
        'label': label,
        'mode': mode,
      };
}

/// Describes one or more type of breakpoint a `BreakpointMode` applies to. This
/// is a non-exhaustive enumeration and may expand as future breakpoint types
/// are added.
typedef BreakpointModeApplicability = String;

/// Arguments for `cancel` request.
class CancelArguments extends RequestArguments {
  /// The ID (attribute `progressId`) of the progress to cancel. If missing no
  /// progress is cancelled.
  /// Both a `requestId` and a `progressId` can be specified in one request.
  final String? progressId;

  /// The ID (attribute `seq`) of the request to cancel. If missing no request
  /// is cancelled.
  /// Both a `requestId` and a `progressId` can be specified in one request.
  final int? requestId;

  static CancelArguments fromJson(Map<String, Object?> obj) =>
      CancelArguments.fromMap(obj);

  CancelArguments({
    this.progressId,
    this.requestId,
  });

  CancelArguments.fromMap(Map<String, Object?> obj)
      : progressId = obj['progressId'] as String?,
        requestId = obj['requestId'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['progressId'] is! String?) {
      return false;
    }
    if (obj['requestId'] is! int?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (progressId != null) 'progressId': progressId,
        if (requestId != null) 'requestId': requestId,
      };
}

/// Response to `cancel` request. This is just an acknowledgement, so no body
/// field is required.
class CancelResponse extends Response {
  static CancelResponse fromJson(Map<String, Object?> obj) =>
      CancelResponse.fromMap(obj);

  CancelResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  CancelResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Information about the capabilities of a debug adapter.
class Capabilities {
  /// The set of additional module information exposed by the debug adapter.
  final List<ColumnDescriptor>? additionalModuleColumns;

  /// Modes of breakpoints supported by the debug adapter, such as 'hardware' or
  /// 'software'. If present, the client may allow the user to select a mode and
  /// include it in its `setBreakpoints` request.
  ///
  /// Clients may present the first applicable mode in this array as the
  /// 'default' mode in gestures that set breakpoints.
  final List<BreakpointMode>? breakpointModes;

  /// The set of characters that should trigger completion in a REPL. If not
  /// specified, the UI should assume the `.` character.
  final List<String>? completionTriggerCharacters;

  /// Available exception filter options for the `setExceptionBreakpoints`
  /// request.
  final List<ExceptionBreakpointsFilter>? exceptionBreakpointFilters;

  /// The debug adapter supports the `suspendDebuggee` attribute on the
  /// `disconnect` request.
  final bool? supportSuspendDebuggee;

  /// The debug adapter supports the `terminateDebuggee` attribute on the
  /// `disconnect` request.
  final bool? supportTerminateDebuggee;

  /// Checksum algorithms supported by the debug adapter.
  final List<ChecksumAlgorithm>? supportedChecksumAlgorithms;

  /// The debug adapter supports ANSI escape sequences in styling of
  /// `OutputEvent.output` and `Variable.value` fields.
  final bool? supportsANSIStyling;

  /// The debug adapter supports the `breakpointLocations` request.
  final bool? supportsBreakpointLocationsRequest;

  /// The debug adapter supports the `cancel` request.
  final bool? supportsCancelRequest;

  /// The debug adapter supports the `clipboard` context value in the `evaluate`
  /// request.
  final bool? supportsClipboardContext;

  /// The debug adapter supports the `completions` request.
  final bool? supportsCompletionsRequest;

  /// The debug adapter supports conditional breakpoints.
  final bool? supportsConditionalBreakpoints;

  /// The debug adapter supports the `configurationDone` request.
  final bool? supportsConfigurationDoneRequest;

  /// The debug adapter supports the `asAddress` and `bytes` fields in the
  /// `dataBreakpointInfo` request.
  final bool? supportsDataBreakpointBytes;

  /// The debug adapter supports data breakpoints.
  final bool? supportsDataBreakpoints;

  /// The debug adapter supports the delayed loading of parts of the stack,
  /// which requires that both the `startFrame` and `levels` arguments and the
  /// `totalFrames` result of the `stackTrace` request are supported.
  final bool? supportsDelayedStackTraceLoading;

  /// The debug adapter supports the `disassemble` request.
  final bool? supportsDisassembleRequest;

  /// The debug adapter supports a (side effect free) `evaluate` request for
  /// data hovers.
  final bool? supportsEvaluateForHovers;

  /// The debug adapter supports `filterOptions` as an argument on the
  /// `setExceptionBreakpoints` request.
  final bool? supportsExceptionFilterOptions;

  /// The debug adapter supports the `exceptionInfo` request.
  final bool? supportsExceptionInfoRequest;

  /// The debug adapter supports `exceptionOptions` on the
  /// `setExceptionBreakpoints` request.
  final bool? supportsExceptionOptions;

  /// The debug adapter supports function breakpoints.
  final bool? supportsFunctionBreakpoints;

  /// The debug adapter supports the `gotoTargets` request.
  final bool? supportsGotoTargetsRequest;

  /// The debug adapter supports breakpoints that break execution after a
  /// specified number of hits.
  final bool? supportsHitConditionalBreakpoints;

  /// The debug adapter supports adding breakpoints based on instruction
  /// references.
  final bool? supportsInstructionBreakpoints;

  /// The debug adapter supports the `loadedSources` request.
  final bool? supportsLoadedSourcesRequest;

  /// The debug adapter supports log points by interpreting the `logMessage`
  /// attribute of the `SourceBreakpoint`.
  final bool? supportsLogPoints;

  /// The debug adapter supports the `modules` request.
  final bool? supportsModulesRequest;

  /// The debug adapter supports the `readMemory` request.
  final bool? supportsReadMemoryRequest;

  /// The debug adapter supports restarting a frame.
  final bool? supportsRestartFrame;

  /// The debug adapter supports the `restart` request. In this case a client
  /// should not implement `restart` by terminating and relaunching the adapter
  /// but by calling the `restart` request.
  final bool? supportsRestartRequest;

  /// The debug adapter supports the `setExpression` request.
  final bool? supportsSetExpression;

  /// The debug adapter supports setting a variable to a value.
  final bool? supportsSetVariable;

  /// The debug adapter supports the `singleThread` property on the execution
  /// requests (`continue`, `next`, `stepIn`, `stepOut`, `reverseContinue`,
  /// `stepBack`).
  final bool? supportsSingleThreadExecutionRequests;

  /// The debug adapter supports stepping back via the `stepBack` and
  /// `reverseContinue` requests.
  final bool? supportsStepBack;

  /// The debug adapter supports the `stepInTargets` request.
  final bool? supportsStepInTargetsRequest;

  /// The debug adapter supports stepping granularities (argument `granularity`)
  /// for the stepping requests.
  final bool? supportsSteppingGranularity;

  /// The debug adapter supports the `terminate` request.
  final bool? supportsTerminateRequest;

  /// The debug adapter supports the `terminateThreads` request.
  final bool? supportsTerminateThreadsRequest;

  /// The debug adapter supports a `format` attribute on the `stackTrace`,
  /// `variables`, and `evaluate` requests.
  final bool? supportsValueFormattingOptions;

  /// The debug adapter supports the `writeMemory` request.
  final bool? supportsWriteMemoryRequest;

  static Capabilities fromJson(Map<String, Object?> obj) =>
      Capabilities.fromMap(obj);

  Capabilities({
    this.additionalModuleColumns,
    this.breakpointModes,
    this.completionTriggerCharacters,
    this.exceptionBreakpointFilters,
    this.supportSuspendDebuggee,
    this.supportTerminateDebuggee,
    this.supportedChecksumAlgorithms,
    this.supportsANSIStyling,
    this.supportsBreakpointLocationsRequest,
    this.supportsCancelRequest,
    this.supportsClipboardContext,
    this.supportsCompletionsRequest,
    this.supportsConditionalBreakpoints,
    this.supportsConfigurationDoneRequest,
    this.supportsDataBreakpointBytes,
    this.supportsDataBreakpoints,
    this.supportsDelayedStackTraceLoading,
    this.supportsDisassembleRequest,
    this.supportsEvaluateForHovers,
    this.supportsExceptionFilterOptions,
    this.supportsExceptionInfoRequest,
    this.supportsExceptionOptions,
    this.supportsFunctionBreakpoints,
    this.supportsGotoTargetsRequest,
    this.supportsHitConditionalBreakpoints,
    this.supportsInstructionBreakpoints,
    this.supportsLoadedSourcesRequest,
    this.supportsLogPoints,
    this.supportsModulesRequest,
    this.supportsReadMemoryRequest,
    this.supportsRestartFrame,
    this.supportsRestartRequest,
    this.supportsSetExpression,
    this.supportsSetVariable,
    this.supportsSingleThreadExecutionRequests,
    this.supportsStepBack,
    this.supportsStepInTargetsRequest,
    this.supportsSteppingGranularity,
    this.supportsTerminateRequest,
    this.supportsTerminateThreadsRequest,
    this.supportsValueFormattingOptions,
    this.supportsWriteMemoryRequest,
  });

  Capabilities.fromMap(Map<String, Object?> obj)
      : additionalModuleColumns = (obj['additionalModuleColumns'] as List?)
            ?.map((item) =>
                ColumnDescriptor.fromJson(item as Map<String, Object?>))
            .toList(),
        breakpointModes = (obj['breakpointModes'] as List?)
            ?.map(
                (item) => BreakpointMode.fromJson(item as Map<String, Object?>))
            .toList(),
        completionTriggerCharacters =
            (obj['completionTriggerCharacters'] as List?)
                ?.map((item) => item as String)
                .toList(),
        exceptionBreakpointFilters =
            (obj['exceptionBreakpointFilters'] as List?)
                ?.map((item) => ExceptionBreakpointsFilter.fromJson(
                    item as Map<String, Object?>))
                .toList(),
        supportSuspendDebuggee = obj['supportSuspendDebuggee'] as bool?,
        supportTerminateDebuggee = obj['supportTerminateDebuggee'] as bool?,
        supportedChecksumAlgorithms =
            (obj['supportedChecksumAlgorithms'] as List?)
                ?.map((item) => item as ChecksumAlgorithm)
                .toList(),
        supportsANSIStyling = obj['supportsANSIStyling'] as bool?,
        supportsBreakpointLocationsRequest =
            obj['supportsBreakpointLocationsRequest'] as bool?,
        supportsCancelRequest = obj['supportsCancelRequest'] as bool?,
        supportsClipboardContext = obj['supportsClipboardContext'] as bool?,
        supportsCompletionsRequest = obj['supportsCompletionsRequest'] as bool?,
        supportsConditionalBreakpoints =
            obj['supportsConditionalBreakpoints'] as bool?,
        supportsConfigurationDoneRequest =
            obj['supportsConfigurationDoneRequest'] as bool?,
        supportsDataBreakpointBytes =
            obj['supportsDataBreakpointBytes'] as bool?,
        supportsDataBreakpoints = obj['supportsDataBreakpoints'] as bool?,
        supportsDelayedStackTraceLoading =
            obj['supportsDelayedStackTraceLoading'] as bool?,
        supportsDisassembleRequest = obj['supportsDisassembleRequest'] as bool?,
        supportsEvaluateForHovers = obj['supportsEvaluateForHovers'] as bool?,
        supportsExceptionFilterOptions =
            obj['supportsExceptionFilterOptions'] as bool?,
        supportsExceptionInfoRequest =
            obj['supportsExceptionInfoRequest'] as bool?,
        supportsExceptionOptions = obj['supportsExceptionOptions'] as bool?,
        supportsFunctionBreakpoints =
            obj['supportsFunctionBreakpoints'] as bool?,
        supportsGotoTargetsRequest = obj['supportsGotoTargetsRequest'] as bool?,
        supportsHitConditionalBreakpoints =
            obj['supportsHitConditionalBreakpoints'] as bool?,
        supportsInstructionBreakpoints =
            obj['supportsInstructionBreakpoints'] as bool?,
        supportsLoadedSourcesRequest =
            obj['supportsLoadedSourcesRequest'] as bool?,
        supportsLogPoints = obj['supportsLogPoints'] as bool?,
        supportsModulesRequest = obj['supportsModulesRequest'] as bool?,
        supportsReadMemoryRequest = obj['supportsReadMemoryRequest'] as bool?,
        supportsRestartFrame = obj['supportsRestartFrame'] as bool?,
        supportsRestartRequest = obj['supportsRestartRequest'] as bool?,
        supportsSetExpression = obj['supportsSetExpression'] as bool?,
        supportsSetVariable = obj['supportsSetVariable'] as bool?,
        supportsSingleThreadExecutionRequests =
            obj['supportsSingleThreadExecutionRequests'] as bool?,
        supportsStepBack = obj['supportsStepBack'] as bool?,
        supportsStepInTargetsRequest =
            obj['supportsStepInTargetsRequest'] as bool?,
        supportsSteppingGranularity =
            obj['supportsSteppingGranularity'] as bool?,
        supportsTerminateRequest = obj['supportsTerminateRequest'] as bool?,
        supportsTerminateThreadsRequest =
            obj['supportsTerminateThreadsRequest'] as bool?,
        supportsValueFormattingOptions =
            obj['supportsValueFormattingOptions'] as bool?,
        supportsWriteMemoryRequest = obj['supportsWriteMemoryRequest'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['additionalModuleColumns'] is! List ||
        (obj['additionalModuleColumns']
            .any((item) => !ColumnDescriptor.canParse(item))))) {
      return false;
    }
    if ((obj['breakpointModes'] is! List ||
        (obj['breakpointModes']
            .any((item) => !BreakpointMode.canParse(item))))) {
      return false;
    }
    if ((obj['completionTriggerCharacters'] is! List ||
        (obj['completionTriggerCharacters'].any((item) => item is! String)))) {
      return false;
    }
    if ((obj['exceptionBreakpointFilters'] is! List ||
        (obj['exceptionBreakpointFilters']
            .any((item) => !ExceptionBreakpointsFilter.canParse(item))))) {
      return false;
    }
    if (obj['supportSuspendDebuggee'] is! bool?) {
      return false;
    }
    if (obj['supportTerminateDebuggee'] is! bool?) {
      return false;
    }
    if ((obj['supportedChecksumAlgorithms'] is! List ||
        (obj['supportedChecksumAlgorithms']
            .any((item) => item is! ChecksumAlgorithm)))) {
      return false;
    }
    if (obj['supportsANSIStyling'] is! bool?) {
      return false;
    }
    if (obj['supportsBreakpointLocationsRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsCancelRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsClipboardContext'] is! bool?) {
      return false;
    }
    if (obj['supportsCompletionsRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsConditionalBreakpoints'] is! bool?) {
      return false;
    }
    if (obj['supportsConfigurationDoneRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsDataBreakpointBytes'] is! bool?) {
      return false;
    }
    if (obj['supportsDataBreakpoints'] is! bool?) {
      return false;
    }
    if (obj['supportsDelayedStackTraceLoading'] is! bool?) {
      return false;
    }
    if (obj['supportsDisassembleRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsEvaluateForHovers'] is! bool?) {
      return false;
    }
    if (obj['supportsExceptionFilterOptions'] is! bool?) {
      return false;
    }
    if (obj['supportsExceptionInfoRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsExceptionOptions'] is! bool?) {
      return false;
    }
    if (obj['supportsFunctionBreakpoints'] is! bool?) {
      return false;
    }
    if (obj['supportsGotoTargetsRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsHitConditionalBreakpoints'] is! bool?) {
      return false;
    }
    if (obj['supportsInstructionBreakpoints'] is! bool?) {
      return false;
    }
    if (obj['supportsLoadedSourcesRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsLogPoints'] is! bool?) {
      return false;
    }
    if (obj['supportsModulesRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsReadMemoryRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsRestartFrame'] is! bool?) {
      return false;
    }
    if (obj['supportsRestartRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsSetExpression'] is! bool?) {
      return false;
    }
    if (obj['supportsSetVariable'] is! bool?) {
      return false;
    }
    if (obj['supportsSingleThreadExecutionRequests'] is! bool?) {
      return false;
    }
    if (obj['supportsStepBack'] is! bool?) {
      return false;
    }
    if (obj['supportsStepInTargetsRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsSteppingGranularity'] is! bool?) {
      return false;
    }
    if (obj['supportsTerminateRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsTerminateThreadsRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsValueFormattingOptions'] is! bool?) {
      return false;
    }
    if (obj['supportsWriteMemoryRequest'] is! bool?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (additionalModuleColumns != null)
          'additionalModuleColumns': additionalModuleColumns,
        if (breakpointModes != null) 'breakpointModes': breakpointModes,
        if (completionTriggerCharacters != null)
          'completionTriggerCharacters': completionTriggerCharacters,
        if (exceptionBreakpointFilters != null)
          'exceptionBreakpointFilters': exceptionBreakpointFilters,
        if (supportSuspendDebuggee != null)
          'supportSuspendDebuggee': supportSuspendDebuggee,
        if (supportTerminateDebuggee != null)
          'supportTerminateDebuggee': supportTerminateDebuggee,
        if (supportedChecksumAlgorithms != null)
          'supportedChecksumAlgorithms': supportedChecksumAlgorithms,
        if (supportsANSIStyling != null)
          'supportsANSIStyling': supportsANSIStyling,
        if (supportsBreakpointLocationsRequest != null)
          'supportsBreakpointLocationsRequest':
              supportsBreakpointLocationsRequest,
        if (supportsCancelRequest != null)
          'supportsCancelRequest': supportsCancelRequest,
        if (supportsClipboardContext != null)
          'supportsClipboardContext': supportsClipboardContext,
        if (supportsCompletionsRequest != null)
          'supportsCompletionsRequest': supportsCompletionsRequest,
        if (supportsConditionalBreakpoints != null)
          'supportsConditionalBreakpoints': supportsConditionalBreakpoints,
        if (supportsConfigurationDoneRequest != null)
          'supportsConfigurationDoneRequest': supportsConfigurationDoneRequest,
        if (supportsDataBreakpointBytes != null)
          'supportsDataBreakpointBytes': supportsDataBreakpointBytes,
        if (supportsDataBreakpoints != null)
          'supportsDataBreakpoints': supportsDataBreakpoints,
        if (supportsDelayedStackTraceLoading != null)
          'supportsDelayedStackTraceLoading': supportsDelayedStackTraceLoading,
        if (supportsDisassembleRequest != null)
          'supportsDisassembleRequest': supportsDisassembleRequest,
        if (supportsEvaluateForHovers != null)
          'supportsEvaluateForHovers': supportsEvaluateForHovers,
        if (supportsExceptionFilterOptions != null)
          'supportsExceptionFilterOptions': supportsExceptionFilterOptions,
        if (supportsExceptionInfoRequest != null)
          'supportsExceptionInfoRequest': supportsExceptionInfoRequest,
        if (supportsExceptionOptions != null)
          'supportsExceptionOptions': supportsExceptionOptions,
        if (supportsFunctionBreakpoints != null)
          'supportsFunctionBreakpoints': supportsFunctionBreakpoints,
        if (supportsGotoTargetsRequest != null)
          'supportsGotoTargetsRequest': supportsGotoTargetsRequest,
        if (supportsHitConditionalBreakpoints != null)
          'supportsHitConditionalBreakpoints':
              supportsHitConditionalBreakpoints,
        if (supportsInstructionBreakpoints != null)
          'supportsInstructionBreakpoints': supportsInstructionBreakpoints,
        if (supportsLoadedSourcesRequest != null)
          'supportsLoadedSourcesRequest': supportsLoadedSourcesRequest,
        if (supportsLogPoints != null) 'supportsLogPoints': supportsLogPoints,
        if (supportsModulesRequest != null)
          'supportsModulesRequest': supportsModulesRequest,
        if (supportsReadMemoryRequest != null)
          'supportsReadMemoryRequest': supportsReadMemoryRequest,
        if (supportsRestartFrame != null)
          'supportsRestartFrame': supportsRestartFrame,
        if (supportsRestartRequest != null)
          'supportsRestartRequest': supportsRestartRequest,
        if (supportsSetExpression != null)
          'supportsSetExpression': supportsSetExpression,
        if (supportsSetVariable != null)
          'supportsSetVariable': supportsSetVariable,
        if (supportsSingleThreadExecutionRequests != null)
          'supportsSingleThreadExecutionRequests':
              supportsSingleThreadExecutionRequests,
        if (supportsStepBack != null) 'supportsStepBack': supportsStepBack,
        if (supportsStepInTargetsRequest != null)
          'supportsStepInTargetsRequest': supportsStepInTargetsRequest,
        if (supportsSteppingGranularity != null)
          'supportsSteppingGranularity': supportsSteppingGranularity,
        if (supportsTerminateRequest != null)
          'supportsTerminateRequest': supportsTerminateRequest,
        if (supportsTerminateThreadsRequest != null)
          'supportsTerminateThreadsRequest': supportsTerminateThreadsRequest,
        if (supportsValueFormattingOptions != null)
          'supportsValueFormattingOptions': supportsValueFormattingOptions,
        if (supportsWriteMemoryRequest != null)
          'supportsWriteMemoryRequest': supportsWriteMemoryRequest,
      };
}

/// The checksum of an item calculated by the specified algorithm.
class Checksum {
  /// The algorithm used to calculate this checksum.
  final ChecksumAlgorithm algorithm;

  /// Value of the checksum, encoded as a hexadecimal value.
  final String checksum;

  static Checksum fromJson(Map<String, Object?> obj) => Checksum.fromMap(obj);

  Checksum({
    required this.algorithm,
    required this.checksum,
  });

  Checksum.fromMap(Map<String, Object?> obj)
      : algorithm = obj['algorithm'] as ChecksumAlgorithm,
        checksum = obj['checksum'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['algorithm'] is! ChecksumAlgorithm) {
      return false;
    }
    if (obj['checksum'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'algorithm': algorithm,
        'checksum': checksum,
      };
}

/// Names of checksum algorithms that may be supported by a debug adapter.
typedef ChecksumAlgorithm = String;

/// A `ColumnDescriptor` specifies what module attribute to show in a column of
/// the modules view, how to format it,
/// and what the column's label should be.
/// It is only used if the underlying UI actually supports this level of
/// customization.
class ColumnDescriptor {
  /// Name of the attribute rendered in this column.
  final String attributeName;

  /// Format to use for the rendered values in this column. TBD how the format
  /// strings looks like.
  final String? format;

  /// Header UI label of column.
  final String label;

  /// Datatype of values in this column. Defaults to `string` if not specified.
  final String? type;

  /// Width of this column in characters (hint only).
  final int? width;

  static ColumnDescriptor fromJson(Map<String, Object?> obj) =>
      ColumnDescriptor.fromMap(obj);

  ColumnDescriptor({
    required this.attributeName,
    this.format,
    required this.label,
    this.type,
    this.width,
  });

  ColumnDescriptor.fromMap(Map<String, Object?> obj)
      : attributeName = obj['attributeName'] as String,
        format = obj['format'] as String?,
        label = obj['label'] as String,
        type = obj['type'] as String?,
        width = obj['width'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['attributeName'] is! String) {
      return false;
    }
    if (obj['format'] is! String?) {
      return false;
    }
    if (obj['label'] is! String) {
      return false;
    }
    if (obj['type'] is! String?) {
      return false;
    }
    if (obj['width'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'attributeName': attributeName,
        if (format != null) 'format': format,
        'label': label,
        if (type != null) 'type': type,
        if (width != null) 'width': width,
      };
}

/// `CompletionItems` are the suggestions returned from the `completions`
/// request.
class CompletionItem {
  /// A human-readable string with additional information about this item, like
  /// type or symbol information.
  final String? detail;

  /// The label of this completion item. By default this is also the text that
  /// is inserted when selecting this completion.
  final String label;

  /// Length determines how many characters are overwritten by the completion
  /// text and it is measured in UTF-16 code units. If missing the value 0 is
  /// assumed which results in the completion text being inserted.
  final int? length;

  /// Determines the length of the new selection after the text has been
  /// inserted (or replaced) and it is measured in UTF-16 code units. The
  /// selection can not extend beyond the bounds of the completion text. If
  /// omitted the length is assumed to be 0.
  final int? selectionLength;

  /// Determines the start of the new selection after the text has been inserted
  /// (or replaced). `selectionStart` is measured in UTF-16 code units and must
  /// be in the range 0 and length of the completion text. If omitted the
  /// selection starts at the end of the completion text.
  final int? selectionStart;

  /// A string that should be used when comparing this item with other items. If
  /// not returned or an empty string, the `label` is used instead.
  final String? sortText;

  /// Start position (within the `text` attribute of the `completions` request)
  /// where the completion text is added. The position is measured in UTF-16
  /// code units and the client capability `columnsStartAt1` determines whether
  /// it is 0- or 1-based. If the start position is omitted the text is added at
  /// the location specified by the `column` attribute of the `completions`
  /// request.
  final int? start;

  /// If text is returned and not an empty string, then it is inserted instead
  /// of the label.
  final String? text;

  /// The item's type. Typically the client uses this information to render the
  /// item in the UI with an icon.
  final CompletionItemType? type;

  static CompletionItem fromJson(Map<String, Object?> obj) =>
      CompletionItem.fromMap(obj);

  CompletionItem({
    this.detail,
    required this.label,
    this.length,
    this.selectionLength,
    this.selectionStart,
    this.sortText,
    this.start,
    this.text,
    this.type,
  });

  CompletionItem.fromMap(Map<String, Object?> obj)
      : detail = obj['detail'] as String?,
        label = obj['label'] as String,
        length = obj['length'] as int?,
        selectionLength = obj['selectionLength'] as int?,
        selectionStart = obj['selectionStart'] as int?,
        sortText = obj['sortText'] as String?,
        start = obj['start'] as int?,
        text = obj['text'] as String?,
        type = obj['type'] as CompletionItemType?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['detail'] is! String?) {
      return false;
    }
    if (obj['label'] is! String) {
      return false;
    }
    if (obj['length'] is! int?) {
      return false;
    }
    if (obj['selectionLength'] is! int?) {
      return false;
    }
    if (obj['selectionStart'] is! int?) {
      return false;
    }
    if (obj['sortText'] is! String?) {
      return false;
    }
    if (obj['start'] is! int?) {
      return false;
    }
    if (obj['text'] is! String?) {
      return false;
    }
    if (obj['type'] is! CompletionItemType?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (detail != null) 'detail': detail,
        'label': label,
        if (length != null) 'length': length,
        if (selectionLength != null) 'selectionLength': selectionLength,
        if (selectionStart != null) 'selectionStart': selectionStart,
        if (sortText != null) 'sortText': sortText,
        if (start != null) 'start': start,
        if (text != null) 'text': text,
        if (type != null) 'type': type,
      };
}

/// Some predefined types for the CompletionItem. Please note that not all
/// clients have specific icons for all of them.
typedef CompletionItemType = String;

/// Arguments for `completions` request.
class CompletionsArguments extends RequestArguments {
  /// The position within `text` for which to determine the completion
  /// proposals. It is measured in UTF-16 code units and the client capability
  /// `columnsStartAt1` determines whether it is 0- or 1-based.
  final int column;

  /// Returns completions in the scope of this stack frame. If not specified,
  /// the completions are returned for the global scope.
  final int? frameId;

  /// A line for which to determine the completion proposals. If missing the
  /// first line of the text is assumed.
  final int? line;

  /// One or more source lines. Typically this is the text users have typed into
  /// the debug console before they asked for completion.
  final String text;

  static CompletionsArguments fromJson(Map<String, Object?> obj) =>
      CompletionsArguments.fromMap(obj);

  CompletionsArguments({
    required this.column,
    this.frameId,
    this.line,
    required this.text,
  });

  CompletionsArguments.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int,
        frameId = obj['frameId'] as int?,
        line = obj['line'] as int?,
        text = obj['text'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int) {
      return false;
    }
    if (obj['frameId'] is! int?) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    if (obj['text'] is! String) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'column': column,
        if (frameId != null) 'frameId': frameId,
        if (line != null) 'line': line,
        'text': text,
      };
}

/// Response to `completions` request.
class CompletionsResponse extends Response {
  static CompletionsResponse fromJson(Map<String, Object?> obj) =>
      CompletionsResponse.fromMap(obj);

  CompletionsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  CompletionsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `configurationDone` request.
class ConfigurationDoneArguments extends RequestArguments {
  static ConfigurationDoneArguments fromJson(Map<String, Object?> obj) =>
      ConfigurationDoneArguments.fromMap(obj);

  ConfigurationDoneArguments();

  ConfigurationDoneArguments.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {};
}

/// Response to `configurationDone` request. This is just an acknowledgement, so
/// no body field is required.
class ConfigurationDoneResponse extends Response {
  static ConfigurationDoneResponse fromJson(Map<String, Object?> obj) =>
      ConfigurationDoneResponse.fromMap(obj);

  ConfigurationDoneResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ConfigurationDoneResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `continue` request.
class ContinueArguments extends RequestArguments {
  /// If this flag is true, execution is resumed only for the thread with given
  /// `threadId`.
  final bool? singleThread;

  /// Specifies the active thread. If the debug adapter supports single thread
  /// execution (see `supportsSingleThreadExecutionRequests`) and the argument
  /// `singleThread` is true, only the thread with this ID is resumed.
  final int threadId;

  static ContinueArguments fromJson(Map<String, Object?> obj) =>
      ContinueArguments.fromMap(obj);

  ContinueArguments({
    this.singleThread,
    required this.threadId,
  });

  ContinueArguments.fromMap(Map<String, Object?> obj)
      : singleThread = obj['singleThread'] as bool?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['singleThread'] is! bool?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (singleThread != null) 'singleThread': singleThread,
        'threadId': threadId,
      };
}

/// Response to `continue` request.
class ContinueResponse extends Response {
  static ContinueResponse fromJson(Map<String, Object?> obj) =>
      ContinueResponse.fromMap(obj);

  ContinueResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ContinueResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Properties of a data breakpoint passed to the `setDataBreakpoints` request.
class DataBreakpoint {
  /// The access type of the data.
  final DataBreakpointAccessType? accessType;

  /// An expression for conditional breakpoints.
  final String? condition;

  /// An id representing the data. This id is returned from the
  /// `dataBreakpointInfo` request.
  final String dataId;

  /// An expression that controls how many hits of the breakpoint are ignored.
  /// The debug adapter is expected to interpret the expression as needed.
  final String? hitCondition;

  static DataBreakpoint fromJson(Map<String, Object?> obj) =>
      DataBreakpoint.fromMap(obj);

  DataBreakpoint({
    this.accessType,
    this.condition,
    required this.dataId,
    this.hitCondition,
  });

  DataBreakpoint.fromMap(Map<String, Object?> obj)
      : accessType = obj['accessType'] as DataBreakpointAccessType?,
        condition = obj['condition'] as String?,
        dataId = obj['dataId'] as String,
        hitCondition = obj['hitCondition'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['accessType'] is! DataBreakpointAccessType?) {
      return false;
    }
    if (obj['condition'] is! String?) {
      return false;
    }
    if (obj['dataId'] is! String) {
      return false;
    }
    if (obj['hitCondition'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (accessType != null) 'accessType': accessType,
        if (condition != null) 'condition': condition,
        'dataId': dataId,
        if (hitCondition != null) 'hitCondition': hitCondition,
      };
}

/// This enumeration defines all possible access types for data breakpoints.
typedef DataBreakpointAccessType = String;

/// Arguments for `dataBreakpointInfo` request.
class DataBreakpointInfoArguments extends RequestArguments {
  /// If `true`, the `name` is a memory address and the debugger should
  /// interpret it as a decimal value, or hex value if it is prefixed with `0x`.
  ///
  /// Clients may set this property only if the `supportsDataBreakpointBytes`
  /// capability is true.
  final bool? asAddress;

  /// If specified, a debug adapter should return information for the range of
  /// memory extending `bytes` number of bytes from the address or variable
  /// specified by `name`. Breakpoints set using the resulting data ID should
  /// pause on data access anywhere within that range.
  ///
  /// Clients may set this property only if the `supportsDataBreakpointBytes`
  /// capability is true.
  final int? bytes;

  /// When `name` is an expression, evaluate it in the scope of this stack
  /// frame. If not specified, the expression is evaluated in the global scope.
  /// When `variablesReference` is specified, this property has no effect.
  final int? frameId;

  /// The mode of the desired breakpoint. If defined, this must be one of the
  /// `breakpointModes` the debug adapter advertised in its `Capabilities`.
  final String? mode;

  /// The name of the variable's child to obtain data breakpoint information
  /// for.
  /// If `variablesReference` isn't specified, this can be an expression, or an
  /// address if `asAddress` is also true.
  final String name;

  /// Reference to the variable container if the data breakpoint is requested
  /// for a child of the container. The `variablesReference` must have been
  /// obtained in the current suspended state. See 'Lifetime of Object
  /// References' in the Overview section for details.
  final int? variablesReference;

  static DataBreakpointInfoArguments fromJson(Map<String, Object?> obj) =>
      DataBreakpointInfoArguments.fromMap(obj);

  DataBreakpointInfoArguments({
    this.asAddress,
    this.bytes,
    this.frameId,
    this.mode,
    required this.name,
    this.variablesReference,
  });

  DataBreakpointInfoArguments.fromMap(Map<String, Object?> obj)
      : asAddress = obj['asAddress'] as bool?,
        bytes = obj['bytes'] as int?,
        frameId = obj['frameId'] as int?,
        mode = obj['mode'] as String?,
        name = obj['name'] as String,
        variablesReference = obj['variablesReference'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['asAddress'] is! bool?) {
      return false;
    }
    if (obj['bytes'] is! int?) {
      return false;
    }
    if (obj['frameId'] is! int?) {
      return false;
    }
    if (obj['mode'] is! String?) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['variablesReference'] is! int?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (asAddress != null) 'asAddress': asAddress,
        if (bytes != null) 'bytes': bytes,
        if (frameId != null) 'frameId': frameId,
        if (mode != null) 'mode': mode,
        'name': name,
        if (variablesReference != null)
          'variablesReference': variablesReference,
      };
}

/// Response to `dataBreakpointInfo` request.
class DataBreakpointInfoResponse extends Response {
  static DataBreakpointInfoResponse fromJson(Map<String, Object?> obj) =>
      DataBreakpointInfoResponse.fromMap(obj);

  DataBreakpointInfoResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  DataBreakpointInfoResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `disassemble` request.
class DisassembleArguments extends RequestArguments {
  /// Number of instructions to disassemble starting at the specified location
  /// and offset.
  /// An adapter must return exactly this number of instructions - any
  /// unavailable instructions should be replaced with an implementation-defined
  /// 'invalid instruction' value.
  final int instructionCount;

  /// Offset (in instructions) to be applied after the byte offset (if any)
  /// before disassembling. Can be negative.
  final int? instructionOffset;

  /// Memory reference to the base location containing the instructions to
  /// disassemble.
  final String memoryReference;

  /// Offset (in bytes) to be applied to the reference location before
  /// disassembling. Can be negative.
  final int? offset;

  /// If true, the adapter should attempt to resolve memory addresses and other
  /// values to symbolic names.
  final bool? resolveSymbols;

  static DisassembleArguments fromJson(Map<String, Object?> obj) =>
      DisassembleArguments.fromMap(obj);

  DisassembleArguments({
    required this.instructionCount,
    this.instructionOffset,
    required this.memoryReference,
    this.offset,
    this.resolveSymbols,
  });

  DisassembleArguments.fromMap(Map<String, Object?> obj)
      : instructionCount = obj['instructionCount'] as int,
        instructionOffset = obj['instructionOffset'] as int?,
        memoryReference = obj['memoryReference'] as String,
        offset = obj['offset'] as int?,
        resolveSymbols = obj['resolveSymbols'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['instructionCount'] is! int) {
      return false;
    }
    if (obj['instructionOffset'] is! int?) {
      return false;
    }
    if (obj['memoryReference'] is! String) {
      return false;
    }
    if (obj['offset'] is! int?) {
      return false;
    }
    if (obj['resolveSymbols'] is! bool?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'instructionCount': instructionCount,
        if (instructionOffset != null) 'instructionOffset': instructionOffset,
        'memoryReference': memoryReference,
        if (offset != null) 'offset': offset,
        if (resolveSymbols != null) 'resolveSymbols': resolveSymbols,
      };
}

/// Response to `disassemble` request.
class DisassembleResponse extends Response {
  static DisassembleResponse fromJson(Map<String, Object?> obj) =>
      DisassembleResponse.fromMap(obj);

  DisassembleResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  DisassembleResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>?) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Represents a single disassembled instruction.
class DisassembledInstruction {
  /// The address of the instruction. Treated as a hex value if prefixed with
  /// `0x`, or as a decimal value otherwise.
  final String address;

  /// The column within the line that corresponds to this instruction, if any.
  final int? column;

  /// The end column of the range that corresponds to this instruction, if any.
  final int? endColumn;

  /// The end line of the range that corresponds to this instruction, if any.
  final int? endLine;

  /// Text representing the instruction and its operands, in an
  /// implementation-defined format.
  final String instruction;

  /// Raw bytes representing the instruction and its operands, in an
  /// implementation-defined format.
  final String? instructionBytes;

  /// The line within the source location that corresponds to this instruction,
  /// if any.
  final int? line;

  /// Source location that corresponds to this instruction, if any.
  /// Should always be set (if available) on the first instruction returned,
  /// but can be omitted afterwards if this instruction maps to the same source
  /// file as the previous instruction.
  final Source? location;

  /// A hint for how to present the instruction in the UI.
  ///
  /// A value of `invalid` may be used to indicate this instruction is 'filler'
  /// and cannot be reached by the program. For example, unreadable memory
  /// addresses may be presented is 'invalid.'
  final String? presentationHint;

  /// Name of the symbol that corresponds with the location of this instruction,
  /// if any.
  final String? symbol;

  static DisassembledInstruction fromJson(Map<String, Object?> obj) =>
      DisassembledInstruction.fromMap(obj);

  DisassembledInstruction({
    required this.address,
    this.column,
    this.endColumn,
    this.endLine,
    required this.instruction,
    this.instructionBytes,
    this.line,
    this.location,
    this.presentationHint,
    this.symbol,
  });

  DisassembledInstruction.fromMap(Map<String, Object?> obj)
      : address = obj['address'] as String,
        column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        instruction = obj['instruction'] as String,
        instructionBytes = obj['instructionBytes'] as String?,
        line = obj['line'] as int?,
        location = obj['location'] == null
            ? null
            : Source.fromJson(obj['location'] as Map<String, Object?>),
        presentationHint = obj['presentationHint'] as String?,
        symbol = obj['symbol'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['address'] is! String) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['instruction'] is! String) {
      return false;
    }
    if (obj['instructionBytes'] is! String?) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    if (!Source.canParse(obj['location'])) {
      return false;
    }
    if (obj['presentationHint'] is! String?) {
      return false;
    }
    if (obj['symbol'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'address': address,
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'instruction': instruction,
        if (instructionBytes != null) 'instructionBytes': instructionBytes,
        if (line != null) 'line': line,
        if (location != null) 'location': location,
        if (presentationHint != null) 'presentationHint': presentationHint,
        if (symbol != null) 'symbol': symbol,
      };
}

/// Arguments for `disconnect` request.
class DisconnectArguments extends RequestArguments {
  /// A value of true indicates that this `disconnect` request is part of a
  /// restart sequence.
  final bool? restart;

  /// Indicates whether the debuggee should stay suspended when the debugger is
  /// disconnected.
  /// If unspecified, the debuggee should resume execution.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportSuspendDebuggee` is true.
  final bool? suspendDebuggee;

  /// Indicates whether the debuggee should be terminated when the debugger is
  /// disconnected.
  /// If unspecified, the debug adapter is free to do whatever it thinks is
  /// best.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportTerminateDebuggee` is true.
  final bool? terminateDebuggee;

  static DisconnectArguments fromJson(Map<String, Object?> obj) =>
      DisconnectArguments.fromMap(obj);

  DisconnectArguments({
    this.restart,
    this.suspendDebuggee,
    this.terminateDebuggee,
  });

  DisconnectArguments.fromMap(Map<String, Object?> obj)
      : restart = obj['restart'] as bool?,
        suspendDebuggee = obj['suspendDebuggee'] as bool?,
        terminateDebuggee = obj['terminateDebuggee'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['restart'] is! bool?) {
      return false;
    }
    if (obj['suspendDebuggee'] is! bool?) {
      return false;
    }
    if (obj['terminateDebuggee'] is! bool?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (restart != null) 'restart': restart,
        if (suspendDebuggee != null) 'suspendDebuggee': suspendDebuggee,
        if (terminateDebuggee != null) 'terminateDebuggee': terminateDebuggee,
      };
}

/// Response to `disconnect` request. This is just an acknowledgement, so no
/// body field is required.
class DisconnectResponse extends Response {
  static DisconnectResponse fromJson(Map<String, Object?> obj) =>
      DisconnectResponse.fromMap(obj);

  DisconnectResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  DisconnectResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// On error (whenever `success` is false), the body can provide more details.
class ErrorResponse extends Response {
  static ErrorResponse fromJson(Map<String, Object?> obj) =>
      ErrorResponse.fromMap(obj);

  ErrorResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ErrorResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `evaluate` request.
class EvaluateArguments extends RequestArguments {
  /// The contextual column where the expression should be evaluated. This may
  /// be provided if `line` is also provided.
  ///
  /// It is measured in UTF-16 code units and the client capability
  /// `columnsStartAt1` determines whether it is 0- or 1-based.
  final int? column;

  /// The context in which the evaluate request is used.
  final String? context;

  /// The expression to evaluate.
  final String expression;

  /// Specifies details on how to format the result.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsValueFormattingOptions` is true.
  final ValueFormat? format;

  /// Evaluate the expression in the scope of this stack frame. If not
  /// specified, the expression is evaluated in the global scope.
  final int? frameId;

  /// The contextual line where the expression should be evaluated. In the
  /// 'hover' context, this should be set to the start of the expression being
  /// hovered.
  final int? line;

  /// The contextual source in which the `line` is found. This must be provided
  /// if `line` is provided.
  final Source? source;

  static EvaluateArguments fromJson(Map<String, Object?> obj) =>
      EvaluateArguments.fromMap(obj);

  EvaluateArguments({
    this.column,
    this.context,
    required this.expression,
    this.format,
    this.frameId,
    this.line,
    this.source,
  });

  EvaluateArguments.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        context = obj['context'] as String?,
        expression = obj['expression'] as String,
        format = obj['format'] == null
            ? null
            : ValueFormat.fromJson(obj['format'] as Map<String, Object?>),
        frameId = obj['frameId'] as int?,
        line = obj['line'] as int?,
        source = obj['source'] == null
            ? null
            : Source.fromJson(obj['source'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['context'] is! String?) {
      return false;
    }
    if (obj['expression'] is! String) {
      return false;
    }
    if (!ValueFormat.canParse(obj['format'])) {
      return false;
    }
    if (obj['frameId'] is! int?) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (context != null) 'context': context,
        'expression': expression,
        if (format != null) 'format': format,
        if (frameId != null) 'frameId': frameId,
        if (line != null) 'line': line,
        if (source != null) 'source': source,
      };
}

/// Response to `evaluate` request.
class EvaluateResponse extends Response {
  static EvaluateResponse fromJson(Map<String, Object?> obj) =>
      EvaluateResponse.fromMap(obj);

  EvaluateResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  EvaluateResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A debug adapter initiated event.
class Event extends ProtocolMessage {
  /// Event-specific information.
  final Object? body;

  /// Type of event.
  final String event;

  static Event fromJson(Map<String, Object?> obj) => Event.fromMap(obj);

  Event({
    this.body,
    required this.event,
    required super.seq,
  }) : super(
          type: 'event',
        );

  Event.fromMap(super.obj)
      : body = obj['body'],
        event = obj['event'] as String,
        super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['event'] is! String) {
      return false;
    }
    if (obj['type'] is! String) {
      return false;
    }
    return ProtocolMessage.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        if (body != null) 'body': body,
        'event': event,
      };
}

/// This enumeration defines all possible conditions when a thrown exception
/// should result in a break.
/// never: never breaks,
/// always: always breaks,
/// unhandled: breaks when exception unhandled,
/// userUnhandled: breaks if the exception is not handled by user code.
typedef ExceptionBreakMode = String;

/// An `ExceptionBreakpointsFilter` is shown in the UI as an filter option for
/// configuring how exceptions are dealt with.
class ExceptionBreakpointsFilter {
  /// A help text providing information about the condition. This string is
  /// shown as the placeholder text for a text box and can be translated.
  final String? conditionDescription;

  /// Initial value of the filter option. If not specified a value false is
  /// assumed.
  final bool? defaultValue;

  /// A help text providing additional information about the exception filter.
  /// This string is typically shown as a hover and can be translated.
  final String? description;

  /// The internal ID of the filter option. This value is passed to the
  /// `setExceptionBreakpoints` request.
  final String filter;

  /// The name of the filter option. This is shown in the UI.
  final String label;

  /// Controls whether a condition can be specified for this filter option. If
  /// false or missing, a condition can not be set.
  final bool? supportsCondition;

  static ExceptionBreakpointsFilter fromJson(Map<String, Object?> obj) =>
      ExceptionBreakpointsFilter.fromMap(obj);

  ExceptionBreakpointsFilter({
    this.conditionDescription,
    this.defaultValue,
    this.description,
    required this.filter,
    required this.label,
    this.supportsCondition,
  });

  ExceptionBreakpointsFilter.fromMap(Map<String, Object?> obj)
      : conditionDescription = obj['conditionDescription'] as String?,
        defaultValue = obj['default'] as bool?,
        description = obj['description'] as String?,
        filter = obj['filter'] as String,
        label = obj['label'] as String,
        supportsCondition = obj['supportsCondition'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['conditionDescription'] is! String?) {
      return false;
    }
    if (obj['default'] is! bool?) {
      return false;
    }
    if (obj['description'] is! String?) {
      return false;
    }
    if (obj['filter'] is! String) {
      return false;
    }
    if (obj['label'] is! String) {
      return false;
    }
    if (obj['supportsCondition'] is! bool?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (conditionDescription != null)
          'conditionDescription': conditionDescription,
        if (defaultValue != null) 'default': defaultValue,
        if (description != null) 'description': description,
        'filter': filter,
        'label': label,
        if (supportsCondition != null) 'supportsCondition': supportsCondition,
      };
}

/// Detailed information about an exception that has occurred.
class ExceptionDetails {
  /// An expression that can be evaluated in the current scope to obtain the
  /// exception object.
  final String? evaluateName;

  /// Fully-qualified type name of the exception object.
  final String? fullTypeName;

  /// Details of the exception contained by this exception, if any.
  final List<ExceptionDetails>? innerException;

  /// Message contained in the exception.
  final String? message;

  /// Stack trace at the time the exception was thrown.
  final String? stackTrace;

  /// Short type name of the exception object.
  final String? typeName;

  static ExceptionDetails fromJson(Map<String, Object?> obj) =>
      ExceptionDetails.fromMap(obj);

  ExceptionDetails({
    this.evaluateName,
    this.fullTypeName,
    this.innerException,
    this.message,
    this.stackTrace,
    this.typeName,
  });

  ExceptionDetails.fromMap(Map<String, Object?> obj)
      : evaluateName = obj['evaluateName'] as String?,
        fullTypeName = obj['fullTypeName'] as String?,
        innerException = (obj['innerException'] as List?)
            ?.map((item) =>
                ExceptionDetails.fromJson(item as Map<String, Object?>))
            .toList(),
        message = obj['message'] as String?,
        stackTrace = obj['stackTrace'] as String?,
        typeName = obj['typeName'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['evaluateName'] is! String?) {
      return false;
    }
    if (obj['fullTypeName'] is! String?) {
      return false;
    }
    if ((obj['innerException'] is! List ||
        (obj['innerException']
            .any((item) => !ExceptionDetails.canParse(item))))) {
      return false;
    }
    if (obj['message'] is! String?) {
      return false;
    }
    if (obj['stackTrace'] is! String?) {
      return false;
    }
    if (obj['typeName'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (evaluateName != null) 'evaluateName': evaluateName,
        if (fullTypeName != null) 'fullTypeName': fullTypeName,
        if (innerException != null) 'innerException': innerException,
        if (message != null) 'message': message,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (typeName != null) 'typeName': typeName,
      };
}

/// An `ExceptionFilterOptions` is used to specify an exception filter together
/// with a condition for the `setExceptionBreakpoints` request.
class ExceptionFilterOptions {
  /// An expression for conditional exceptions.
  /// The exception breaks into the debugger if the result of the condition is
  /// true.
  final String? condition;

  /// ID of an exception filter returned by the `exceptionBreakpointFilters`
  /// capability.
  final String filterId;

  /// The mode of this exception breakpoint. If defined, this must be one of the
  /// `breakpointModes` the debug adapter advertised in its `Capabilities`.
  final String? mode;

  static ExceptionFilterOptions fromJson(Map<String, Object?> obj) =>
      ExceptionFilterOptions.fromMap(obj);

  ExceptionFilterOptions({
    this.condition,
    required this.filterId,
    this.mode,
  });

  ExceptionFilterOptions.fromMap(Map<String, Object?> obj)
      : condition = obj['condition'] as String?,
        filterId = obj['filterId'] as String,
        mode = obj['mode'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['condition'] is! String?) {
      return false;
    }
    if (obj['filterId'] is! String) {
      return false;
    }
    if (obj['mode'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (condition != null) 'condition': condition,
        'filterId': filterId,
        if (mode != null) 'mode': mode,
      };
}

/// Arguments for `exceptionInfo` request.
class ExceptionInfoArguments extends RequestArguments {
  /// Thread for which exception information should be retrieved.
  final int threadId;

  static ExceptionInfoArguments fromJson(Map<String, Object?> obj) =>
      ExceptionInfoArguments.fromMap(obj);

  ExceptionInfoArguments({
    required this.threadId,
  });

  ExceptionInfoArguments.fromMap(Map<String, Object?> obj)
      : threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'threadId': threadId,
      };
}

/// Response to `exceptionInfo` request.
class ExceptionInfoResponse extends Response {
  static ExceptionInfoResponse fromJson(Map<String, Object?> obj) =>
      ExceptionInfoResponse.fromMap(obj);

  ExceptionInfoResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ExceptionInfoResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// An `ExceptionOptions` assigns configuration options to a set of exceptions.
class ExceptionOptions {
  /// Condition when a thrown exception should result in a break.
  final ExceptionBreakMode breakMode;

  /// A path that selects a single or multiple exceptions in a tree. If `path`
  /// is missing, the whole tree is selected.
  /// By convention the first segment of the path is a category that is used to
  /// group exceptions in the UI.
  final List<ExceptionPathSegment>? path;

  static ExceptionOptions fromJson(Map<String, Object?> obj) =>
      ExceptionOptions.fromMap(obj);

  ExceptionOptions({
    required this.breakMode,
    this.path,
  });

  ExceptionOptions.fromMap(Map<String, Object?> obj)
      : breakMode = obj['breakMode'] as ExceptionBreakMode,
        path = (obj['path'] as List?)
            ?.map((item) =>
                ExceptionPathSegment.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['breakMode'] is! ExceptionBreakMode) {
      return false;
    }
    if ((obj['path'] is! List ||
        (obj['path'].any((item) => !ExceptionPathSegment.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakMode': breakMode,
        if (path != null) 'path': path,
      };
}

/// An `ExceptionPathSegment` represents a segment in a path that is used to
/// match leafs or nodes in a tree of exceptions.
/// If a segment consists of more than one name, it matches the names provided
/// if `negate` is false or missing, or it matches anything except the names
/// provided if `negate` is true.
class ExceptionPathSegment {
  /// Depending on the value of `negate` the names that should match or not
  /// match.
  final List<String> names;

  /// If false or missing this segment matches the names provided, otherwise it
  /// matches anything except the names provided.
  final bool? negate;

  static ExceptionPathSegment fromJson(Map<String, Object?> obj) =>
      ExceptionPathSegment.fromMap(obj);

  ExceptionPathSegment({
    required this.names,
    this.negate,
  });

  ExceptionPathSegment.fromMap(Map<String, Object?> obj)
      : names = (obj['names'] as List).map((item) => item as String).toList(),
        negate = obj['negate'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['names'] is! List ||
        (obj['names'].any((item) => item is! String)))) {
      return false;
    }
    if (obj['negate'] is! bool?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'names': names,
        if (negate != null) 'negate': negate,
      };
}

/// Properties of a breakpoint passed to the `setFunctionBreakpoints` request.
class FunctionBreakpoint {
  /// An expression for conditional breakpoints.
  /// It is only honored by a debug adapter if the corresponding capability
  /// `supportsConditionalBreakpoints` is true.
  final String? condition;

  /// An expression that controls how many hits of the breakpoint are ignored.
  /// The debug adapter is expected to interpret the expression as needed.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsHitConditionalBreakpoints` is true.
  final String? hitCondition;

  /// The name of the function.
  final String name;

  static FunctionBreakpoint fromJson(Map<String, Object?> obj) =>
      FunctionBreakpoint.fromMap(obj);

  FunctionBreakpoint({
    this.condition,
    this.hitCondition,
    required this.name,
  });

  FunctionBreakpoint.fromMap(Map<String, Object?> obj)
      : condition = obj['condition'] as String?,
        hitCondition = obj['hitCondition'] as String?,
        name = obj['name'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['condition'] is! String?) {
      return false;
    }
    if (obj['hitCondition'] is! String?) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (condition != null) 'condition': condition,
        if (hitCondition != null) 'hitCondition': hitCondition,
        'name': name,
      };
}

/// Arguments for `goto` request.
class GotoArguments extends RequestArguments {
  /// The location where the debuggee will continue to run.
  final int targetId;

  /// Set the goto target for this thread.
  final int threadId;

  static GotoArguments fromJson(Map<String, Object?> obj) =>
      GotoArguments.fromMap(obj);

  GotoArguments({
    required this.targetId,
    required this.threadId,
  });

  GotoArguments.fromMap(Map<String, Object?> obj)
      : targetId = obj['targetId'] as int,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['targetId'] is! int) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'targetId': targetId,
        'threadId': threadId,
      };
}

/// Response to `goto` request. This is just an acknowledgement, so no body
/// field is required.
class GotoResponse extends Response {
  static GotoResponse fromJson(Map<String, Object?> obj) =>
      GotoResponse.fromMap(obj);

  GotoResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  GotoResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A `GotoTarget` describes a code location that can be used as a target in the
/// `goto` request.
/// The possible goto targets can be determined via the `gotoTargets` request.
class GotoTarget {
  /// The column of the goto target.
  final int? column;

  /// The end column of the range covered by the goto target.
  final int? endColumn;

  /// The end line of the range covered by the goto target.
  final int? endLine;

  /// Unique identifier for a goto target. This is used in the `goto` request.
  final int id;

  /// A memory reference for the instruction pointer value represented by this
  /// target.
  final String? instructionPointerReference;

  /// The name of the goto target (shown in the UI).
  final String label;

  /// The line of the goto target.
  final int line;

  static GotoTarget fromJson(Map<String, Object?> obj) =>
      GotoTarget.fromMap(obj);

  GotoTarget({
    this.column,
    this.endColumn,
    this.endLine,
    required this.id,
    this.instructionPointerReference,
    required this.label,
    required this.line,
  });

  GotoTarget.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        id = obj['id'] as int,
        instructionPointerReference =
            obj['instructionPointerReference'] as String?,
        label = obj['label'] as String,
        line = obj['line'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['id'] is! int) {
      return false;
    }
    if (obj['instructionPointerReference'] is! String?) {
      return false;
    }
    if (obj['label'] is! String) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'id': id,
        if (instructionPointerReference != null)
          'instructionPointerReference': instructionPointerReference,
        'label': label,
        'line': line,
      };
}

/// Arguments for `gotoTargets` request.
class GotoTargetsArguments extends RequestArguments {
  /// The position within `line` for which the goto targets are determined. It
  /// is measured in UTF-16 code units and the client capability
  /// `columnsStartAt1` determines whether it is 0- or 1-based.
  final int? column;

  /// The line location for which the goto targets are determined.
  final int line;

  /// The source location for which the goto targets are determined.
  final Source source;

  static GotoTargetsArguments fromJson(Map<String, Object?> obj) =>
      GotoTargetsArguments.fromMap(obj);

  GotoTargetsArguments({
    this.column,
    required this.line,
    required this.source,
  });

  GotoTargetsArguments.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        line = obj['line'] as int,
        source = Source.fromJson(obj['source'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        'line': line,
        'source': source,
      };
}

/// Response to `gotoTargets` request.
class GotoTargetsResponse extends Response {
  static GotoTargetsResponse fromJson(Map<String, Object?> obj) =>
      GotoTargetsResponse.fromMap(obj);

  GotoTargetsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  GotoTargetsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `initialize` request.
class InitializeRequestArguments extends RequestArguments {
  /// The ID of the debug adapter.
  final String adapterID;

  /// The ID of the client using this adapter.
  final String? clientID;

  /// The human-readable name of the client using this adapter.
  final String? clientName;

  /// If true all column numbers are 1-based (default).
  final bool? columnsStartAt1;

  /// If true all line numbers are 1-based (default).
  final bool? linesStartAt1;

  /// The ISO-639 locale of the client using this adapter, e.g. en-US or de-CH.
  final String? locale;

  /// Determines in what format paths are specified. The default is `path`,
  /// which is the native format.
  final String? pathFormat;

  /// The client will interpret ANSI escape sequences in the display of
  /// `OutputEvent.output` and `Variable.value` fields when
  /// `Capabilities.supportsANSIStyling` is also enabled.
  final bool? supportsANSIStyling;

  /// Client supports the `argsCanBeInterpretedByShell` attribute on the
  /// `runInTerminal` request.
  final bool? supportsArgsCanBeInterpretedByShell;

  /// Client supports the `invalidated` event.
  final bool? supportsInvalidatedEvent;

  /// Client supports the `memory` event.
  final bool? supportsMemoryEvent;

  /// Client supports memory references.
  final bool? supportsMemoryReferences;

  /// Client supports progress reporting.
  final bool? supportsProgressReporting;

  /// Client supports the `runInTerminal` request.
  final bool? supportsRunInTerminalRequest;

  /// Client supports the `startDebugging` request.
  final bool? supportsStartDebuggingRequest;

  /// Client supports the paging of variables.
  final bool? supportsVariablePaging;

  /// Client supports the `type` attribute for variables.
  final bool? supportsVariableType;

  static InitializeRequestArguments fromJson(Map<String, Object?> obj) =>
      InitializeRequestArguments.fromMap(obj);

  InitializeRequestArguments({
    required this.adapterID,
    this.clientID,
    this.clientName,
    this.columnsStartAt1,
    this.linesStartAt1,
    this.locale,
    this.pathFormat,
    this.supportsANSIStyling,
    this.supportsArgsCanBeInterpretedByShell,
    this.supportsInvalidatedEvent,
    this.supportsMemoryEvent,
    this.supportsMemoryReferences,
    this.supportsProgressReporting,
    this.supportsRunInTerminalRequest,
    this.supportsStartDebuggingRequest,
    this.supportsVariablePaging,
    this.supportsVariableType,
  });

  InitializeRequestArguments.fromMap(Map<String, Object?> obj)
      : adapterID = obj['adapterID'] as String,
        clientID = obj['clientID'] as String?,
        clientName = obj['clientName'] as String?,
        columnsStartAt1 = obj['columnsStartAt1'] as bool?,
        linesStartAt1 = obj['linesStartAt1'] as bool?,
        locale = obj['locale'] as String?,
        pathFormat = obj['pathFormat'] as String?,
        supportsANSIStyling = obj['supportsANSIStyling'] as bool?,
        supportsArgsCanBeInterpretedByShell =
            obj['supportsArgsCanBeInterpretedByShell'] as bool?,
        supportsInvalidatedEvent = obj['supportsInvalidatedEvent'] as bool?,
        supportsMemoryEvent = obj['supportsMemoryEvent'] as bool?,
        supportsMemoryReferences = obj['supportsMemoryReferences'] as bool?,
        supportsProgressReporting = obj['supportsProgressReporting'] as bool?,
        supportsRunInTerminalRequest =
            obj['supportsRunInTerminalRequest'] as bool?,
        supportsStartDebuggingRequest =
            obj['supportsStartDebuggingRequest'] as bool?,
        supportsVariablePaging = obj['supportsVariablePaging'] as bool?,
        supportsVariableType = obj['supportsVariableType'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['adapterID'] is! String) {
      return false;
    }
    if (obj['clientID'] is! String?) {
      return false;
    }
    if (obj['clientName'] is! String?) {
      return false;
    }
    if (obj['columnsStartAt1'] is! bool?) {
      return false;
    }
    if (obj['linesStartAt1'] is! bool?) {
      return false;
    }
    if (obj['locale'] is! String?) {
      return false;
    }
    if (obj['pathFormat'] is! String?) {
      return false;
    }
    if (obj['supportsANSIStyling'] is! bool?) {
      return false;
    }
    if (obj['supportsArgsCanBeInterpretedByShell'] is! bool?) {
      return false;
    }
    if (obj['supportsInvalidatedEvent'] is! bool?) {
      return false;
    }
    if (obj['supportsMemoryEvent'] is! bool?) {
      return false;
    }
    if (obj['supportsMemoryReferences'] is! bool?) {
      return false;
    }
    if (obj['supportsProgressReporting'] is! bool?) {
      return false;
    }
    if (obj['supportsRunInTerminalRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsStartDebuggingRequest'] is! bool?) {
      return false;
    }
    if (obj['supportsVariablePaging'] is! bool?) {
      return false;
    }
    if (obj['supportsVariableType'] is! bool?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'adapterID': adapterID,
        if (clientID != null) 'clientID': clientID,
        if (clientName != null) 'clientName': clientName,
        if (columnsStartAt1 != null) 'columnsStartAt1': columnsStartAt1,
        if (linesStartAt1 != null) 'linesStartAt1': linesStartAt1,
        if (locale != null) 'locale': locale,
        if (pathFormat != null) 'pathFormat': pathFormat,
        if (supportsANSIStyling != null)
          'supportsANSIStyling': supportsANSIStyling,
        if (supportsArgsCanBeInterpretedByShell != null)
          'supportsArgsCanBeInterpretedByShell':
              supportsArgsCanBeInterpretedByShell,
        if (supportsInvalidatedEvent != null)
          'supportsInvalidatedEvent': supportsInvalidatedEvent,
        if (supportsMemoryEvent != null)
          'supportsMemoryEvent': supportsMemoryEvent,
        if (supportsMemoryReferences != null)
          'supportsMemoryReferences': supportsMemoryReferences,
        if (supportsProgressReporting != null)
          'supportsProgressReporting': supportsProgressReporting,
        if (supportsRunInTerminalRequest != null)
          'supportsRunInTerminalRequest': supportsRunInTerminalRequest,
        if (supportsStartDebuggingRequest != null)
          'supportsStartDebuggingRequest': supportsStartDebuggingRequest,
        if (supportsVariablePaging != null)
          'supportsVariablePaging': supportsVariablePaging,
        if (supportsVariableType != null)
          'supportsVariableType': supportsVariableType,
      };
}

/// Response to `initialize` request.
class InitializeResponse extends Response {
  static InitializeResponse fromJson(Map<String, Object?> obj) =>
      InitializeResponse.fromMap(obj);

  InitializeResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  InitializeResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!Capabilities.canParse(obj['body'])) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Properties of a breakpoint passed to the `setInstructionBreakpoints` request
class InstructionBreakpoint {
  /// An expression for conditional breakpoints.
  /// It is only honored by a debug adapter if the corresponding capability
  /// `supportsConditionalBreakpoints` is true.
  final String? condition;

  /// An expression that controls how many hits of the breakpoint are ignored.
  /// The debug adapter is expected to interpret the expression as needed.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsHitConditionalBreakpoints` is true.
  final String? hitCondition;

  /// The instruction reference of the breakpoint.
  /// This should be a memory or instruction pointer reference from an
  /// `EvaluateResponse`, `Variable`, `StackFrame`, `GotoTarget`, or
  /// `Breakpoint`.
  final String instructionReference;

  /// The mode of this breakpoint. If defined, this must be one of the
  /// `breakpointModes` the debug adapter advertised in its `Capabilities`.
  final String? mode;

  /// The offset from the instruction reference in bytes.
  /// This can be negative.
  final int? offset;

  static InstructionBreakpoint fromJson(Map<String, Object?> obj) =>
      InstructionBreakpoint.fromMap(obj);

  InstructionBreakpoint({
    this.condition,
    this.hitCondition,
    required this.instructionReference,
    this.mode,
    this.offset,
  });

  InstructionBreakpoint.fromMap(Map<String, Object?> obj)
      : condition = obj['condition'] as String?,
        hitCondition = obj['hitCondition'] as String?,
        instructionReference = obj['instructionReference'] as String,
        mode = obj['mode'] as String?,
        offset = obj['offset'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['condition'] is! String?) {
      return false;
    }
    if (obj['hitCondition'] is! String?) {
      return false;
    }
    if (obj['instructionReference'] is! String) {
      return false;
    }
    if (obj['mode'] is! String?) {
      return false;
    }
    if (obj['offset'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (condition != null) 'condition': condition,
        if (hitCondition != null) 'hitCondition': hitCondition,
        'instructionReference': instructionReference,
        if (mode != null) 'mode': mode,
        if (offset != null) 'offset': offset,
      };
}

/// Logical areas that can be invalidated by the `invalidated` event.
typedef InvalidatedAreas = String;

/// Arguments for `launch` request. Additional attributes are implementation
/// specific.
class LaunchRequestArguments extends RequestArguments {
  /// Arbitrary data from the previous, restarted session.
  /// The data is sent as the `restart` attribute of the `terminated` event.
  /// The client should leave the data intact.
  final Object? restart;

  /// If true, the launch request should launch the program without enabling
  /// debugging.
  final bool? noDebug;

  static LaunchRequestArguments fromJson(Map<String, Object?> obj) =>
      LaunchRequestArguments.fromMap(obj);

  LaunchRequestArguments({
    this.restart,
    this.noDebug,
  });

  LaunchRequestArguments.fromMap(Map<String, Object?> obj)
      : restart = obj['__restart'],
        noDebug = obj['noDebug'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['noDebug'] is! bool?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (restart != null) '__restart': restart,
        if (noDebug != null) 'noDebug': noDebug,
      };
}

/// Response to `launch` request. This is just an acknowledgement, so no body
/// field is required.
class LaunchResponse extends Response {
  static LaunchResponse fromJson(Map<String, Object?> obj) =>
      LaunchResponse.fromMap(obj);

  LaunchResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  LaunchResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `loadedSources` request.
class LoadedSourcesArguments extends RequestArguments {
  static LoadedSourcesArguments fromJson(Map<String, Object?> obj) =>
      LoadedSourcesArguments.fromMap(obj);

  LoadedSourcesArguments();

  LoadedSourcesArguments.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {};
}

/// Response to `loadedSources` request.
class LoadedSourcesResponse extends Response {
  static LoadedSourcesResponse fromJson(Map<String, Object?> obj) =>
      LoadedSourcesResponse.fromMap(obj);

  LoadedSourcesResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  LoadedSourcesResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `locations` request.
class LocationsArguments extends RequestArguments {
  /// Location reference to resolve.
  final int locationReference;

  static LocationsArguments fromJson(Map<String, Object?> obj) =>
      LocationsArguments.fromMap(obj);

  LocationsArguments({
    required this.locationReference,
  });

  LocationsArguments.fromMap(Map<String, Object?> obj)
      : locationReference = obj['locationReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['locationReference'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'locationReference': locationReference,
      };
}

/// Response to `locations` request.
class LocationsResponse extends Response {
  static LocationsResponse fromJson(Map<String, Object?> obj) =>
      LocationsResponse.fromMap(obj);

  LocationsResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  LocationsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>?) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A structured message object. Used to return errors from requests.
class Message {
  /// A format string for the message. Embedded variables have the form
  /// `{name}`.
  /// If variable name starts with an underscore character, the variable does
  /// not contain user data (PII) and can be safely used for telemetry purposes.
  final String format;

  /// Unique (within a debug adapter implementation) identifier for the message.
  /// The purpose of these error IDs is to help extension authors that have the
  /// requirement that every user visible error message needs a corresponding
  /// error number, so that users or customer support can find information about
  /// the specific error more easily.
  final int id;

  /// If true send to telemetry.
  final bool? sendTelemetry;

  /// If true show user.
  final bool? showUser;

  /// A url where additional information about this message can be found.
  final String? url;

  /// A label that is presented to the user as the UI for opening the url.
  final String? urlLabel;

  /// An object used as a dictionary for looking up the variables in the format
  /// string.
  final Map<String, Object?>? variables;

  static Message fromJson(Map<String, Object?> obj) => Message.fromMap(obj);

  Message({
    required this.format,
    required this.id,
    this.sendTelemetry,
    this.showUser,
    this.url,
    this.urlLabel,
    this.variables,
  });

  Message.fromMap(Map<String, Object?> obj)
      : format = obj['format'] as String,
        id = obj['id'] as int,
        sendTelemetry = obj['sendTelemetry'] as bool?,
        showUser = obj['showUser'] as bool?,
        url = obj['url'] as String?,
        urlLabel = obj['urlLabel'] as String?,
        variables = obj['variables'] as Map<String, Object?>?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['format'] is! String) {
      return false;
    }
    if (obj['id'] is! int) {
      return false;
    }
    if (obj['sendTelemetry'] is! bool?) {
      return false;
    }
    if (obj['showUser'] is! bool?) {
      return false;
    }
    if (obj['url'] is! String?) {
      return false;
    }
    if (obj['urlLabel'] is! String?) {
      return false;
    }
    if (obj['variables'] is! Map<String, Object?>?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'format': format,
        'id': id,
        if (sendTelemetry != null) 'sendTelemetry': sendTelemetry,
        if (showUser != null) 'showUser': showUser,
        if (url != null) 'url': url,
        if (urlLabel != null) 'urlLabel': urlLabel,
        if (variables != null) 'variables': variables,
      };
}

/// A Module object represents a row in the modules view.
/// The `id` attribute identifies a module in the modules view and is used in a
/// `module` event for identifying a module for adding, updating or deleting.
/// The `name` attribute is used to minimally render the module in the UI.
///
/// Additional attributes can be added to the module. They show up in the module
/// view if they have a corresponding `ColumnDescriptor`.
///
/// To avoid an unnecessary proliferation of additional attributes with similar
/// semantics but different names, we recommend to re-use attributes from the
/// 'recommended' list below first, and only introduce new attributes if nothing
/// appropriate could be found.
class Module {
  /// Address range covered by this module.
  final String? addressRange;

  /// Module created or modified, encoded as a RFC 3339 timestamp.
  final String? dateTimeStamp;

  /// Unique identifier for the module.
  final Either2<int, String> id;

  /// True if the module is optimized.
  final bool? isOptimized;

  /// True if the module is considered 'user code' by a debugger that supports
  /// 'Just My Code'.
  final bool? isUserCode;

  /// A name of the module.
  final String name;

  /// Logical full path to the module. The exact definition is implementation
  /// defined, but usually this would be a full path to the on-disk file for the
  /// module.
  final String? path;

  /// Logical full path to the symbol file. The exact definition is
  /// implementation defined.
  final String? symbolFilePath;

  /// User-understandable description of if symbols were found for the module
  /// (ex: 'Symbols Loaded', 'Symbols not found', etc.)
  final String? symbolStatus;

  /// Version of Module.
  final String? version;

  static Module fromJson(Map<String, Object?> obj) => Module.fromMap(obj);

  Module({
    this.addressRange,
    this.dateTimeStamp,
    required this.id,
    this.isOptimized,
    this.isUserCode,
    required this.name,
    this.path,
    this.symbolFilePath,
    this.symbolStatus,
    this.version,
  });

  Module.fromMap(Map<String, Object?> obj)
      : addressRange = obj['addressRange'] as String?,
        dateTimeStamp = obj['dateTimeStamp'] as String?,
        id = obj['id'] is int
            ? Either2<int, String>.t1(obj['id'] as int)
            : Either2<int, String>.t2(obj['id'] as String),
        isOptimized = obj['isOptimized'] as bool?,
        isUserCode = obj['isUserCode'] as bool?,
        name = obj['name'] as String,
        path = obj['path'] as String?,
        symbolFilePath = obj['symbolFilePath'] as String?,
        symbolStatus = obj['symbolStatus'] as String?,
        version = obj['version'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['addressRange'] is! String?) {
      return false;
    }
    if (obj['dateTimeStamp'] is! String?) {
      return false;
    }
    if ((obj['id'] is! int && obj['id'] is! String)) {
      return false;
    }
    if (obj['isOptimized'] is! bool?) {
      return false;
    }
    if (obj['isUserCode'] is! bool?) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['path'] is! String?) {
      return false;
    }
    if (obj['symbolFilePath'] is! String?) {
      return false;
    }
    if (obj['symbolStatus'] is! String?) {
      return false;
    }
    if (obj['version'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (addressRange != null) 'addressRange': addressRange,
        if (dateTimeStamp != null) 'dateTimeStamp': dateTimeStamp,
        'id': id,
        if (isOptimized != null) 'isOptimized': isOptimized,
        if (isUserCode != null) 'isUserCode': isUserCode,
        'name': name,
        if (path != null) 'path': path,
        if (symbolFilePath != null) 'symbolFilePath': symbolFilePath,
        if (symbolStatus != null) 'symbolStatus': symbolStatus,
        if (version != null) 'version': version,
      };
}

/// Arguments for `modules` request.
class ModulesArguments extends RequestArguments {
  /// The number of modules to return. If `moduleCount` is not specified or 0,
  /// all modules are returned.
  final int? moduleCount;

  /// The index of the first module to return; if omitted modules start at 0.
  final int? startModule;

  static ModulesArguments fromJson(Map<String, Object?> obj) =>
      ModulesArguments.fromMap(obj);

  ModulesArguments({
    this.moduleCount,
    this.startModule,
  });

  ModulesArguments.fromMap(Map<String, Object?> obj)
      : moduleCount = obj['moduleCount'] as int?,
        startModule = obj['startModule'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['moduleCount'] is! int?) {
      return false;
    }
    if (obj['startModule'] is! int?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (moduleCount != null) 'moduleCount': moduleCount,
        if (startModule != null) 'startModule': startModule,
      };
}

/// Response to `modules` request.
class ModulesResponse extends Response {
  static ModulesResponse fromJson(Map<String, Object?> obj) =>
      ModulesResponse.fromMap(obj);

  ModulesResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ModulesResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `next` request.
class NextArguments extends RequestArguments {
  /// Stepping granularity. If no granularity is specified, a granularity of
  /// `statement` is assumed.
  final SteppingGranularity? granularity;

  /// If this flag is true, all other suspended threads are not resumed.
  final bool? singleThread;

  /// Specifies the thread for which to resume execution for one step (of the
  /// given granularity).
  final int threadId;

  static NextArguments fromJson(Map<String, Object?> obj) =>
      NextArguments.fromMap(obj);

  NextArguments({
    this.granularity,
    this.singleThread,
    required this.threadId,
  });

  NextArguments.fromMap(Map<String, Object?> obj)
      : granularity = obj['granularity'] as SteppingGranularity?,
        singleThread = obj['singleThread'] as bool?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['granularity'] is! SteppingGranularity?) {
      return false;
    }
    if (obj['singleThread'] is! bool?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (granularity != null) 'granularity': granularity,
        if (singleThread != null) 'singleThread': singleThread,
        'threadId': threadId,
      };
}

/// Response to `next` request. This is just an acknowledgement, so no body
/// field is required.
class NextResponse extends Response {
  static NextResponse fromJson(Map<String, Object?> obj) =>
      NextResponse.fromMap(obj);

  NextResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  NextResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `pause` request.
class PauseArguments extends RequestArguments {
  /// Pause execution for this thread.
  final int threadId;

  static PauseArguments fromJson(Map<String, Object?> obj) =>
      PauseArguments.fromMap(obj);

  PauseArguments({
    required this.threadId,
  });

  PauseArguments.fromMap(Map<String, Object?> obj)
      : threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'threadId': threadId,
      };
}

/// Response to `pause` request. This is just an acknowledgement, so no body
/// field is required.
class PauseResponse extends Response {
  static PauseResponse fromJson(Map<String, Object?> obj) =>
      PauseResponse.fromMap(obj);

  PauseResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  PauseResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Base class of requests, responses, and events.
class ProtocolMessage {
  /// Sequence number of the message (also known as message ID). The `seq` for
  /// the first message sent by a client or debug adapter is 1, and for each
  /// subsequent message is 1 greater than the previous message sent by that
  /// actor. `seq` can be used to order requests, responses, and events, and to
  /// associate requests with their corresponding responses. For protocol
  /// messages of type `request` the sequence number can be used to cancel the
  /// request.
  final int seq;

  /// Message type.
  final String type;

  static ProtocolMessage fromJson(Map<String, Object?> obj) =>
      ProtocolMessage.fromMap(obj);

  ProtocolMessage({
    required this.seq,
    required this.type,
  });

  ProtocolMessage.fromMap(Map<String, Object?> obj)
      : seq = obj['seq'] as int,
        type = obj['type'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['seq'] is! int) {
      return false;
    }
    if (obj['type'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'seq': seq,
        'type': type,
      };
}

/// Arguments for `readMemory` request.
class ReadMemoryArguments extends RequestArguments {
  /// Number of bytes to read at the specified location and offset.
  final int count;

  /// Memory reference to the base location from which data should be read.
  final String memoryReference;

  /// Offset (in bytes) to be applied to the reference location before reading
  /// data. Can be negative.
  final int? offset;

  static ReadMemoryArguments fromJson(Map<String, Object?> obj) =>
      ReadMemoryArguments.fromMap(obj);

  ReadMemoryArguments({
    required this.count,
    required this.memoryReference,
    this.offset,
  });

  ReadMemoryArguments.fromMap(Map<String, Object?> obj)
      : count = obj['count'] as int,
        memoryReference = obj['memoryReference'] as String,
        offset = obj['offset'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['count'] is! int) {
      return false;
    }
    if (obj['memoryReference'] is! String) {
      return false;
    }
    if (obj['offset'] is! int?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'count': count,
        'memoryReference': memoryReference,
        if (offset != null) 'offset': offset,
      };
}

/// Response to `readMemory` request.
class ReadMemoryResponse extends Response {
  static ReadMemoryResponse fromJson(Map<String, Object?> obj) =>
      ReadMemoryResponse.fromMap(obj);

  ReadMemoryResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ReadMemoryResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>?) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A client or debug adapter initiated request.
class Request extends ProtocolMessage {
  /// Object containing arguments for the command.
  final Object? arguments;

  /// The command to execute.
  final String command;

  static Request fromJson(Map<String, Object?> obj) => Request.fromMap(obj);

  Request({
    this.arguments,
    required this.command,
    required super.seq,
  }) : super(
          type: 'request',
        );

  Request.fromMap(super.obj)
      : arguments = obj['arguments'],
        command = obj['command'] as String,
        super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['command'] is! String) {
      return false;
    }
    if (obj['type'] is! String) {
      return false;
    }
    return ProtocolMessage.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        if (arguments != null) 'arguments': arguments,
        'command': command,
      };
}

/// Response for a request.
class Response extends ProtocolMessage {
  /// Contains request result if success is true and error details if success is
  /// false.
  final Object? body;

  /// The command requested.
  final String command;

  /// Contains the raw error in short form if `success` is false.
  /// This raw error might be interpreted by the client and is not shown in the
  /// UI.
  /// Some predefined values exist.
  final String? message;

  /// Sequence number of the corresponding request.
  final int requestSeq;

  /// Outcome of the request.
  /// If true, the request was successful and the `body` attribute may contain
  /// the result of the request.
  /// If the value is false, the attribute `message` contains the error in short
  /// form and the `body` may contain additional information (see
  /// `ErrorResponse.body.error`).
  final bool success;

  static Response fromJson(Map<String, Object?> obj) => Response.fromMap(obj);

  Response({
    this.body,
    required this.command,
    this.message,
    required this.requestSeq,
    required this.success,
    required super.seq,
  }) : super(
          type: 'response',
        );

  Response.fromMap(super.obj)
      : body = obj['body'],
        command = obj['command'] as String,
        message = obj['message'] as String?,
        requestSeq = obj['request_seq'] as int,
        success = obj['success'] as bool,
        super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['command'] is! String) {
      return false;
    }
    if (obj['message'] is! String?) {
      return false;
    }
    if (obj['request_seq'] is! int) {
      return false;
    }
    if (obj['success'] is! bool) {
      return false;
    }
    if (obj['type'] is! String) {
      return false;
    }
    return ProtocolMessage.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        if (body != null) 'body': body,
        'command': command,
        if (message != null) 'message': message,
        'request_seq': requestSeq,
        'success': success,
      };
}

/// Arguments for `restart` request.
class RestartArguments extends RequestArguments {
  /// The latest version of the `launch` or `attach` configuration.
  final Either2<LaunchRequestArguments, AttachRequestArguments>? arguments;

  static RestartArguments fromJson(Map<String, Object?> obj) =>
      RestartArguments.fromMap(obj);

  RestartArguments({
    this.arguments,
  });

  RestartArguments.fromMap(Map<String, Object?> obj)
      : arguments = LaunchRequestArguments.canParse(obj['arguments'])
            ? Either2<LaunchRequestArguments, AttachRequestArguments>.t1(
                LaunchRequestArguments.fromJson(
                    obj['arguments'] as Map<String, Object?>))
            : AttachRequestArguments.canParse(obj['arguments'])
                ? Either2<LaunchRequestArguments, AttachRequestArguments>.t2(
                    AttachRequestArguments.fromJson(
                        obj['arguments'] as Map<String, Object?>))
                : null;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((!LaunchRequestArguments.canParse(obj['arguments']) &&
        !AttachRequestArguments.canParse(obj['arguments']) &&
        obj['arguments'] != null)) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (arguments != null) 'arguments': arguments,
      };
}

/// Arguments for `restartFrame` request.
class RestartFrameArguments extends RequestArguments {
  /// Restart the stack frame identified by `frameId`. The `frameId` must have
  /// been obtained in the current suspended state. See 'Lifetime of Object
  /// References' in the Overview section for details.
  final int frameId;

  static RestartFrameArguments fromJson(Map<String, Object?> obj) =>
      RestartFrameArguments.fromMap(obj);

  RestartFrameArguments({
    required this.frameId,
  });

  RestartFrameArguments.fromMap(Map<String, Object?> obj)
      : frameId = obj['frameId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['frameId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'frameId': frameId,
      };
}

/// Response to `restartFrame` request. This is just an acknowledgement, so no
/// body field is required.
class RestartFrameResponse extends Response {
  static RestartFrameResponse fromJson(Map<String, Object?> obj) =>
      RestartFrameResponse.fromMap(obj);

  RestartFrameResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  RestartFrameResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Response to `restart` request. This is just an acknowledgement, so no body
/// field is required.
class RestartResponse extends Response {
  static RestartResponse fromJson(Map<String, Object?> obj) =>
      RestartResponse.fromMap(obj);

  RestartResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  RestartResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `reverseContinue` request.
class ReverseContinueArguments extends RequestArguments {
  /// If this flag is true, backward execution is resumed only for the thread
  /// with given `threadId`.
  final bool? singleThread;

  /// Specifies the active thread. If the debug adapter supports single thread
  /// execution (see `supportsSingleThreadExecutionRequests`) and the
  /// `singleThread` argument is true, only the thread with this ID is resumed.
  final int threadId;

  static ReverseContinueArguments fromJson(Map<String, Object?> obj) =>
      ReverseContinueArguments.fromMap(obj);

  ReverseContinueArguments({
    this.singleThread,
    required this.threadId,
  });

  ReverseContinueArguments.fromMap(Map<String, Object?> obj)
      : singleThread = obj['singleThread'] as bool?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['singleThread'] is! bool?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (singleThread != null) 'singleThread': singleThread,
        'threadId': threadId,
      };
}

/// Response to `reverseContinue` request. This is just an acknowledgement, so
/// no body field is required.
class ReverseContinueResponse extends Response {
  static ReverseContinueResponse fromJson(Map<String, Object?> obj) =>
      ReverseContinueResponse.fromMap(obj);

  ReverseContinueResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ReverseContinueResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `runInTerminal` request.
class RunInTerminalRequestArguments extends RequestArguments {
  /// List of arguments. The first argument is the command to run.
  final List<String> args;

  /// This property should only be set if the corresponding capability
  /// `supportsArgsCanBeInterpretedByShell` is true. If the client uses an
  /// intermediary shell to launch the application, then the client must not
  /// attempt to escape characters with special meanings for the shell. The user
  /// is fully responsible for escaping as needed and that arguments using
  /// special characters may not be portable across shells.
  final bool? argsCanBeInterpretedByShell;

  /// Working directory for the command. For non-empty, valid paths this
  /// typically results in execution of a change directory command.
  final String cwd;

  /// Environment key-value pairs that are added to or removed from the default
  /// environment.
  final Map<String, Object?>? env;

  /// What kind of terminal to launch. Defaults to `integrated` if not
  /// specified.
  final String? kind;

  /// Title of the terminal.
  final String? title;

  static RunInTerminalRequestArguments fromJson(Map<String, Object?> obj) =>
      RunInTerminalRequestArguments.fromMap(obj);

  RunInTerminalRequestArguments({
    required this.args,
    this.argsCanBeInterpretedByShell,
    required this.cwd,
    this.env,
    this.kind,
    this.title,
  });

  RunInTerminalRequestArguments.fromMap(Map<String, Object?> obj)
      : args = (obj['args'] as List).map((item) => item as String).toList(),
        argsCanBeInterpretedByShell =
            obj['argsCanBeInterpretedByShell'] as bool?,
        cwd = obj['cwd'] as String,
        env = obj['env'] as Map<String, Object?>?,
        kind = obj['kind'] as String?,
        title = obj['title'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['args'] is! List ||
        (obj['args'].any((item) => item is! String)))) {
      return false;
    }
    if (obj['argsCanBeInterpretedByShell'] is! bool?) {
      return false;
    }
    if (obj['cwd'] is! String) {
      return false;
    }
    if (obj['env'] is! Map<String, Object?>?) {
      return false;
    }
    if (obj['kind'] is! String?) {
      return false;
    }
    if (obj['title'] is! String?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'args': args,
        if (argsCanBeInterpretedByShell != null)
          'argsCanBeInterpretedByShell': argsCanBeInterpretedByShell,
        'cwd': cwd,
        if (env != null) 'env': env,
        if (kind != null) 'kind': kind,
        if (title != null) 'title': title,
      };
}

/// Response to `runInTerminal` request.
class RunInTerminalResponse extends Response {
  static RunInTerminalResponse fromJson(Map<String, Object?> obj) =>
      RunInTerminalResponse.fromMap(obj);

  RunInTerminalResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  RunInTerminalResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A `Scope` is a named container for variables. Optionally a scope can map to
/// a source or a range within a source.
class Scope {
  /// Start position of the range covered by the scope. It is measured in UTF-16
  /// code units and the client capability `columnsStartAt1` determines whether
  /// it is 0- or 1-based.
  final int? column;

  /// End position of the range covered by the scope. It is measured in UTF-16
  /// code units and the client capability `columnsStartAt1` determines whether
  /// it is 0- or 1-based.
  final int? endColumn;

  /// The end line of the range covered by this scope.
  final int? endLine;

  /// If true, the number of variables in this scope is large or expensive to
  /// retrieve.
  final bool expensive;

  /// The number of indexed variables in this scope.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  final int? indexedVariables;

  /// The start line of the range covered by this scope.
  final int? line;

  /// Name of the scope such as 'Arguments', 'Locals', or 'Registers'. This
  /// string is shown in the UI as is and can be translated.
  final String name;

  /// The number of named variables in this scope.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  final int? namedVariables;

  /// A hint for how to present this scope in the UI. If this attribute is
  /// missing, the scope is shown with a generic UI.
  final String? presentationHint;

  /// The source for this scope.
  final Source? source;

  /// The variables of this scope can be retrieved by passing the value of
  /// `variablesReference` to the `variables` request as long as execution
  /// remains suspended. See 'Lifetime of Object References' in the Overview
  /// section for details.
  final int variablesReference;

  static Scope fromJson(Map<String, Object?> obj) => Scope.fromMap(obj);

  Scope({
    this.column,
    this.endColumn,
    this.endLine,
    required this.expensive,
    this.indexedVariables,
    this.line,
    required this.name,
    this.namedVariables,
    this.presentationHint,
    this.source,
    required this.variablesReference,
  });

  Scope.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        expensive = obj['expensive'] as bool,
        indexedVariables = obj['indexedVariables'] as int?,
        line = obj['line'] as int?,
        name = obj['name'] as String,
        namedVariables = obj['namedVariables'] as int?,
        presentationHint = obj['presentationHint'] as String?,
        source = obj['source'] == null
            ? null
            : Source.fromJson(obj['source'] as Map<String, Object?>),
        variablesReference = obj['variablesReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['expensive'] is! bool) {
      return false;
    }
    if (obj['indexedVariables'] is! int?) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['namedVariables'] is! int?) {
      return false;
    }
    if (obj['presentationHint'] is! String?) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    if (obj['variablesReference'] is! int) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'expensive': expensive,
        if (indexedVariables != null) 'indexedVariables': indexedVariables,
        if (line != null) 'line': line,
        'name': name,
        if (namedVariables != null) 'namedVariables': namedVariables,
        if (presentationHint != null) 'presentationHint': presentationHint,
        if (source != null) 'source': source,
        'variablesReference': variablesReference,
      };
}

/// Arguments for `scopes` request.
class ScopesArguments extends RequestArguments {
  /// Retrieve the scopes for the stack frame identified by `frameId`. The
  /// `frameId` must have been obtained in the current suspended state. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int frameId;

  static ScopesArguments fromJson(Map<String, Object?> obj) =>
      ScopesArguments.fromMap(obj);

  ScopesArguments({
    required this.frameId,
  });

  ScopesArguments.fromMap(Map<String, Object?> obj)
      : frameId = obj['frameId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['frameId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'frameId': frameId,
      };
}

/// Response to `scopes` request.
class ScopesResponse extends Response {
  static ScopesResponse fromJson(Map<String, Object?> obj) =>
      ScopesResponse.fromMap(obj);

  ScopesResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ScopesResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setBreakpoints` request.
class SetBreakpointsArguments extends RequestArguments {
  /// The code locations of the breakpoints.
  final List<SourceBreakpoint>? breakpoints;

  /// Deprecated: The code locations of the breakpoints.
  final List<int>? lines;

  /// The source location of the breakpoints; either `source.path` or
  /// `source.sourceReference` must be specified.
  final Source source;

  /// A value of true indicates that the underlying source has been modified
  /// which results in new breakpoint locations.
  final bool? sourceModified;

  static SetBreakpointsArguments fromJson(Map<String, Object?> obj) =>
      SetBreakpointsArguments.fromMap(obj);

  SetBreakpointsArguments({
    this.breakpoints,
    this.lines,
    required this.source,
    this.sourceModified,
  });

  SetBreakpointsArguments.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List?)
            ?.map((item) =>
                SourceBreakpoint.fromJson(item as Map<String, Object?>))
            .toList(),
        lines = (obj['lines'] as List?)?.map((item) => item as int).toList(),
        source = Source.fromJson(obj['source'] as Map<String, Object?>),
        sourceModified = obj['sourceModified'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !SourceBreakpoint.canParse(item))))) {
      return false;
    }
    if ((obj['lines'] is! List || (obj['lines'].any((item) => item is! int)))) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    if (obj['sourceModified'] is! bool?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (breakpoints != null) 'breakpoints': breakpoints,
        if (lines != null) 'lines': lines,
        'source': source,
        if (sourceModified != null) 'sourceModified': sourceModified,
      };
}

/// Response to `setBreakpoints` request.
/// Returned is information about each breakpoint created by this request.
/// This includes the actual code location and whether the breakpoint could be
/// verified.
/// The breakpoints returned are in the same order as the elements of the
/// `breakpoints`
/// (or the deprecated `lines`) array in the arguments.
class SetBreakpointsResponse extends Response {
  static SetBreakpointsResponse fromJson(Map<String, Object?> obj) =>
      SetBreakpointsResponse.fromMap(obj);

  SetBreakpointsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetBreakpointsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setDataBreakpoints` request.
class SetDataBreakpointsArguments extends RequestArguments {
  /// The contents of this array replaces all existing data breakpoints. An
  /// empty array clears all data breakpoints.
  final List<DataBreakpoint> breakpoints;

  static SetDataBreakpointsArguments fromJson(Map<String, Object?> obj) =>
      SetDataBreakpointsArguments.fromMap(obj);

  SetDataBreakpointsArguments({
    required this.breakpoints,
  });

  SetDataBreakpointsArguments.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map(
                (item) => DataBreakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !DataBreakpoint.canParse(item))))) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

/// Response to `setDataBreakpoints` request.
/// Returned is information about each breakpoint created by this request.
class SetDataBreakpointsResponse extends Response {
  static SetDataBreakpointsResponse fromJson(Map<String, Object?> obj) =>
      SetDataBreakpointsResponse.fromMap(obj);

  SetDataBreakpointsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetDataBreakpointsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setExceptionBreakpoints` request.
class SetExceptionBreakpointsArguments extends RequestArguments {
  /// Configuration options for selected exceptions.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsExceptionOptions` is true.
  final List<ExceptionOptions>? exceptionOptions;

  /// Set of exception filters and their options. The set of all possible
  /// exception filters is defined by the `exceptionBreakpointFilters`
  /// capability. This attribute is only honored by a debug adapter if the
  /// corresponding capability `supportsExceptionFilterOptions` is true. The
  /// `filter` and `filterOptions` sets are additive.
  final List<ExceptionFilterOptions>? filterOptions;

  /// Set of exception filters specified by their ID. The set of all possible
  /// exception filters is defined by the `exceptionBreakpointFilters`
  /// capability. The `filter` and `filterOptions` sets are additive.
  final List<String> filters;

  static SetExceptionBreakpointsArguments fromJson(Map<String, Object?> obj) =>
      SetExceptionBreakpointsArguments.fromMap(obj);

  SetExceptionBreakpointsArguments({
    this.exceptionOptions,
    this.filterOptions,
    required this.filters,
  });

  SetExceptionBreakpointsArguments.fromMap(Map<String, Object?> obj)
      : exceptionOptions = (obj['exceptionOptions'] as List?)
            ?.map((item) =>
                ExceptionOptions.fromJson(item as Map<String, Object?>))
            .toList(),
        filterOptions = (obj['filterOptions'] as List?)
            ?.map((item) =>
                ExceptionFilterOptions.fromJson(item as Map<String, Object?>))
            .toList(),
        filters =
            (obj['filters'] as List).map((item) => item as String).toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['exceptionOptions'] is! List ||
        (obj['exceptionOptions']
            .any((item) => !ExceptionOptions.canParse(item))))) {
      return false;
    }
    if ((obj['filterOptions'] is! List ||
        (obj['filterOptions']
            .any((item) => !ExceptionFilterOptions.canParse(item))))) {
      return false;
    }
    if ((obj['filters'] is! List ||
        (obj['filters'].any((item) => item is! String)))) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (exceptionOptions != null) 'exceptionOptions': exceptionOptions,
        if (filterOptions != null) 'filterOptions': filterOptions,
        'filters': filters,
      };
}

/// Response to `setExceptionBreakpoints` request.
/// The response contains an array of `Breakpoint` objects with information
/// about each exception breakpoint or filter. The `Breakpoint` objects are in
/// the same order as the elements of the `filters`, `filterOptions`,
/// `exceptionOptions` arrays given as arguments. If both `filters` and
/// `filterOptions` are given, the returned array must start with `filters`
/// information first, followed by `filterOptions` information.
/// The `verified` property of a `Breakpoint` object signals whether the
/// exception breakpoint or filter could be successfully created and whether the
/// condition is valid. In case of an error the `message` property explains the
/// problem. The `id` property can be used to introduce a unique ID for the
/// exception breakpoint or filter so that it can be updated subsequently by
/// sending breakpoint events.
/// For backward compatibility both the `breakpoints` array and the enclosing
/// `body` are optional. If these elements are missing a client is not able to
/// show problems for individual exception breakpoints or filters.
class SetExceptionBreakpointsResponse extends Response {
  static SetExceptionBreakpointsResponse fromJson(Map<String, Object?> obj) =>
      SetExceptionBreakpointsResponse.fromMap(obj);

  SetExceptionBreakpointsResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetExceptionBreakpointsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>?) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setExpression` request.
class SetExpressionArguments extends RequestArguments {
  /// The l-value expression to assign to.
  final String expression;

  /// Specifies how the resulting value should be formatted.
  final ValueFormat? format;

  /// Evaluate the expressions in the scope of this stack frame. If not
  /// specified, the expressions are evaluated in the global scope.
  final int? frameId;

  /// The value expression to assign to the l-value expression.
  final String value;

  static SetExpressionArguments fromJson(Map<String, Object?> obj) =>
      SetExpressionArguments.fromMap(obj);

  SetExpressionArguments({
    required this.expression,
    this.format,
    this.frameId,
    required this.value,
  });

  SetExpressionArguments.fromMap(Map<String, Object?> obj)
      : expression = obj['expression'] as String,
        format = obj['format'] == null
            ? null
            : ValueFormat.fromJson(obj['format'] as Map<String, Object?>),
        frameId = obj['frameId'] as int?,
        value = obj['value'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['expression'] is! String) {
      return false;
    }
    if (!ValueFormat.canParse(obj['format'])) {
      return false;
    }
    if (obj['frameId'] is! int?) {
      return false;
    }
    if (obj['value'] is! String) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'expression': expression,
        if (format != null) 'format': format,
        if (frameId != null) 'frameId': frameId,
        'value': value,
      };
}

/// Response to `setExpression` request.
class SetExpressionResponse extends Response {
  static SetExpressionResponse fromJson(Map<String, Object?> obj) =>
      SetExpressionResponse.fromMap(obj);

  SetExpressionResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetExpressionResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setFunctionBreakpoints` request.
class SetFunctionBreakpointsArguments extends RequestArguments {
  /// The function names of the breakpoints.
  final List<FunctionBreakpoint> breakpoints;

  static SetFunctionBreakpointsArguments fromJson(Map<String, Object?> obj) =>
      SetFunctionBreakpointsArguments.fromMap(obj);

  SetFunctionBreakpointsArguments({
    required this.breakpoints,
  });

  SetFunctionBreakpointsArguments.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) =>
                FunctionBreakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints']
            .any((item) => !FunctionBreakpoint.canParse(item))))) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

/// Response to `setFunctionBreakpoints` request.
/// Returned is information about each breakpoint created by this request.
class SetFunctionBreakpointsResponse extends Response {
  static SetFunctionBreakpointsResponse fromJson(Map<String, Object?> obj) =>
      SetFunctionBreakpointsResponse.fromMap(obj);

  SetFunctionBreakpointsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetFunctionBreakpointsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setInstructionBreakpoints` request
class SetInstructionBreakpointsArguments extends RequestArguments {
  /// The instruction references of the breakpoints
  final List<InstructionBreakpoint> breakpoints;

  static SetInstructionBreakpointsArguments fromJson(
          Map<String, Object?> obj) =>
      SetInstructionBreakpointsArguments.fromMap(obj);

  SetInstructionBreakpointsArguments({
    required this.breakpoints,
  });

  SetInstructionBreakpointsArguments.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) =>
                InstructionBreakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints']
            .any((item) => !InstructionBreakpoint.canParse(item))))) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

/// Response to `setInstructionBreakpoints` request
class SetInstructionBreakpointsResponse extends Response {
  static SetInstructionBreakpointsResponse fromJson(Map<String, Object?> obj) =>
      SetInstructionBreakpointsResponse.fromMap(obj);

  SetInstructionBreakpointsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetInstructionBreakpointsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `setVariable` request.
class SetVariableArguments extends RequestArguments {
  /// Specifies details on how to format the response value.
  final ValueFormat? format;

  /// The name of the variable in the container.
  final String name;

  /// The value of the variable.
  final String value;

  /// The reference of the variable container. The `variablesReference` must
  /// have been obtained in the current suspended state. See 'Lifetime of Object
  /// References' in the Overview section for details.
  final int variablesReference;

  static SetVariableArguments fromJson(Map<String, Object?> obj) =>
      SetVariableArguments.fromMap(obj);

  SetVariableArguments({
    this.format,
    required this.name,
    required this.value,
    required this.variablesReference,
  });

  SetVariableArguments.fromMap(Map<String, Object?> obj)
      : format = obj['format'] == null
            ? null
            : ValueFormat.fromJson(obj['format'] as Map<String, Object?>),
        name = obj['name'] as String,
        value = obj['value'] as String,
        variablesReference = obj['variablesReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!ValueFormat.canParse(obj['format'])) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['value'] is! String) {
      return false;
    }
    if (obj['variablesReference'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (format != null) 'format': format,
        'name': name,
        'value': value,
        'variablesReference': variablesReference,
      };
}

/// Response to `setVariable` request.
class SetVariableResponse extends Response {
  static SetVariableResponse fromJson(Map<String, Object?> obj) =>
      SetVariableResponse.fromMap(obj);

  SetVariableResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SetVariableResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A `Source` is a descriptor for source code.
/// It is returned from the debug adapter as part of a `StackFrame` and it is
/// used by clients when specifying breakpoints.
class Source {
  /// Additional data that a debug adapter might want to loop through the
  /// client.
  /// The client should leave the data intact and persist it across sessions.
  /// The client should not interpret the data.
  final Object? adapterData;

  /// The checksums associated with this file.
  final List<Checksum>? checksums;

  /// The short name of the source. Every source returned from the debug adapter
  /// has a name.
  /// When sending a source to the debug adapter this name is optional.
  final String? name;

  /// The origin of this source. For example, 'internal module', 'inlined
  /// content from source map', etc.
  final String? origin;

  /// The path of the source to be shown in the UI.
  /// It is only used to locate and load the content of the source if no
  /// `sourceReference` is specified (or its value is 0).
  final String? path;

  /// A hint for how to present the source in the UI.
  /// A value of `deemphasize` can be used to indicate that the source is not
  /// available or that it is skipped on stepping.
  final String? presentationHint;

  /// If the value > 0 the contents of the source must be retrieved through the
  /// `source` request (even if a path is specified).
  /// Since a `sourceReference` is only valid for a session, it can not be used
  /// to persist a source.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? sourceReference;

  /// A list of sources that are related to this source. These may be the source
  /// that generated this source.
  final List<Source>? sources;

  static Source fromJson(Map<String, Object?> obj) => Source.fromMap(obj);

  Source({
    this.adapterData,
    this.checksums,
    this.name,
    this.origin,
    this.path,
    this.presentationHint,
    this.sourceReference,
    this.sources,
  });

  Source.fromMap(Map<String, Object?> obj)
      : adapterData = obj['adapterData'],
        checksums = (obj['checksums'] as List?)
            ?.map((item) => Checksum.fromJson(item as Map<String, Object?>))
            .toList(),
        name = obj['name'] as String?,
        origin = obj['origin'] as String?,
        path = obj['path'] as String?,
        presentationHint = obj['presentationHint'] as String?,
        sourceReference = obj['sourceReference'] as int?,
        sources = (obj['sources'] as List?)
            ?.map((item) => Source.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['checksums'] is! List ||
        (obj['checksums'].any((item) => !Checksum.canParse(item))))) {
      return false;
    }
    if (obj['name'] is! String?) {
      return false;
    }
    if (obj['origin'] is! String?) {
      return false;
    }
    if (obj['path'] is! String?) {
      return false;
    }
    if (obj['presentationHint'] is! String?) {
      return false;
    }
    if (obj['sourceReference'] is! int?) {
      return false;
    }
    if ((obj['sources'] is! List ||
        (obj['sources'].any((item) => !Source.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (adapterData != null) 'adapterData': adapterData,
        if (checksums != null) 'checksums': checksums,
        if (name != null) 'name': name,
        if (origin != null) 'origin': origin,
        if (path != null) 'path': path,
        if (presentationHint != null) 'presentationHint': presentationHint,
        if (sourceReference != null) 'sourceReference': sourceReference,
        if (sources != null) 'sources': sources,
      };
}

/// Arguments for `source` request.
class SourceArguments extends RequestArguments {
  /// Specifies the source content to load. Either `source.path` or
  /// `source.sourceReference` must be specified.
  final Source? source;

  /// The reference to the source. This is the same as `source.sourceReference`.
  /// This is provided for backward compatibility since old clients do not
  /// understand the `source` attribute.
  final int sourceReference;

  static SourceArguments fromJson(Map<String, Object?> obj) =>
      SourceArguments.fromMap(obj);

  SourceArguments({
    this.source,
    required this.sourceReference,
  });

  SourceArguments.fromMap(Map<String, Object?> obj)
      : source = obj['source'] == null
            ? null
            : Source.fromJson(obj['source'] as Map<String, Object?>),
        sourceReference = obj['sourceReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    if (obj['sourceReference'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (source != null) 'source': source,
        'sourceReference': sourceReference,
      };
}

/// Properties of a breakpoint or logpoint passed to the `setBreakpoints`
/// request.
class SourceBreakpoint {
  /// Start position within source line of the breakpoint or logpoint. It is
  /// measured in UTF-16 code units and the client capability `columnsStartAt1`
  /// determines whether it is 0- or 1-based.
  final int? column;

  /// The expression for conditional breakpoints.
  /// It is only honored by a debug adapter if the corresponding capability
  /// `supportsConditionalBreakpoints` is true.
  final String? condition;

  /// The expression that controls how many hits of the breakpoint are ignored.
  /// The debug adapter is expected to interpret the expression as needed.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsHitConditionalBreakpoints` is true.
  /// If both this property and `condition` are specified, `hitCondition` should
  /// be evaluated only if the `condition` is met, and the debug adapter should
  /// stop only if both conditions are met.
  final String? hitCondition;

  /// The source line of the breakpoint or logpoint.
  final int line;

  /// If this attribute exists and is non-empty, the debug adapter must not
  /// 'break' (stop)
  /// but log the message instead. Expressions within `{}` are interpolated.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsLogPoints` is true.
  /// If either `hitCondition` or `condition` is specified, then the message
  /// should only be logged if those conditions are met.
  final String? logMessage;

  /// The mode of this breakpoint. If defined, this must be one of the
  /// `breakpointModes` the debug adapter advertised in its `Capabilities`.
  final String? mode;

  static SourceBreakpoint fromJson(Map<String, Object?> obj) =>
      SourceBreakpoint.fromMap(obj);

  SourceBreakpoint({
    this.column,
    this.condition,
    this.hitCondition,
    required this.line,
    this.logMessage,
    this.mode,
  });

  SourceBreakpoint.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        condition = obj['condition'] as String?,
        hitCondition = obj['hitCondition'] as String?,
        line = obj['line'] as int,
        logMessage = obj['logMessage'] as String?,
        mode = obj['mode'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['condition'] is! String?) {
      return false;
    }
    if (obj['hitCondition'] is! String?) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    if (obj['logMessage'] is! String?) {
      return false;
    }
    if (obj['mode'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (condition != null) 'condition': condition,
        if (hitCondition != null) 'hitCondition': hitCondition,
        'line': line,
        if (logMessage != null) 'logMessage': logMessage,
        if (mode != null) 'mode': mode,
      };
}

/// Response to `source` request.
class SourceResponse extends Response {
  static SourceResponse fromJson(Map<String, Object?> obj) =>
      SourceResponse.fromMap(obj);

  SourceResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  SourceResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A Stackframe contains the source location.
class StackFrame {
  /// Indicates whether this frame can be restarted with the `restartFrame`
  /// request. Clients should only use this if the debug adapter supports the
  /// `restart` request and the corresponding capability `supportsRestartFrame`
  /// is true. If a debug adapter has this capability, then `canRestart`
  /// defaults to `true` if the property is absent.
  final bool? canRestart;

  /// Start position of the range covered by the stack frame. It is measured in
  /// UTF-16 code units and the client capability `columnsStartAt1` determines
  /// whether it is 0- or 1-based. If attribute `source` is missing or doesn't
  /// exist, `column` is 0 and should be ignored by the client.
  final int column;

  /// End position of the range covered by the stack frame. It is measured in
  /// UTF-16 code units and the client capability `columnsStartAt1` determines
  /// whether it is 0- or 1-based.
  final int? endColumn;

  /// The end line of the range covered by the stack frame.
  final int? endLine;

  /// An identifier for the stack frame. It must be unique across all threads.
  /// This id can be used to retrieve the scopes of the frame with the `scopes`
  /// request or to restart the execution of a stack frame.
  final int id;

  /// A memory reference for the current instruction pointer in this frame.
  final String? instructionPointerReference;

  /// The line within the source of the frame. If the source attribute is
  /// missing or doesn't exist, `line` is 0 and should be ignored by the client.
  final int line;

  /// The module associated with this frame, if any.
  final Either2<int, String>? moduleId;

  /// The name of the stack frame, typically a method name.
  final String name;

  /// A hint for how to present this frame in the UI.
  /// A value of `label` can be used to indicate that the frame is an artificial
  /// frame that is used as a visual label or separator. A value of `subtle` can
  /// be used to change the appearance of a frame in a 'subtle' way.
  final String? presentationHint;

  /// The source of the frame.
  final Source? source;

  static StackFrame fromJson(Map<String, Object?> obj) =>
      StackFrame.fromMap(obj);

  StackFrame({
    this.canRestart,
    required this.column,
    this.endColumn,
    this.endLine,
    required this.id,
    this.instructionPointerReference,
    required this.line,
    this.moduleId,
    required this.name,
    this.presentationHint,
    this.source,
  });

  StackFrame.fromMap(Map<String, Object?> obj)
      : canRestart = obj['canRestart'] as bool?,
        column = obj['column'] as int,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        id = obj['id'] as int,
        instructionPointerReference =
            obj['instructionPointerReference'] as String?,
        line = obj['line'] as int,
        moduleId = obj['moduleId'] is int
            ? Either2<int, String>.t1(obj['moduleId'] as int)
            : obj['moduleId'] is String
                ? Either2<int, String>.t2(obj['moduleId'] as String)
                : null,
        name = obj['name'] as String,
        presentationHint = obj['presentationHint'] as String?,
        source = obj['source'] == null
            ? null
            : Source.fromJson(obj['source'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['canRestart'] is! bool?) {
      return false;
    }
    if (obj['column'] is! int) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['id'] is! int) {
      return false;
    }
    if (obj['instructionPointerReference'] is! String?) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    if ((obj['moduleId'] is! int &&
        obj['moduleId'] is! String &&
        obj['moduleId'] != null)) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['presentationHint'] is! String?) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (canRestart != null) 'canRestart': canRestart,
        'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'id': id,
        if (instructionPointerReference != null)
          'instructionPointerReference': instructionPointerReference,
        'line': line,
        if (moduleId != null) 'moduleId': moduleId,
        'name': name,
        if (presentationHint != null) 'presentationHint': presentationHint,
        if (source != null) 'source': source,
      };
}

/// Provides formatting information for a stack frame.
class StackFrameFormat extends ValueFormat {
  /// Includes all stack frames, including those the debug adapter might
  /// otherwise hide.
  final bool? includeAll;

  /// Displays the line number of the stack frame.
  final bool? line;

  /// Displays the module of the stack frame.
  final bool? module;

  /// Displays the names of parameters for the stack frame.
  final bool? parameterNames;

  /// Displays the types of parameters for the stack frame.
  final bool? parameterTypes;

  /// Displays the values of parameters for the stack frame.
  final bool? parameterValues;

  /// Displays parameters for the stack frame.
  final bool? parameters;

  static StackFrameFormat fromJson(Map<String, Object?> obj) =>
      StackFrameFormat.fromMap(obj);

  StackFrameFormat({
    this.includeAll,
    this.line,
    this.module,
    this.parameterNames,
    this.parameterTypes,
    this.parameterValues,
    this.parameters,
    super.hex,
  });

  StackFrameFormat.fromMap(super.obj)
      : includeAll = obj['includeAll'] as bool?,
        line = obj['line'] as bool?,
        module = obj['module'] as bool?,
        parameterNames = obj['parameterNames'] as bool?,
        parameterTypes = obj['parameterTypes'] as bool?,
        parameterValues = obj['parameterValues'] as bool?,
        parameters = obj['parameters'] as bool?,
        super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['includeAll'] is! bool?) {
      return false;
    }
    if (obj['line'] is! bool?) {
      return false;
    }
    if (obj['module'] is! bool?) {
      return false;
    }
    if (obj['parameterNames'] is! bool?) {
      return false;
    }
    if (obj['parameterTypes'] is! bool?) {
      return false;
    }
    if (obj['parameterValues'] is! bool?) {
      return false;
    }
    if (obj['parameters'] is! bool?) {
      return false;
    }
    return ValueFormat.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        if (includeAll != null) 'includeAll': includeAll,
        if (line != null) 'line': line,
        if (module != null) 'module': module,
        if (parameterNames != null) 'parameterNames': parameterNames,
        if (parameterTypes != null) 'parameterTypes': parameterTypes,
        if (parameterValues != null) 'parameterValues': parameterValues,
        if (parameters != null) 'parameters': parameters,
      };
}

/// Arguments for `stackTrace` request.
class StackTraceArguments extends RequestArguments {
  /// Specifies details on how to format the stack frames.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsValueFormattingOptions` is true.
  final StackFrameFormat? format;

  /// The maximum number of frames to return. If levels is not specified or 0,
  /// all frames are returned.
  final int? levels;

  /// The index of the first frame to return; if omitted frames start at 0.
  final int? startFrame;

  /// Retrieve the stacktrace for this thread.
  final int threadId;

  static StackTraceArguments fromJson(Map<String, Object?> obj) =>
      StackTraceArguments.fromMap(obj);

  StackTraceArguments({
    this.format,
    this.levels,
    this.startFrame,
    required this.threadId,
  });

  StackTraceArguments.fromMap(Map<String, Object?> obj)
      : format = obj['format'] == null
            ? null
            : StackFrameFormat.fromJson(obj['format'] as Map<String, Object?>),
        levels = obj['levels'] as int?,
        startFrame = obj['startFrame'] as int?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!StackFrameFormat.canParse(obj['format'])) {
      return false;
    }
    if (obj['levels'] is! int?) {
      return false;
    }
    if (obj['startFrame'] is! int?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (format != null) 'format': format,
        if (levels != null) 'levels': levels,
        if (startFrame != null) 'startFrame': startFrame,
        'threadId': threadId,
      };
}

/// Response to `stackTrace` request.
class StackTraceResponse extends Response {
  static StackTraceResponse fromJson(Map<String, Object?> obj) =>
      StackTraceResponse.fromMap(obj);

  StackTraceResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  StackTraceResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `startDebugging` request.
class StartDebuggingRequestArguments extends RequestArguments {
  /// Arguments passed to the new debug session. The arguments must only contain
  /// properties understood by the `launch` or `attach` requests of the debug
  /// adapter and they must not contain any client-specific properties (e.g.
  /// `type`) or client-specific features (e.g. substitutable 'variables').
  final Map<String, Object?> configuration;

  /// Indicates whether the new debug session should be started with a `launch`
  /// or `attach` request.
  final String request;

  static StartDebuggingRequestArguments fromJson(Map<String, Object?> obj) =>
      StartDebuggingRequestArguments.fromMap(obj);

  StartDebuggingRequestArguments({
    required this.configuration,
    required this.request,
  });

  StartDebuggingRequestArguments.fromMap(Map<String, Object?> obj)
      : configuration = obj['configuration'] as Map<String, Object?>,
        request = obj['request'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['configuration'] is! Map<String, Object?>) {
      return false;
    }
    if (obj['request'] is! String) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'configuration': configuration,
        'request': request,
      };
}

/// Response to `startDebugging` request. This is just an acknowledgement, so no
/// body field is required.
class StartDebuggingResponse extends Response {
  static StartDebuggingResponse fromJson(Map<String, Object?> obj) =>
      StartDebuggingResponse.fromMap(obj);

  StartDebuggingResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  StartDebuggingResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `stepBack` request.
class StepBackArguments extends RequestArguments {
  /// Stepping granularity to step. If no granularity is specified, a
  /// granularity of `statement` is assumed.
  final SteppingGranularity? granularity;

  /// If this flag is true, all other suspended threads are not resumed.
  final bool? singleThread;

  /// Specifies the thread for which to resume execution for one step backwards
  /// (of the given granularity).
  final int threadId;

  static StepBackArguments fromJson(Map<String, Object?> obj) =>
      StepBackArguments.fromMap(obj);

  StepBackArguments({
    this.granularity,
    this.singleThread,
    required this.threadId,
  });

  StepBackArguments.fromMap(Map<String, Object?> obj)
      : granularity = obj['granularity'] as SteppingGranularity?,
        singleThread = obj['singleThread'] as bool?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['granularity'] is! SteppingGranularity?) {
      return false;
    }
    if (obj['singleThread'] is! bool?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (granularity != null) 'granularity': granularity,
        if (singleThread != null) 'singleThread': singleThread,
        'threadId': threadId,
      };
}

/// Response to `stepBack` request. This is just an acknowledgement, so no body
/// field is required.
class StepBackResponse extends Response {
  static StepBackResponse fromJson(Map<String, Object?> obj) =>
      StepBackResponse.fromMap(obj);

  StepBackResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  StepBackResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `stepIn` request.
class StepInArguments extends RequestArguments {
  /// Stepping granularity. If no granularity is specified, a granularity of
  /// `statement` is assumed.
  final SteppingGranularity? granularity;

  /// If this flag is true, all other suspended threads are not resumed.
  final bool? singleThread;

  /// Id of the target to step into.
  final int? targetId;

  /// Specifies the thread for which to resume execution for one step-into (of
  /// the given granularity).
  final int threadId;

  static StepInArguments fromJson(Map<String, Object?> obj) =>
      StepInArguments.fromMap(obj);

  StepInArguments({
    this.granularity,
    this.singleThread,
    this.targetId,
    required this.threadId,
  });

  StepInArguments.fromMap(Map<String, Object?> obj)
      : granularity = obj['granularity'] as SteppingGranularity?,
        singleThread = obj['singleThread'] as bool?,
        targetId = obj['targetId'] as int?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['granularity'] is! SteppingGranularity?) {
      return false;
    }
    if (obj['singleThread'] is! bool?) {
      return false;
    }
    if (obj['targetId'] is! int?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (granularity != null) 'granularity': granularity,
        if (singleThread != null) 'singleThread': singleThread,
        if (targetId != null) 'targetId': targetId,
        'threadId': threadId,
      };
}

/// Response to `stepIn` request. This is just an acknowledgement, so no body
/// field is required.
class StepInResponse extends Response {
  static StepInResponse fromJson(Map<String, Object?> obj) =>
      StepInResponse.fromMap(obj);

  StepInResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  StepInResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A `StepInTarget` can be used in the `stepIn` request and determines into
/// which single target the `stepIn` request should step.
class StepInTarget {
  /// Start position of the range covered by the step in target. It is measured
  /// in UTF-16 code units and the client capability `columnsStartAt1`
  /// determines whether it is 0- or 1-based.
  final int? column;

  /// End position of the range covered by the step in target. It is measured in
  /// UTF-16 code units and the client capability `columnsStartAt1` determines
  /// whether it is 0- or 1-based.
  final int? endColumn;

  /// The end line of the range covered by the step-in target.
  final int? endLine;

  /// Unique identifier for a step-in target.
  final int id;

  /// The name of the step-in target (shown in the UI).
  final String label;

  /// The line of the step-in target.
  final int? line;

  static StepInTarget fromJson(Map<String, Object?> obj) =>
      StepInTarget.fromMap(obj);

  StepInTarget({
    this.column,
    this.endColumn,
    this.endLine,
    required this.id,
    required this.label,
    this.line,
  });

  StepInTarget.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        id = obj['id'] as int,
        label = obj['label'] as String,
        line = obj['line'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['id'] is! int) {
      return false;
    }
    if (obj['label'] is! String) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'id': id,
        'label': label,
        if (line != null) 'line': line,
      };
}

/// Arguments for `stepInTargets` request.
class StepInTargetsArguments extends RequestArguments {
  /// The stack frame for which to retrieve the possible step-in targets.
  final int frameId;

  static StepInTargetsArguments fromJson(Map<String, Object?> obj) =>
      StepInTargetsArguments.fromMap(obj);

  StepInTargetsArguments({
    required this.frameId,
  });

  StepInTargetsArguments.fromMap(Map<String, Object?> obj)
      : frameId = obj['frameId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['frameId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'frameId': frameId,
      };
}

/// Response to `stepInTargets` request.
class StepInTargetsResponse extends Response {
  static StepInTargetsResponse fromJson(Map<String, Object?> obj) =>
      StepInTargetsResponse.fromMap(obj);

  StepInTargetsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  StepInTargetsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `stepOut` request.
class StepOutArguments extends RequestArguments {
  /// Stepping granularity. If no granularity is specified, a granularity of
  /// `statement` is assumed.
  final SteppingGranularity? granularity;

  /// If this flag is true, all other suspended threads are not resumed.
  final bool? singleThread;

  /// Specifies the thread for which to resume execution for one step-out (of
  /// the given granularity).
  final int threadId;

  static StepOutArguments fromJson(Map<String, Object?> obj) =>
      StepOutArguments.fromMap(obj);

  StepOutArguments({
    this.granularity,
    this.singleThread,
    required this.threadId,
  });

  StepOutArguments.fromMap(Map<String, Object?> obj)
      : granularity = obj['granularity'] as SteppingGranularity?,
        singleThread = obj['singleThread'] as bool?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['granularity'] is! SteppingGranularity?) {
      return false;
    }
    if (obj['singleThread'] is! bool?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (granularity != null) 'granularity': granularity,
        if (singleThread != null) 'singleThread': singleThread,
        'threadId': threadId,
      };
}

/// Response to `stepOut` request. This is just an acknowledgement, so no body
/// field is required.
class StepOutResponse extends Response {
  static StepOutResponse fromJson(Map<String, Object?> obj) =>
      StepOutResponse.fromMap(obj);

  StepOutResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  StepOutResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// The granularity of one 'step' in the stepping requests `next`, `stepIn`,
/// `stepOut`, and `stepBack`.
typedef SteppingGranularity = String;

/// Arguments for `terminate` request.
class TerminateArguments extends RequestArguments {
  /// A value of true indicates that this `terminate` request is part of a
  /// restart sequence.
  final bool? restart;

  static TerminateArguments fromJson(Map<String, Object?> obj) =>
      TerminateArguments.fromMap(obj);

  TerminateArguments({
    this.restart,
  });

  TerminateArguments.fromMap(Map<String, Object?> obj)
      : restart = obj['restart'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['restart'] is! bool?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (restart != null) 'restart': restart,
      };
}

/// Response to `terminate` request. This is just an acknowledgement, so no body
/// field is required.
class TerminateResponse extends Response {
  static TerminateResponse fromJson(Map<String, Object?> obj) =>
      TerminateResponse.fromMap(obj);

  TerminateResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  TerminateResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `terminateThreads` request.
class TerminateThreadsArguments extends RequestArguments {
  /// Ids of threads to be terminated.
  final List<int>? threadIds;

  static TerminateThreadsArguments fromJson(Map<String, Object?> obj) =>
      TerminateThreadsArguments.fromMap(obj);

  TerminateThreadsArguments({
    this.threadIds,
  });

  TerminateThreadsArguments.fromMap(Map<String, Object?> obj)
      : threadIds =
            (obj['threadIds'] as List?)?.map((item) => item as int).toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['threadIds'] is! List ||
        (obj['threadIds'].any((item) => item is! int)))) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (threadIds != null) 'threadIds': threadIds,
      };
}

/// Response to `terminateThreads` request. This is just an acknowledgement, no
/// body field is required.
class TerminateThreadsResponse extends Response {
  static TerminateThreadsResponse fromJson(Map<String, Object?> obj) =>
      TerminateThreadsResponse.fromMap(obj);

  TerminateThreadsResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  TerminateThreadsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// A Thread
class Thread {
  /// Unique identifier for the thread.
  final int id;

  /// The name of the thread.
  final String name;

  static Thread fromJson(Map<String, Object?> obj) => Thread.fromMap(obj);

  Thread({
    required this.id,
    required this.name,
  });

  Thread.fromMap(Map<String, Object?> obj)
      : id = obj['id'] as int,
        name = obj['name'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['id'] is! int) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
      };
}

/// Response to `threads` request.
class ThreadsResponse extends Response {
  static ThreadsResponse fromJson(Map<String, Object?> obj) =>
      ThreadsResponse.fromMap(obj);

  ThreadsResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  ThreadsResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Provides formatting information for a value.
class ValueFormat {
  /// Display the value in hex.
  final bool? hex;

  static ValueFormat fromJson(Map<String, Object?> obj) =>
      ValueFormat.fromMap(obj);

  ValueFormat({
    this.hex,
  });

  ValueFormat.fromMap(Map<String, Object?> obj) : hex = obj['hex'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['hex'] is! bool?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (hex != null) 'hex': hex,
      };
}

/// A Variable is a name/value pair.
/// The `type` attribute is shown if space permits or when hovering over the
/// variable's name.
/// The `kind` attribute is used to render additional properties of the
/// variable, e.g. different icons can be used to indicate that a variable is
/// public or private.
/// If the value is structured (has children), a handle is provided to retrieve
/// the children with the `variables` request.
/// If the number of named or indexed children is large, the numbers should be
/// returned via the `namedVariables` and `indexedVariables` attributes.
/// The client can use this information to present the children in a paged UI
/// and fetch them in chunks.
class Variable {
  /// A reference that allows the client to request the location where the
  /// variable is declared. This should be present only if the adapter is likely
  /// to be able to resolve the location.
  ///
  /// This reference shares the same lifetime as the `variablesReference`. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int? declarationLocationReference;

  /// The evaluatable name of this variable which can be passed to the
  /// `evaluate` request to fetch the variable's value.
  final String? evaluateName;

  /// The number of indexed child variables.
  /// The client can use this information to present the children in a paged UI
  /// and fetch them in chunks.
  final int? indexedVariables;

  /// A memory reference associated with this variable.
  /// For pointer type variables, this is generally a reference to the memory
  /// address contained in the pointer.
  /// For executable data, this reference may later be used in a `disassemble`
  /// request.
  /// This attribute may be returned by a debug adapter if corresponding
  /// capability `supportsMemoryReferences` is true.
  final String? memoryReference;

  /// The variable's name.
  final String name;

  /// The number of named child variables.
  /// The client can use this information to present the children in a paged UI
  /// and fetch them in chunks.
  final int? namedVariables;

  /// Properties of a variable that can be used to determine how to render the
  /// variable in the UI.
  final VariablePresentationHint? presentationHint;

  /// The type of the variable's value. Typically shown in the UI when hovering
  /// over the value.
  /// This attribute should only be returned by a debug adapter if the
  /// corresponding capability `supportsVariableType` is true.
  final String? type;

  /// The variable's value.
  /// This can be a multi-line text, e.g. for a function the body of a function.
  /// For structured variables (which do not have a simple value), it is
  /// recommended to provide a one-line representation of the structured object.
  /// This helps to identify the structured object in the collapsed state when
  /// its children are not yet visible.
  /// An empty string can be used if no value should be shown in the UI.
  final String value;

  /// A reference that allows the client to request the location where the
  /// variable's value is declared. For example, if the variable contains a
  /// function pointer, the adapter may be able to look up the function's
  /// location. This should be present only if the adapter is likely to be able
  /// to resolve the location.
  ///
  /// This reference shares the same lifetime as the `variablesReference`. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int? valueLocationReference;

  /// If `variablesReference` is > 0, the variable is structured and its
  /// children can be retrieved by passing `variablesReference` to the
  /// `variables` request as long as execution remains suspended. See 'Lifetime
  /// of Object References' in the Overview section for details.
  final int variablesReference;

  static Variable fromJson(Map<String, Object?> obj) => Variable.fromMap(obj);

  Variable({
    this.declarationLocationReference,
    this.evaluateName,
    this.indexedVariables,
    this.memoryReference,
    required this.name,
    this.namedVariables,
    this.presentationHint,
    this.type,
    required this.value,
    this.valueLocationReference,
    required this.variablesReference,
  });

  Variable.fromMap(Map<String, Object?> obj)
      : declarationLocationReference =
            obj['declarationLocationReference'] as int?,
        evaluateName = obj['evaluateName'] as String?,
        indexedVariables = obj['indexedVariables'] as int?,
        memoryReference = obj['memoryReference'] as String?,
        name = obj['name'] as String,
        namedVariables = obj['namedVariables'] as int?,
        presentationHint = obj['presentationHint'] == null
            ? null
            : VariablePresentationHint.fromJson(
                obj['presentationHint'] as Map<String, Object?>),
        type = obj['type'] as String?,
        value = obj['value'] as String,
        valueLocationReference = obj['valueLocationReference'] as int?,
        variablesReference = obj['variablesReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['declarationLocationReference'] is! int?) {
      return false;
    }
    if (obj['evaluateName'] is! String?) {
      return false;
    }
    if (obj['indexedVariables'] is! int?) {
      return false;
    }
    if (obj['memoryReference'] is! String?) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['namedVariables'] is! int?) {
      return false;
    }
    if (!VariablePresentationHint.canParse(obj['presentationHint'])) {
      return false;
    }
    if (obj['type'] is! String?) {
      return false;
    }
    if (obj['value'] is! String) {
      return false;
    }
    if (obj['valueLocationReference'] is! int?) {
      return false;
    }
    if (obj['variablesReference'] is! int) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (declarationLocationReference != null)
          'declarationLocationReference': declarationLocationReference,
        if (evaluateName != null) 'evaluateName': evaluateName,
        if (indexedVariables != null) 'indexedVariables': indexedVariables,
        if (memoryReference != null) 'memoryReference': memoryReference,
        'name': name,
        if (namedVariables != null) 'namedVariables': namedVariables,
        if (presentationHint != null) 'presentationHint': presentationHint,
        if (type != null) 'type': type,
        'value': value,
        if (valueLocationReference != null)
          'valueLocationReference': valueLocationReference,
        'variablesReference': variablesReference,
      };
}

/// Properties of a variable that can be used to determine how to render the
/// variable in the UI.
class VariablePresentationHint {
  /// Set of attributes represented as an array of strings. Before introducing
  /// additional values, try to use the listed values.
  final List<String>? attributes;

  /// The kind of variable. Before introducing additional values, try to use the
  /// listed values.
  final String? kind;

  /// If true, clients can present the variable with a UI that supports a
  /// specific gesture to trigger its evaluation.
  /// This mechanism can be used for properties that require executing code when
  /// retrieving their value and where the code execution can be expensive
  /// and/or produce side-effects. A typical example are properties based on a
  /// getter function.
  /// Please note that in addition to the `lazy` flag, the variable's
  /// `variablesReference` is expected to refer to a variable that will provide
  /// the value through another `variable` request.
  final bool? lazy;

  /// Visibility of variable. Before introducing additional values, try to use
  /// the listed values.
  final String? visibility;

  static VariablePresentationHint fromJson(Map<String, Object?> obj) =>
      VariablePresentationHint.fromMap(obj);

  VariablePresentationHint({
    this.attributes,
    this.kind,
    this.lazy,
    this.visibility,
  });

  VariablePresentationHint.fromMap(Map<String, Object?> obj)
      : attributes = (obj['attributes'] as List?)
            ?.map((item) => item as String)
            .toList(),
        kind = obj['kind'] as String?,
        lazy = obj['lazy'] as bool?,
        visibility = obj['visibility'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['attributes'] is! List ||
        (obj['attributes'].any((item) => item is! String)))) {
      return false;
    }
    if (obj['kind'] is! String?) {
      return false;
    }
    if (obj['lazy'] is! bool?) {
      return false;
    }
    if (obj['visibility'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (attributes != null) 'attributes': attributes,
        if (kind != null) 'kind': kind,
        if (lazy != null) 'lazy': lazy,
        if (visibility != null) 'visibility': visibility,
      };
}

/// Arguments for `variables` request.
class VariablesArguments extends RequestArguments {
  /// The number of variables to return. If count is missing or 0, all variables
  /// are returned.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsVariablePaging` is true.
  final int? count;

  /// Filter to limit the child variables to either named or indexed. If
  /// omitted, both types are fetched.
  final String? filter;

  /// Specifies details on how to format the Variable values.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsValueFormattingOptions` is true.
  final ValueFormat? format;

  /// The index of the first variable to return; if omitted children start at 0.
  /// The attribute is only honored by a debug adapter if the corresponding
  /// capability `supportsVariablePaging` is true.
  final int? start;

  /// The variable for which to retrieve its children. The `variablesReference`
  /// must have been obtained in the current suspended state. See 'Lifetime of
  /// Object References' in the Overview section for details.
  final int variablesReference;

  static VariablesArguments fromJson(Map<String, Object?> obj) =>
      VariablesArguments.fromMap(obj);

  VariablesArguments({
    this.count,
    this.filter,
    this.format,
    this.start,
    required this.variablesReference,
  });

  VariablesArguments.fromMap(Map<String, Object?> obj)
      : count = obj['count'] as int?,
        filter = obj['filter'] as String?,
        format = obj['format'] == null
            ? null
            : ValueFormat.fromJson(obj['format'] as Map<String, Object?>),
        start = obj['start'] as int?,
        variablesReference = obj['variablesReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['count'] is! int?) {
      return false;
    }
    if (obj['filter'] is! String?) {
      return false;
    }
    if (!ValueFormat.canParse(obj['format'])) {
      return false;
    }
    if (obj['start'] is! int?) {
      return false;
    }
    if (obj['variablesReference'] is! int) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (count != null) 'count': count,
        if (filter != null) 'filter': filter,
        if (format != null) 'format': format,
        if (start != null) 'start': start,
        'variablesReference': variablesReference,
      };
}

/// Response to `variables` request.
class VariablesResponse extends Response {
  static VariablesResponse fromJson(Map<String, Object?> obj) =>
      VariablesResponse.fromMap(obj);

  VariablesResponse({
    required super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  VariablesResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Arguments for `writeMemory` request.
class WriteMemoryArguments extends RequestArguments {
  /// Property to control partial writes. If true, the debug adapter should
  /// attempt to write memory even if the entire memory region is not writable.
  /// In such a case the debug adapter should stop after hitting the first byte
  /// of memory that cannot be written and return the number of bytes written in
  /// the response via the `offset` and `bytesWritten` properties.
  /// If false or missing, a debug adapter should attempt to verify the region
  /// is writable before writing, and fail the response if it is not.
  final bool? allowPartial;

  /// Bytes to write, encoded using base64.
  final String data;

  /// Memory reference to the base location to which data should be written.
  final String memoryReference;

  /// Offset (in bytes) to be applied to the reference location before writing
  /// data. Can be negative.
  final int? offset;

  static WriteMemoryArguments fromJson(Map<String, Object?> obj) =>
      WriteMemoryArguments.fromMap(obj);

  WriteMemoryArguments({
    this.allowPartial,
    required this.data,
    required this.memoryReference,
    this.offset,
  });

  WriteMemoryArguments.fromMap(Map<String, Object?> obj)
      : allowPartial = obj['allowPartial'] as bool?,
        data = obj['data'] as String,
        memoryReference = obj['memoryReference'] as String,
        offset = obj['offset'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['allowPartial'] is! bool?) {
      return false;
    }
    if (obj['data'] is! String) {
      return false;
    }
    if (obj['memoryReference'] is! String) {
      return false;
    }
    if (obj['offset'] is! int?) {
      return false;
    }
    return RequestArguments.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (allowPartial != null) 'allowPartial': allowPartial,
        'data': data,
        'memoryReference': memoryReference,
        if (offset != null) 'offset': offset,
      };
}

/// Response to `writeMemory` request.
class WriteMemoryResponse extends Response {
  static WriteMemoryResponse fromJson(Map<String, Object?> obj) =>
      WriteMemoryResponse.fromMap(obj);

  WriteMemoryResponse({
    super.body,
    required super.command,
    super.message,
    required super.requestSeq,
    required super.seq,
    required super.success,
  });

  WriteMemoryResponse.fromMap(super.obj) : super.fromMap();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['body'] is! Map<String, Object?>?) {
      return false;
    }
    return Response.canParse(obj);
  }

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class AttachResponseBody {
  static AttachResponseBody fromJson(Map<String, Object?> obj) =>
      AttachResponseBody.fromMap(obj);

  AttachResponseBody();

  AttachResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class BreakpointEventBody extends EventBody {
  /// The `id` attribute is used to find the target breakpoint, the other
  /// attributes are used as the new values.
  final Breakpoint breakpoint;

  /// The reason for the event.
  final String reason;

  static BreakpointEventBody fromJson(Map<String, Object?> obj) =>
      BreakpointEventBody.fromMap(obj);

  BreakpointEventBody({
    required this.breakpoint,
    required this.reason,
  });

  BreakpointEventBody.fromMap(Map<String, Object?> obj)
      : breakpoint =
            Breakpoint.fromJson(obj['breakpoint'] as Map<String, Object?>),
        reason = obj['reason'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!Breakpoint.canParse(obj['breakpoint'])) {
      return false;
    }
    if (obj['reason'] is! String) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'breakpoint': breakpoint,
        'reason': reason,
      };
}

class BreakpointLocationsResponseBody {
  /// Sorted set of possible breakpoint locations.
  final List<BreakpointLocation> breakpoints;

  static BreakpointLocationsResponseBody fromJson(Map<String, Object?> obj) =>
      BreakpointLocationsResponseBody.fromMap(obj);

  BreakpointLocationsResponseBody({
    required this.breakpoints,
  });

  BreakpointLocationsResponseBody.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) =>
                BreakpointLocation.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints']
            .any((item) => !BreakpointLocation.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class CancelResponseBody {
  static CancelResponseBody fromJson(Map<String, Object?> obj) =>
      CancelResponseBody.fromMap(obj);

  CancelResponseBody();

  CancelResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class CapabilitiesEventBody extends EventBody {
  /// The set of updated capabilities.
  final Capabilities capabilities;

  static CapabilitiesEventBody fromJson(Map<String, Object?> obj) =>
      CapabilitiesEventBody.fromMap(obj);

  CapabilitiesEventBody({
    required this.capabilities,
  });

  CapabilitiesEventBody.fromMap(Map<String, Object?> obj)
      : capabilities =
            Capabilities.fromJson(obj['capabilities'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!Capabilities.canParse(obj['capabilities'])) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'capabilities': capabilities,
      };
}

class CompletionsResponseBody {
  /// The possible completions for .
  final List<CompletionItem> targets;

  static CompletionsResponseBody fromJson(Map<String, Object?> obj) =>
      CompletionsResponseBody.fromMap(obj);

  CompletionsResponseBody({
    required this.targets,
  });

  CompletionsResponseBody.fromMap(Map<String, Object?> obj)
      : targets = (obj['targets'] as List)
            .map(
                (item) => CompletionItem.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['targets'] is! List ||
        (obj['targets'].any((item) => !CompletionItem.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'targets': targets,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class ConfigurationDoneResponseBody {
  static ConfigurationDoneResponseBody fromJson(Map<String, Object?> obj) =>
      ConfigurationDoneResponseBody.fromMap(obj);

  ConfigurationDoneResponseBody();

  ConfigurationDoneResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class ContinueResponseBody {
  /// The value true (or a missing property) signals to the client that all
  /// threads have been resumed. The value false indicates that not all threads
  /// were resumed.
  final bool? allThreadsContinued;

  static ContinueResponseBody fromJson(Map<String, Object?> obj) =>
      ContinueResponseBody.fromMap(obj);

  ContinueResponseBody({
    this.allThreadsContinued,
  });

  ContinueResponseBody.fromMap(Map<String, Object?> obj)
      : allThreadsContinued = obj['allThreadsContinued'] as bool?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['allThreadsContinued'] is! bool?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (allThreadsContinued != null)
          'allThreadsContinued': allThreadsContinued,
      };
}

class ContinuedEventBody extends EventBody {
  /// If `allThreadsContinued` is true, a debug adapter can announce that all
  /// threads have continued.
  final bool? allThreadsContinued;

  /// The thread which was continued.
  final int threadId;

  static ContinuedEventBody fromJson(Map<String, Object?> obj) =>
      ContinuedEventBody.fromMap(obj);

  ContinuedEventBody({
    this.allThreadsContinued,
    required this.threadId,
  });

  ContinuedEventBody.fromMap(Map<String, Object?> obj)
      : allThreadsContinued = obj['allThreadsContinued'] as bool?,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['allThreadsContinued'] is! bool?) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (allThreadsContinued != null)
          'allThreadsContinued': allThreadsContinued,
        'threadId': threadId,
      };
}

class DataBreakpointInfoResponseBody {
  /// Attribute lists the available access types for a potential data
  /// breakpoint. A UI client could surface this information.
  final List<DataBreakpointAccessType>? accessTypes;

  /// Attribute indicates that a potential data breakpoint could be persisted
  /// across sessions.
  final bool? canPersist;

  /// An identifier for the data on which a data breakpoint can be registered
  /// with the `setDataBreakpoints` request or null if no data breakpoint is
  /// available. If a `variablesReference` or `frameId` is passed, the `dataId`
  /// is valid in the current suspended state, otherwise it's valid
  /// indefinitely. See 'Lifetime of Object References' in the Overview section
  /// for details. Breakpoints set using the `dataId` in the
  /// `setDataBreakpoints` request may outlive the lifetime of the associated
  /// `dataId`.
  final Either2<String, Null> dataId;

  /// UI string that describes on what data the breakpoint is set on or why a
  /// data breakpoint is not available.
  final String description;

  static DataBreakpointInfoResponseBody fromJson(Map<String, Object?> obj) =>
      DataBreakpointInfoResponseBody.fromMap(obj);

  DataBreakpointInfoResponseBody({
    this.accessTypes,
    this.canPersist,
    required this.dataId,
    required this.description,
  });

  DataBreakpointInfoResponseBody.fromMap(Map<String, Object?> obj)
      : accessTypes = (obj['accessTypes'] as List?)
            ?.map((item) => item as DataBreakpointAccessType)
            .toList(),
        canPersist = obj['canPersist'] as bool?,
        dataId = obj['dataId'] is String
            ? Either2<String, Null>.t1(obj['dataId'] as String)
            : Either2<String, Null>.t2(obj['dataId'] as Null),
        description = obj['description'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['accessTypes'] is! List ||
        (obj['accessTypes']
            .any((item) => item is! DataBreakpointAccessType)))) {
      return false;
    }
    if (obj['canPersist'] is! bool?) {
      return false;
    }
    if ((obj['dataId'] is! String && obj['dataId'] != null)) {
      return false;
    }
    if (obj['description'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (accessTypes != null) 'accessTypes': accessTypes,
        if (canPersist != null) 'canPersist': canPersist,
        'dataId': dataId,
        'description': description,
      };
}

class DisassembleResponseBody {
  /// The list of disassembled instructions.
  final List<DisassembledInstruction> instructions;

  static DisassembleResponseBody fromJson(Map<String, Object?> obj) =>
      DisassembleResponseBody.fromMap(obj);

  DisassembleResponseBody({
    required this.instructions,
  });

  DisassembleResponseBody.fromMap(Map<String, Object?> obj)
      : instructions = (obj['instructions'] as List)
            .map((item) =>
                DisassembledInstruction.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['instructions'] is! List ||
        (obj['instructions']
            .any((item) => !DisassembledInstruction.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'instructions': instructions,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class DisconnectResponseBody {
  static DisconnectResponseBody fromJson(Map<String, Object?> obj) =>
      DisconnectResponseBody.fromMap(obj);

  DisconnectResponseBody();

  DisconnectResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class ErrorResponseBody {
  /// A structured error message.
  final Message? error;

  static ErrorResponseBody fromJson(Map<String, Object?> obj) =>
      ErrorResponseBody.fromMap(obj);

  ErrorResponseBody({
    this.error,
  });

  ErrorResponseBody.fromMap(Map<String, Object?> obj)
      : error = obj['error'] == null
            ? null
            : Message.fromJson(obj['error'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!Message.canParse(obj['error'])) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (error != null) 'error': error,
      };
}

class EvaluateResponseBody {
  /// The number of indexed child variables.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? indexedVariables;

  /// A memory reference to a location appropriate for this result.
  /// For pointer type eval results, this is generally a reference to the memory
  /// address contained in the pointer.
  /// This attribute may be returned by a debug adapter if corresponding
  /// capability `supportsMemoryReferences` is true.
  final String? memoryReference;

  /// The number of named child variables.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? namedVariables;

  /// Properties of an evaluate result that can be used to determine how to
  /// render the result in the UI.
  final VariablePresentationHint? presentationHint;

  /// The result of the evaluate request.
  final String result;

  /// The type of the evaluate result.
  /// This attribute should only be returned by a debug adapter if the
  /// corresponding capability `supportsVariableType` is true.
  final String? type;

  /// A reference that allows the client to request the location where the
  /// returned value is declared. For example, if a function pointer is
  /// returned, the adapter may be able to look up the function's location. This
  /// should be present only if the adapter is likely to be able to resolve the
  /// location.
  ///
  /// This reference shares the same lifetime as the `variablesReference`. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int? valueLocationReference;

  /// If `variablesReference` is > 0, the evaluate result is structured and its
  /// children can be retrieved by passing `variablesReference` to the
  /// `variables` request as long as execution remains suspended. See 'Lifetime
  /// of Object References' in the Overview section for details.
  final int variablesReference;

  static EvaluateResponseBody fromJson(Map<String, Object?> obj) =>
      EvaluateResponseBody.fromMap(obj);

  EvaluateResponseBody({
    this.indexedVariables,
    this.memoryReference,
    this.namedVariables,
    this.presentationHint,
    required this.result,
    this.type,
    this.valueLocationReference,
    required this.variablesReference,
  });

  EvaluateResponseBody.fromMap(Map<String, Object?> obj)
      : indexedVariables = obj['indexedVariables'] as int?,
        memoryReference = obj['memoryReference'] as String?,
        namedVariables = obj['namedVariables'] as int?,
        presentationHint = obj['presentationHint'] == null
            ? null
            : VariablePresentationHint.fromJson(
                obj['presentationHint'] as Map<String, Object?>),
        result = obj['result'] as String,
        type = obj['type'] as String?,
        valueLocationReference = obj['valueLocationReference'] as int?,
        variablesReference = obj['variablesReference'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['indexedVariables'] is! int?) {
      return false;
    }
    if (obj['memoryReference'] is! String?) {
      return false;
    }
    if (obj['namedVariables'] is! int?) {
      return false;
    }
    if (!VariablePresentationHint.canParse(obj['presentationHint'])) {
      return false;
    }
    if (obj['result'] is! String) {
      return false;
    }
    if (obj['type'] is! String?) {
      return false;
    }
    if (obj['valueLocationReference'] is! int?) {
      return false;
    }
    if (obj['variablesReference'] is! int) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (indexedVariables != null) 'indexedVariables': indexedVariables,
        if (memoryReference != null) 'memoryReference': memoryReference,
        if (namedVariables != null) 'namedVariables': namedVariables,
        if (presentationHint != null) 'presentationHint': presentationHint,
        'result': result,
        if (type != null) 'type': type,
        if (valueLocationReference != null)
          'valueLocationReference': valueLocationReference,
        'variablesReference': variablesReference,
      };
}

class ExceptionInfoResponseBody {
  /// Mode that caused the exception notification to be raised.
  final ExceptionBreakMode breakMode;

  /// Descriptive text for the exception.
  final String? description;

  /// Detailed information about the exception.
  final ExceptionDetails? details;

  /// ID of the exception that was thrown.
  final String exceptionId;

  static ExceptionInfoResponseBody fromJson(Map<String, Object?> obj) =>
      ExceptionInfoResponseBody.fromMap(obj);

  ExceptionInfoResponseBody({
    required this.breakMode,
    this.description,
    this.details,
    required this.exceptionId,
  });

  ExceptionInfoResponseBody.fromMap(Map<String, Object?> obj)
      : breakMode = obj['breakMode'] as ExceptionBreakMode,
        description = obj['description'] as String?,
        details = obj['details'] == null
            ? null
            : ExceptionDetails.fromJson(obj['details'] as Map<String, Object?>),
        exceptionId = obj['exceptionId'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['breakMode'] is! ExceptionBreakMode) {
      return false;
    }
    if (obj['description'] is! String?) {
      return false;
    }
    if (!ExceptionDetails.canParse(obj['details'])) {
      return false;
    }
    if (obj['exceptionId'] is! String) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakMode': breakMode,
        if (description != null) 'description': description,
        if (details != null) 'details': details,
        'exceptionId': exceptionId,
      };
}

class ExitedEventBody extends EventBody {
  /// The exit code returned from the debuggee.
  final int exitCode;

  static ExitedEventBody fromJson(Map<String, Object?> obj) =>
      ExitedEventBody.fromMap(obj);

  ExitedEventBody({
    required this.exitCode,
  });

  ExitedEventBody.fromMap(Map<String, Object?> obj)
      : exitCode = obj['exitCode'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['exitCode'] is! int) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'exitCode': exitCode,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class GotoResponseBody {
  static GotoResponseBody fromJson(Map<String, Object?> obj) =>
      GotoResponseBody.fromMap(obj);

  GotoResponseBody();

  GotoResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class GotoTargetsResponseBody {
  /// The possible goto targets of the specified location.
  final List<GotoTarget> targets;

  static GotoTargetsResponseBody fromJson(Map<String, Object?> obj) =>
      GotoTargetsResponseBody.fromMap(obj);

  GotoTargetsResponseBody({
    required this.targets,
  });

  GotoTargetsResponseBody.fromMap(Map<String, Object?> obj)
      : targets = (obj['targets'] as List)
            .map((item) => GotoTarget.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['targets'] is! List ||
        (obj['targets'].any((item) => !GotoTarget.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'targets': targets,
      };
}

/// The capabilities of this debug adapter.
class InitializeResponseBody {
  static InitializeResponseBody fromJson(Map<String, Object?> obj) =>
      InitializeResponseBody.fromMap(obj);

  InitializeResponseBody();

  InitializeResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

/// Event-specific information.
class InitializedEventBody extends EventBody {
  static InitializedEventBody fromJson(Map<String, Object?> obj) =>
      InitializedEventBody.fromMap(obj);

  InitializedEventBody();

  InitializedEventBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {};
}

class InvalidatedEventBody extends EventBody {
  /// Set of logical areas that got invalidated. This property has a hint
  /// characteristic: a client can only be expected to make a 'best effort' in
  /// honoring the areas but there are no guarantees. If this property is
  /// missing, empty, or if values are not understood, the client should assume
  /// a single value `all`.
  final List<InvalidatedAreas>? areas;

  /// If specified, the client only needs to refetch data related to this stack
  /// frame (and the `threadId` is ignored).
  final int? stackFrameId;

  /// If specified, the client only needs to refetch data related to this
  /// thread.
  final int? threadId;

  static InvalidatedEventBody fromJson(Map<String, Object?> obj) =>
      InvalidatedEventBody.fromMap(obj);

  InvalidatedEventBody({
    this.areas,
    this.stackFrameId,
    this.threadId,
  });

  InvalidatedEventBody.fromMap(Map<String, Object?> obj)
      : areas = (obj['areas'] as List?)
            ?.map((item) => item as InvalidatedAreas)
            .toList(),
        stackFrameId = obj['stackFrameId'] as int?,
        threadId = obj['threadId'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['areas'] is! List ||
        (obj['areas'].any((item) => item is! InvalidatedAreas)))) {
      return false;
    }
    if (obj['stackFrameId'] is! int?) {
      return false;
    }
    if (obj['threadId'] is! int?) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (areas != null) 'areas': areas,
        if (stackFrameId != null) 'stackFrameId': stackFrameId,
        if (threadId != null) 'threadId': threadId,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class LaunchResponseBody {
  static LaunchResponseBody fromJson(Map<String, Object?> obj) =>
      LaunchResponseBody.fromMap(obj);

  LaunchResponseBody();

  LaunchResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class LoadedSourceEventBody extends EventBody {
  /// The reason for the event.
  final String reason;

  /// The new, changed, or removed source.
  final Source source;

  static LoadedSourceEventBody fromJson(Map<String, Object?> obj) =>
      LoadedSourceEventBody.fromMap(obj);

  LoadedSourceEventBody({
    required this.reason,
    required this.source,
  });

  LoadedSourceEventBody.fromMap(Map<String, Object?> obj)
      : reason = obj['reason'] as String,
        source = Source.fromJson(obj['source'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['reason'] is! String) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'reason': reason,
        'source': source,
      };
}

class LoadedSourcesResponseBody {
  /// Set of loaded sources.
  final List<Source> sources;

  static LoadedSourcesResponseBody fromJson(Map<String, Object?> obj) =>
      LoadedSourcesResponseBody.fromMap(obj);

  LoadedSourcesResponseBody({
    required this.sources,
  });

  LoadedSourcesResponseBody.fromMap(Map<String, Object?> obj)
      : sources = (obj['sources'] as List)
            .map((item) => Source.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['sources'] is! List ||
        (obj['sources'].any((item) => !Source.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'sources': sources,
      };
}

class LocationsResponseBody {
  /// Position of the location within the `line`. It is measured in UTF-16 code
  /// units and the client capability `columnsStartAt1` determines whether it is
  /// 0- or 1-based. If no column is given, the first position in the start line
  /// is assumed.
  final int? column;

  /// End position of the location within `endLine`, present if the location
  /// refers to a range. It is measured in UTF-16 code units and the client
  /// capability `columnsStartAt1` determines whether it is 0- or 1-based.
  final int? endColumn;

  /// End line of the location, present if the location refers to a range.  The
  /// client capability `linesStartAt1` determines whether it is 0- or 1-based.
  final int? endLine;

  /// The line number of the location. The client capability `linesStartAt1`
  /// determines whether it is 0- or 1-based.
  final int line;

  /// The source containing the location; either `source.path` or
  /// `source.sourceReference` must be specified.
  final Source source;

  static LocationsResponseBody fromJson(Map<String, Object?> obj) =>
      LocationsResponseBody.fromMap(obj);

  LocationsResponseBody({
    this.column,
    this.endColumn,
    this.endLine,
    required this.line,
    required this.source,
  });

  LocationsResponseBody.fromMap(Map<String, Object?> obj)
      : column = obj['column'] as int?,
        endColumn = obj['endColumn'] as int?,
        endLine = obj['endLine'] as int?,
        line = obj['line'] as int,
        source = Source.fromJson(obj['source'] as Map<String, Object?>);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['endColumn'] is! int?) {
      return false;
    }
    if (obj['endLine'] is! int?) {
      return false;
    }
    if (obj['line'] is! int) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (column != null) 'column': column,
        if (endColumn != null) 'endColumn': endColumn,
        if (endLine != null) 'endLine': endLine,
        'line': line,
        'source': source,
      };
}

class MemoryEventBody extends EventBody {
  /// Number of bytes updated.
  final int count;

  /// Memory reference of a memory range that has been updated.
  final String memoryReference;

  /// Starting offset in bytes where memory has been updated. Can be negative.
  final int offset;

  static MemoryEventBody fromJson(Map<String, Object?> obj) =>
      MemoryEventBody.fromMap(obj);

  MemoryEventBody({
    required this.count,
    required this.memoryReference,
    required this.offset,
  });

  MemoryEventBody.fromMap(Map<String, Object?> obj)
      : count = obj['count'] as int,
        memoryReference = obj['memoryReference'] as String,
        offset = obj['offset'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['count'] is! int) {
      return false;
    }
    if (obj['memoryReference'] is! String) {
      return false;
    }
    if (obj['offset'] is! int) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'count': count,
        'memoryReference': memoryReference,
        'offset': offset,
      };
}

class ModuleEventBody extends EventBody {
  /// The new, changed, or removed module. In case of `removed` only the module
  /// id is used.
  final Module module;

  /// The reason for the event.
  final String reason;

  static ModuleEventBody fromJson(Map<String, Object?> obj) =>
      ModuleEventBody.fromMap(obj);

  ModuleEventBody({
    required this.module,
    required this.reason,
  });

  ModuleEventBody.fromMap(Map<String, Object?> obj)
      : module = Module.fromJson(obj['module'] as Map<String, Object?>),
        reason = obj['reason'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (!Module.canParse(obj['module'])) {
      return false;
    }
    if (obj['reason'] is! String) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'module': module,
        'reason': reason,
      };
}

class ModulesResponseBody {
  /// All modules or range of modules.
  final List<Module> modules;

  /// The total number of modules available.
  final int? totalModules;

  static ModulesResponseBody fromJson(Map<String, Object?> obj) =>
      ModulesResponseBody.fromMap(obj);

  ModulesResponseBody({
    required this.modules,
    this.totalModules,
  });

  ModulesResponseBody.fromMap(Map<String, Object?> obj)
      : modules = (obj['modules'] as List)
            .map((item) => Module.fromJson(item as Map<String, Object?>))
            .toList(),
        totalModules = obj['totalModules'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['modules'] is! List ||
        (obj['modules'].any((item) => !Module.canParse(item))))) {
      return false;
    }
    if (obj['totalModules'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'modules': modules,
        if (totalModules != null) 'totalModules': totalModules,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class NextResponseBody {
  static NextResponseBody fromJson(Map<String, Object?> obj) =>
      NextResponseBody.fromMap(obj);

  NextResponseBody();

  NextResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class OutputEventBody extends EventBody {
  /// The output category. If not specified or if the category is not understood
  /// by the client, `console` is assumed.
  final String? category;

  /// The position in `line` where the output was produced. It is measured in
  /// UTF-16 code units and the client capability `columnsStartAt1` determines
  /// whether it is 0- or 1-based.
  final int? column;

  /// Additional data to report. For the `telemetry` category the data is sent
  /// to telemetry, for the other categories the data is shown in JSON format.
  final Object? data;

  /// Support for keeping an output log organized by grouping related messages.
  final String? group;

  /// The source location's line where the output was produced.
  final int? line;

  /// A reference that allows the client to request the location where the new
  /// value is declared. For example, if the logged value is function pointer,
  /// the adapter may be able to look up the function's location. This should be
  /// present only if the adapter is likely to be able to resolve the location.
  ///
  /// This reference shares the same lifetime as the `variablesReference`. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int? locationReference;

  /// The output to report.
  ///
  /// ANSI escape sequences may be used to influence text color and styling if
  /// `supportsANSIStyling` is present in both the adapter's `Capabilities` and
  /// the client's `InitializeRequestArguments`. A client may strip any
  /// unrecognized ANSI sequences.
  ///
  /// If the `supportsANSIStyling` capabilities are not both true, then the
  /// client should display the output literally.
  final String output;

  /// The source location where the output was produced.
  final Source? source;

  /// If an attribute `variablesReference` exists and its value is > 0, the
  /// output contains objects which can be retrieved by passing
  /// `variablesReference` to the `variables` request as long as execution
  /// remains suspended. See 'Lifetime of Object References' in the Overview
  /// section for details.
  final int? variablesReference;

  static OutputEventBody fromJson(Map<String, Object?> obj) =>
      OutputEventBody.fromMap(obj);

  OutputEventBody({
    this.category,
    this.column,
    this.data,
    this.group,
    this.line,
    this.locationReference,
    required this.output,
    this.source,
    this.variablesReference,
  });

  OutputEventBody.fromMap(Map<String, Object?> obj)
      : category = obj['category'] as String?,
        column = obj['column'] as int?,
        data = obj['data'],
        group = obj['group'] as String?,
        line = obj['line'] as int?,
        locationReference = obj['locationReference'] as int?,
        output = obj['output'] as String,
        source = obj['source'] == null
            ? null
            : Source.fromJson(obj['source'] as Map<String, Object?>),
        variablesReference = obj['variablesReference'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['category'] is! String?) {
      return false;
    }
    if (obj['column'] is! int?) {
      return false;
    }
    if (obj['group'] is! String?) {
      return false;
    }
    if (obj['line'] is! int?) {
      return false;
    }
    if (obj['locationReference'] is! int?) {
      return false;
    }
    if (obj['output'] is! String) {
      return false;
    }
    if (!Source.canParse(obj['source'])) {
      return false;
    }
    if (obj['variablesReference'] is! int?) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (category != null) 'category': category,
        if (column != null) 'column': column,
        if (data != null) 'data': data,
        if (group != null) 'group': group,
        if (line != null) 'line': line,
        if (locationReference != null) 'locationReference': locationReference,
        'output': output,
        if (source != null) 'source': source,
        if (variablesReference != null)
          'variablesReference': variablesReference,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class PauseResponseBody {
  static PauseResponseBody fromJson(Map<String, Object?> obj) =>
      PauseResponseBody.fromMap(obj);

  PauseResponseBody();

  PauseResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class ProcessEventBody extends EventBody {
  /// If true, the process is running on the same computer as the debug adapter.
  final bool? isLocalProcess;

  /// The logical name of the process. This is usually the full path to
  /// process's executable file. Example: /home/example/myproj/program.js.
  final String name;

  /// The size of a pointer or address for this process, in bits. This value may
  /// be used by clients when formatting addresses for display.
  final int? pointerSize;

  /// Describes how the debug engine started debugging this process.
  final String? startMethod;

  /// The process ID of the debugged process, as assigned by the operating
  /// system. This property should be omitted for logical processes that do not
  /// map to operating system processes on the machine.
  final int? systemProcessId;

  static ProcessEventBody fromJson(Map<String, Object?> obj) =>
      ProcessEventBody.fromMap(obj);

  ProcessEventBody({
    this.isLocalProcess,
    required this.name,
    this.pointerSize,
    this.startMethod,
    this.systemProcessId,
  });

  ProcessEventBody.fromMap(Map<String, Object?> obj)
      : isLocalProcess = obj['isLocalProcess'] as bool?,
        name = obj['name'] as String,
        pointerSize = obj['pointerSize'] as int?,
        startMethod = obj['startMethod'] as String?,
        systemProcessId = obj['systemProcessId'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['isLocalProcess'] is! bool?) {
      return false;
    }
    if (obj['name'] is! String) {
      return false;
    }
    if (obj['pointerSize'] is! int?) {
      return false;
    }
    if (obj['startMethod'] is! String?) {
      return false;
    }
    if (obj['systemProcessId'] is! int?) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (isLocalProcess != null) 'isLocalProcess': isLocalProcess,
        'name': name,
        if (pointerSize != null) 'pointerSize': pointerSize,
        if (startMethod != null) 'startMethod': startMethod,
        if (systemProcessId != null) 'systemProcessId': systemProcessId,
      };
}

class ProgressEndEventBody extends EventBody {
  /// More detailed progress message. If omitted, the previous message (if any)
  /// is used.
  final String? message;

  /// The ID that was introduced in the initial `ProgressStartEvent`.
  final String progressId;

  static ProgressEndEventBody fromJson(Map<String, Object?> obj) =>
      ProgressEndEventBody.fromMap(obj);

  ProgressEndEventBody({
    this.message,
    required this.progressId,
  });

  ProgressEndEventBody.fromMap(Map<String, Object?> obj)
      : message = obj['message'] as String?,
        progressId = obj['progressId'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['message'] is! String?) {
      return false;
    }
    if (obj['progressId'] is! String) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (message != null) 'message': message,
        'progressId': progressId,
      };
}

class ProgressStartEventBody extends EventBody {
  /// If true, the request that reports progress may be cancelled with a
  /// `cancel` request.
  /// So this property basically controls whether the client should use UX that
  /// supports cancellation.
  /// Clients that don't support cancellation are allowed to ignore the setting.
  final bool? cancellable;

  /// More detailed progress message.
  final String? message;

  /// Progress percentage to display (value range: 0 to 100). If omitted no
  /// percentage is shown.
  final num? percentage;

  /// An ID that can be used in subsequent `progressUpdate` and `progressEnd`
  /// events to make them refer to the same progress reporting.
  /// IDs must be unique within a debug session.
  final String progressId;

  /// The request ID that this progress report is related to. If specified a
  /// debug adapter is expected to emit progress events for the long running
  /// request until the request has been either completed or cancelled.
  /// If the request ID is omitted, the progress report is assumed to be related
  /// to some general activity of the debug adapter.
  final int? requestId;

  /// Short title of the progress reporting. Shown in the UI to describe the
  /// long running operation.
  final String title;

  static ProgressStartEventBody fromJson(Map<String, Object?> obj) =>
      ProgressStartEventBody.fromMap(obj);

  ProgressStartEventBody({
    this.cancellable,
    this.message,
    this.percentage,
    required this.progressId,
    this.requestId,
    required this.title,
  });

  ProgressStartEventBody.fromMap(Map<String, Object?> obj)
      : cancellable = obj['cancellable'] as bool?,
        message = obj['message'] as String?,
        percentage = obj['percentage'] as num?,
        progressId = obj['progressId'] as String,
        requestId = obj['requestId'] as int?,
        title = obj['title'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['cancellable'] is! bool?) {
      return false;
    }
    if (obj['message'] is! String?) {
      return false;
    }
    if (obj['percentage'] is! num?) {
      return false;
    }
    if (obj['progressId'] is! String) {
      return false;
    }
    if (obj['requestId'] is! int?) {
      return false;
    }
    if (obj['title'] is! String) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (cancellable != null) 'cancellable': cancellable,
        if (message != null) 'message': message,
        if (percentage != null) 'percentage': percentage,
        'progressId': progressId,
        if (requestId != null) 'requestId': requestId,
        'title': title,
      };
}

class ProgressUpdateEventBody extends EventBody {
  /// More detailed progress message. If omitted, the previous message (if any)
  /// is used.
  final String? message;

  /// Progress percentage to display (value range: 0 to 100). If omitted no
  /// percentage is shown.
  final num? percentage;

  /// The ID that was introduced in the initial `progressStart` event.
  final String progressId;

  static ProgressUpdateEventBody fromJson(Map<String, Object?> obj) =>
      ProgressUpdateEventBody.fromMap(obj);

  ProgressUpdateEventBody({
    this.message,
    this.percentage,
    required this.progressId,
  });

  ProgressUpdateEventBody.fromMap(Map<String, Object?> obj)
      : message = obj['message'] as String?,
        percentage = obj['percentage'] as num?,
        progressId = obj['progressId'] as String;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['message'] is! String?) {
      return false;
    }
    if (obj['percentage'] is! num?) {
      return false;
    }
    if (obj['progressId'] is! String) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (message != null) 'message': message,
        if (percentage != null) 'percentage': percentage,
        'progressId': progressId,
      };
}

class ReadMemoryResponseBody {
  /// The address of the first byte of data returned.
  /// Treated as a hex value if prefixed with `0x`, or as a decimal value
  /// otherwise.
  final String address;

  /// The bytes read from memory, encoded using base64. If the decoded length of
  /// `data` is less than the requested `count` in the original `readMemory`
  /// request, and `unreadableBytes` is zero or omitted, then the client should
  /// assume it's reached the end of readable memory.
  final String? data;

  /// The number of unreadable bytes encountered after the last successfully
  /// read byte.
  /// This can be used to determine the number of bytes that should be skipped
  /// before a subsequent `readMemory` request succeeds.
  final int? unreadableBytes;

  static ReadMemoryResponseBody fromJson(Map<String, Object?> obj) =>
      ReadMemoryResponseBody.fromMap(obj);

  ReadMemoryResponseBody({
    required this.address,
    this.data,
    this.unreadableBytes,
  });

  ReadMemoryResponseBody.fromMap(Map<String, Object?> obj)
      : address = obj['address'] as String,
        data = obj['data'] as String?,
        unreadableBytes = obj['unreadableBytes'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['address'] is! String) {
      return false;
    }
    if (obj['data'] is! String?) {
      return false;
    }
    if (obj['unreadableBytes'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'address': address,
        if (data != null) 'data': data,
        if (unreadableBytes != null) 'unreadableBytes': unreadableBytes,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class RestartFrameResponseBody {
  static RestartFrameResponseBody fromJson(Map<String, Object?> obj) =>
      RestartFrameResponseBody.fromMap(obj);

  RestartFrameResponseBody();

  RestartFrameResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

/// Contains request result if success is true and error details if success is
/// false.
class RestartResponseBody {
  static RestartResponseBody fromJson(Map<String, Object?> obj) =>
      RestartResponseBody.fromMap(obj);

  RestartResponseBody();

  RestartResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

/// Contains request result if success is true and error details if success is
/// false.
class ReverseContinueResponseBody {
  static ReverseContinueResponseBody fromJson(Map<String, Object?> obj) =>
      ReverseContinueResponseBody.fromMap(obj);

  ReverseContinueResponseBody();

  ReverseContinueResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class RunInTerminalResponseBody {
  /// The process ID. The value should be less than or equal to 2147483647
  /// (2^31-1).
  final int? processId;

  /// The process ID of the terminal shell. The value should be less than or
  /// equal to 2147483647 (2^31-1).
  final int? shellProcessId;

  static RunInTerminalResponseBody fromJson(Map<String, Object?> obj) =>
      RunInTerminalResponseBody.fromMap(obj);

  RunInTerminalResponseBody({
    this.processId,
    this.shellProcessId,
  });

  RunInTerminalResponseBody.fromMap(Map<String, Object?> obj)
      : processId = obj['processId'] as int?,
        shellProcessId = obj['shellProcessId'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['processId'] is! int?) {
      return false;
    }
    if (obj['shellProcessId'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (processId != null) 'processId': processId,
        if (shellProcessId != null) 'shellProcessId': shellProcessId,
      };
}

class ScopesResponseBody {
  /// The scopes of the stack frame. If the array has length zero, there are no
  /// scopes available.
  final List<Scope> scopes;

  static ScopesResponseBody fromJson(Map<String, Object?> obj) =>
      ScopesResponseBody.fromMap(obj);

  ScopesResponseBody({
    required this.scopes,
  });

  ScopesResponseBody.fromMap(Map<String, Object?> obj)
      : scopes = (obj['scopes'] as List)
            .map((item) => Scope.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['scopes'] is! List ||
        (obj['scopes'].any((item) => !Scope.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'scopes': scopes,
      };
}

class SetBreakpointsResponseBody {
  /// Information about the breakpoints.
  /// The array elements are in the same order as the elements of the
  /// `breakpoints` (or the deprecated `lines`) array in the arguments.
  final List<Breakpoint> breakpoints;

  static SetBreakpointsResponseBody fromJson(Map<String, Object?> obj) =>
      SetBreakpointsResponseBody.fromMap(obj);

  SetBreakpointsResponseBody({
    required this.breakpoints,
  });

  SetBreakpointsResponseBody.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) => Breakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !Breakpoint.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

class SetDataBreakpointsResponseBody {
  /// Information about the data breakpoints. The array elements correspond to
  /// the elements of the input argument `breakpoints` array.
  final List<Breakpoint> breakpoints;

  static SetDataBreakpointsResponseBody fromJson(Map<String, Object?> obj) =>
      SetDataBreakpointsResponseBody.fromMap(obj);

  SetDataBreakpointsResponseBody({
    required this.breakpoints,
  });

  SetDataBreakpointsResponseBody.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) => Breakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !Breakpoint.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

class SetExceptionBreakpointsResponseBody {
  /// Information about the exception breakpoints or filters.
  /// The breakpoints returned are in the same order as the elements of the
  /// `filters`, `filterOptions`, `exceptionOptions` arrays in the arguments. If
  /// both `filters` and `filterOptions` are given, the returned array must
  /// start with `filters` information first, followed by `filterOptions`
  /// information.
  final List<Breakpoint>? breakpoints;

  static SetExceptionBreakpointsResponseBody fromJson(
          Map<String, Object?> obj) =>
      SetExceptionBreakpointsResponseBody.fromMap(obj);

  SetExceptionBreakpointsResponseBody({
    this.breakpoints,
  });

  SetExceptionBreakpointsResponseBody.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List?)
            ?.map((item) => Breakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !Breakpoint.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (breakpoints != null) 'breakpoints': breakpoints,
      };
}

class SetExpressionResponseBody {
  /// The number of indexed child variables.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? indexedVariables;

  /// A memory reference to a location appropriate for this result.
  /// For pointer type eval results, this is generally a reference to the memory
  /// address contained in the pointer.
  /// This attribute may be returned by a debug adapter if corresponding
  /// capability `supportsMemoryReferences` is true.
  final String? memoryReference;

  /// The number of named child variables.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? namedVariables;

  /// Properties of a value that can be used to determine how to render the
  /// result in the UI.
  final VariablePresentationHint? presentationHint;

  /// The type of the value.
  /// This attribute should only be returned by a debug adapter if the
  /// corresponding capability `supportsVariableType` is true.
  final String? type;

  /// The new value of the expression.
  final String value;

  /// A reference that allows the client to request the location where the new
  /// value is declared. For example, if the new value is function pointer, the
  /// adapter may be able to look up the function's location. This should be
  /// present only if the adapter is likely to be able to resolve the location.
  ///
  /// This reference shares the same lifetime as the `variablesReference`. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int? valueLocationReference;

  /// If `variablesReference` is > 0, the evaluate result is structured and its
  /// children can be retrieved by passing `variablesReference` to the
  /// `variables` request as long as execution remains suspended. See 'Lifetime
  /// of Object References' in the Overview section for details.
  final int? variablesReference;

  static SetExpressionResponseBody fromJson(Map<String, Object?> obj) =>
      SetExpressionResponseBody.fromMap(obj);

  SetExpressionResponseBody({
    this.indexedVariables,
    this.memoryReference,
    this.namedVariables,
    this.presentationHint,
    this.type,
    required this.value,
    this.valueLocationReference,
    this.variablesReference,
  });

  SetExpressionResponseBody.fromMap(Map<String, Object?> obj)
      : indexedVariables = obj['indexedVariables'] as int?,
        memoryReference = obj['memoryReference'] as String?,
        namedVariables = obj['namedVariables'] as int?,
        presentationHint = obj['presentationHint'] == null
            ? null
            : VariablePresentationHint.fromJson(
                obj['presentationHint'] as Map<String, Object?>),
        type = obj['type'] as String?,
        value = obj['value'] as String,
        valueLocationReference = obj['valueLocationReference'] as int?,
        variablesReference = obj['variablesReference'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['indexedVariables'] is! int?) {
      return false;
    }
    if (obj['memoryReference'] is! String?) {
      return false;
    }
    if (obj['namedVariables'] is! int?) {
      return false;
    }
    if (!VariablePresentationHint.canParse(obj['presentationHint'])) {
      return false;
    }
    if (obj['type'] is! String?) {
      return false;
    }
    if (obj['value'] is! String) {
      return false;
    }
    if (obj['valueLocationReference'] is! int?) {
      return false;
    }
    if (obj['variablesReference'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (indexedVariables != null) 'indexedVariables': indexedVariables,
        if (memoryReference != null) 'memoryReference': memoryReference,
        if (namedVariables != null) 'namedVariables': namedVariables,
        if (presentationHint != null) 'presentationHint': presentationHint,
        if (type != null) 'type': type,
        'value': value,
        if (valueLocationReference != null)
          'valueLocationReference': valueLocationReference,
        if (variablesReference != null)
          'variablesReference': variablesReference,
      };
}

class SetFunctionBreakpointsResponseBody {
  /// Information about the breakpoints. The array elements correspond to the
  /// elements of the `breakpoints` array.
  final List<Breakpoint> breakpoints;

  static SetFunctionBreakpointsResponseBody fromJson(
          Map<String, Object?> obj) =>
      SetFunctionBreakpointsResponseBody.fromMap(obj);

  SetFunctionBreakpointsResponseBody({
    required this.breakpoints,
  });

  SetFunctionBreakpointsResponseBody.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) => Breakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !Breakpoint.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

class SetInstructionBreakpointsResponseBody {
  /// Information about the breakpoints. The array elements correspond to the
  /// elements of the `breakpoints` array.
  final List<Breakpoint> breakpoints;

  static SetInstructionBreakpointsResponseBody fromJson(
          Map<String, Object?> obj) =>
      SetInstructionBreakpointsResponseBody.fromMap(obj);

  SetInstructionBreakpointsResponseBody({
    required this.breakpoints,
  });

  SetInstructionBreakpointsResponseBody.fromMap(Map<String, Object?> obj)
      : breakpoints = (obj['breakpoints'] as List)
            .map((item) => Breakpoint.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['breakpoints'] is! List ||
        (obj['breakpoints'].any((item) => !Breakpoint.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'breakpoints': breakpoints,
      };
}

class SetVariableResponseBody {
  /// The number of indexed child variables.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? indexedVariables;

  /// A memory reference to a location appropriate for this result.
  /// For pointer type eval results, this is generally a reference to the memory
  /// address contained in the pointer.
  /// This attribute may be returned by a debug adapter if corresponding
  /// capability `supportsMemoryReferences` is true.
  final String? memoryReference;

  /// The number of named child variables.
  /// The client can use this information to present the variables in a paged UI
  /// and fetch them in chunks.
  /// The value should be less than or equal to 2147483647 (2^31-1).
  final int? namedVariables;

  /// The type of the new value. Typically shown in the UI when hovering over
  /// the value.
  final String? type;

  /// The new value of the variable.
  final String value;

  /// A reference that allows the client to request the location where the new
  /// value is declared. For example, if the new value is function pointer, the
  /// adapter may be able to look up the function's location. This should be
  /// present only if the adapter is likely to be able to resolve the location.
  ///
  /// This reference shares the same lifetime as the `variablesReference`. See
  /// 'Lifetime of Object References' in the Overview section for details.
  final int? valueLocationReference;

  /// If `variablesReference` is > 0, the new value is structured and its
  /// children can be retrieved by passing `variablesReference` to the
  /// `variables` request as long as execution remains suspended. See 'Lifetime
  /// of Object References' in the Overview section for details.
  ///
  /// If this property is included in the response, any `variablesReference`
  /// previously associated with the updated variable, and those of its
  /// children, are no longer valid.
  final int? variablesReference;

  static SetVariableResponseBody fromJson(Map<String, Object?> obj) =>
      SetVariableResponseBody.fromMap(obj);

  SetVariableResponseBody({
    this.indexedVariables,
    this.memoryReference,
    this.namedVariables,
    this.type,
    required this.value,
    this.valueLocationReference,
    this.variablesReference,
  });

  SetVariableResponseBody.fromMap(Map<String, Object?> obj)
      : indexedVariables = obj['indexedVariables'] as int?,
        memoryReference = obj['memoryReference'] as String?,
        namedVariables = obj['namedVariables'] as int?,
        type = obj['type'] as String?,
        value = obj['value'] as String,
        valueLocationReference = obj['valueLocationReference'] as int?,
        variablesReference = obj['variablesReference'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['indexedVariables'] is! int?) {
      return false;
    }
    if (obj['memoryReference'] is! String?) {
      return false;
    }
    if (obj['namedVariables'] is! int?) {
      return false;
    }
    if (obj['type'] is! String?) {
      return false;
    }
    if (obj['value'] is! String) {
      return false;
    }
    if (obj['valueLocationReference'] is! int?) {
      return false;
    }
    if (obj['variablesReference'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (indexedVariables != null) 'indexedVariables': indexedVariables,
        if (memoryReference != null) 'memoryReference': memoryReference,
        if (namedVariables != null) 'namedVariables': namedVariables,
        if (type != null) 'type': type,
        'value': value,
        if (valueLocationReference != null)
          'valueLocationReference': valueLocationReference,
        if (variablesReference != null)
          'variablesReference': variablesReference,
      };
}

class SourceResponseBody {
  /// Content of the source reference.
  final String content;

  /// Content type (MIME type) of the source.
  final String? mimeType;

  static SourceResponseBody fromJson(Map<String, Object?> obj) =>
      SourceResponseBody.fromMap(obj);

  SourceResponseBody({
    required this.content,
    this.mimeType,
  });

  SourceResponseBody.fromMap(Map<String, Object?> obj)
      : content = obj['content'] as String,
        mimeType = obj['mimeType'] as String?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['content'] is! String) {
      return false;
    }
    if (obj['mimeType'] is! String?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'content': content,
        if (mimeType != null) 'mimeType': mimeType,
      };
}

class StackTraceResponseBody {
  /// The frames of the stack frame. If the array has length zero, there are no
  /// stack frames available.
  /// This means that there is no location information available.
  final List<StackFrame> stackFrames;

  /// The total number of frames available in the stack. If omitted or if
  /// `totalFrames` is larger than the available frames, a client is expected to
  /// request frames until a request returns less frames than requested (which
  /// indicates the end of the stack). Returning monotonically increasing
  /// `totalFrames` values for subsequent requests can be used to enforce paging
  /// in the client.
  final int? totalFrames;

  static StackTraceResponseBody fromJson(Map<String, Object?> obj) =>
      StackTraceResponseBody.fromMap(obj);

  StackTraceResponseBody({
    required this.stackFrames,
    this.totalFrames,
  });

  StackTraceResponseBody.fromMap(Map<String, Object?> obj)
      : stackFrames = (obj['stackFrames'] as List)
            .map((item) => StackFrame.fromJson(item as Map<String, Object?>))
            .toList(),
        totalFrames = obj['totalFrames'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['stackFrames'] is! List ||
        (obj['stackFrames'].any((item) => !StackFrame.canParse(item))))) {
      return false;
    }
    if (obj['totalFrames'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'stackFrames': stackFrames,
        if (totalFrames != null) 'totalFrames': totalFrames,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class StartDebuggingResponseBody {
  static StartDebuggingResponseBody fromJson(Map<String, Object?> obj) =>
      StartDebuggingResponseBody.fromMap(obj);

  StartDebuggingResponseBody();

  StartDebuggingResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

/// Contains request result if success is true and error details if success is
/// false.
class StepBackResponseBody {
  static StepBackResponseBody fromJson(Map<String, Object?> obj) =>
      StepBackResponseBody.fromMap(obj);

  StepBackResponseBody();

  StepBackResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

/// Contains request result if success is true and error details if success is
/// false.
class StepInResponseBody {
  static StepInResponseBody fromJson(Map<String, Object?> obj) =>
      StepInResponseBody.fromMap(obj);

  StepInResponseBody();

  StepInResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class StepInTargetsResponseBody {
  /// The possible step-in targets of the specified source location.
  final List<StepInTarget> targets;

  static StepInTargetsResponseBody fromJson(Map<String, Object?> obj) =>
      StepInTargetsResponseBody.fromMap(obj);

  StepInTargetsResponseBody({
    required this.targets,
  });

  StepInTargetsResponseBody.fromMap(Map<String, Object?> obj)
      : targets = (obj['targets'] as List)
            .map((item) => StepInTarget.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['targets'] is! List ||
        (obj['targets'].any((item) => !StepInTarget.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'targets': targets,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class StepOutResponseBody {
  static StepOutResponseBody fromJson(Map<String, Object?> obj) =>
      StepOutResponseBody.fromMap(obj);

  StepOutResponseBody();

  StepOutResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class StoppedEventBody extends EventBody {
  /// If `allThreadsStopped` is true, a debug adapter can announce that all
  /// threads have stopped.
  /// - The client should use this information to enable that all threads can be expanded to access their stacktraces.
  /// - If the attribute is missing or false, only the thread with the given `threadId` can be expanded.
  final bool? allThreadsStopped;

  /// The full reason for the event, e.g. 'Paused on exception'. This string is
  /// shown in the UI as is and can be translated.
  final String? description;

  /// Ids of the breakpoints that triggered the event. In most cases there is
  /// only a single breakpoint but here are some examples for multiple
  /// breakpoints:
  /// - Different types of breakpoints map to the same location.
  /// - Multiple source breakpoints get collapsed to the same instruction by the compiler/runtime.
  /// - Multiple function breakpoints with different function names map to the same location.
  final List<int>? hitBreakpointIds;

  /// A value of true hints to the client that this event should not change the
  /// focus.
  final bool? preserveFocusHint;

  /// The reason for the event.
  /// For backward compatibility this string is shown in the UI if the
  /// `description` attribute is missing (but it must not be translated).
  final String reason;

  /// Additional information. E.g. if reason is `exception`, text contains the
  /// exception name. This string is shown in the UI.
  final String? text;

  /// The thread which was stopped.
  final int? threadId;

  static StoppedEventBody fromJson(Map<String, Object?> obj) =>
      StoppedEventBody.fromMap(obj);

  StoppedEventBody({
    this.allThreadsStopped,
    this.description,
    this.hitBreakpointIds,
    this.preserveFocusHint,
    required this.reason,
    this.text,
    this.threadId,
  });

  StoppedEventBody.fromMap(Map<String, Object?> obj)
      : allThreadsStopped = obj['allThreadsStopped'] as bool?,
        description = obj['description'] as String?,
        hitBreakpointIds = (obj['hitBreakpointIds'] as List?)
            ?.map((item) => item as int)
            .toList(),
        preserveFocusHint = obj['preserveFocusHint'] as bool?,
        reason = obj['reason'] as String,
        text = obj['text'] as String?,
        threadId = obj['threadId'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['allThreadsStopped'] is! bool?) {
      return false;
    }
    if (obj['description'] is! String?) {
      return false;
    }
    if ((obj['hitBreakpointIds'] is! List ||
        (obj['hitBreakpointIds'].any((item) => item is! int)))) {
      return false;
    }
    if (obj['preserveFocusHint'] is! bool?) {
      return false;
    }
    if (obj['reason'] is! String) {
      return false;
    }
    if (obj['text'] is! String?) {
      return false;
    }
    if (obj['threadId'] is! int?) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (allThreadsStopped != null) 'allThreadsStopped': allThreadsStopped,
        if (description != null) 'description': description,
        if (hitBreakpointIds != null) 'hitBreakpointIds': hitBreakpointIds,
        if (preserveFocusHint != null) 'preserveFocusHint': preserveFocusHint,
        'reason': reason,
        if (text != null) 'text': text,
        if (threadId != null) 'threadId': threadId,
      };
}

/// Contains request result if success is true and error details if success is
/// false.
class TerminateResponseBody {
  static TerminateResponseBody fromJson(Map<String, Object?> obj) =>
      TerminateResponseBody.fromMap(obj);

  TerminateResponseBody();

  TerminateResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

/// Contains request result if success is true and error details if success is
/// false.
class TerminateThreadsResponseBody {
  static TerminateThreadsResponseBody fromJson(Map<String, Object?> obj) =>
      TerminateThreadsResponseBody.fromMap(obj);

  TerminateThreadsResponseBody();

  TerminateThreadsResponseBody.fromMap(Map<String, Object?> obj);

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {};
}

class TerminatedEventBody extends EventBody {
  /// A debug adapter may set `restart` to true (or to an arbitrary object) to
  /// request that the client restarts the session.
  /// The value is not interpreted by the client and passed unmodified as an
  /// attribute `__restart` to the `launch` and `attach` requests.
  final Object? restart;

  static TerminatedEventBody fromJson(Map<String, Object?> obj) =>
      TerminatedEventBody.fromMap(obj);

  TerminatedEventBody({
    this.restart,
  });

  TerminatedEventBody.fromMap(Map<String, Object?> obj)
      : restart = obj['restart'];

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        if (restart != null) 'restart': restart,
      };
}

class ThreadEventBody extends EventBody {
  /// The reason for the event.
  final String reason;

  /// The identifier of the thread.
  final int threadId;

  static ThreadEventBody fromJson(Map<String, Object?> obj) =>
      ThreadEventBody.fromMap(obj);

  ThreadEventBody({
    required this.reason,
    required this.threadId,
  });

  ThreadEventBody.fromMap(Map<String, Object?> obj)
      : reason = obj['reason'] as String,
        threadId = obj['threadId'] as int;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['reason'] is! String) {
      return false;
    }
    if (obj['threadId'] is! int) {
      return false;
    }
    return EventBody.canParse(obj);
  }

  Map<String, Object?> toJson() => {
        'reason': reason,
        'threadId': threadId,
      };
}

class ThreadsResponseBody {
  /// All threads.
  final List<Thread> threads;

  static ThreadsResponseBody fromJson(Map<String, Object?> obj) =>
      ThreadsResponseBody.fromMap(obj);

  ThreadsResponseBody({
    required this.threads,
  });

  ThreadsResponseBody.fromMap(Map<String, Object?> obj)
      : threads = (obj['threads'] as List)
            .map((item) => Thread.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['threads'] is! List ||
        (obj['threads'].any((item) => !Thread.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'threads': threads,
      };
}

class VariablesResponseBody {
  /// All (or a range) of variables for the given variable reference.
  final List<Variable> variables;

  static VariablesResponseBody fromJson(Map<String, Object?> obj) =>
      VariablesResponseBody.fromMap(obj);

  VariablesResponseBody({
    required this.variables,
  });

  VariablesResponseBody.fromMap(Map<String, Object?> obj)
      : variables = (obj['variables'] as List)
            .map((item) => Variable.fromJson(item as Map<String, Object?>))
            .toList();

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if ((obj['variables'] is! List ||
        (obj['variables'].any((item) => !Variable.canParse(item))))) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'variables': variables,
      };
}

class WriteMemoryResponseBody {
  /// Property that should be returned when `allowPartial` is true to indicate
  /// the number of bytes starting from address that were successfully written.
  final int? bytesWritten;

  /// Property that should be returned when `allowPartial` is true to indicate
  /// the offset of the first byte of data successfully written. Can be
  /// negative.
  final int? offset;

  static WriteMemoryResponseBody fromJson(Map<String, Object?> obj) =>
      WriteMemoryResponseBody.fromMap(obj);

  WriteMemoryResponseBody({
    this.bytesWritten,
    this.offset,
  });

  WriteMemoryResponseBody.fromMap(Map<String, Object?> obj)
      : bytesWritten = obj['bytesWritten'] as int?,
        offset = obj['offset'] as int?;

  static bool canParse(Object? obj) {
    if (obj is! Map<String, dynamic>) {
      return false;
    }
    if (obj['bytesWritten'] is! int?) {
      return false;
    }
    if (obj['offset'] is! int?) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (bytesWritten != null) 'bytesWritten': bytesWritten,
        if (offset != null) 'offset': offset,
      };
}

const eventTypes = {
  BreakpointEventBody: 'breakpoint',
  CapabilitiesEventBody: 'capabilities',
  ContinuedEventBody: 'continued',
  ExitedEventBody: 'exited',
  InitializedEventBody: 'initialized',
  InvalidatedEventBody: 'invalidated',
  LoadedSourceEventBody: 'loadedSource',
  MemoryEventBody: 'memory',
  ModuleEventBody: 'module',
  OutputEventBody: 'output',
  ProcessEventBody: 'process',
  ProgressEndEventBody: 'progressEnd',
  ProgressStartEventBody: 'progressStart',
  ProgressUpdateEventBody: 'progressUpdate',
  StoppedEventBody: 'stopped',
  TerminatedEventBody: 'terminated',
  ThreadEventBody: 'thread',
};

const commandTypes = {
  AttachRequestArguments: 'attach',
  BreakpointLocationsArguments: 'breakpointLocations',
  CancelArguments: 'cancel',
  CompletionsArguments: 'completions',
  ConfigurationDoneArguments: 'configurationDone',
  ContinueArguments: 'continue',
  DartInitializeRequestArguments: 'initialize',
  DataBreakpointInfoArguments: 'dataBreakpointInfo',
  DisassembleArguments: 'disassemble',
  DisconnectArguments: 'disconnect',
  EvaluateArguments: 'evaluate',
  ExceptionInfoArguments: 'exceptionInfo',
  GotoArguments: 'goto',
  GotoTargetsArguments: 'gotoTargets',
  InitializeRequestArguments: 'initialize',
  LaunchRequestArguments: 'launch',
  LoadedSourcesArguments: 'loadedSources',
  LocationsArguments: 'locations',
  ModulesArguments: 'modules',
  NextArguments: 'next',
  PauseArguments: 'pause',
  ReadMemoryArguments: 'readMemory',
  RestartFrameArguments: 'restartFrame',
  RestartArguments: 'restart',
  ReverseContinueArguments: 'reverseContinue',
  RunInTerminalRequestArguments: 'runInTerminal',
  ScopesArguments: 'scopes',
  SetBreakpointsArguments: 'setBreakpoints',
  SetDataBreakpointsArguments: 'setDataBreakpoints',
  SetExceptionBreakpointsArguments: 'setExceptionBreakpoints',
  SetExpressionArguments: 'setExpression',
  SetFunctionBreakpointsArguments: 'setFunctionBreakpoints',
  SetInstructionBreakpointsArguments: 'setInstructionBreakpoints',
  SetVariableArguments: 'setVariable',
  SourceArguments: 'source',
  StackTraceArguments: 'stackTrace',
  StartDebuggingRequestArguments: 'startDebugging',
  StepBackArguments: 'stepBack',
  StepInArguments: 'stepIn',
  StepInTargetsArguments: 'stepInTargets',
  StepOutArguments: 'stepOut',
  TerminateArguments: 'terminate',
  TerminateThreadsArguments: 'terminateThreads',
  VariablesArguments: 'variables',
  WriteMemoryArguments: 'writeMemory',
};
