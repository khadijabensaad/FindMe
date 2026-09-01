import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:find_me/Auth/verification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  Uint8List? _image;
  File? selectedImage;
  late TextEditingController _usernamecntrl;
  late TextEditingController _emailcntrl;
  late TextEditingController _passwordcntrl;
  bool isObscured = true;
  String _usernameErrorText = "";
  String _emailErrorText = "";
  String _passwordErrorText = "";
  bool _hasErrorUsername = false;
  bool _hasErrorEmail = false;
  bool _hasErrorPassword = false;
  int _counterTesterError = 0;
  String message = "";
  late SharedPreferences prefs;
  bool isVisible = false;
  String userId = "";

  @override
  void initState() {
    _usernamecntrl = TextEditingController();
    _emailcntrl = TextEditingController();
    _passwordcntrl = TextEditingController();
    initSharedPref();
    super.initState();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  //libere l'espace memoire
  @override
  void dispose() {
    _usernamecntrl.dispose();
    _emailcntrl.dispose();
    _passwordcntrl.dispose();
    super.dispose();
  }

  Future<void> signup(
      String username, String email, String password, File file) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.43.28:5000/auth/signup'));
    request.fields
        .addAll({'username': username, 'email': email, 'password': password});
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    http.StreamedResponse response = await request.send();

    var jsonResponse = jsonDecode(await response.stream.bytesToString());
    setState(() {
      isVisible = false;
      message = jsonResponse["message"];
    });
    print("message: ${message}");
    if (jsonResponse["status"]) {
      var userToken = jsonResponse['token'];
      prefs.setString("userToken", userToken);
      prefs.setBool("activated", false);
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(userToken);
      setState(() {
        userId = jwtDecodedToken["id"];
      });
      print(userToken);
      Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => RegisterVerification(userId: userId),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFDF1E1),
        appBar: AppBar(
          title: const Text(
            "Sign Up",
            style: TextStyle(
                color: Color(0xFF965D1A), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color((0xFFFDF1E1)),
          shadowColor: Colors.black,
          elevation: 3,
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
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 0, bottom: 15),
                    child: Image.asset(
                      'assets/images/find_me.PNG',
                      width: 200,
                    ),
                  ),
                  const Text(
                    "Sign Up To Simplify Your Exploration !",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF965D1A),
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Stack(
                    children: [
                      _image != null
                          ? CircleAvatar(
                              radius: 65, backgroundImage: MemoryImage(_image!))
                          : const CircleAvatar(
                              radius: 65,
                              backgroundImage:
                                  AssetImage('assets/images/avatar.png'),
                            ),
                      Positioned(
                          bottom: -5,
                          left: 85,
                          child: IconButton(
                              onPressed: () {
                                showImagePickerOption(context);
                              },
                              icon: const Icon(
                                Icons.add_a_photo_rounded,
                                color: Color(0xFF965D1A),
                                size: 30,
                              )))
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, bottom: 5, top: 5),
                    child: TextField(
                      controller: _usernamecntrl,
                      cursorColor: const Color(0xFFDF9A4F),
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        errorText: _usernameErrorText,
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                                color: _hasErrorUsername
                                    ? Colors.red
                                    : const Color(0xFFDF9A4F),
                                width: 2),
                            gapPadding: 10),
                        focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                                color: _hasErrorUsername
                                    ? Colors.red
                                    : const Color(0xFFDF9A4F),
                                width: 2),
                            gapPadding: 10),
                        labelText: "Username",
                        hintText: "Enter your username",
                        labelStyle: const TextStyle(
                            color: Color(0xFFDF9A4F),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Poppins'),
                        prefixIcon: const Icon(
                            CupertinoIcons.person_crop_circle,
                            size: 25,
                            color: Color.fromARGB(255, 97, 84, 72)),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFFDF9A4F), width: 2),
                            gapPadding: 10),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFFDF9A4F), width: 2),
                            gapPadding: 10),
                        errorStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (_counterTesterError != 0) {
                            if (value.isEmpty) {
                              _usernameErrorText =
                                  "This field cannot be empty!";
                              _hasErrorUsername = true;
                            } else if (value.length < 3) {
                              _usernameErrorText =
                                  "Username should at least have 3 characters!";
                              _hasErrorUsername = true;
                            } else {
                              _usernameErrorText = '';
                              _hasErrorUsername = false;
                            }
                          }
                        });
                      },
                      onTap: () {
                        setState(() {
                          if (_counterTesterError != 0) {
                            if (_usernamecntrl.text.isEmpty) {
                              _usernameErrorText =
                                  "This field cannot be empty!";
                              _hasErrorUsername = true;
                            } else if (_usernamecntrl.text.length < 3) {
                              _usernameErrorText = "Username is not valid!";
                              _hasErrorUsername = true;
                            } else {
                              _usernameErrorText = '';
                              _hasErrorUsername = false;
                            }
                          }
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, bottom: 5, top: 5),
                    child: TextField(
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFFDF9A4F), width: 2),
                            gapPadding: 10),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFFDF9A4F), width: 2),
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
                            } else if (!value.contains('@') ||
                                !value.contains('.')) {
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
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: TextField(
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
                            borderSide: const BorderSide(
                                color: Color(0xFFDF9A4F), width: 2),
                            gapPadding: 10),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFFDF9A4F), width: 2),
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
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  SizedBox(
                    height: 50,
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor:
                            const Color(0xFFDF9A4F), // background color
                      ),
                      child: const Text(
                        'REGISTER',
                        style: TextStyle(
                            color: Color(0xFF965D1A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins'),
                      ),
                      onPressed: () {
                        if (_usernamecntrl.text.length > 2 &&
                            _emailcntrl.text.isNotEmpty &&
                            (_emailcntrl.text.contains('@') &&
                                _emailcntrl.text.contains('.')) &&
                            (_passwordcntrl.text.length > 7) &&
                            (_image != null)) {
                          print("Test request signup ");
                          setState(() {
                            isVisible = true;
                          });
                          signup(_usernamecntrl.text, _emailcntrl.text,
                                  _passwordcntrl.text, selectedImage!)
                              .whenComplete(() => Fluttertoast.showToast(
                                    msg: message,
                                    toastLength: Toast.LENGTH_LONG,
                                    backgroundColor:
                                        Colors.black.withOpacity(0.7),
                                  ));
                          //Navigator.push(context, CupertinoPageRoute(builder: (context)=>const  RegisterVerification()));
                          //print(path);
                        }
                        if (_image == null) {
                          Fluttertoast.showToast(
                            msg: "Add Profile Picture",
                            toastLength: Toast.LENGTH_LONG,
                            backgroundColor: Colors.black.withOpacity(0.7),
                          );
                        }
                        setState(() {
                          _counterTesterError += 1;
                          if (_usernamecntrl.text.isEmpty) {
                            _usernameErrorText = "This field cannot be empty!";
                            _hasErrorUsername = true;
                          } else if (_usernamecntrl.text.length < 3) {
                            _usernameErrorText =
                                "Username should at least have 3 characters!";
                            _hasErrorUsername = true;
                          }

                          if (_emailcntrl.text.isEmpty) {
                            _emailErrorText = "This field cannot be empty!";
                            _hasErrorEmail = true;
                          } else if (!_emailcntrl.text.contains('@') ||
                              !_emailcntrl.text.contains('.')) {
                            _emailErrorText = "Email is not valid!";
                            _hasErrorEmail = true;
                          }

                          if (_passwordcntrl.text.length < 8) {
                            _passwordErrorText =
                                "Password should at least contain 8 characters!";
                            _hasErrorPassword = true;
                          }
                        });
                      },
                    ),
                  ),
                  Visibility(
                    child: CircularProgressIndicator(
                      color: Color(0xFF965D1A),
                    ),
                    visible: isVisible,
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
          ),
        ));
  }

  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: const Color(0xFFFDF1E1),
        context: context,
        builder: (builder) {
          return SizedBox(
            height: 150,
            width: double.infinity,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Text(
                    "Choose Your Profile Picture :",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Color(0xFF965D1A)),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _pickImageFromCamera();
                        },
                        icon: const Icon(
                          CupertinoIcons.camera_fill,
                          color: Color(0xFF965D1A),
                        ),
                        label: const Text(
                          'Camera',
                          style: TextStyle(
                              color: Color(0xFF965D1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _pickImageFromGallery();
                        },
                        icon: const Icon(
                          CupertinoIcons.photo_fill_on_rectangle_fill,
                          color: Color(0xFF965D1A),
                        ),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(
                              color: Color(0xFF965D1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
  }

  Future _pickImageFromGallery() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }

  Future _pickImageFromCamera() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }
}
