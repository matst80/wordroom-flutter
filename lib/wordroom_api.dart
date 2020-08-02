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

  AuthResponse _authResponse;

  String get email => PrefService.get("email") ?? "-1";

  String get password => PrefService.get("password") ?? "-1";

  Future<Response> _put_auth(String url, dynamic body) async {
    await _enshure_auth();
    return await _client.put(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authResponse?.token
        },
        body: jsonEncode(body));
  }

  Future<Response> _post(String url, dynamic body) async =>
      await _client.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

  Future<Response> _get(String url) async =>
      await _client.get(url, headers: {'Content-Type': 'application/json'});

  Future _enshure_auth() async {
    if (_authResponse == null) {
      _authResponse = await login();
    }
  }

  Future<Response> _get_auth(String url) async {
    await _enshure_auth();
    return await _client.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': _authResponse?.token
    });
  }

  Future<Board> startRandom(String language) async {
    var response = await _get_auth(
        "$baseUrl/api/game/start?language=$language&difficulty=easy");
    return Board(response.body);
  }

  Future<AuthResponse> login() async {
    var response = await _post(
        "$baseUrl/api/auth", {"email": email, "password": password});
    var jsonResponse = jsonDecode(response.body);
    var auth = AuthResponse(
        token: jsonResponse["access_token"],
        renew_token: jsonResponse["renewal_token"]);
    if (auth != null) {
      _authResponse = auth;
    }
    return auth;
  }

  Future<HintResponse> getHint(int sessionId) async {
    var response = await _get_auth("$baseUrl/api/game/hint/$sessionId");
    var jsonAnswer = jsonDecode(response.body);
    var path = jsonAnswer["path"].cast<int>();
    return HintResponse(jsonAnswer["word"], path);
  }

  Future<HintResponse> getBoardHint(Board board) {
    return getHint(board.sessionId);
  }

  Future<MoveResponse> makeMove(int sessionId, List<int> path) async {
    var response =
        await _put_auth("$baseUrl/api/game/move/$sessionId", {'path': path});
    return MoveResponse(response.body);
  }

  Future<MoveResponse> makeBoardMove(Board board, List<int> path) {
    return makeMove(board.sessionId, path);
  }
}
