// ignore_for_file: prefer_single_quotes

import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:quiver/strings.dart';
import 'package:signalr_netcore_plus/src/http_connection_options.dart';

import 'http_client.dart';
import 'transport.dart';

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

Future<void> sendMessage(
  Logger? logger,
  String transportName,
  HttpClient httpClient,
  String? url,
  Object content,
  HttpConnectionOptions options,
) async {
  final headers = <String, String>{};
  if (options.accessTokenFactory != null) {
    final token = await options.accessTokenFactory!();
    if (isNotBlank(token)) {
      headers["Authorization"] = "Bearer $token";
    }
  }

  // logger.log(LogLevel.Trace, `(${transportName} transport) sending data. ${getDataDetail(content, logMessageContent)}.`);
  logger?.finest("($transportName transport) sending data.");

  //final responseType = content is String ? "arraybuffer" : "text";
  var req = HttpRequest(
    content: content,
    headers: headers,
    timeout: options.timeout,
  );
  final response = await httpClient.post(url, options: req);

  logger?.finest("($transportName transport) request complete. Response status: ${response.statusCode}.");
}
