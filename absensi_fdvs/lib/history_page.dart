import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'model/history_model.dart';
import 'url_helper.dart';

Future<List<History>> fetchHistory(http.Client client) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String _prefIdKaryawan = prefs.getString('id_karyawan');

  final response = await client.post(
      UrlHelper.BASE_URL + '/get_log_history/',
      body: {
        'id_karyawan': _prefIdKaryawan,
      },
      headers: {
        'Accept': 'application/json'
      }
  );
  return compute(parseHistory, response.body);
}

List<History> parseHistory(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<History>((json) => History.fromJson(json)).toList();
}

class ShowHistory extends StatefulWidget {
  @override
  _ShowHistoryState createState() => _ShowHistoryState();
}

class _ShowHistoryState extends State<ShowHistory> {

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Absensi'),
      ),
      body: FutureBuilder(
          future: fetchHistory(http.Client()),
          builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);

            return snapshot.hasData
                ? RefreshIndicator(onRefresh: _refresh, child: HistoryPage(histories: snapshot.data),)
                : Center(child: CircularProgressIndicator());
          }
      ),
    );
  }
}


class HistoryPage extends StatefulWidget {

  final List<History> histories;

  const HistoryPage({Key key, this.histories}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[0],
      body: ListView.builder(
        itemCount: widget.histories.length,
        itemBuilder: (context, index) {
          return widget.histories[index].date == 'null'
          ? Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Data tidak ditemukan', style: TextStyle(fontSize: 18.0),),
            ),
          )
          : Card(
            elevation: 5.0,
            margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(
                    '${widget.histories[index].date}',
                    style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ListTile(
                        title: Text('Masuk', style: TextStyle(color: Colors.black54, fontSize: 14.0),),
                        subtitle: Text(
                          '${widget.histories[index].time_in}',
                          style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('Keluar', style: TextStyle(color: Colors.black54, fontSize: 14.0),),
                        subtitle: Text(
                          '${widget.histories[index].time_out}',
                          style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
