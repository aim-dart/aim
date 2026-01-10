import 'dart:typed_data';

import 'package:aim_orm_postgres/src/util.dart';
import 'package:test/test.dart';

void main() {
  group('int32Bytes', () {
    test('converts int to big-endian bytes', () {
      final bytes = int32Bytes(0x12345678);
      expect(bytes, [0x12, 0x34, 0x56, 0x78]);
    });

    test('handles zero', () {
      final bytes = int32Bytes(0);
      expect(bytes, [0x00, 0x00, 0x00, 0x00]);
    });

    test('handles max positive value', () {
      final bytes = int32Bytes(0x7FFFFFFF);
      expect(bytes, [0x7F, 0xFF, 0xFF, 0xFF]);
    });

    test('handles negative values', () {
      final bytes = int32Bytes(-1);
      expect(bytes, [0xFF, 0xFF, 0xFF, 0xFF]);
    });

    test('handles various values', () {
      expect(int32Bytes(1), [0x00, 0x00, 0x00, 0x01]);
      expect(int32Bytes(256), [0x00, 0x00, 0x01, 0x00]);
      expect(int32Bytes(65536), [0x00, 0x01, 0x00, 0x00]);
      expect(int32Bytes(16777216), [0x01, 0x00, 0x00, 0x00]);
    });
  });

  group('bytesToInt32', () {
    test('converts big-endian bytes to int', () {
      final value = bytesToInt32(Uint8List.fromList([0x12, 0x34, 0x56, 0x78]));
      expect(value, 0x12345678);
    });

    test('handles zero', () {
      final value = bytesToInt32(Uint8List.fromList([0x00, 0x00, 0x00, 0x00]));
      expect(value, 0);
    });

    test('handles negative values (signed)', () {
      final value = bytesToInt32(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
      expect(value, -1); // 符号付き32ビット整数として-1
    });

    test('handles max positive value', () {
      final value = bytesToInt32(Uint8List.fromList([0x7F, 0xFF, 0xFF, 0xFF]));
      expect(value, 0x7FFFFFFF);
    });

    test('handles various values', () {
      expect(bytesToInt32(Uint8List.fromList([0x00, 0x00, 0x00, 0x01])), 1);
      expect(bytesToInt32(Uint8List.fromList([0x00, 0x00, 0x01, 0x00])), 256);
      expect(bytesToInt32(Uint8List.fromList([0x00, 0x01, 0x00, 0x00])), 65536);
      expect(
        bytesToInt32(Uint8List.fromList([0x01, 0x00, 0x00, 0x00])),
        16777216,
      );
    });
  });

  group('int16Bytes', () {
    test('converts int to big-endian bytes', () {
      final bytes = int16Bytes(0x1234);
      expect(bytes, [0x12, 0x34]);
    });

    test('handles zero', () {
      final bytes = int16Bytes(0);
      expect(bytes, [0x00, 0x00]);
    });

    test('handles max value', () {
      final bytes = int16Bytes(0xFFFF);
      expect(bytes, [0xFF, 0xFF]);
    });

    test('handles various values', () {
      expect(int16Bytes(1), [0x00, 0x01]);
      expect(int16Bytes(256), [0x01, 0x00]);
      expect(int16Bytes(0xABCD), [0xAB, 0xCD]);
    });
  });

  group('bytesToInt16', () {
    test('converts big-endian bytes to int', () {
      final value = bytesToInt16(Uint8List.fromList([0x12, 0x34]));
      expect(value, 0x1234);
    });

    test('handles zero', () {
      final value = bytesToInt16(Uint8List.fromList([0x00, 0x00]));
      expect(value, 0);
    });

    test('handles max value', () {
      final value = bytesToInt16(Uint8List.fromList([0xFF, 0xFF]));
      expect(value, 0xFFFF);
    });

    test('handles various values', () {
      expect(bytesToInt16(Uint8List.fromList([0x00, 0x01])), 1);
      expect(bytesToInt16(Uint8List.fromList([0x01, 0x00])), 256);
      expect(bytesToInt16(Uint8List.fromList([0xAB, 0xCD])), 0xABCD);
    });
  });

  group('Round-trip conversions', () {
    test('int32 round-trip', () {
      const values = [
        0,
        1,
        -1,
        256,
        65536,
        16777216,
        0x12345678,
        0x7FFFFFFF,
        -2147483648, // min int32
      ];

      for (final original in values) {
        final bytes = int32Bytes(original);
        final converted = bytesToInt32(bytes);
        expect(converted, original, reason: 'Failed for value: $original');
      }
    });

    test('int16 round-trip', () {
      const values = [0, 1, 256, 0x1234, 0xABCD, 0xFFFF];

      for (final original in values) {
        final bytes = int16Bytes(original);
        final converted = bytesToInt16(bytes);
        expect(converted, original, reason: 'Failed for value: $original');
      }
    });
  });

  group('Edge cases', () {
    test('int32Bytes with large positive number', () {
      final bytes = int32Bytes(2147483647); // max int32
      expect(bytes, [0x7F, 0xFF, 0xFF, 0xFF]);
      expect(bytesToInt32(bytes), 2147483647);
    });

    test('int32Bytes with large negative number', () {
      final bytes = int32Bytes(-2147483648); // min int32
      expect(bytes, [0x80, 0x00, 0x00, 0x00]);
      expect(bytesToInt32(bytes), -2147483648);
    });

    test('bytesToInt32 handles NULL value indicator', () {
      // PostgreSQLではlength = -1がNULL値を示す
      final bytes = int32Bytes(-1);
      expect(bytesToInt32(bytes), -1);
    });
  });

  group('Byte order verification', () {
    test('verifies big-endian byte order for int32', () {
      // 0x01020304 should be [0x01, 0x02, 0x03, 0x04] in big-endian
      final bytes = int32Bytes(0x01020304);
      expect(bytes[0], 0x01, reason: 'Most significant byte first');
      expect(bytes[1], 0x02);
      expect(bytes[2], 0x03);
      expect(bytes[3], 0x04, reason: 'Least significant byte last');
    });

    test('verifies big-endian byte order for int16', () {
      // 0x0102 should be [0x01, 0x02] in big-endian
      final bytes = int16Bytes(0x0102);
      expect(bytes[0], 0x01, reason: 'Most significant byte first');
      expect(bytes[1], 0x02, reason: 'Least significant byte last');
    });
  });
}
