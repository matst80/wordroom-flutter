import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:wordroom/wordroom_api.dart';

import 'main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email;
  String _password;
  WordroomApi _api = WordroomApi();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.blueGrey, Colors.lightBlueAccent]),
        ),
        child: ListView(
          children: <Widget>[
            Column(
              children: <Widget>[
                Text("Email"),
                TextFormField(
                  onChanged: (val) {
                    PrefService.setString("email", val);
                  },
                  initialValue: "mats.tornberg@gmail.com",
                  decoration: InputDecoration(labelText: 'Enter your email'),
                ),
                Text("Password"),
                TextFormField(
                  initialValue: "7bananer",
                  obscureText: true,
                  onChanged: (val) {
                    PrefService.setString("password", val);
                  },
                  decoration: InputDecoration(labelText: 'Enter your password'),
                ),
                FlatButton(
                  child: Text('Login'),
                  onPressed: () async {
                    var result = await _api.login();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                WordroomPlayGrid(title: 'Wordroom')));
                  },
                ),
                FlatButton(
                  child: Text('Signup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
