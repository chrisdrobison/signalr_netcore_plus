import 'dart:math';
import 'dart:typed_data';

class BinaryMessageFormat {
  BinaryMessageFormat._();

  static Uint8List write(Uint8List output) {
    var size = output.length;
    final lenBuffer = [];
    do {
      var sizePart = size & 0x7f;
      size = size >> 7;
      if (size > 0) {
        sizePart = sizePart | 0x80;
      }
      lenBuffer.add(sizePart);
    } while (size > 0);

    size = output.length;

    final buffer = Uint8List(lenBuffer.length + size);
    for (var i = 0; i < lenBuffer.length; i++) {
      buffer[i] = lenBuffer[i];
    }
    for (var i = 0; i < size; i++) {
      buffer[i + lenBuffer.length] = output[i];
    }

    return buffer;
  }

  static List<Uint8List> parse(Uint8List input) {
    List<Uint8List> result = [];
    Uint8List uint8Array = input;
    int maxLengthPrefixSize = 5;
    List<int> numBitsToShift = [0, 7, 14, 21, 28];

    int offset = 0;
    while (offset < input.lengthInBytes) {
      int numBytes = 0;
      int size = 0;
      int byteRead;
      do {
        byteRead = uint8Array[offset + numBytes];
        size = size | ((byteRead & 0x7f) << (numBitsToShift[numBytes]));
        numBytes++;
      } while (numBytes < min(maxLengthPrefixSize, input.lengthInBytes - offset) && (byteRead & 0x80) != 0);

      if ((byteRead & 0x80) != 0 && numBytes < maxLengthPrefixSize) {
        throw Exception('Cannot read message size.');
      }

      if (numBytes == maxLengthPrefixSize && byteRead > 7) {
        throw Exception('Messages bigger than 2GB are not supported.');
      }

      if (uint8Array.lengthInBytes >= (offset + numBytes + size)) {
        result.add(uint8Array.buffer.asUint8List(offset + numBytes, size));
      } else {
        throw Exception('Incomplete message.');
      }

      offset = offset + numBytes + size;
    }

    return result;
  }
}
