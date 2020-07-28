import 'dart:convert';

import 'package:http/http.dart';
import 'package:preferences/preference_service.dart';

import 'models.dart';

class WordroomApi {
  static const String baseUrl = "https://wordroom.knatofs.se";

  BaseClient _client;

  WordroomApi() {
    _client = Client();
  }

  String get name => PrefService.get("user_display_name") ?? "anonymous";

  String get userid => PrefService.get("userid") ?? "-1";

  Future<Response> _put(String url, dynamic body) async =>
      await _client.put(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

  //Future<Response> _post(String url, dynamic body) async =>
//      await _client.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));

  Future<Response> _get(String url) async =>
      await _client.get(url, headers: {'Content-Type': 'application/json'});

  Future<Board> startRandom(String language) async {
    var response = await _put(
        "$baseUrl/api/start/$language", {"userid": userid, "name": name});
    return Board(response.body);
  }

  Future<Board> join(id) async {
    var response =
        await _put("$baseUrl/api/join/$id", {"userid": userid, "name": name});
    return Board(response.body);
  }

  Future<String> getHint(int sessionId, int boardId) async {
    var response = await _get("$baseUrl/api/hint/$sessionId/$boardId");
    var jsonAnswer = jsonDecode(response.body);
    return jsonAnswer["word"];
  }

  Future<String> getBoardHint(Board board) {
    return getHint(board.sessionId, board.boardId);
  }

  Future<MoveResponse> makeMove(
      int sessionId, int boardId, List<int> path) async {
    var response =
        await _put("$baseUrl/api/move/$sessionId/$boardId", {'path': path});
    return MoveResponse(response.body);
  }

  Future<MoveResponse> makeBoardMove(Board board, List<int> path) {
    return makeMove(board.sessionId, board.boardId, path);
  }
}
