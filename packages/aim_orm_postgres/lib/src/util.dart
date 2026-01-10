import 'dart:typed_data';

Uint8List int16Bytes(int value) {
  final bytes = Uint8List(2);
  bytes[0] = (value >> 8) & 0xFF;
  bytes[1] = value & 0xFF;
  return bytes;
}

Uint8List int32Bytes(int value) {
  final bytes = Uint8List(4);
  bytes[0] = (value >> 24) & 0xFF;
  bytes[1] = (value >> 16) & 0xFF;
  bytes[2] = (value >> 8) & 0xFF;
  bytes[3] = value & 0xFF;
  return bytes;
}

int bytesToInt32(Uint8List bytes) {
  final value = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  // 符号付き32ビット整数として扱う（-1がNULLを表す）
  return value.toSigned(32);
}

int bytesToInt16(Uint8List bytes) {
  return (bytes[0] << 8) | bytes[1];
}

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
