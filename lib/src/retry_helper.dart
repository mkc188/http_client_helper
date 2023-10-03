import 'package:http_client_helper/src/cancellation_token.dart';
import 'dart:math' as math;

class RetryHelper {
  RetryHelper._();

  static final _rand = math.Random();
  static final maxRandomizationFactor = 0.15;
  static final interval = const Duration(milliseconds: 200);
  static final maxAttempts = 10;
  static final maxDelay = const Duration(seconds: 120);

  static Duration computeDelay(int attempt) {
    final exp = math.min(attempt, 31); // prevent overflows.
    var delay = interval * math.pow(2, exp);
    final randomPercent = _rand.nextDouble() * maxRandomizationFactor * 2 -
        maxRandomizationFactor;
    final randomDelay = delay.inMilliseconds * randomPercent;
    delay = Duration(milliseconds: delay.inMilliseconds + randomDelay.ceil());
    return delay > maxDelay ? maxDelay : delay;
  }

  //try again，after millisecondsDelay time
  static Future<T?> tryRun<T>(
    Future<T> Function() asyncFunc, {
    Duration timeRetry = const Duration(milliseconds: 100),
    int retries = 3,
    CancellationToken? cancelToken,
    bool Function()? throwThenExpction,
  }) async {
    int attempts = 0;
    while (attempts <= retries) {
      attempts++;
      //print("try at ${attempts} times");
      try {
        return await asyncFunc();
        // ignore: unused_catch_clause
      } on OperationCanceledError catch (error) {
        rethrow;
      } catch (error) {
        if (throwThenExpction != null && throwThenExpction()) {
          rethrow;
        }
        //twice time to retry
        //if (attempts > 1) millisecondsDelay *= 2;
      }
      //delay to retry
      //try {
      if (attempts < retries) {
        final Future<void> future = CancellationTokenSource.register(
            cancelToken, Future<void>.delayed(timeRetry + computeDelay(attempts), () {}));
        await future;
      }

      //} on OperationCanceledError catch (error) {
      //throw error;
      //}
    }
    return null;
  }
}

