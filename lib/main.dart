import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:share/share.dart';
import 'package:wordroom/gridwidget.dart';
import 'package:wordroom/hints.dart';

import 'linklistener.dart';
import 'models.dart';
import 'wordroom_api.dart';

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

class _WordroomState extends LinkListener<WordroomPlayGrid> {
  _WordroomState() {
    _api = WordroomApi();
    _hintManager = HintManager();
  }

  Board _board;
  WordroomApi _api;
  HintManager _hintManager;
  String _currentWord = "";
  String title = "Wordroom";

/*
  String _identifier = 'Unknown';

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
*/

  Future<void> _startLevel() async {
    var board = await _api.startRandom("en");
    setState(() {
      _board = board;
    });
  }

  Future<void> _joinLevel(id) async {
    var board = await _api.join(id);
    setState(() {
      _board = board;
    });
  }

  @override
  void processLink(String link) {
    var sessionToLoad = link.split('/').last;
    print("loading: $sessionToLoad");
    _joinLevel(sessionToLoad);
  }

  @override
  void initState() {
    _board = Board.empty();
    super.initState();
    startLinkListeners();
    _startLevel();
  }

  void _shareSession(title, text) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: [
              FlatButton(
                child: Text("Share"),
                onPressed: () {
                  var sessionId = _board.sessionId;
                  Share.share("https://wordroom.knatofs.se/sessions/$sessionId",
                      subject: "Checkout my wordroom session");
                },
              )
            ],
          );
        });
  }

  void _queueHint() async {
    var hint = await _api.getBoardHint(_board);
    hint.split("").forEach((char) {
      _hintManager.queueHint(char);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade200,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              _shareSession('Invite others', 'Share your game');
            },
          )
        ],
        title: Text(_board.title),
      ),
      body: GridWidget(
        api: _api,
        game: _board,
        hintManager: _hintManager,
        onWordChange: (word) => setState(() {
          _currentWord = word;
        }),
        onMoveResponse: (moveResponse) {
          var noMoves = moveResponse.moves;
          if (moveResponse.levelComplete) {
            _shareSession(
                'You made it!', 'Well done. it only took $noMoves moves');
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.accessibility),
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              iconSize: 32,
              color: Colors.purple,
              onPressed: () {
                _queueHint();
              },
            ),
            Text(
              "$_currentWord   ",
              style: TextStyle(),
            )
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
