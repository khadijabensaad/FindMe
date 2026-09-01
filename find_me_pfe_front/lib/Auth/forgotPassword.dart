import 'dart:convert';

import 'package:find_me/Auth/forgetPasswordOTP.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late TextEditingController _emailcntrl;
  String _emailErrorText = "";
  bool _hasErrorEmail = false;
  int _counterTesterError = 0;
  late String message = "";

  @override
  void initState() {
    _emailcntrl = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailcntrl.dispose();
    super.dispose();
  }

  Future<void> forgetPassword(String email) async {
    var reqBody = jsonEncode({"email": email});
    String url = 'http://192.168.43.28:5000/auth/forgetPassword';
    var response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    setState(() {
      message = jsonResponse["message"];
    });
    if (jsonResponse["status"]) {
      String userId = jsonResponse["userId"];
      String name = jsonResponse["name"];
      String email = jsonResponse["email"];
      print(userId);
      Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
              builder: (context) => ForgetPasswordOTP(
                  userId: userId, username: name, useremail: email)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1E1),
      appBar: AppBar(
        backgroundColor: const Color((0xFFFDF1E1)),
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              CupertinoIcons.back,
              color: Color((0xFF965D1A)),
            )),
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 20),
            Image.asset("assets/images/findMeFleche.PNG"),
            const SizedBox(height: 10),
            const Text(
              'Forgot Password',
              style: TextStyle(
                  fontSize: 26,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDF9A4F)),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Please Enter Your Email and we will send a verification code to return your account",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Opacity(
                opacity: 0.9,
                child: Image.asset(
                  "assets/images/forgot_pwd.png",
                  width: 200,
                )),
            const SizedBox(height: 30),
            TextField(
              controller: _emailcntrl,
              cursorColor: const Color(0xFFDF9A4F),
              style: const TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                errorText: _emailErrorText,
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: _hasErrorEmail
                            ? Colors.red
                            : const Color(0xFFDF9A4F),
                        width: 2),
                    gapPadding: 10),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: _hasErrorEmail
                            ? Colors.red
                            : const Color(0xFFDF9A4F),
                        width: 2),
                    gapPadding: 10),
                labelText: "Email",
                hintText: "Enter your email",
                labelStyle: const TextStyle(
                    color: Color(0xFFDF9A4F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins'),
                prefixIcon: const Icon(CupertinoIcons.mail,
                    size: 25, color: Color.fromARGB(255, 97, 84, 72)),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: Color(0xFFDF9A4F), width: 2),
                    gapPadding: 10),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: Color(0xFFDF9A4F), width: 2),
                    gapPadding: 10),
                errorStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              onChanged: (value) {
                setState(() {
                  if (_counterTesterError != 0) {
                    if (value.isEmpty) {
                      _emailErrorText = "This field cannot be empty!";
                      _hasErrorEmail = true;
                    } else if (!value.contains('@') || !value.contains('.')) {
                      _emailErrorText = "Email is not valid!";
                      _hasErrorEmail = true;
                    } else {
                      _emailErrorText = '';
                      _hasErrorEmail = false;
                    }
                  }
                });
              },
              onTap: () {
                setState(() {
                  if (_counterTesterError != 0) {
                    if (_emailcntrl.text.isEmpty) {
                      _emailErrorText = "This field cannot be empty!";
                      _hasErrorEmail = true;
                    } else if (!_emailcntrl.text.contains('@') ||
                        !_emailcntrl.text.contains('.')) {
                      _emailErrorText = "Email is not valid!";
                      _hasErrorEmail = true;
                    } else {
                      _emailErrorText = '';
                      _hasErrorEmail = false;
                    }
                  }
                });
              },
            ),
            const SizedBox(
              height: 40,
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_emailcntrl.text.isNotEmpty &&
                        (_emailcntrl.text.contains('@') &&
                            _emailcntrl.text.contains('.'))) {
                      //Navigator.push(context, CupertinoPageRoute(builder: (context) => const ForgetPasswordOTP(),));
                      forgetPassword(_emailcntrl.text)
                          .whenComplete(() => Fluttertoast.showToast(
                                msg: message,
                                toastLength: Toast.LENGTH_LONG,
                                backgroundColor: Colors.black.withOpacity(0.7),
                              ));
                    }
                    _counterTesterError += 1;
                    if (_emailcntrl.text.isEmpty) {
                      _emailErrorText = "This field cannot be empty!";
                      _hasErrorEmail = true;
                    } else if (!_emailcntrl.text.contains('@') ||
                        !_emailcntrl.text.contains('.')) {
                      _emailErrorText = "Email is not valid!";
                      _hasErrorEmail = true;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: const Color(0xFFDF9A4F), // background color
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                      color: Color(0xFF965D1A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(height: 20)
          ]),
        ),
      )),
    );
  }
}
