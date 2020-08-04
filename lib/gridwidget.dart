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

  int _getWordIndex(idx) {
    int result = 0;
    var i = 0;
    if (widget.game != null && widget.game.paths != null) {
      widget.game.paths.forEach((key, v) {
        if (v is List<dynamic>) {
          if (v.contains(idx)) {
            result = i + 0;
          }
        }
        i++;
      });
    }
    return result;
  }

  Color _offset(Color base, int val) {
    //int r = base.red - (val/2).round();
    int g = base.green + (val / 2).round();
    //int b = base.blue - val;
    return base.withAlpha(255 - val);
  }

  static List<Color> _colors = [
    Color.fromARGB(255, 85, 239, 196),
    Color.fromARGB(255, 129, 236, 236),
    Color.fromARGB(255, 116, 185, 255),
    Color.fromARGB(255, 162, 155, 254),
    Color.fromARGB(255, 223, 230, 233),
    Color.fromARGB(255, 0, 184, 148),
    Color.fromARGB(255, 0, 206, 201),
    Color.fromARGB(255, 9, 132, 227),
    Color.fromARGB(255, 108, 92, 231),
    Color.fromARGB(255, 178, 190, 195),
    Color.fromARGB(255, 255, 234, 167),
    Color.fromARGB(255, 250, 177, 160),
    Color.fromARGB(255, 255, 118, 117),
    Color.fromARGB(255, 253, 121, 168),
    Color.fromARGB(255, 99, 110, 114),
    Color.fromARGB(255, 253, 203, 110),
    Color.fromARGB(255, 225, 112, 85),
    Color.fromARGB(255, 214, 48, 49),
    Color.fromARGB(255, 232, 67, 147),
    Color.fromARGB(255, 45, 52, 54)
  ];

  Color _getColor(idx) {
    return _colors[_getWordIndex(idx) % _colors.length];
  }

  List<CharWidget> _getChars() =>
      List.from(widget.game.charList.map((e) => CharWidget(
            char: e.char,
            wordColor: _getColor(e.idx),
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
