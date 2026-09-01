import 'dart:convert';
import 'package:find_me/Auth/login.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key, required this.email});
  final String email;

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  late TextEditingController _passwordcntrl;
  String _passwordErrorText = "";
  bool _hasErrorPassword = false;
  int _counterTesterError = 0;
  bool isObscured = true;
  late String message = "";

  @override
  void initState() {
    _passwordcntrl = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _passwordcntrl.dispose();
    super.dispose();
  }

  Future<void> resetPassword(String pwd) async {
    var reqBody = jsonEncode({"email": widget.email, "password": pwd});
    String url = 'http://192.168.43.28:5000/auth/resetPassword';
    var response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    print(jsonResponse["message"]);
    setState(() {
      message = jsonResponse["message"];
    });
    if (jsonResponse["status"]) {
      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const LoginPage()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1E1),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Image.asset("assets/images/findMeFleche.PNG"),
            const SizedBox(height: 10),
            const Text(
              'Reset Password',
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
              "Please Enter Your New Password and we will reset your account password on Find Me",
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
                  "assets/images/Reset_password.png",
                  width: 220,
                )),
            const SizedBox(height: 30),
            TextField(
              controller: _passwordcntrl,
              cursorColor: const Color(0xFFDF9A4F),
              style: const TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              obscureText: isObscured,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Enter your password",
                errorText: _passwordErrorText,
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: _hasErrorPassword
                            ? Colors.red
                            : const Color(0xFFDF9A4F),
                        width: 2),
                    gapPadding: 10),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: _hasErrorPassword
                            ? Colors.red
                            : const Color(0xFFDF9A4F),
                        width: 2),
                    gapPadding: 10),
                errorStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                labelStyle: const TextStyle(
                    color: Color(0xFFDF9A4F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins'),
                prefixIcon: const Icon(CupertinoIcons.lock_fill,
                    size: 25, color: Color.fromARGB(255, 97, 84, 72)),
                suffix: IconButton(
                  icon: isObscured
                      ? const Icon(
                          CupertinoIcons.eye_slash_fill,
                          size: 23,
                          color: Color.fromARGB(255, 97, 84, 72),
                        )
                      : const Icon(
                          CupertinoIcons.eye_fill,
                          size: 23,
                          color: Color.fromARGB(255, 97, 84, 72),
                        ),
                  splashRadius: 10,
                  onPressed: () {
                    setState(() {
                      isObscured = !isObscured;
                    });
                  },
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.fromLTRB(50, 5, 1, 10),
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
              ),
              onChanged: (value) {
                setState(() {
                  if (_counterTesterError != 0) {
                    if (value.length < 8) {
                      _passwordErrorText =
                          "Password should at least contain 8 characters!";
                      _hasErrorPassword = true;
                    } else {
                      _passwordErrorText = "";
                      _hasErrorPassword = false;
                    }
                  }
                });
              },
              onTap: () {
                setState(() {
                  if (_counterTesterError != 0) {
                    if (_passwordcntrl.text.length < 8) {
                      _passwordErrorText =
                          "Password should at least contain 8 characters!";
                      _hasErrorPassword = true;
                    } else {
                      _passwordErrorText = "";
                      _hasErrorPassword = false;
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
                    if (_passwordcntrl.text.isNotEmpty &&
                        (_passwordcntrl.text.length > 7)) {
                      resetPassword(_passwordcntrl.text)
                          .whenComplete(() => Fluttertoast.showToast(
                                msg: message,
                                toastLength: Toast.LENGTH_LONG,
                                backgroundColor: Colors.black.withOpacity(0.7),
                              ));
                    }
                    _counterTesterError += 1;
                    if (_passwordcntrl.text.length < 8) {
                      _passwordErrorText =
                          "Password should at least contain 8 characters!";
                      _hasErrorPassword = true;
                    } else {
                      _passwordErrorText = "";
                      _hasErrorPassword = false;
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
                  'Reset Password',
                  style: TextStyle(
                      color: Color(0xFF965D1A),
                      fontSize: 17,
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
