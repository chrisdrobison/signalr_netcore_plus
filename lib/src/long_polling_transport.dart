// ignore_for_file: prefer_single_quotes

import 'package:logging/logging.dart';
import 'package:quiver/strings.dart';
import 'package:signalr_netcore_plus/src/errors.dart';
import 'package:signalr_netcore_plus/src/utils.dart';

import 'abort_controller.dart';
import 'http_client.dart';
import 'http_connection_options.dart';
import 'transport.dart';

class LongPollingTransport implements Transport {
  static final Logger _log = Logger('SignalR-Transport-LongPolling');

  final HttpClient _httpClient;
  final HttpConnectionOptions _options;
  final AbortController _pollAbort = AbortController();

  String? _url;
  bool _running = false;
  Future<void>? _receiving;
  Exception? _closeError;

  @override
  Function(Object? error)? onClose;

  @override
  Function(Object data)? onReceive;

  LongPollingTransport({
    required HttpClient httpClient,
    required HttpConnectionOptions options,
  })  : _httpClient = httpClient,
        _options = options;

  @override
  Future<void> connect(String url, TransferFormat transferFormat) async {
    _url = url;
    _log.finest('(LongPolling transport) Connecting.');

    if (transferFormat == TransferFormat.binary) {
      throw Exception('The \'LongPolling\' transport only supports the \'text\' transfer format.');
    }

    var pollOptions = HttpRequest(
      abortSignal: _pollAbort,
      headers: _options.headers,
      timeout: Duration(milliseconds: 100000),
    );

    final token = await _getAccessToken();
    _updateHeaderToken(pollOptions, token);

    // Make initial long polling request
    // Server uses first long polling request to finish initializing connection and it returns without data
    final pollUrl = '$_url&_=${DateTime.now()}';
    _log.finest('(LongPolling transport) polling: $pollUrl');
    final response = await _httpClient.get(pollUrl, options: pollOptions);

    if (response.statusCode != 200) {
      _log.severe('(LongPolling transport) Unexpected response code: ${response.statusCode}');

      // Mark running as false so that the poll immediately ends and runs the close logic
      _closeError = HttpException(
        message: response.statusText ?? '',
        statusCode: response.statusCode,
      );
      _running = false;
    } else {
      _running = true;
    }

    _receiving = _poll(_url!, pollOptions);
  }

  @override
  Future<void> send(Object data) {
    if (!_running) {
      return Future.error(Exception('Cannot send until the transport is connected'));
    }
    return sendMessage(_log, "LongPolling", _httpClient, _url!, data, _options);
  }

  @override
  Future<void> stop() async {
    _log.finest('(LongPolling transport) Stopping polling.');

    // Tell receiving loop to stop, abort any current request, and then wait for the receiving loop to finish
    _running = false;
    _pollAbort.abort();

    try {
      await _receiving;

      // Send DELETE to clean up long polling on the server
      _log.finest("(LongPolling transport) sending DELETE request to $_url.");

      Object? error;
      try {
        final deleteOptions = HttpRequest();
        final token = await _getAccessToken();
        _updateHeaderToken(deleteOptions, token);
        await _httpClient.delete(_url, options: deleteOptions);
      } catch (e) {
        error = e;
      }

      if (error != null) {
        if (error is HttpException) {
          _log.severe("(LongPolling transport) DELETE request failed with status code ${error.statusCode}");
        } else {
          _log.severe("(LongPolling transport) DELETE request failed with error $error");
        }
      } else {
        _log.finest("(LongPolling transport) DELETE request accepted.");
      }
    } finally {
      _log.finest("(LongPolling transport) Stop finished.");

      // Raise close event here instead of in polling
      // It needs to happen after the DELETE request is sent
      _raiseOnClose();
    }
  }

  Future<void> _poll(String url, HttpRequest pollOptions) async {
    try {
      while (_running) {
        // We have to get the access token on each poll, in case it changes
        final token = await _getAccessToken();
        _updateHeaderToken(pollOptions, token);

        try {
          final pollUrl = "$url&_=${DateTime.now()}";
          _log.finest("(LongPolling transport) polling: $pollUrl");
          final response = await _httpClient.get(pollUrl, options: pollOptions);

          if (response.statusCode == 204) {
            _log.info("(LongPolling transport) Poll terminated by server");

            _running = false;
          } else if (response.statusCode != 200) {
            _log.severe("(LongPolling transport) Unexpected response code: ${response.statusCode}");

            // Unexpected status code
            _closeError = HttpException(message: response.statusText ?? "", statusCode: response.statusCode);
            _running = false;
          } else {
            // Process the response
            if (isNotBlank(response.content as String?)) {
              // _logger.log(LogLevel.Trace, "(LongPolling transport) data received. ${getDataDetail(response.content, this.logMessageContent)}");
              _log.finest("(LongPolling transport) data received");
              onReceive?.call(response.content!);
            } else {
              // This is another way timeout manifest.
              _log.finest("(LongPolling transport) Poll timed out, reissuing.");
            }
          }
        } catch (e) {
          if (!_running) {
            // Log but disregard errors that occur after stopping
            _log.finest("(LongPolling transport) Poll errored after shutdown: $e");
          } else {
            if (e is TimeoutException) {
              _log.finest("(LongPolling transport) Poll aborted.");
            } else {
              _closeError = Exception(e.toString());
              _running = false;
            }
          }
        }
      }
    } finally {
      _log.finest('(LongPolling transport) Polling complete.');

      // We will reach here with pollAborted==false when the server returned a response causing the transport to stop.
      // If pollAborted==true then client initiated the stop and the stop method will raise the close event after DELETE is sent.
      if (!_pollAbort.aborted) {
        _raiseOnClose();
      }
    }
  }

  Future<String?> _getAccessToken() async {
    if (_options.accessTokenFactory != null) {
      return await _options.accessTokenFactory!();
    }
    return null;
  }

  void _updateHeaderToken(HttpRequest request, String? token) {
    request.headers ??= <String, String>{};

    if (isNotBlank(token)) {
      request.headers!['Authorization'] = 'Bearer $token';
    } else {
      request.headers!.remove('Authorization');
    }
  }

  void _raiseOnClose() {
    if (onClose != null) {
      var logMessage = "(LongPolling transport) Firing onclose event.";
      if (_closeError != null) {
        logMessage += " Error: $_closeError";
      }
      _log.finest(logMessage);
      onClose?.call(Exception(_closeError?.toString()));
    }
  }
}
