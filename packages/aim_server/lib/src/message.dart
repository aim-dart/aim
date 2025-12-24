import 'dart:async';
import 'dart:convert';

import 'package:aim_server/src/body.dart';

/// Mixin that provides common functionality for HTTP messages.
///
/// This mixin provides headers, context, and body management that can be
/// shared between Request and Response classes.
mixin MessageMixin {
  /// The HTTP headers.
  Map<String, String> get headers;

  /// Extra context that can be used by middleware and handlers.
  ///
  /// For requests, this is used to pass data to inner middleware and handlers;
  /// for responses, it's used to pass data to outer middleware and handlers.
  Map<String, Object> get context;

  /// The streaming body of the message.
  Body get body;

  /// If `true`, the stream returned by [read] won't emit any bytes.
  bool get isEmpty => body.contentLength == 0;

  /// The contents of the content-length field in [headers].
  ///
  /// If not set, `null`.
  int? get contentLength {
    if (!headers.containsKey('content-length')) return null;
    return int.tryParse(headers['content-length']!);
  }

  /// Returns a [Stream] representing the body.
  ///
  /// Can only be called once.
  Stream<List<int>> read() => body.read();

  /// Returns a [Future] containing the body as a String.
  ///
  /// If [encoding] is passed, that's used to decode the body.
  /// Otherwise UTF-8 is used.
  ///
  /// This calls [read] internally, which can only be called once.
  Future<String> readAsString([Encoding? encoding]) {
    encoding ??= utf8;
    return encoding.decodeStream(read());
  }
}
