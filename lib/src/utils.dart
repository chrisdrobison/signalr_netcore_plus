// ignore_for_file: prefer_single_quotes

import 'dart:typed_data';

String getDataDetail(Object? data, bool includeContent) {
  var detail = '';
  if (data is Uint8List) {
    detail = 'Binary data of length ${data.lengthInBytes}';
    if (includeContent) {
      detail += ". Content: '${formatArrayBuffer(data)}'";
    }
  } else if (data is String) {
    detail = 'String data of length ${data.length}';
    if (includeContent) {
      detail += ". Content: '$data'";
    }
  }
  return detail;
}

String formatArrayBuffer(Uint8List data) {
  // Uint8Array.map only supports returning another Uint8Array?
  var str = '';
  for (var val in data) {
    var pad = val < 16 ? '0' : '';
    str += '0x$pad${val.toString()} ';
  }

  // Trim of trailing space.
  return str.substring(0, str.length - 1);
}
