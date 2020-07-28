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
          'language',
          defaultVal: 'en',
          values: ['en', 'sv'],
        ),
        PreferenceTitle('User'),
        TextFieldPreference(
          'Display Name',
          'user_display_name',
        ),
        PreferenceTitle('Advanced'),
        CheckboxPreference('Enable Advanced Features', 'advanced_enabled')
      ]),
    );
  }
}
