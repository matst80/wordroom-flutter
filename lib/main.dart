import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'charwidget.dart';
import 'measurewidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(WordRoomOnline());
}

class WordRoomOnline extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordroom',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        backgroundColor: Colors.purpleAccent.shade700,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Wordroom'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class CharPosition {
  CharPosition({this.char, this.idx});

  final String char;
  final int idx;
}

class MoveResponse {
  MoveResponse(String data) {
    var json = jsonDecode(data);
    ok = json["ok"];
    levelComplete = json["levelComplete"];
    moves = json["moves"];
  }

  bool ok;
  bool levelComplete;

  int moves;
}

class _MyHomePageState extends State<MyHomePage> {
  static const String baseUrl = "https://wordroom.knatofs.se";
  static const int width = 6;
  static const int height = 8;
  static const int total = width * height;

  List<CharPosition> _charList =
      List.generate(total, (index) => CharPosition(char: ' ', idx: index));

  int _sessionId;
  int _boardId;
  double _itemWidth = 1;
  double _itemHeight = 1;
  String _currentWord = "";

  String title = "Wordroom";

  bool _pressed;
  List<int> _current = new List<int>();

  List<int> _taken = new List<int>();
  List<int> _highlighted = new List<int>();

  var client = http.Client();

  Future<void> _startLevel() async {
    var response = await client.get("$baseUrl/api/start");
    var data = jsonDecode(response.body);
    var board = data["board"];
    var session = data["session"];
    var gridString = board["charlist"];
    var i = 0;
    setState(() {
      _sessionId = session["id"];
      _boardId = board["id"];
      title = board["title"];
      _taken = new List<int>();
      _current = new List<int>();
      _charList = List.from(gridString
          .split('')
          .map((char) => CharPosition(char: char, idx: i++)));
    });
  }

  Future<String> _getHint() async {
    var response = await client.get("$baseUrl/api/hint/$_sessionId/$_boardId");
    var jsonAnswer = jsonDecode(response.body);
    return jsonAnswer["word"];
  }

  Future<MoveResponse> _makeMove(List<int> path) async {
    var response = await client.put("$baseUrl/api/move/$_sessionId/$_boardId",
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'path': path}));
    return MoveResponse(response.body);
  }

  List<int> _getLetterPositions(String letter) => List.from(
      _charList.where((element) => element.char == letter).map((e) => e.idx));

  Queue _queue = new Queue();

  void _triggerQueue() {
    const timeout = const Duration(seconds: 1);
    if (_queue.length > 0) {
      var toShow = _queue.removeLast() as List<int>;
      setState(() {
        _highlighted = toShow;
      });
      new Timer(timeout, () {
        _triggerQueue();
      });
    } else {
      setState(() {
        _highlighted = new List<int>();
      });
    }
  }

  Future<void> _showHint() async {
    var word = await _getHint();

    var toHighlight =
        word.split("").reversed.map((char) => _getLetterPositions(char));
    _queue.addAll(toHighlight);
    _triggerQueue();
  }

  void _showChars(String char) {
    var hasQueue = _queue.length>0;
    _queue.add(_getLetterPositions(char));
    if (!hasQueue) {
      _triggerQueue();
    }
  }

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  Future<void> _validateCurrent() async {
    var moveResponse = await _makeMove(_current);
    var noMoves = moveResponse.moves;
    if (moveResponse.levelComplete) {
      showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text('You made it!'),
              content: Text('Well done. it took $noMoves.moves'),
            );
          }
      );

      _startLevel();
    }
    setState(() {
      _pressed = false;
      if (moveResponse.ok) {
        _taken.addAll(_current);
      }
      _current = new List<int>();
    });
  }

  void _startCapture(PointerEvent e) {
    setState(() {
      _pressed = true;
    });
  }

  int getIndex(Offset position) {
    var x = (position.dx / _itemWidth).floor();
    var y = (position.dy / _itemHeight).floor();
    return y * width + x;
  }

  void _updateLocation(PointerEvent e) {
    // nothing yet
    var idx = getIndex(e.localPosition);
    if (!_current.contains(idx) &&
        !_taken.contains(idx) &&
        idx >= 0 &&
        idx <= total) {
      setState(() {
        _current.add(idx);
        _currentWord = _current.map((idx)=>_charList[idx].char).join("");
      });
      HapticFeedback.lightImpact();
      Feedback.forTap(context);
    }
  }

  void _endCapture(PointerEvent e) {
    _validateCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("$title"),
      ),
      body: Container(
          color: Colors.purple.shade200,
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
          )),
      bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Container(
            height: 70,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.help_outline),
                  padding: EdgeInsets.all(8),
                  iconSize: 48,
                  color: Colors.purple,
                  onPressed: () {
                    _showHint();
                  },
                ),
                Text("$_currentWord")
              ],
            ),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startLevel();
          //_showHint();
        },
        child: Icon(Icons.restore),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

}
