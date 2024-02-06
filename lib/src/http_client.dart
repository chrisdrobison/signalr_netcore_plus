import 'abort_controller.dart';

class HttpRequest {
  /// The HTTP method to use for the request.
  String? method;

  /// The URL for the request.
  String? url;

  ///The body content for the request. May be a [String] or an [Uint8List].
  Object? content;

  ///An object describing headers to apply to the request.
  Map<String, String>? headers;

  /// An AbortSignal that can be monitored for cancellation.
  AbortSignal? abortSignal;

  ///The time to wait for the request to complete before throwing a [TimeoutException].
  Duration? timeout;

  HttpRequest({
    this.method,
    this.url,
    this.content,
    this.headers,
    this.abortSignal,
    this.timeout,
  });
}

class HttpResponse {
  /// The status code of the response.
  final int statusCode;

  /// The status message of the response
  final String? statusText;

  /// May be a [String] (json) or an [Uint8List] (binary)
  final Object? content;

  HttpResponse(this.statusCode, {this.statusText = '', this.content});
}

abstract class HttpClient {
  /// Issues an HTTP GET request to the specified URL, returning a Promise that resolves with an {@link @microsoft/signalr.HttpResponse} representing the result.
  ///
  /// url The URL for the request.
  /// HttpRequest options Additional options to configure the request. The 'url' field in this object will be overridden by the url parameter.
  /// Returns a Future<HttpResponse> that resolves with an HttpResponse describing the response, or rejects with an Error indicating a failure.
  ///
  Future<HttpResponse> get(String url, {required HttpRequest options}) {
    options.method = 'GET';
    options.url = url;
    return send(options);
  }

  /// Issues an HTTP POST request to the specified URL, returning a Promise that resolves with an {@link @microsoft/signalr.HttpResponse} representing the result.
  ///
  /// url: The URL for the request.
  /// options: Additional options to configure the request. The 'url' field in this object will be overridden by the url parameter.
  /// Returns a Future that resolves with an describing the response, or rejects with an Error indicating a failure.
  ///
  Future<HttpResponse> post(String? url, {required HttpRequest options}) {
    options.method = 'POST';
    options.url = url;
    return send(options);
  }

  ///Issues an HTTP DELETE request to the specified URL, returning a Promise that resolves with an {@link @microsoft/signalr.HttpResponse} representing the result.
  ///
  /// The URL for the request.
  /// Additional options to configure the request. The 'url' field in this object will be overridden by the url parameter.
  /// Returns a Future that resolves with an describing the response, or rejects with an Error indicating a failure.
  ///
  Future<HttpResponse> delete(String? url, {required HttpRequest options}) {
    options.method = 'DELETE';
    options.url = url;
    return send(options);
  }

  ///Issues an HTTP request to the specified URL, returning a Future that resolves with an SignalRHttpResponse representing the result.
  ///
  /// request: An HttpRequest describing the request to send.
  /// Returns a Future that resolves with an SignalRHttpResponse describing the response, or rejects with an Error indicating a failure.
  ///
  Future<HttpResponse> send(HttpRequest request);
}
