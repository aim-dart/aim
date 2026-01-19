import 'dart:convert';
import 'dart:typed_data';

class NoticeMessage {
  final String severity;
  final String? code;
  final String message;
  final String? detail;
  final String? hint;
  final Map<String, String> allFields;

  NoticeMessage._({
    required this.severity,
    this.code,
    required this.message,
    this.detail,
    this.hint,
    required this.allFields,
  });

  static NoticeMessage fromPayload(Uint8List payload) {
    var offset = 0;
    final fields = <String, String>{};

    // フィールドを順次解析（Byte1 タイプコード + null終端文字列）
    while (offset < payload.length && payload[offset] != 0) {
      final fieldType = String.fromCharCode(payload[offset]);
      offset++;

      // null終端文字列を探す
      final endIndex = payload.indexOf(0, offset);
      if (endIndex == -1) break;

      final fieldValue = utf8.decode(payload.sublist(offset, endIndex));
      fields[fieldType] = fieldValue;

      offset = endIndex + 1; // nullバイトの次へ
    }

    return NoticeMessage._(
      severity: fields['S'] ?? fields['V'] ?? 'UNKNOWN',
      code: fields['C'],
      message: fields['M'] ?? 'Unknown notice',
      detail: fields['D'],
      hint: fields['H'],
      allFields: fields,
    );
  }

  @override
  String toString() {
    return {
      'severity': severity,
      'code': code,
      'message': message,
      'detail': detail,
      'hint': hint,
    }.toString();
  }
}