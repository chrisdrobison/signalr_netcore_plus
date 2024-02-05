// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handshake_protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HandshakeRequestMessage _$HandshakeRequestMessageFromJson(
        Map<String, dynamic> json) =>
    HandshakeRequestMessage(
      json['protocol'] as String,
      json['version'] as int,
    );

Map<String, dynamic> _$HandshakeRequestMessageToJson(
        HandshakeRequestMessage instance) =>
    <String, dynamic>{
      'protocol': instance.protocol,
      'version': instance.version,
    };

HandshakeResponseMessage _$HandshakeResponseMessageFromJson(
        Map<String, dynamic> json) =>
    HandshakeResponseMessage(
      error: json['error'] as String?,
    );

Map<String, dynamic> _$HandshakeResponseMessageToJson(
        HandshakeResponseMessage instance) =>
    <String, dynamic>{
      'error': instance.error,
    };
