import 'transport.dart';

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException({required this.statusCode, required this.message});

  @override
  String toString() {
    return 'HttpError{statusCode: $statusCode, message: $message}';
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException({this.message = 'A timeout occurred'});

  @override
  String toString() {
    return 'TimeoutException{message: $message}';
  }
}

class AbortException implements Exception {
  final String message;

  AbortException({this.message = 'An abort occurred'});

  @override
  String toString() {
    return 'AbortException{message: $message}';
  }
}

class UnsupportedTransportException implements Exception {
  final String message;
  final HttpTransportType transportType;

  UnsupportedTransportException({
    this.message = 'The transport type is not supported',
    required this.transportType,
  });

  @override
  String toString() {
    return 'UnsupportedTransportException{message: $message, transportType: $transportType}';
  }
}

class DisbledTransportException implements Exception {
  final String message;
  final HttpTransportType transportType;

  DisbledTransportException({
    this.message = 'The transport type is disabled',
    required this.transportType,
  });

  @override
  String toString() {
    return 'DisbledTransportException{message: $message, transportType: $transportType}';
  }
}

class FailedToStartTransportException implements Exception {
  final String message;
  final HttpTransportType transportType;

  FailedToStartTransportException({
    this.message = 'Failed to start the transport',
    required this.transportType,
  });

  @override
  String toString() {
    return 'FailedToStartTransportException{message: $message, transportType: $transportType}';
  }
}

class FailedToNegotiateWithServerException implements Exception {
  final String message;

  FailedToNegotiateWithServerException({this.message = 'Failed to negotiate'});

  @override
  String toString() {
    return 'FailedToNegotiateException{message: $message}';
  }
}

class AggregateException implements Exception {
  final List<Exception> innerErrors;

  AggregateException({required this.innerErrors});

  @override
  String toString() {
    return 'AggregateException{exceptions: $innerErrors}';
  }
}

class UnknownMessageTypeException implements Exception {
  final String message;
  final int messageType;

  UnknownMessageTypeException({
    this.message = 'Unknown message type',
    required this.messageType,
  });

  @override
  String toString() {
    return 'UnknownMessageTypeException{message: $message, messageType: $messageType}';
  }
}
