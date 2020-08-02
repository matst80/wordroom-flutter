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

    var gridString = data["charlist"];
    var i = 0;

    sessionId = data["sessionId"];
    title = data["title"];

    charList = List.from(
        gridString.split('').map((char) => CharPosition(char: char, idx: i++)));

    // debug only
    words = data["words"].cast<String>();
    paths = data["paths"];
  }

  String title;
  List<CharPosition> charList;
  int sessionId;
  String language;

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

class AuthResponse {
  AuthResponse({this.token, this.renew_token});

  final String token;
  final String renew_token;
}

class HintResponse {
  final String word;
  final List<int> path;

  HintResponse(this.word, this.path);
}

class MoveResponse {
  MoveResponse(String data) {
    var json = jsonDecode(data);
    ok = json["valid"];
    levelComplete = json["complete"];
    moves = json["moves"];
    duration = json["duration"];
  }

  bool ok;
  bool levelComplete;
  int duration;
  int moves;
}
