import 'dart:async';
import 'dart:convert';
import 'package:aim_server/src/body.dart';
import 'package:test/test.dart';

void main() {
  group('Body - Body types', () {
    test('Should handle string body', () async {
      final body = Body('Hello, World!');
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final text = utf8.decode(bytes);
      expect(text, equals('Hello, World!'));
    });

    test('Should handle byte array body', () async {
      final bytes = [72, 101, 108, 108, 111]; // "Hello"
      final body = Body(bytes);
      final stream = body.read();
      final result = await stream.expand((chunk) => chunk).toList();
      expect(result, equals(bytes));
    });

    test('Should handle stream body', () async {
      final sourceStream = Stream<List<int>>.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final body = Body(sourceStream);
      final stream = body.read();
      final result = await stream.toList();
      expect(result, hasLength(2));
      expect(result[0], equals([1, 2, 3]));
      expect(result[1], equals([4, 5, 6]));
    });

    test('Should handle null body as empty', () async {
      final body = Body(null);
      final stream = body.read();
      final result = await stream.toList();
      expect(result, isEmpty);
    });

    test('Should handle empty string body', () async {
      final body = Body('');
      expect(body.contentLength, equals(0));
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      expect(bytes, isEmpty);
    });

    test('Should handle Body instance passed to Body constructor', () async {
      final originalBody = Body('Hello');
      final wrappedBody = Body(originalBody);
      expect(wrappedBody, same(originalBody));
    });
  });

  group('Body - Encoding', () {
    test('Should encode and decode UTF-8 text correctly', () async {
      final body = Body('Hello 世界');
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final text = utf8.decode(bytes);
      expect(text, equals('Hello 世界'));
    });

    test('Should support custom encoding', () async {
      final body = Body('Test', latin1);
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final text = latin1.decode(bytes);
      expect(text, equals('Test'));
    });

    test('Should handle multi-byte characters correctly', () async {
      final text = 'こんにちは世界🌍';
      final body = Body(text);
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final decoded = utf8.decode(bytes);
      expect(decoded, equals(text));
    });

    test('Should handle emoji and special Unicode', () async {
      final text = '😀 🎉 ❤️ 🌟';
      final body = Body(text);
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final decoded = utf8.decode(bytes);
      expect(decoded, equals(text));
    });
  });

  group('Body - Content length', () {
    test('Should calculate content length for string', () {
      final body = Body('Hello');
      expect(body.contentLength, equals(5));
    });

    test('Should calculate content length for multi-byte string', () {
      final body = Body('こんにちは'); // 5 characters, but more bytes
      expect(body.contentLength, isNotNull);
      expect(body.contentLength, greaterThan(5));
    });

    test('Should calculate content length for bytes', () {
      final bytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final body = Body(bytes);
      expect(body.contentLength, equals(10));
    });

    test('Should leave content length null for streams', () {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final body = Body(stream);
      expect(body.contentLength, isNull);
    });

    test('Should return 0 for null body', () {
      final body = Body(null);
      expect(body.contentLength, equals(0));
    });

    test('Should return 0 for empty string', () {
      final body = Body('');
      expect(body.contentLength, equals(0));
    });

    test('Should calculate correct length for UTF-8 encoded string', () {
      final text = 'Hello World!';
      final body = Body(text);
      expect(body.contentLength, equals(text.length));
    });
  });

  group('Body - Reading constraints', () {
    test('Should allow reading body once', () async {
      final body = Body('Hello');
      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final text = utf8.decode(bytes);
      expect(text, equals('Hello'));
    });

    test('Should throw on second read attempt', () async {
      final body = Body('Once');
      await body.read().drain(); // First read

      expect(
        () => body.read(), // Second read
        throwsStateError,
      );
    });

    test('Should throw with clear error message on second read', () {
      final body = Body('Data');
      body.read(); // First read

      try {
        body.read(); // Second read
        fail('Should have thrown StateError');
      } catch (e) {
        expect(e, isA<StateError>());
        expect(e.toString(), contains("'read' method can only be called once"));
      }
    });

    test('Should prevent multiple concurrent reads', () async {
      final body = Body('Concurrent');
      final read1 = body.read();

      expect(
        () => body.read(), // Second read while first is active
        throwsStateError,
      );

      await read1.drain(); // Complete first read
    });
  });

  group('Body - Streaming', () {
    test('Should stream large bodies efficiently', () async {
      final chunks = List.generate(100, (i) => List.filled(1000, i % 256));
      final stream = Stream<List<int>>.fromIterable(chunks);
      final body = Body(stream);

      final result = await body.read().toList();
      expect(result, hasLength(100));
    });

    test('Should handle stream errors gracefully', () async {
      final stream = Stream<List<int>>.error(Exception('Stream error'));
      final body = Body(stream);

      expect(() => body.read().toList(), throwsException);
    });

    test('Should handle empty streams', () async {
      final stream = Stream<List<int>>.empty();
      final body = Body(stream);

      final result = await body.read().toList();
      expect(result, isEmpty);
    });

    test('Should handle single-chunk streams', () async {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final body = Body(stream);

      final result = await body.read().first;
      expect(result, equals([1, 2, 3]));
    });

    test('Should handle multi-chunk streams', () async {
      final chunks = [
        [1, 2],
        [3, 4],
        [5, 6],
      ];
      final stream = Stream<List<int>>.fromIterable(chunks);
      final body = Body(stream);

      final result = await body.read().toList();
      expect(result, equals(chunks));
    });
  });

  group('Body - Type conversion', () {
    test('Should convert List to List<int>', () async {
      final List<dynamic> dynamicList = [1, 2, 3];
      final body = Body(dynamicList);

      final result = await body.read().first;
      expect(result, isA<List<int>>());
      expect(result, equals([1, 2, 3]));
    });

    test('Should convert Stream to Stream<List<int>>', () async {
      final Stream<dynamic> dynamicStream = Stream.value([1, 2, 3]);
      final body = Body(dynamicStream);

      final result = await body.read().first;
      expect(result, isA<List<int>>());
      expect(result, equals([1, 2, 3]));
    });

    test('Should throw for invalid body types', () {
      expect(
        () => Body(123), // Invalid type
        throwsArgumentError,
      );
    });

    test('Should throw for object body', () {
      expect(
        () => Body({'key': 'value'}), // Invalid type
        throwsArgumentError,
      );
    });
  });

  group('Body - Edge cases', () {
    test('Should handle very large strings', () async {
      final largeString = 'x' * 10000;
      final body = Body(largeString);
      expect(body.contentLength, equals(10000));

      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      expect(bytes, hasLength(10000));
    });

    test('Should handle binary data', () async {
      final binaryData = List.generate(256, (i) => i);
      final body = Body(binaryData);

      final result = await body.read().expand((chunk) => chunk).toList();
      expect(result, equals(binaryData));
    });

    test('Should handle strings with null characters', () async {
      final text = 'Hello\x00World';
      final body = Body(text);

      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final decoded = utf8.decode(bytes);
      expect(decoded, equals(text));
    });

    test('Should handle all whitespace string', () async {
      final text = '   \t\n\r   ';
      final body = Body(text);

      final stream = body.read();
      final bytes = await stream.expand((chunk) => chunk).toList();
      final decoded = utf8.decode(bytes);
      expect(decoded, equals(text));
    });

    test('Should handle zero-byte lists', () async {
      final emptyList = <int>[];
      final body = Body(emptyList);
      expect(body.contentLength, equals(0));

      final result = await body.read().toList();
      expect(result, hasLength(1)); // Empty list still yields one chunk
      expect(result[0], isEmpty);
    });
  });
}
