import 'package:logging/logging.dart';
import 'package:quiver/strings.dart';
import 'package:signalr_netcore_plus/src/http_client.dart';
import 'package:signalr_netcore_plus/src/http_connection_options.dart';
import 'package:signalr_netcore_plus/src/utils.dart';

import 'sse/sse_channel.dart';
import 'transport.dart';

class ServerSentEventsTransport implements Transport {
  static final Logger _log = Logger('SignalR-Tranport-ServerSentEvents');

  final HttpClient _httpClient;
  final HttpConnectionOptions _httpConnectionOptions;

  String? _url;
  SseChannel? _sseClient;

  @override
  Function(Object? error)? onClose;

  @override
  Function(Object data)? onReceive;

  ServerSentEventsTransport({
    required HttpClient client,
    required HttpConnectionOptions httpConnectionOptions,
  })  : _httpClient = client,
        _httpConnectionOptions = httpConnectionOptions;

  @override
  Future<void> connect(String url, TransferFormat transferFormat) async {
    _log.finest('(SSE transport) Connecting.');
    _url = url;

    String? token;
    if (_httpConnectionOptions.accessTokenFactory != null) {
      token = await _httpConnectionOptions.accessTokenFactory!();
      if (isNotBlank(token)) {
        url += '${url.contains('?') ? '&' : '?'}access_token=${Uri.encodeComponent(token)}';
      }
    }

    var opened = false;
    if (transferFormat != TransferFormat.text) {
      throw ArgumentError('The Server-Sent Events transport only supports the \'Text\' transfer format');
    }

    SseChannel client;
    try {
      client = SseChannel.connect(Uri.parse(url));
      _log.info('(SSE transport) Connected to $url.');
      opened = true;
      _sseClient = client;
    } catch (e) {
      _log.severe('(SSE transport) Error occurred when opening the transport.', e);
      rethrow;
    }

    _sseClient!.stream.listen(
      (data) {
        try {
          _log.finest(
              '(SSE transport) Data received: ${getDataDetail(data, _httpConnectionOptions.logMessageContent)}.');
          onReceive?.call(data);
        } catch (error) {
          _close(error);
        }
      },
      onError: (error) {
        _log.severe('(SSE transport) Error occurred when receiving data.', error);
        if (opened) {
          _close(error);
        }
      },
    );
  }

  @override
  Future<void> send(Object data) async {
    if (_sseClient == null) {
      return Future.error(Exception('Cannot send until the transport is connected'));
    }

    await sendMessage(
      _log,
      'SSE',
      _httpClient,
      _url!,
      data,
      _httpConnectionOptions,
    );
  }

  @override
  Future<void> stop() {
    _close();
    return Future.value();
  }

  void _close([Object? error]) {
    if (_sseClient == null) {
      return;
    }

    _sseClient = null;
    onClose?.call(error);
  }
}
