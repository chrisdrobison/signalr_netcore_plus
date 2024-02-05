import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:quiver/strings.dart';

import 'errors.dart';
import 'hub_protocol.dart';
import 'text_message_format.dart';
import 'transport.dart';

class JsonHubProtocol implements HubProtocol {
  static final Logger _log = Logger('SignalR-JsonHubProtocol');

  @override
  String name = 'json';

  @override
  int version = 2;

  @override
  TransferFormat get transferFormat => TransferFormat.text;

  @override
  List<HubMessage> parseMessages(Object input) {
    if (input is! String) {
      throw Exception('Invalid input for JSON hub protocol.');
    }

    if (isBlank(input)) {
      return <HubMessage>[];
    }

    final messages = TextMessageFormat.parse(input);
    final hubMessages = <HubMessage>[];
    for (var message in messages) {
      var parsedMessage = jsonDecode(message);
      if (parsedMessage is num) {
        throw Exception('Invalid payload.');
      }

      try {
        hubMessages.add(HubMessage.fromJson(parsedMessage));
      } on UnknownMessageTypeException catch (e) {
        _log.info('Unknown message type: ${e.messageType}, ignoring message.');
      }
    }

    return hubMessages;
  }

  @override
  Object writeMessage(HubMessage message) {
    return jsonEncode(message);
  }
}
