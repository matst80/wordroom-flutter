import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:preferences/preferences.dart';
import 'package:share/share.dart';
import 'package:unique_identifier/unique_identifier.dart';
import 'package:wordroom/gridwidget.dart';
import 'package:wordroom/hints.dart';
import 'package:wordroom/settingsview.dart';

import 'linklistener.dart';
import 'login_page.dart';
import 'models.dart';
import 'wordroom_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init(prefix: 'wr_');

  PrefService.setDefaultValues({'language_id': '1'});

  runApp(WordRoomOnline());
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class WordRoomOnline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var email = PrefService.get("email");
    var needsSignin = email == null;

    return MaterialApp(
      title: 'Wordroom',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        backgroundColor: Colors.purpleAccent.shade700,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: MyBehavior(),
          child: child,
        );
      },
      home: needsSignin ? LoginPage() : WordroomPlayGrid(title: 'Wordroom'),
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

  Future<void> _initUniqueIdentifierState() async {
    try {
      var identifier = await UniqueIdentifier.serial;
      PrefService.setString("userid", identifier);
    } on PlatformException {
      print("not supported deviceid");
    }
  }

  Future<void> _startLevel() async {
    var board = await _api.startRandom(PrefService.get("language_id"));
    setState(() {
      _board = board;
    });
  }

  Future<void> _joinLevel(id) async {
    //var board = await _api.join(id);
    //setState(() {
//      _board = board;
//    });
  }

  @override
  void processLink(String link) {
    var sessionToLoad = link
        .split('/')
        .last;
    print("loading: $sessionToLoad");
    _joinLevel(sessionToLoad);
  }

  @override
  void initState() {
    _board = Board.empty();
    super.initState();
    startLinkListeners();
    _initUniqueIdentifierState();
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
    if (hint.path != null && hint.path.isNotEmpty) {
      hint.path.forEach((nr) {
        _hintManager.queueHint(List<int>.filled(1, nr));
      });
    } else {
      hint.word.split("").forEach((char) {
        _hintManager.queueHint(char);
      });
    }
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
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
              child: Container(
                  padding: EdgeInsets.all(10),
                  child: GridWidget(
                    api: _api,
                    game: _board,
                    hintManager: _hintManager,
                    onWordChange: (word) =>
                        setState(() {
                          _currentWord = word;
                        }),
                    onMoveResponse: (moveResponse) {
                      var noMoves = moveResponse.moves;
                      if (moveResponse.levelComplete) {
                        _shareSession('You made it!',
                            'Well done. it only took $noMoves moves');
                      }
                    },
                  ))),
        ],
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
            IconButton(
              icon: Icon(Icons.settings),
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              iconSize: 32,
              color: Colors.purple,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SettingsPage(title: 'Settings')),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startLevel();
        },
        child: Icon(Icons.restore),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
