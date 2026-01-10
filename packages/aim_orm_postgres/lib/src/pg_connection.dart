import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aim_orm_postgres/src/util.dart';
import 'package:crypto/crypto.dart';

enum PostgresMessageType {
  authentication('R'),
  parameterStatus('S'),
  backendKeyData('K'),
  readyForQuery('Z'),
  errorResponse('E'),
  rowDescription('T'),
  dataRow('D'),
  commandComplete('C'),
  parse('P'),
  parseComplete('1'),
  bindComplete('2'),
  noData('n'),
  unknown('?');

  final String code;

  const PostgresMessageType(this.code);

  static PostgresMessageType fromCode(String code) {
    return PostgresMessageType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PostgresMessageType.unknown,
    );
  }
}

/// クエリ実行結果
class QueryResult {
  QueryResult({required this.columns, required this.rows});

  final List<Map<String, dynamic>> columns;
  final List<List<dynamic>> rows;

  /// 行データをMap形式に変換
  List<Map<String, dynamic>> toMaps() {
    return rows.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < columns.length; i++) {
        map[columns[i]['name'] as String] = row[i];
      }
      return map;
    }).toList();
  }
}

/// クエリ実行エラー
class QueryException implements Exception {
  QueryException(this.message);

  final String message;

  @override
  String toString() => 'QueryException: $message';
}

enum PostgresAuthenticationType {
  ok(0),
  cleartextPassword(3),
  md5Password(5),
  scram(10),
  unknown(-1);

  const PostgresAuthenticationType(this.code);

  final int code;

  static PostgresAuthenticationType fromCode(int code) {
    return PostgresAuthenticationType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => PostgresAuthenticationType.unknown,
    );
  }
}

class PostgresConnection {
  PostgresConnection._(
    this._uri,
    this._socket,
    this._iterator,
    this._messageBuffer,
  );

  final Uri _uri;
  final Socket _socket;
  final StreamIterator<Uint8List> _iterator;
  final BytesBuilder _messageBuffer;

  static Future<PostgresConnection> connect(String connectionString) async {
    final uri = Uri.parse(connectionString);
    final socket = await Socket.connect(uri.host, uri.port);
    final iterator = StreamIterator<Uint8List>(socket);
    final messageBuffer = BytesBuilder();

    final conn = PostgresConnection._(uri, socket, iterator, messageBuffer);

    await conn._authenticate();

    return conn;
  }

  /// ReadyForQueryメッセージまでのメッセージシーケンスを受信（結果を返す用）
  Future<List<Uint8List>> _receiveUntilReady() async {
    final messages = <Uint8List>[];

    while (true) {
      final message = await _receiveMessage(_iterator, _messageBuffer);
      messages.add(message);

      final messageType = PostgresMessageType.fromCode(
        String.fromCharCode(message[0]),
      );

      if (messageType == PostgresMessageType.readyForQuery) {
        break;
      }
    }

    return messages;
  }

  Future<Uint8List> _receiveMessage(
    StreamIterator<Uint8List> iterator,
    BytesBuilder messageBuffer,
  ) async {
    while (true) {
      final bytes = messageBuffer.toBytes();

      if (bytes.length < 5) {
        final hasNext = await iterator.moveNext();
        if (!hasNext) {
          throw Exception('Stream ended unexpectedly');
        }
        messageBuffer.add(iterator.current);
        continue;
      }

      final length = bytesToInt32(bytes.sublist(1, 5));
      final totalLength = 1 + length;

      if (bytes.length < totalLength) {
        final hasNext = await iterator.moveNext();
        if (!hasNext) {
          throw Exception('Stream ended unexpectedly');
        }
        messageBuffer.add(iterator.current);
        continue;
      }

      final message = bytes.sublist(0, totalLength);
      messageBuffer.clear();
      if (bytes.length > totalLength) {
        messageBuffer.add(bytes.sublist(totalLength));
      }

      return message;
    }
  }

  Future<void> close() async {
    await _iterator.cancel();
    await _socket.close();
  }
}

