import 'dart:convert';

class Board {
  Board.empty() {
    charList =
        List.generate(total, (index) => CharPosition(char: ' ', idx: index));
    words = new List<String>();
    title = "Loading";
  }

  Board(String jsonString) {
    var data = jsonDecode(jsonString);
    var board = data["board"];
    var session = data["session"];
    var gridString = board["charlist"];
    var i = 0;

    sessionId = session["id"];
    boardId = board["id"];
    title = board["title"];

    charList = List.from(
        gridString.split('').map((char) => CharPosition(char: char, idx: i++)));

    // debug only
    words = board["words"].cast<String>();
    paths = board["paths"];
    code = board["code"];
  }

  String title;
  List<CharPosition> charList;
  int sessionId;
  int boardId;
  String language;
  String code;

  Map paths;

  int get width => 6;

  int get height => 8;

  int get total => width * height;

  // debug only
  List<String> words;
}

class CharPosition {
  CharPosition({this.char, this.idx});

  final String char;
  final int idx;
}

class HintResponse {
  final String word;
  final List<int> path;

  HintResponse(this.word, this.path);
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
