import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:signalr_netcore_plus/src/binary_message_formart.dart';

import 'hub_protocol.dart';
import 'msgpack/msgpack.dart' as msgpack;
import 'transport.dart';

class MsgPackHubProtocol implements HubProtocol {
  static final Logger _log = Logger('SignalR-Protocol-MsgPack');
  static final Uint8List _serializedPingMessage = Uint8List.fromList([0x91, MessageType.ping.value]);

  static const int _errorResult = 1;
  static const int _voidResult = 2;
  static const int _nonVoidResult = 3;

  @override
  String get name => 'messagepack';

  @override
  int get version => 2;

  @override
  TransferFormat get transferFormat => TransferFormat.binary;

  @override
  List<HubMessage> parseMessages(Object input) {
    if (input is! Uint8List) {
      throw Exception('Invalid input for MsgPackHubProtocol.');
    }

    final messages = BinaryMessageFormat.parse(input);
    final hubMessages = <HubMessage>[];
    for (final message in messages) {
      final parsedMessage = _parseMessage(message);
      if (parsedMessage != null) {
        hubMessages.add(parsedMessage);
      }
    }
    return hubMessages;
  }

  @override
  Object writeMessage(HubMessage message) {
    switch (message) {
      case InvocationMessage invocationMessage:
        return _writeInvocation(invocationMessage);
      case StreamInvocationMessage streamInvocationMessage:
        return _writeStreamInvocation(streamInvocationMessage);
      case StreamItemMessage streamItemMessage:
        return _writeStreamItem(streamItemMessage);
      case CompletionMessage completionMessage:
        return _writeCompletion(completionMessage);
      case PingMessage _:
        return BinaryMessageFormat.write(_serializedPingMessage);
      case CancelInvocationMessage cancelInvocationMessage:
        return _writeCancelInvocation(cancelInvocationMessage);
      case CloseMessage closeMessage:
        return _writeClose(closeMessage);
      case AckMessage ackMessage:
        return _writeAck(ackMessage);
      case SequenceMessage sequenceMessage:
        return _writeSequence(sequenceMessage);
      default:
        throw Exception('Invalid message type.');
    }
  }

  HubMessage? _parseMessage(Uint8List input) {
    if (input.isEmpty) {
      throw Exception('Invalid payload.');
    }

    final properties = msgpack.deserialize(input);
    if (properties is! List || properties.isEmpty) {
      throw Exception('Invalid payload.');
    }

    final messageType = MessageType.values.firstWhere((element) => element.value == properties[0]);
    switch (messageType) {
      case MessageType.invocation:
        return _createInvocationMessage(_readHeaders(properties), properties);
      case MessageType.streamItem:
        return _createStreamItemMessage(_readHeaders(properties), properties);
      case MessageType.completion:
        return _createCompletionMessage(_readHeaders(properties), properties);
      case MessageType.ping:
        return _createPingMessage(properties);
      case MessageType.close:
        return _createCloseMessage(properties);
      case MessageType.ack:
        return _createAckMessage(properties);
      case MessageType.sequence:
        return _createSequenceMessage(properties);
      default:
        _log.info('Unknown message type: $messageType, ignoring message.');
        return null;
    }
  }

  InvocationMessage _createInvocationMessage(Map headers, List properties) {
    // check minimum length to allow protocol to add items to the end of objects in future releases
    if (properties.length < 5) {
      throw Exception('Invalid payload for Invocation message.');
    }

    return InvocationMessage(
      target: properties[3],
      arguments: properties[4],
      headers: headers as Map<String, String>?,
      invocationId: properties[2],
      streamIds: [],
    );
  }

  CompletionMessage _createCompletionMessage(Map headers, List properties) {
    // check minimum length to allow protocol to add items to the end of objects in future releases
    if (properties.length < 4) {
      throw Exception('Invalid payload for Completion message.');
    }

    final resultKind = properties[3];
    if (resultKind != _voidResult && properties.length < 5) {
      throw Exception('Invalid payload for Completion message.');
    }

    String? error;
    Object? result;

    if (resultKind == _errorResult) {
      error = properties[4];
    } else if (resultKind == _nonVoidResult) {
      result = properties[4];
    }

    return CompletionMessage(
      headers: headers as Map<String, String>?,
      invocationId: properties[2],
      result: result,
      error: error,
    );
  }

  StreamItemMessage _createStreamItemMessage(Map headers, List properties) {
    // check minimum length to allow protocol to add items to the end of objects in future releases
    if (properties.length < 4) {
      throw Exception('Invalid payload for StreamItem message.');
    }

    return StreamItemMessage(
      headers: headers as Map<String, String>?,
      invocationId: properties[2],
      item: properties[3],
    );
  }

  PingMessage _createPingMessage(List properties) {
    if (properties.isEmpty) {
      throw Exception('Invalid payload for Ping message.');
    }

    return PingMessage();
  }

  CloseMessage _createCloseMessage(List properties) {
    if (properties.length < 2) {
      throw Exception('Invalid payload for Close message.');
    }

    return CloseMessage(
      allowReconnect: properties.length >= 3 ? properties[2] : null,
      error: properties[1],
    );
  }

  AckMessage _createAckMessage(List properties) {
    if (properties.isEmpty) {
      throw Exception('Invalid payload for Ack message.');
    }

    return AckMessage(
      sequenceId: properties[1],
    );
  }

  SequenceMessage _createSequenceMessage(List properties) {
    if (properties.isEmpty) {
      throw Exception('Invalid payload for Sequence message.');
    }

    return SequenceMessage(
      sequenceId: properties[1],
    );
  }

  Uint8List _writeInvocation(InvocationMessage message) {
    final payload = [
      MessageType.invocation.value,
      message.headers ?? {},
      message.invocationId,
      message.target,
      message.arguments,
      if (message.streamIds != null) message.streamIds,
    ];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeStreamInvocation(StreamInvocationMessage message) {
    final payload = [
      MessageType.streamInvocation.value,
      message.headers ?? {},
      message.invocationId,
      message.target,
      message.arguments,
      if (message.streamIds != null) message.streamIds,
    ];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeStreamItem(StreamItemMessage message) {
    final payload = [
      MessageType.streamItem.value,
      message.headers ?? {},
      message.invocationId,
      message.item,
    ];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeCompletion(CompletionMessage message) {
    final resultKind = message.error != null
        ? _errorResult
        : message.result != null
            ? _nonVoidResult
            : _voidResult;
    final payload = [
      MessageType.completion.value,
      message.headers ?? {},
      message.invocationId,
      resultKind,
      if (resultKind == _errorResult) message.error,
      if (resultKind == _nonVoidResult) message.result,
    ];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeCancelInvocation(CancelInvocationMessage message) {
    final payload = [
      MessageType.cancelInvocation.value,
      message.headers ?? {},
      message.invocationId,
    ];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeClose(CloseMessage message) {
    final payload = [MessageType.close.value, null];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeAck(AckMessage message) {
    final payload = [MessageType.ack.value, message.sequenceId];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Uint8List _writeSequence(SequenceMessage message) {
    final payload = [MessageType.sequence.value, message.sequenceId];
    final packedData = msgpack.serialize(payload);
    return BinaryMessageFormat.write(packedData);
  }

  Map _readHeaders(List properties) {
    final headers = properties[1];
    if (headers is! Map) {
      throw Exception('Invalid payload.');
    }

    return headers;
  }
}
