import 'dart:async';

import 'package:flutter/widgets.dart';

/// Application activity only: there is deliberately no player-controlled pause.
class GameActivity extends ValueNotifier<bool> with WidgetsBindingObserver {
  GameActivity._() : super(true) {
    WidgetsBinding.instance.addObserver(this);
    value =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  static GameActivity? _instance;
  static GameActivity get instance => _instance ??= GameActivity._();
  FocusNode? _lastFocus;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active == value) return;
    if (!active) _lastFocus = FocusManager.instance.primaryFocus;
    value = active;
    if (active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final focus = _lastFocus;
        if (focus?.context?.mounted == true && focus!.canRequestFocus) {
          focus.requestFocus();
        }
        _lastFocus = null;
      });
    }
  }

  Future<void> get whenActive async {
    if (value) return;
    final completer = Completer<void>();
    void changed() {
      if (!value) return;
      removeListener(changed);
      completer.complete();
    }

    addListener(changed);
    await completer.future;
  }

  static Future<void> delay(Duration duration) {
    final completer = Completer<void>();
    ActiveGameTimer(duration, completer.complete);
    return completer.future;
  }
}

/// A one-shot timer whose remaining duration excludes background time.
class ActiveGameTimer {
  ActiveGameTimer(this._remaining, this._callback) {
    GameActivity.instance.addListener(_activityChanged);
    _activityChanged();
  }

  Duration _remaining;
  final VoidCallback _callback;
  final Stopwatch _watch = Stopwatch();
  Timer? _timer;
  bool _cancelled = false;

  void _activityChanged() {
    if (_cancelled) return;
    _timer?.cancel();
    if (_watch.isRunning) {
      _watch.stop();
      _remaining -= _watch.elapsed;
      _watch.reset();
    }
    if (GameActivity.instance.value) {
      _watch.start();
      _timer = Timer(_remaining.isNegative ? Duration.zero : _remaining, () {
        cancel();
        _callback();
      });
    }
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _timer?.cancel();
    _watch.stop();
    GameActivity.instance.removeListener(_activityChanged);
  }
}

/// The session is updated before notifying only the clock's listeners.
class ActiveGameClock extends ValueNotifier<Duration> {
  ActiveGameClock({required this.onTick, Stopwatch? stopwatch})
    : _watch = stopwatch ?? Stopwatch(),
      super(Duration.zero) {
    GameActivity.instance.addListener(_activityChanged);
    _activityChanged();
  }

  final Duration Function(Duration delta) onTick;
  final Stopwatch _watch;
  Duration _previous = Duration.zero;
  Timer? _timer;

  void reset([Duration elapsed = Duration.zero]) {
    _watch.reset();
    _previous = Duration.zero;
    value = elapsed;
  }

  void flush() {
    final now = _watch.elapsed;
    final delta = now - _previous;
    _previous = now;
    if (delta > Duration.zero) value = onTick(delta);
  }

  void _activityChanged() {
    _timer?.cancel();
    if (GameActivity.instance.value) {
      _watch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => flush());
    } else {
      _watch.stop();
      flush();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _watch.stop();
    GameActivity.instance.removeListener(_activityChanged);
    super.dispose();
  }
}

class GameActivityBoundary extends StatelessWidget {
  const GameActivityBoundary({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: GameActivity.instance,
    child: child,
    builder: (context, active, child) => TickerMode(
      enabled: active,
      child: ExcludeFocus(
        excluding: !active,
        child: IgnorePointer(ignoring: !active, child: child),
      ),
    ),
  );
}