extension PostgresConnectionAuthenticator on PostgresConnection {
  Future<void> _authenticate() async {
    // スタートアップメッセージ送信
    final parts = _uri.userInfo.split(':');
    final username = parts[0];

    final startupMessage = BytesBuilder();
    final version = 196608; // Protocol version 3.0

    final params = {'user': username, 'database': _uri.path.substring(1)};
    final paramsBytes = BytesBuilder();
    for (final entry in params.entries) {
      paramsBytes.add(utf8.encode(entry.key));
      paramsBytes.addByte(0);
      paramsBytes.add(utf8.encode(entry.value));
      paramsBytes.addByte(0);
    }
    paramsBytes.addByte(0); // Terminating null byte

    final messageLength =
        4 + 4 + paramsBytes.length; // Length + version + params

    startupMessage.add(int32Bytes(messageLength));
    startupMessage.add(int32Bytes(version));
    startupMessage.add(paramsBytes.toBytes());

    _socket.add(startupMessage.toBytes());
    await _socket.flush();

    // ReadyForQueryまで受信しながら即座に処理（パスワード送信などが必要）
    while (true) {
      final message = await _receiveMessage(_iterator, _messageBuffer);

      final messageType = PostgresMessageType.fromCode(
        String.fromCharCode(message[0]),
      );

      // エラーレスポンスの処理
      if (messageType == PostgresMessageType.errorResponse) {
        final errorMessage = _parseErrorResponse(message.sublist(5));
        throw QueryException(errorMessage);
      }

      // 認証メッセージのみ処理（パスワード送信が必要）
      if (messageType == PostgresMessageType.authentication) {
        final payload = message.sublist(5);
        await _handleAuthentication(payload, _socket);
      }

      if (messageType == PostgresMessageType.readyForQuery) {
        break;
      }
    }
  }

  /// ErrorResponseメッセージからエラーメッセージを抽出
  String _parseErrorResponse(Uint8List payload) {
    var offset = 0;
    final fields = <String, String>{};

    // フィールドを順に解析（Byte1のタイプコード + Null終端文字列）
    while (offset < payload.length && payload[offset] != 0) {
      final fieldType = String.fromCharCode(payload[offset]);
      offset++;

      // Null終端文字列を探す
      final endIndex = payload.indexOf(0, offset);
      if (endIndex == -1) break;

      final fieldValue = utf8.decode(payload.sublist(offset, endIndex));
      fields[fieldType] = fieldValue;

      offset = endIndex + 1; // Nullバイトの次へ
    }

    // 'M'フィールド（メッセージ）を優先、なければ'S'（Severity）を使用
    return fields['M'] ?? fields['S'] ?? 'Unknown error';
  }

  Future<void> _handleAuthentication(Uint8List payload, Socket socket) async {
    final authTypeCode = bytesToInt32(payload.sublist(0, 4));
    final authType = PostgresAuthenticationType.fromCode(authTypeCode);

    switch (authType) {
      case PostgresAuthenticationType.ok:
        // 認証成功
        break;
      case PostgresAuthenticationType.cleartextPassword:
        await _sendCleartextPasswordMessage(_uri.userInfo.split(':')[1]);
        break;
      case PostgresAuthenticationType.md5Password:
        final salt = payload.sublist(4, 8);
        await _sendMd5PasswordMessage(
          _uri.userInfo.split(':')[0],
          _uri.userInfo.split(':')[1],
          salt,
        );
      case PostgresAuthenticationType.scram:
        // TODO: SCRAM実装
        throw UnimplementedError('SCRAM authentication not yet supported');
      case PostgresAuthenticationType.unknown:
        throw Exception('Unsupported authentication type: $authTypeCode');
    }
  }

  Future<void> _sendCleartextPasswordMessage(String password) async {
    final builder = BytesBuilder();

    builder.addByte('p'.codeUnitAt(0));

    final passwordBytes = utf8.encode(password);
    final messageLength =
        4 + passwordBytes.length + 1; // length + password + null

    builder.add(int32Bytes(messageLength));
    builder.add(passwordBytes);
    builder.addByte(0); // null terminator

    _socket.add(builder.toBytes());
    await _socket.flush();
  }

  Future<void> _sendMd5PasswordMessage(
    String username,
    String password,
    Uint8List salt,
  ) async {
    final builder = BytesBuilder();
    builder.addByte('p'.codeUnitAt(0));

    final inner = Uint8List.fromList(
      md5.convert(utf8.encode(password + username)).bytes,
    );
    final innerHex = bytesToHex(inner);

    final combined = BytesBuilder();
    combined.add(utf8.encode(innerHex));
    combined.add(salt);

    final outer = Uint8List.fromList(
      md5.convert(combined.toBytes()).bytes,
    );
    final md5Password = 'md5${bytesToHex(outer)}';

    final passwordBytes = utf8.encode(md5Password);
    final messageLength = 4 + passwordBytes.length + 1; // length + password + null

    builder.add(int32Bytes(messageLength));
    builder.add(passwordBytes);
    builder.addByte(0); // null terminator

    _socket.add(builder.toBytes());
    await _socket.flush();
  }
}

