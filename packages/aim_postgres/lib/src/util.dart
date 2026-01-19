import 'dart:typed_data';

/// Converts a 16-bit integer to big-endian byte array.
///
/// Returns a [Uint8List] of length 2 containing the big-endian representation
/// of the [value].
Uint8List int16Bytes(int value) {
  final bytes = Uint8List(2);
  bytes[0] = (value >> 8) & 0xFF;
  bytes[1] = value & 0xFF;
  return bytes;
}

/// Converts a 32-bit integer to big-endian byte array.
///
/// Returns a [Uint8List] of length 4 containing the big-endian representation
/// of the [value].
Uint8List int32Bytes(int value) {
  final bytes = Uint8List(4);
  bytes[0] = (value >> 24) & 0xFF;
  bytes[1] = (value >> 16) & 0xFF;
  bytes[2] = (value >> 8) & 0xFF;
  bytes[3] = value & 0xFF;
  return bytes;
}

/// Converts a big-endian byte array to a signed 32-bit integer.
///
/// The [bytes] must be at least 4 bytes long. Returns a signed 32-bit integer
/// value. Special value -1 represents NULL in PostgreSQL wire protocol.
int bytesToInt32(Uint8List bytes) {
  final value = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  // Treat as signed 32-bit integer (-1 represents NULL)
  return value.toSigned(32);
}

/// Converts a big-endian byte array to a 16-bit integer.
///
/// The [bytes] must be at least 2 bytes long. Returns an unsigned 16-bit
/// integer value.
int bytesToInt16(Uint8List bytes) {
  return (bytes[0] << 8) | bytes[1];
}

/// Converts a byte array to its hexadecimal string representation.
///
/// Returns a lowercase hexadecimal string with each byte represented by
/// exactly 2 characters (padded with '0' if necessary).
String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
