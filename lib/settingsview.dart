import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Settings',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          backgroundColor: Colors.purpleAccent.shade700,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SettingsPage(title: 'Settings'));
  }
}

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PreferencePage([
        PreferenceTitle('General'),
        DropdownPreference(
          'Language',
          'language_id',
          defaultVal: '1',
          values: ['1', '2'],
        ),
        PreferenceTitle('User'),
        TextFieldPreference(
          'Email',
          'email',
        ),
        TextFieldPreference(
          'Password',
          'password',
          obscureText: true,
        ),
        PreferenceTitle('Advanced'),
        CheckboxPreference('Enable Advanced Features', 'advanced_enabled')
      ]),
    );
  }
}
