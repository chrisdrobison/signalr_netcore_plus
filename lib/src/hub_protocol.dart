// ignore_for_file: overridden_fields

import 'package:json_annotation/json_annotation.dart';

import 'errors.dart';
import 'transport.dart';

part 'hub_protocol.g.dart';

const int invocationType = 1;
const int streamItemType = 2;
const int completionType = 3;
const int streamInvocationType = 4;
const int cancelInvocationType = 5;
const int pingType = 6;
const int closeType = 7;
const int ackType = 8;
const int sequenceType = 9;

enum MessageType {
  invocation(invocationType),
  streamItem(streamItemType),
  completion(completionType),
  streamInvocation(streamInvocationType),
  cancelInvocation(cancelInvocationType),
  ping(pingType),
  close(closeType),
  ack(ackType),
  sequence(sequenceType);

  final int value;

  const MessageType(this.value);
}

sealed class HubMessage {
  final MessageType type;

  const HubMessage(this.type);

  factory HubMessage.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case invocationType:
        return InvocationMessage.fromJson(json);
      case streamItemType:
        return StreamItemMessage.fromJson(json);
      case completionType:
        return CompletionMessage.fromJson(json);
      case streamInvocationType:
        return StreamInvocationMessage.fromJson(json);
      case cancelInvocationType:
        return CancelInvocationMessage.fromJson(json);
      case pingType:
        return PingMessage.fromJson(json);
      case closeType:
        return CloseMessage.fromJson(json);
      case ackType:
        return AckMessage.fromJson(json);
      case sequenceType:
        return SequenceMessage.fromJson(json);
      default:
        throw UnknownMessageTypeException(
          message: 'Unknown message type: ${json['type']}',
          messageType: json['type'],
        );
    }
  }

  Map<String, dynamic> toJson();
}

sealed class HubInvocationMessage extends HubMessage {
  final String? invocationId;
  final Map<String, String>? headers;

  const HubInvocationMessage({
    required MessageType type,
    this.invocationId,
    this.headers,
  }) : super(type);
}

@JsonSerializable()
class InvocationMessage extends HubInvocationMessage {
  final String target;
  final List<Object?> arguments;
  final List<String>? streamIds;

  const InvocationMessage({
    required this.target,
    required this.arguments,
    this.streamIds,
    super.invocationId,
    super.headers,
  }) : super(type: MessageType.invocation);

  factory InvocationMessage.fromJson(Map<String, dynamic> json) => _$InvocationMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$InvocationMessageToJson(this);
}

@JsonSerializable()
class StreamInvocationMessage extends HubInvocationMessage {
  @override
  final String invocationId;
  final String target;
  final List<Object?> arguments;
  final List<String>? streamIds;

  const StreamInvocationMessage({
    required this.invocationId,
    required this.target,
    required this.arguments,
    this.streamIds,
    super.headers,
  }) : super(type: MessageType.streamInvocation, invocationId: invocationId);

  factory StreamInvocationMessage.fromJson(Map<String, dynamic> json) => _$StreamInvocationMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$StreamInvocationMessageToJson(this);
}

@JsonSerializable()
class StreamItemMessage extends HubInvocationMessage {
  @override
  final String invocationId;
  final Object? item;

  const StreamItemMessage({
    required this.invocationId,
    required this.item,
    super.headers,
  }) : super(type: MessageType.streamItem, invocationId: invocationId);

  factory StreamItemMessage.fromJson(Map<String, dynamic> json) => _$StreamItemMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$StreamItemMessageToJson(this);
}

@JsonSerializable()
class CompletionMessage extends HubInvocationMessage {
  @override
  final String invocationId;
  final String? error;
  final Object? result;

  const CompletionMessage({
    required this.invocationId,
    this.error,
    this.result,
    super.headers,
  }) : super(type: MessageType.completion, invocationId: invocationId);

  factory CompletionMessage.fromJson(Map<String, dynamic> json) => _$CompletionMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CompletionMessageToJson(this);
}

@JsonSerializable()
class PingMessage extends HubMessage {
  const PingMessage() : super(MessageType.ping);

  factory PingMessage.fromJson(Map<String, dynamic> json) => _$PingMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PingMessageToJson(this);
}

@JsonSerializable()
class CloseMessage extends HubMessage {
  final String? error;
  final bool? allowReconnect;

  const CloseMessage({
    this.error,
    this.allowReconnect,
  }) : super(MessageType.close);

  factory CloseMessage.fromJson(Map<String, dynamic> json) => _$CloseMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CloseMessageToJson(this);
}

@JsonSerializable()
class CancelInvocationMessage extends HubInvocationMessage {
  @override
  final String invocationId;

  const CancelInvocationMessage({
    required this.invocationId,
    super.headers,
  }) : super(type: MessageType.cancelInvocation, invocationId: invocationId);

  factory CancelInvocationMessage.fromJson(Map<String, dynamic> json) => _$CancelInvocationMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CancelInvocationMessageToJson(this);
}

@JsonSerializable()
class AckMessage extends HubMessage {
  final int sequenceId;

  const AckMessage({
    required this.sequenceId,
  }) : super(MessageType.ack);

  factory AckMessage.fromJson(Map<String, dynamic> json) => _$AckMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AckMessageToJson(this);
}

@JsonSerializable()
class SequenceMessage extends HubMessage {
  final int sequenceId;

  const SequenceMessage({
    required this.sequenceId,
  }) : super(MessageType.sequence);

  factory SequenceMessage.fromJson(Map<String, dynamic> json) => _$SequenceMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SequenceMessageToJson(this);
}

abstract interface class HubProtocol {
  String get name;
  int get version;
  TransferFormat get transferFormat;

  List<HubMessage> parseMessages(Object input);

  Object writeMessage(HubMessage message);
}
