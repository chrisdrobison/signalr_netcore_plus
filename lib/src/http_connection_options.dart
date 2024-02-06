import 'http_client.dart';
import 'transport.dart';

class HttpConnectionOptions {
  /// Default headers to be sent with every request.
  final Map<String, String>? headers;

  /// An [HttpClient] to use to send HTTP requests.
  final HttpClient? httpClient;

  /// Transport type to use for the connection. Either this or [transport] must be specified, but not both.
  final HttpTransportType? transportType;

  /// An instance of [Transport] to use for the connection. Either this or [transportType] must be specified, but not both.
  final Transport? transport;

  /// A function that provides an access token for the connection.
  final AccessTokenFactory? accessTokenFactory;

  /// A boolean indicating whether to log message content.
  final bool logMessageContent;

  /// A boolean indicating whether to skip negotiation.
  final bool skipNegotiation;

  /// The time to wait for the connection to complete before throwing a [TimeoutException]. Default is 100 seconds.
  final Duration timeout;

  HttpConnectionOptions({
    this.headers,
    this.httpClient,
    this.transportType,
    this.transport,
    this.accessTokenFactory,
    this.logMessageContent = false,
    this.skipNegotiation = false,
    this.timeout = const Duration(seconds: 100),
  }) {
    if (transportType != null && transport != null) {
      throw ArgumentError('Either transportType or transport must be specified, but not both.');
    }
  }
}
