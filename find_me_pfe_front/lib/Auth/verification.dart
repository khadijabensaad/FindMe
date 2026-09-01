import 'dart:convert';
import 'package:find_me/Auth/signupComplete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterVerification extends StatefulWidget {
  const RegisterVerification({super.key, required this.userId});
  final String userId;

  @override
  State<RegisterVerification> createState() => _RegisterVerificationState();
}

class _RegisterVerificationState extends State<RegisterVerification> {
  late FocusNode pin2FocusNode;
  late FocusNode pin3FocusNode;
  late FocusNode pin4FocusNode;
  late FocusNode pin5FocusNode;
  late TextEditingController controller1;
  late TextEditingController controller2;
  late TextEditingController controller3;
  late TextEditingController controller4;
  late TextEditingController controller5;
  String message = "";
  late SharedPreferences prefs;
  late String email = "";
  late String name = "";

  @override
  void initState() {
    pin2FocusNode = FocusNode();
    pin3FocusNode = FocusNode();
    pin4FocusNode = FocusNode();
    pin5FocusNode = FocusNode();
    controller1 = TextEditingController();
    controller2 = TextEditingController();
    controller3 = TextEditingController();
    controller4 = TextEditingController();
    controller5 = TextEditingController();
    initSharedPref();
    super.initState();
  }

  @override
  void dispose() {
    pin2FocusNode.dispose();
    pin3FocusNode.dispose();
    pin4FocusNode.dispose();
    pin5FocusNode.dispose();
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
    controller5.dispose();
    super.dispose();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> otpVerification(String otp) async {
    var reqBody = jsonEncode({"userId": widget.userId, "otp": otp});
    String url = 'http://192.168.43.28:5000/auth/otp';
    var response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    setState(() {
      message = jsonResponse["message"];
    });
    if (jsonResponse["status"]) {
      prefs.setBool("activated", true);
      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const SignUpComplete()),
          (route) => false);
    }
  }

  Future<void> resendOtpVerification() async {
    var userToken = prefs.getString("userToken");
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(userToken!);
    setState(() {
      email = jwtDecodedToken["email"];
      name = jwtDecodedToken["name"];
    });
    print("userId: ${widget.userId}");
    print("email: ${email}");
    print("name: ${name}");
    var reqBody =
        jsonEncode({"userId": widget.userId, "email": email, "name": name});
    String url = 'http://192.168.43.28:5000/auth/resendOtp';
    var response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse["status"]) {
      setState(() {
        message = jsonResponse["message"];
      });
    }
  }

  void nextField(String value, FocusNode focusNode) {
    if (value.length == 1) {
      focusNode.requestFocus();
    }
  }

  String getContent() {
    String content = '';
    content += controller1.text;
    content += controller2.text;
    content += controller3.text;
    content += controller4.text;
    content += controller5.text;
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1E1),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 90),
            Image.asset(
              "assets/images/findMeFleche.PNG",
            ),
            const SizedBox(height: 10),
            const Text(
              'Verification',
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
              "We Sent a Verification Code To Your Email",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("This Code will Expire in ",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                TweenAnimationBuilder(
                  tween: Tween(begin: 300.0, end: 0),
                  duration: const Duration(seconds: 300),
                  builder: (context, value, child) => Text(
                    "${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toInt().toString().padLeft(2, '0')}",
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDF9A4F)),
                  ),
                )
              ],
            ),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 60,
                  height: 80,
                  child: TextField(
                    controller: controller1,
                    autofocus: true,
                    cursorColor: const Color(0xFFDF9A4F),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 24),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                    ),
                    onChanged: (value) {
                      nextField(value, pin2FocusNode);
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 80,
                  child: TextField(
                    controller: controller2,
                    focusNode: pin2FocusNode,
                    cursorColor: const Color(0xFFDF9A4F),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 24),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                    ),
                    onChanged: (value) {
                      nextField(value, pin3FocusNode);
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 80,
                  child: TextField(
                    controller: controller3,
                    focusNode: pin3FocusNode,
                    cursorColor: const Color(0xFFDF9A4F),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 24),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                    ),
                    onChanged: (value) {
                      nextField(value, pin4FocusNode);
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 80,
                  child: TextField(
                    controller: controller4,
                    focusNode: pin4FocusNode,
                    cursorColor: const Color(0xFFDF9A4F),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 24),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                    ),
                    onChanged: (value) {
                      nextField(value, pin5FocusNode);
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 80,
                  child: TextField(
                    controller: controller5,
                    focusNode: pin5FocusNode,
                    cursorColor: const Color(0xFFDF9A4F),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 24),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Color(0xFFDF9A4F), width: 2),
                          gapPadding: 5),
                    ),
                    onChanged: (value) {
                      pin5FocusNode.unfocus();
                    },
                  ),
                ),
              ],
            ),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            SizedBox(
              height: 50,
              width: 230,
              child: ElevatedButton(
                onPressed: () {
                  String content = getContent();
                  print(content);
                  print(widget.userId);
                  //Navigator.push(context, CupertinoPageRoute(builder: (context) => const SignUpComplete(),));
                  otpVerification(content)
                      .whenComplete(() => Fluttertoast.showToast(
                            msg: message,
                            toastLength: Toast.LENGTH_LONG,
                            backgroundColor: Colors.black.withOpacity(0.7),
                          ));
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: const Color(0xFFDF9A4F), // background color
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(
                      color: Color(0xFF965D1A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't Receive The Code?",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                TextButton(
                    onPressed: () {
                      resendOtpVerification()
                          .whenComplete(() => Fluttertoast.showToast(
                                msg: message,
                                toastLength: Toast.LENGTH_LONG,
                                backgroundColor: Colors.black.withOpacity(0.7),
                              ));
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateColor.resolveWith(
                          (states) => const Color.fromARGB(255, 255, 237, 211)),
                    ),
                    child: const Text(
                      "Resend Code",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF965D1A),
                        decoration: TextDecoration.underline,
                      ),
                    )),
              ],
            ),
            const Expanded(
              flex: 3,
              child: SizedBox(),
            ),
          ],
        ),
      )),
    );
  }
}
