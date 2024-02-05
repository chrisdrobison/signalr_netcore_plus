import 'package:meta/meta.dart';

abstract class Connection {
  final Map<String, dynamic> features = <String, dynamic>{};
  final String? connectionId;

  String? baseUrl;
  Function(Object)? onReceive;
  Function(Object?)? onClose;

  @protected
  Connection({
    this.baseUrl,
    this.connectionId,
    this.onReceive,
    this.onClose,
  });

  Future<void> start();
  Future<void> send(Object data);
  Future<void> stop([Object? error]);
}
