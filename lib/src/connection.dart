import 'package:meta/meta.dart';

abstract class Connection {
  final String baseUrl;
  final Map<String, dynamic>? features;
  final String? connectionId;

  Function(Object)? onReceive;
  Function(Object?)? onClose;

  @protected
  Connection({
    required this.baseUrl,
    this.features,
    this.connectionId,
    this.onReceive,
    this.onClose,
  });

  Future<void> start();
  Future<void> send(Object data);
  Future<void> stop([Object? error]);
}
