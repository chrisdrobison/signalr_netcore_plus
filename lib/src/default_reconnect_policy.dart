import 'retry_policy.dart';

class DefaultReconnectPolicy implements RetryPolicy {
  static const List<Duration?> _defaultDelays = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 10),
    Duration(seconds: 30),
    null
  ];

  final List<Duration?> delays;

  DefaultReconnectPolicy({List<Duration?>? delays}) : delays = delays != null ? [...delays, null] : _defaultDelays;

  @override
  Duration? nextDelay(RetryContext context) {
    return delays[context.previousRetryCount];
  }
}
