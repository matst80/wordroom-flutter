import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wordroom/main.dart';
import 'measurewidget.dart';

class Board {
  Board(String jsonString) {
    var data = jsonDecode(jsonString);
    var board = data["board"];
    var session = data["session"];
    var gridString = board["charlist"];
    var i = 0;

    sessionId = session["id"];
    boardId = board["id"];
    title = board["title"];

    charList = List.from(gridString
        .split('')
        .map((char) => CharPosition(char: char, idx: i++)));

    // debug only
    words = board["words"];
  }

  String title;
  List<CharPosition> charList;
  int sessionId;
  int boardId;
  String language;

  // debug only
  List<String> words;
}

class GridWidget extends StatefulWidget {
  GridWidget({Key key, this.width, this.height}) : super(key: key);

  final int width;
  final int height;

  @override
  _GridWidgetState createState() => _GridWidgetState();
}

class _GridWidgetState extends State<GridWidget> {
  _GridWidgetState();

  double _itemWidth = 1;
  double _itemHeight = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10),
        child: MeasureSize(
          onChange: (size) {
            setState(() {
              _itemWidth = size.width / width;
              _itemHeight = _itemWidth;
            });
          },
          child: Listener(
              onPointerDown: _startCapture,
              onPointerMove: _updateLocation,
              onPointerUp: _endCapture,
              child: GridView.count(
                crossAxisCount: 6,
                children: List.from(_charList.map((e) => CharWidget(
                  char: e.char,
                  highlighted: _highlighted.contains(e.idx),
                  taken: _taken.contains(e.idx),
                  selected: _current.contains(e.idx),
                  onLongPress: (){ _showChars(e.char);},
                ))),
              )),
        ))
  }

}