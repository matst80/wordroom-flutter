import 'dart:async';
import 'dart:collection';

mixin HintProviderWorker {
  bool isMounted();

  void showHint(dynamic chars);

  void hideHint();
}

class HintManager {
  HintManager() {
    _hints = new Queue();
    _workers = new List<HintProviderWorker>();
  }

  Timer _timer;
  Queue _hints;
  List<HintProviderWorker> _workers;
  Duration duration = Duration(seconds: 1);

  void addWorker(HintProviderWorker worker) {
    if (!_workers.contains(worker)) _workers.add(worker);
  }

  void queueHint(hint) {
    _hints.add(hint);
    if ((_timer == null || !_timer.isActive) && _workers.length > 0) {
      _showHint();
    }
  }

  void _showHint() {
    if (_hints.length == 0) {
      _workers.forEach((worker) {
        if (worker != null && worker.isMounted()) {
          worker.hideHint();
        }
      });
      return;
    }

    var hint = _hints.removeFirst();
    _workers.forEach((worker) {
      if (worker != null && worker.isMounted()) {
        worker.showHint(hint);
      }
    });
    _timer = Timer(duration, _showHint);
  }
}
