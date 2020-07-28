import 'package:flutter/material.dart';

import 'charwidget.dart';
import 'hints.dart';
import 'measurewidget.dart';
import 'models.dart';
import 'wordroom_api.dart';

class GridWidget extends StatefulWidget {
  GridWidget(
      {Key key,
      @required this.game,
      @required this.api,
      @required this.hintManager,
      this.onWordChange,
      this.onMoveResponse})
      : super(key: key);

  final Board game;
  final HintManager hintManager;
  final WordroomApi api;
  final ValueChanged<String> onWordChange;
  final ValueChanged<MoveResponse> onMoveResponse;

  @override
  _GridWidgetState createState() => _GridWidgetState();
}

class _GridWidgetState extends State<GridWidget> with HintProviderWorker {
  _GridWidgetState();

  double _itemWidth = 1;
  double _itemHeight = 1;

  List<int> _current = new List<int>();
  List<int> _taken = new List<int>();
  List<int> _highlighted = new List<int>();

  int _getIndex(Offset position) {
    var x = (position.dx / _itemWidth).floor();
    var y = (position.dy / _itemHeight).floor();
    return y * widget.game.width + x;
  }

  void _updateLocation(PointerEvent e) {
    var idx = _getIndex(e.localPosition);
    if (_isValidIndex(idx)) {
      setState(() {
        _current.add(idx);
      });

      _updateWord(_current
          .map((idx) => widget.game.charList[idx].char)
          .join("")
          .toUpperCase());

      Feedback.forTap(context);
    }
  }

  bool _isValidIndex(int idx) =>
      !_current.contains(idx) &&
          !_taken.contains(idx) &&
          idx >= 0 &&
          idx < widget.game.total;

  void _updateWord(String word) {
    widget.onWordChange?.call(word);
  }

  void _endCapture(PointerEvent e) async {
    if (_current.length <= 1) {
      setState(() {
        _current = new List<int>();
      });
      return;
    }
    var moveResponse = await widget.api.makeBoardMove(widget.game, _current);

    setState(() {
      if (moveResponse.ok) {
        _taken.addAll(_current);
        widget.onMoveResponse?.call(moveResponse);
      }
      _current = new List<int>();
    });
  }

  List<CharWidget> _getChars() =>
      List.from(widget.game.charList.map((e) =>
          CharWidget(
            char: e.char,
            highlighted: _highlighted.contains(e.idx),
            taken: _taken.contains(e.idx),
            selected: _current.contains(e.idx),
            onLongPress: () {
              widget.hintManager.queueHint(e.char);
            },
          )));

  @override
  Widget build(BuildContext context) {
    return MeasureSize(
      onChange: (size) {
        setState(() {
          _itemWidth = size.width / widget.game.width;
          _itemHeight = _itemWidth;
        });
      },
      child: Listener(
        onPointerMove: _updateLocation,
        onPointerUp: _endCapture,
        child: GridView.count(crossAxisCount: 6, children: _getChars()),
      ),
    );
  }

  @override
  void hideHint() {
    setState(() {
      _highlighted = new List<int>();
    });
  }

  List<int> _getLetterPositions(String letter) =>
      List.from(
          widget.game.charList.where((e) => e.char == letter).map((e) =>
          e.idx));

  @override
  void showHint(chars) {
    setState(() {
      if (chars is String) {
        _highlighted = _getLetterPositions(chars);
      } else if (chars is List<int>) {
        _highlighted = chars;
      }
    });
  }

  @override
  void initState() {
    widget.hintManager.addWorker(this);
    super.initState();
  }

  @override
  void didUpdateWidget(GridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game != oldWidget.game) {
      _resetLevel();
    }
  }

  @override
  bool isMounted() {
    return mounted;
  }

  void _resetLevel() {
    setState(() {
      _highlighted.clear();
      _current.clear();
      _taken.clear();
    });
  }
}
