/// An abstraction that controls when the client attempts to reconnect and how many times it does so.
abstract interface class RetryPolicy {
  /// Called after the transport loses the connection.
  /// [context] - Details related to the retry event to help determine how long to wait for the next retry.
  /// Returns the delay before the next attempt, or null if the client should give up.
  Duration? nextDelay(RetryContext context);
}

class RetryContext {
  /// The number of times the client has already retried.
  final int previousRetryCount;

  /// The amount of time that has elapsed since the client first tried to connect.
  final Duration elasped;

  /// The error that caused the retry, if any.
  final Object error;

  RetryContext({
    required this.previousRetryCount,
    required this.elasped,
    required this.error,
  });
}
