import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:signalr_netcore_plus/src/text_message_format.dart';

part 'handshake_protocol.g.dart';

@JsonSerializable()
class HandshakeRequestMessage {
  final String protocol;
  final int version;

  HandshakeRequestMessage(this.protocol, this.version);

  factory HandshakeRequestMessage.fromJson(Map<String, dynamic> json) => _$HandshakeRequestMessageFromJson(json);

  Map<String, dynamic> toJson() => _$HandshakeRequestMessageToJson(this);
}

@JsonSerializable()
class HandshakeResponseMessage {
  final String? error;

  HandshakeResponseMessage({this.error});

  factory HandshakeResponseMessage.fromJson(Map<String, dynamic> json) => _$HandshakeResponseMessageFromJson(json);

  Map<String, dynamic> toJson() => _$HandshakeResponseMessageToJson(this);
}

class HandshakeProtocol {
  String writeHandshakeRequest(HandshakeRequestMessage message) {
    return TextMessageFormat.write(jsonEncode(message));
  }

  (Object? remainingData, HandshakeResponseMessage response) parseHandshakeResponse(Object data) {
    String messageData;
    Object? remainingData;

    if (data is Uint8List) {
      final separatorIndex = data.indexOf(TextMessageFormat.recordSeparatorCode);
      if (separatorIndex == -1) {
        throw Exception('Message is incomplete.');
      }

      final responseLength = separatorIndex + 1;
      messageData = String.fromCharCodes(data, 0, responseLength);
      remainingData = (data.length > responseLength) ? data.sublist(responseLength) : null;
    } else {
      final textData = data as String;
      final separatorIndex = textData.indexOf(TextMessageFormat.recordSeparator);
      if (separatorIndex == -1) {
        throw Exception('Message is incomplete.');
      }

      final responseLength = separatorIndex + 1;
      messageData = textData.substring(0, responseLength);
      remainingData = (textData.length > responseLength) ? textData.substring(responseLength) : null;
    }

    final messages = TextMessageFormat.parse(messageData);
    final response = HandshakeResponseMessage.fromJson(jsonDecode(messages[0]));
    return (remainingData, response);
  }
}
