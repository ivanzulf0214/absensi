import 'package:flutter/material.dart';

import 'login_page.dart';
import 'absensi_page.dart';
import 'history_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.blue[800],
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder> {
        '/LoginPage': (BuildContext context) => new LoginPage(),
        '/MainMenu': (BuildContext context) => new AbsensiPage(),
        '/HistoryPage': (BuildContext context) => new HistoryPage(),
      }
    );
  }
}