/// メッセージパーシング用の共通関数
extension PostgresConnectionMessageParser on PostgresConnection {
  /// メッセージシーケンスからクエリ結果を抽出
  QueryResult parseQueryResult(List<Uint8List> messages) {
    List<Map<String, dynamic>>? columns;
    final rows = <List<dynamic>>[];

    for (final msg in messages) {
      final messageType = PostgresMessageType.fromCode(
        String.fromCharCode(msg[0]),
      );

      switch (messageType) {
        case PostgresMessageType.rowDescription:
          columns = parseRowDescription(msg.sublist(5));
          break;
        case PostgresMessageType.dataRow:
          rows.add(parseDataRow(msg.sublist(5)));
          break;
        case PostgresMessageType.errorResponse:
          throw QueryException(utf8.decode(msg.sublist(5)));
        case PostgresMessageType.commandComplete:
        case PostgresMessageType.parseComplete:
        case PostgresMessageType.bindComplete:
        case PostgresMessageType.noData:
        case PostgresMessageType.readyForQuery:
          // これらは無視
          break;
        default:
          // その他のメッセージは無視
          break;
      }
    }

    return QueryResult(columns: columns ?? [], rows: rows);
  }

  /// RowDescriptionメッセージをパース
  List<Map<String, dynamic>> parseRowDescription(Uint8List payload) {
    var offset = 0;

    // カラム数
    final fieldCount = bytesToInt16(payload.sublist(offset, offset + 2));
    offset += 2;

    final columns = <Map<String, dynamic>>[];

    for (var i = 0; i < fieldCount; i++) {
      // カラム名（null終端）
      final nameEnd = payload.indexOf(0, offset);
      final name = utf8.decode(payload.sublist(offset, nameEnd));
      offset = nameEnd + 1;

      // テーブルOID（4バイト）
      final tableOid = bytesToInt32(payload.sublist(offset, offset + 4));
      offset += 4;

      // カラム属性番号（2バイト）
      final columnAttr = bytesToInt16(payload.sublist(offset, offset + 2));
      offset += 2;

      // 型OID（4バイト）
      final typeOid = bytesToInt32(payload.sublist(offset, offset + 4));
      offset += 4;

      // 型サイズ（2バイト）
      final typeSize = bytesToInt16(payload.sublist(offset, offset + 2));
      offset += 2;

      // 型修飾子（4バイト）
      final typeMod = bytesToInt32(payload.sublist(offset, offset + 4));
      offset += 4;

      // フォーマットコード（2バイト）
      final formatCode = bytesToInt16(payload.sublist(offset, offset + 2));
      offset += 2;

      columns.add({
        'name': name,
        'tableOid': tableOid,
        'columnAttr': columnAttr,
        'typeOid': typeOid,
        'typeSize': typeSize,
        'typeMod': typeMod,
        'formatCode': formatCode,
      });
    }

    return columns;
  }

  /// DataRowメッセージをパース
  List<dynamic> parseDataRow(Uint8List payload) {
    var offset = 0;

    // カラム数
    final columnCount = bytesToInt16(payload.sublist(offset, offset + 2));
    offset += 2;

    final values = <dynamic>[];

    for (var i = 0; i < columnCount; i++) {
      // 値の長さ
      final valueLength = bytesToInt32(payload.sublist(offset, offset + 4));
      offset += 4;

      if (valueLength == -1) {
        // NULL値
        values.add(null);
      } else {
        // 値のデータ（テキスト形式）
        final valueBytes = payload.sublist(offset, offset + valueLength);
        final value = utf8.decode(valueBytes);
        values.add(value);
        offset += valueLength;
      }
    }

    return values;
  }
}

extension PostgresConnectionSimpleQuery on PostgresConnection {
  /// クエリを実行して結果を返す
  Future<QueryResult> sendSimpleQuery(String sql) async {
    final builder = BytesBuilder();
    builder.addByte('Q'.codeUnitAt(0));

    final sqlBytes = utf8.encode(sql);
    final messageLength = 4 + sqlBytes.length + 1; // length + SQL + null

    builder.add(int32Bytes(messageLength));
    builder.add(sqlBytes);
    builder.addByte(0); // null terminator

    _socket.add(builder.toBytes());
    await _socket.flush();

    // メッセージを受信
    final messages = await _receiveUntilReady();

    // 結果をパース
    return parseQueryResult(messages);
  }
}

extension PostgresConnectionExtendedQuery on PostgresConnection {
  /// Extended Query Protocolでクエリを実行（パラメータ化クエリ）
  Future<QueryResult> sendExtendedQuery(
    String sql,
    List<dynamic> parameters,
  ) async {
    // 1. Parse メッセージ送信
    await _sendParse(sql, parameters.length);

    // 2. Bind メッセージ送信
    await _sendBind(parameters);

    // 3. Describe メッセージ送信（Portal）
    await _sendDescribe('P');

    // 4. Execute メッセージ送信
    await _sendExecute();

    // 5. Sync メッセージ送信
    await _sendSync();

    // 6. ReadyForQueryまでメッセージを受信
    final messages = await _receiveUntilReady();

    // 7. 結果をパース
    return parseQueryResult(messages);
  }

