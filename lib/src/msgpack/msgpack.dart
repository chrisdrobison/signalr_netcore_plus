import 'dart:typed_data';

import 'src/deserializer.dart';
import 'src/serializer.dart';

Uint8List serialize(
  dynamic value, {
  ExtEncoder? extEncoder,
}) {
  final s = Serializer(extEncoder: extEncoder);
  s.encode(value);
  return s.takeBytes();
}

dynamic deserialize(
  Uint8List list, {
  ExtDecoder? extDecoder,
  bool copyBinaryData = false,
}) {
  final d = Deserializer(
    list,
    extDecoder: extDecoder,
    copyBinaryData: copyBinaryData,
  );
  return d.decode();
}
