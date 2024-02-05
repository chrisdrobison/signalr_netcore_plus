// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hub_protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvocationMessage _$InvocationMessageFromJson(Map<String, dynamic> json) =>
    InvocationMessage(
      target: json['target'] as String,
      arguments: json['arguments'] as List<dynamic>,
      streamIds: (json['streamIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      invocationId: json['invocationId'] as String?,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$InvocationMessageToJson(InvocationMessage instance) =>
    <String, dynamic>{
      'invocationId': instance.invocationId,
      'headers': instance.headers,
      'target': instance.target,
      'arguments': instance.arguments,
      'streamIds': instance.streamIds,
    };

StreamInvocationMessage _$StreamInvocationMessageFromJson(
        Map<String, dynamic> json) =>
    StreamInvocationMessage(
      invocationId: json['invocationId'] as String,
      target: json['target'] as String,
      arguments: json['arguments'] as List<dynamic>,
      streamIds: (json['streamIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$StreamInvocationMessageToJson(
        StreamInvocationMessage instance) =>
    <String, dynamic>{
      'headers': instance.headers,
      'invocationId': instance.invocationId,
      'target': instance.target,
      'arguments': instance.arguments,
      'streamIds': instance.streamIds,
    };

StreamItemMessage _$StreamItemMessageFromJson(Map<String, dynamic> json) =>
    StreamItemMessage(
      invocationId: json['invocationId'] as String,
      item: json['item'],
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$StreamItemMessageToJson(StreamItemMessage instance) =>
    <String, dynamic>{
      'headers': instance.headers,
      'invocationId': instance.invocationId,
      'item': instance.item,
    };

CompletionMessage _$CompletionMessageFromJson(Map<String, dynamic> json) =>
    CompletionMessage(
      invocationId: json['invocationId'] as String,
      error: json['error'] as String?,
      result: json['result'],
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$CompletionMessageToJson(CompletionMessage instance) =>
    <String, dynamic>{
      'headers': instance.headers,
      'invocationId': instance.invocationId,
      'error': instance.error,
      'result': instance.result,
    };

PingMessage _$PingMessageFromJson(Map<String, dynamic> json) => PingMessage();

Map<String, dynamic> _$PingMessageToJson(PingMessage instance) =>
    <String, dynamic>{};

CloseMessage _$CloseMessageFromJson(Map<String, dynamic> json) => CloseMessage(
      error: json['error'] as String?,
      allowReconnect: json['allowReconnect'] as bool?,
    );

Map<String, dynamic> _$CloseMessageToJson(CloseMessage instance) =>
    <String, dynamic>{
      'error': instance.error,
      'allowReconnect': instance.allowReconnect,
    };

CancelInvocationMessage _$CancelInvocationMessageFromJson(
        Map<String, dynamic> json) =>
    CancelInvocationMessage(
      invocationId: json['invocationId'] as String,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$CancelInvocationMessageToJson(
        CancelInvocationMessage instance) =>
    <String, dynamic>{
      'headers': instance.headers,
      'invocationId': instance.invocationId,
    };

AckMessage _$AckMessageFromJson(Map<String, dynamic> json) => AckMessage(
      sequenceId: json['sequenceId'] as int,
    );

Map<String, dynamic> _$AckMessageToJson(AckMessage instance) =>
    <String, dynamic>{
      'sequenceId': instance.sequenceId,
    };

SequenceMessage _$SequenceMessageFromJson(Map<String, dynamic> json) =>
    SequenceMessage(
      sequenceId: json['sequenceId'] as int,
    );

Map<String, dynamic> _$SequenceMessageToJson(SequenceMessage instance) =>
    <String, dynamic>{
      'sequenceId': instance.sequenceId,
    };
