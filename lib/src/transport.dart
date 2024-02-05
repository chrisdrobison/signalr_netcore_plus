enum HttpTransportType {
  none(0),
  webSockets(1),
  serverSentEvents(2),
  longPolling(4);

  final int value;

  const HttpTransportType(this.value);
}

enum TransferFormat {
  text(1),
  binary(2);

  final int value;

  const TransferFormat(this.value);
}

abstract interface class Transport {
  Future<void> connect(String url, TransferFormat transferFormat);
  Future<void> send(Object data);
  Future<void> stop();

  Function(Object)? onReceive;
  Function(Object?)? onClose;
}