  /// Parse メッセージ送信
  Future<void> _sendParse(String sql, int paramCount) async {
    final builder = BytesBuilder();

    // メッセージタイプ 'P'
    builder.addByte('P'.codeUnitAt(0));

    // ペイロード構築
    final payload = BytesBuilder();

    // Prepared statement名（unnamed = ""）
    payload.addByte(0);

    // SQLクエリ（null終端）
    payload.add(utf8.encode(sql));
    payload.addByte(0);

    // パラメータ型OIDの数（0 = サーバーが推測）
    payload.add(int16Bytes(0));

    // メッセージ長（4バイト自身を含む）
    final messageLength = 4 + payload.length;
    builder.add(int32Bytes(messageLength));
    builder.add(payload.toBytes());

    _socket.add(builder.toBytes());
    await _socket.flush();
  }

  /// Bind メッセージ送信
  Future<void> _sendBind(List<dynamic> parameters) async {
    final builder = BytesBuilder();

    // メッセージタイプ 'B'
    builder.addByte('B'.codeUnitAt(0));

    // ペイロード構築
    final payload = BytesBuilder();

    // Portal名（unnamed = ""）
    payload.addByte(0);

    // Prepared statement名（unnamed = ""）
    payload.addByte(0);

    // パラメータフォーマットコード数（すべてテキスト形式 = 0）
    payload.add(int16Bytes(0));

    // パラメータ値の数
    payload.add(int16Bytes(parameters.length));

    // 各パラメータ値
    for (final param in parameters) {
      final encoded = _encodeParameter(param);
      if (encoded == null) {
        // NULL値
        payload.add(int32Bytes(-1));
      } else {
        payload.add(int32Bytes(encoded.length));
        payload.add(encoded);
      }
    }

    // 結果カラムフォーマットコード数（すべてテキスト形式 = 0）
    payload.add(int16Bytes(0));

    // メッセージ長
    final messageLength = 4 + payload.length;
    builder.add(int32Bytes(messageLength));
    builder.add(payload.toBytes());

    _socket.add(builder.toBytes());
    await _socket.flush();
  }

  /// Describe メッセージ送信
  Future<void> _sendDescribe(String type) async {
    final builder = BytesBuilder();

    // メッセージタイプ 'D'
    builder.addByte('D'.codeUnitAt(0));

    // ペイロード
    final payload = BytesBuilder();

    // 'S' = Statement, 'P' = Portal
    payload.addByte(type.codeUnitAt(0));

    // 名前（unnamed = ""）
    payload.addByte(0);

    // メッセージ長
    final messageLength = 4 + payload.length;
    builder.add(int32Bytes(messageLength));
    builder.add(payload.toBytes());

    _socket.add(builder.toBytes());
    await _socket.flush();
  }

  /// Execute メッセージ送信
  Future<void> _sendExecute() async {
    final builder = BytesBuilder();

    // メッセージタイプ 'E'
    builder.addByte('E'.codeUnitAt(0));

    // ペイロード
    final payload = BytesBuilder();

    // Portal名（unnamed = ""）
    payload.addByte(0);

    // 最大行数（0 = 無制限）
    payload.add(int32Bytes(0));

    // メッセージ長
    final messageLength = 4 + payload.length;
    builder.add(int32Bytes(messageLength));
    builder.add(payload.toBytes());

    _socket.add(builder.toBytes());
    await _socket.flush();
  }

  /// Sync メッセージ送信
  Future<void> _sendSync() async {
    final builder = BytesBuilder();

    // メッセージタイプ 'S'
    builder.addByte('S'.codeUnitAt(0));

    // メッセージ長（ペイロードなし）
    builder.add(int32Bytes(4));

    _socket.add(builder.toBytes());
    await _socket.flush();
  }

  /// パラメータをテキスト形式にエンコード
  Uint8List? _encodeParameter(dynamic value) {
    if (value == null) {
      return null;
    }

    String stringValue;

    if (value is int) {
      stringValue = value.toString();
    } else if (value is double) {
      stringValue = value.toString();
    } else if (value is String) {
      stringValue = value;
    } else if (value is bool) {
      stringValue = value ? 't' : 'f';
    } else if (value is DateTime) {
      // ISO 8601形式
      stringValue = value.toUtc().toIso8601String();
    } else {
      // フォールバック: toString()
      stringValue = value.toString();
    }

    return utf8.encode(stringValue);
  }
}
