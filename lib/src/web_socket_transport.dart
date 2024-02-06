import 'dart:async';

import 'package:logging/logging.dart';
import 'package:quiver/strings.dart';
import 'package:signalr_netcore_plus/src/transport.dart';
import 'package:signalr_netcore_plus/src/utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketTransport implements Transport {
  static final Logger _log = Logger('SignalR-Transport-WebSocket');

  final AccessTokenFactory? _accessTokenFactory;
  final bool _logMessageContent;
  final Map<String, String> _headers;

  WebSocketChannel? _webSocket;
  StreamSubscription? _webSocketListenSub;

  @override
  Function(Object? error)? onClose;

  @override
  Function(Object data)? onReceive;

  WebSocketTransport({
    AccessTokenFactory? accessTokenFactory,
    bool logMessageContent = false,
    required Map<String, String> headers,
  })  : _accessTokenFactory = accessTokenFactory,
        _logMessageContent = logMessageContent,
        _headers = headers;

  @override
  Future<void> connect(String url, TransferFormat transferFormat) async {
    _log.finest('(WebSockets transport) Connecting.');

    String? token;
    if (_accessTokenFactory != null) {
      token = await _accessTokenFactory!();
      if (isNotBlank(token)) {
        url += '${url.contains('?') ? '&' : '?'}access_token=${Uri.encodeComponent(token)}';
      }
    }

    var completer = Completer<void>();
    var opened = false;

    url = url.replaceAll(RegExp(r'/^http/'), 'ws');
    _log.finest('(WebSockets transport) Connecting to: $url.');

    _webSocket = WebSocketChannel.connect(Uri.parse(url));
    _webSocket!.ready.then(
      (value) {
        _log.info('(WebSockets transport) WebSocket connected to $url.');
        opened = true;
        completer.complete();
      },
      onError: (error) {
        _log.severe('(WebSockets transport) Error occurred when opening the WebSocket.', error);
        completer.completeError(error);
      },
    );

    _webSocketListenSub = _webSocket!.stream.listen(
      (data) {
        _log.finest('(WebSockets transport) Data received: ${getDataDetail(data, _logMessageContent)}}.');
        try {
          onReceive?.call(data);
        } catch (error) {
          _close(error);
        }
      },
      onDone: () {
        if (opened) {
          _close(_webSocket!.closeReason);
        } else {
          if (!completer.isCompleted) {
            completer.completeError(
                '(WebSockets transport) Error occurred with the transport: ${_webSocket?.closeReason ?? 'unknown'}.');
          }
        }
      },
      onError: (error) {
        _log.severe('(WebSockets transport) Error occurred when receiving data.', error);
        if (onClose != null) {
          onClose!(error);
        }
      },
    );

    return completer.future;
  }

  @override
  Future<void> send(Object data) {
    if (_webSocket != null) {
      _log.finest('(WebSockets transport) Sending data: ${getDataDetail(data, _logMessageContent)}.');
      _webSocket!.sink.add(data);
      return Future.value();
    } else {
      return Future.error('(WebSockets transport) WebSocket is not connected.');
    }
  }

  @override
  Future<void> stop() {
    if (_webSocket != null) {
      _close();
    }
    return Future.value();
  }

  void _close([Object? error]) async {
    if (_webSocket != null) {
      await _webSocketListenSub?.cancel();
      _webSocketListenSub = null;

      _webSocket!.sink.close();
      _webSocket = null;
    }

    _log.finest('(WebSockets transport) WebSocket closed: ${error ?? 'unknown'}.');
    onClose?.call(error);
  }
}
