import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'charwidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:unique_identifier/unique_identifier.dart';
import 'package:share/share.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:convert';

import 'measurewidget.dart';

void main() {
  runApp(WordRoomOnline());
}

enum UniLinksType { string, uri }

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
      home: WordroomPlayGrid(title: 'Wordroom'),
    );
  }
}

class WordroomPlayGrid extends StatefulWidget {
  WordroomPlayGrid({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _WordroomState createState() => _WordroomState();
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
    duration = json["duration"];
  }

  bool ok;
  bool levelComplete;
  int duration;
  int moves;
}

class _WordroomState extends State<WordroomPlayGrid> with SingleTickerProviderStateMixin {
  static const String baseUrl = "https://wordroom.knatofs.se";
  static const int width = 6;
  static const int height = 8;
  static const int total = width * height;

  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<CharPosition> _charList =
      List.generate(total, (index) => CharPosition(char: ' ', idx: index));

  int _sessionId;
  int _boardId;
  double _itemWidth = 1;
  double _itemHeight = 1;
  String _currentWord = "";

  String title = "Wordroom";

  String _identifier = 'Unknown';

  bool _pressed;
  List<int> _current = new List<int>();

  List<int> _taken = new List<int>();
  List<int> _highlighted = new List<int>();

  var client = http.Client();

  Future<void> initUniqueIdentifierState() async {
    String identifier;
    try {
      identifier = await UniqueIdentifier.serial;
    } on PlatformException {
      identifier = 'Failed to get Unique Identifier';
    }

    if (!mounted) return;

    setState(() {
      _identifier = identifier;
    });
  }

  Future<void> _startLevel() async {
    var response = await client.get("$baseUrl/api/start/en");
    var data = jsonDecode(response.body);
    loadBoard(data);
  }

  Future<void> _joinLevel(id) async {
    var response = await client.get("$baseUrl/api/join/$id");
    var data = jsonDecode(response.body);
    loadBoard(data);
  }

  void loadBoard(data) {
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
    var hasQueue = _queue.length>0;
    var toHighlight =
        word.split("").reversed.map((char) => _getLetterPositions(char));
    _queue.addAll(toHighlight);
    if (!hasQueue) {
      _triggerQueue();
    }
  }

  void _addQueue(List<int> toShow) {
    var hasQueue = _queue.length>0;
    _queue.add(toShow);
    if (!hasQueue) {
      _triggerQueue();
    }
  }

  void _showChars(String char) {
    _addQueue(_getLetterPositions(char));
  }

  @override
  void initState() {
    super.initState();
    _startLevel();
    initPlatformState();
  }

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  initPlatformState() async {
    if (_type == UniLinksType.string) {
      await initPlatformStateForStringUniLinks();
    } else {
      await initPlatformStateForUriUniLinks();
    }
  }

  void parseLink(String link) {
    if (!mounted || link==null || link == "") return;
    var sessionToLoad = link.split('/').last;
    print("loading: $sessionToLoad");
    _joinLevel(sessionToLoad);
  }

  initPlatformStateForStringUniLinks() async {

    getLinksStream().listen((String link) {
      parseLink(link);
    }, onError: (err) {
      print('got err: $err');
    });

    try {
      var initialLink = await getInitialLink();
      parseLink(initialLink);
    } on PlatformException {
      print('got platformerror');
    } on FormatException {
      print('got formaterror');
    }
  }

  initPlatformStateForUriUniLinks() async {

    getUriLinksStream().listen((Uri uri) {
      parseLink(uri.toString());
    }, onError: (err) {
      print('got err: $err');
    });

    try {
      var initialUri = await getInitialUri();
      parseLink(initialUri.toString());
    } on PlatformException {
      print('got platformerror');
    } on FormatException {
      print('got formaterror');
    }

  }

  void _shareSession(title, text) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: [FlatButton(child:Text("Share"), onPressed: () {
              Share.share("https://wordroom.knatofs.se/sessions/$_sessionId",
                  subject: "Checkout my wordroom session");
            },)],
          );
        }
    );
  }

  Future<void> _validateCurrent() async {
    var moveResponse = await _makeMove(_current);
    var noMoves = moveResponse.moves;
    if (moveResponse.levelComplete) {
      _shareSession('You made it!','Well done. it took $noMoves.moves');

      //_startLevel();
    }
    setState(() {
      _pressed = false;
      if (moveResponse.ok) {
        _taken.addAll(_current);
        _currentWord = "";
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
        idx < total) {
      setState(() {
        _current.add(idx);
        _currentWord = _current.map((idx)=>_charList[idx].char).join("").toUpperCase();
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
      key: _scaffoldKey,
      backgroundColor: Colors.purple.shade200,
      appBar: AppBar(
        actions: [IconButton(icon:Icon(Icons.share), onPressed: (){
          _shareSession('Invite others', 'Share your game');
        },)],
        title: Text("$title"),
      ),
      body: Container(
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
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.accessibility),
                  padding: EdgeInsets.fromLTRB(20,10,20,10),
                  iconSize: 32,
                  color: Colors.purple,
                  onPressed: () {
                    _showHint();
                  },
                ),
                Text("$_currentWord   ", style: TextStyle(),)
              ],
            ),
          ),
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
