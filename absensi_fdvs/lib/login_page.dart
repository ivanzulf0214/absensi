import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'absensi_page.dart';
import 'url_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  String msg = '';
  bool isLoggedIn = false;

  String id_karyawan = '';
  String nama = '';

  final _formKey = GlobalKey<FormState>();
  final FocusNode _focus = new FocusNode();

  TextEditingController idCtrl = new TextEditingController();
  TextEditingController passCtrl = new TextEditingController();

  bool _isLoggingIn = false;
  bool showPass = false;
  bool obsecureText;

  @override
  void initState() {
    obsecureText = true;
    _getLoggedIn();
  }

  void _togglePass() {
    setState(() {
      showPass = !showPass;
      obsecureText = !obsecureText;
    });
  }

  Future<Null> _getLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // bikin object pref
    setState(() {
      var _prefsIsLoggedIn = prefs.getBool('isLoggedIn');
      var _prefsIdKaryawan = prefs.getString('id_karyawan');
      var _prefsNamaKaryawan = prefs.getString('nama');
      setState(() {
        isLoggedIn = _prefsIsLoggedIn;
        id_karyawan = _prefsIdKaryawan;
        nama = _prefsNamaKaryawan;
      });
    });
  }

  Future<Null> _doLogin() async {
    if (_formKey.currentState.validate()) {

      setState(() {
        _isLoggingIn = true;
        msg = '';
      });

      String inputID = idCtrl.text;
      String inputPass = passCtrl.text;

      String url = UrlHelper.BASE_URL + '/login';

      var response = await http.post(
        Uri.parse(url),
        body: {
          'id': inputID,
          'password': inputPass
        },
        headers: {
          'Accept': 'application/json'
        }
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        setState(() {
          id_karyawan = jsonResponse['id_karyawan'];
          nama = jsonResponse['nama'];
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedIn', true);
        prefs.setString('id_karyawan', id_karyawan);
        prefs.setString('nama', nama);

//        _getLoggedIn();

        Navigator.pushReplacementNamed(context, '/MainMenu'); // arahin ke MainMenu
      } else {
        setState(() {
          msg = 'Login gagal. Cek lagi id karyawan dan kata sandi';
        });
      }

      setState(() {
        _isLoggingIn = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == true) {
      return AbsensiPage();
    } else {
      return Scaffold(
        body: ModalProgressHUD(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _buildLoginForm(context),
            ),
          ),
          inAsyncCall: _isLoggingIn,
          opacity: 0.5,
          progressIndicator: CircularProgressIndicator(),
        ),
      );
    }
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(padding: const EdgeInsets.only(top: 75.0),),
          Padding(
            padding: const EdgeInsets.only(bottom: 75.0),
            child: Container(
              height: 100.0,
              width: 100.0,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                  ),
                ]
              ),
              child: Image.asset('assets/launcher_fdvs.png', height: 100.0, width: 100.0,),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, bottom: 10.0),
            child: TextFormField(
              controller: idCtrl,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  labelText: 'ID karyawan'
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(_focus);
              },
              validator: (value) {
                if (value.isEmpty) {
                  return 'Tolong masukkan ID karyawan';
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, bottom: 10.0),
            child: TextFormField(
              controller: passCtrl,
              keyboardType: TextInputType.text,
              obscureText: obsecureText,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                suffixIcon: IconButton(
                  icon: Icon(showPass == false ? Icons.visibility : Icons
                      .visibility_off, color: Colors.black,),
                  onPressed: _togglePass,
                ),
              ),
              textInputAction: TextInputAction.done,
              focusNode: _focus,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Tolong masukkan kata sandi';
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child: RaisedButton(
                child: Text('Masuk', style: TextStyle(fontSize: 18.0),),
                color: Colors.blue[800],
                textColor: Colors.white,
                onPressed: _doLogin,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              msg == null ? '' : msg, style: TextStyle(color: Colors.red),),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 10.0),
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
          ),
        ],
      ),
    );
  }

}
