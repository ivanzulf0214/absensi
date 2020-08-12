import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:audioplayers/audio_cache.dart';

import 'history_page.dart';
import 'url_helper.dart';

class AbsensiPage extends StatefulWidget {
  @override
  _AbsensiPageState createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  String nama = '';
  String hari = '';
  String jam_masuk = '-';
  String jam_keluar = '-';

  String result = '';

  String responseMsg = '';

  ProgressDialog pr;

  bool isSubmitting = false;

  Map<String, double> location;
  Location _location = new Location();
  double lat;
  double lng;

  static AudioCache player = new AudioCache();
  var acceptSound = "terimakasih.mp3";

  bool isPlaySound = false;

  void _playAcceptSound() {
    player.play(acceptSound, volume: 1.0);
  }

  Future<Null> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('id_karyawan');
    await prefs.remove('nama');
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/LoginPage');
  }

  @override
  void initState() {
    _getDailyLog();
  }

  Future<Null> _getDailyLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _prefIdKaryawan = prefs.getString('id_karyawan');
    setState(() {
      nama = prefs.get('nama');
    });

    var url = UrlHelper.BASE_URL + '/get_daily_log/';
    var response = await http.post(
        Uri.encodeFull(url),
        headers: {
          'Accept': 'application/json'
        },
        body: {
          'id_karyawan': _prefIdKaryawan
        }
    );

    if (response.statusCode == 200) {

      final jsonResponse = jsonDecode(response.body);
      setState(() {
        hari = jsonResponse['date'];
        jam_masuk = jsonResponse['time_in'];
        jam_keluar = jsonResponse['time_out'];
      });

    }
  }

  Future<Null> _getLocation() async {
    location = await _location.getLocation();
    setState(() {
      lat = location['latitude'];
      lng = location['longitude'];
    });
  }

  Future<void> _refresh() async {
    _getDailyLog();
  }

  Future<Null> _scan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _prefIdKaryawan = prefs.getString('id_karyawan');

    _getLocation();

    String scanRes = await scanner.scan();

    setState(() {
      isSubmitting = true;
    });

    pr = new ProgressDialog(context);


    if (isSubmitting) {
      pr.setMessage('Memproses...');
      pr.show();
    }

    setState(() {
      result = scanRes;
    });

    var url = UrlHelper.BASE_URL + '/do_absensi/';
    var response = await http.post(
        Uri.encodeFull(url),
        body: {
          'id_karyawan': _prefIdKaryawan,
          'secret': result,
          'latlng': '$lat, $lng',
        }
    );

    print('$lat, $lng');

    final jsonResponse = jsonDecode(response.body);
    setState(() {
      responseMsg = jsonResponse['message'];

      if (responseMsg == 'masuk') {
        responseMsg = 'Selamat datang. Semangat untuk hari ini!';
        isPlaySound = true;
      } else if (responseMsg == 'pulang') {
        responseMsg = 'Sampai jumpa. Hati-hati dijalan!';
        isPlaySound = true;
      } else if (responseMsg == 'sudah') {
        responseMsg = 'Anda telah menyelesaikan misi hari ini';
      }

      isSubmitting = false;
    });

    if (!isSubmitting) {
      pr.hide();
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Notifikasi'),
              content: Text('$responseMsg'),
              actions: <Widget>[
                new FlatButton(
                  onPressed: (){
                    Navigator.of(context).pop();
                  },
                  child: Text('Tutup'),
                ),
              ],
            );
          }
      );

      if (isPlaySound == true){
        _playAcceptSound();
        setState(() {
          isPlaySound = false;
        });
      }
      _getDailyLog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return hari != '' ? Scaffold(
      backgroundColor: Colors.yellow[0],
      appBar: AppBar(
        title: Text('Halo, $nama'),
        actions: <Widget>[
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text("Riwayat"),
              ),
              PopupMenuItem(
                value: 2,
                child: Text("Ubah kata sandi"),
              ),
              PopupMenuItem(
                value: 3,
                child: Text("Keluar"),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => new ShowHistory()));
              } else if (value == 2) {

              } else if (value == 3) {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: new Text('Konfirmasi', style: TextStyle(fontSize: 16.0),),
                        content: new Text('Anda yakin ingin keluar?', style: TextStyle(fontSize: 16.0),),
                        actions: <Widget>[
                          new FlatButton(
                              onPressed: (){
                                Navigator.pop(context);
                              },
                              child: new Text('Tidak', style: TextStyle(fontSize: 16.0),)
                          ),
                          new FlatButton(
                              onPressed: _logout,
                              child: new Text('Ya', style: TextStyle(fontSize: 16.0),)
                          )
                        ],
                      );
                    }
                );
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: <Widget>[
            Card(
              elevation: 5.0,
              margin: EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text('Tanggal Absensi', style: TextStyle(color: Colors.black54, fontSize: 14.0),),
                    subtitle: Text(
                      '$hari', style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: ListTile(
                          title: Text('Masuk', style: TextStyle(color: Colors.black54, fontSize: 14.0),),
                          subtitle: Text(
                            '$jam_masuk', style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.bold,)
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text('Keluar', style: TextStyle(color: Colors.black54, fontSize: 14.0),),
                          subtitle: Text(
                            '$jam_keluar', style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('By '),
                  Text('f', style: TextStyle(fontSize: 14.0,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),),
                  Text('d', style: TextStyle(fontSize: 14.0,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold),),
                  Text('v', style: TextStyle(fontSize: 14.0,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),),
                  Text('s', style: TextStyle(fontSize: 14.0,
                      color: Colors.lightBlue[800],
                      fontWeight: FontWeight.bold),),
                  Text(' team'),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.camera_alt),
        label: Text('Scan QR'),
        onPressed: _scan,
//        onPressed: _playAcceptSound,
        backgroundColor: Colors.blue[800],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ) : Scaffold(body: Center(child: CircularProgressIndicator()), backgroundColor: Colors.yellow[0],);
  }
}
