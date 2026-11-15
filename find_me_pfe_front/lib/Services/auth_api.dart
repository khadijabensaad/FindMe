import 'dart:convert';
import 'package:find_me/Models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
<<<<<<< HEAD
import 'package:find_me/core/api_config.dart';
=======
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267

class AuthCallAPi {
  late SharedPreferences prefs;

  AuthCallAPi() {
    initSharedPref(); // Call initSharedPref in the constructor
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<UserModel> getUserById(String identifier) async {
    UserModel user;
    try {
<<<<<<< HEAD
      String url = "${ApiConfig.baseUrl}/auth/getUser/${identifier}";
=======
      String url = "http://192.168.43.28:5000/auth/getUser/${identifier}";
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
      final http.Response resp = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      );
      if (resp.statusCode == 200) {
        dynamic jsonResponse = json.decode(resp.body);
        user = UserModel.fromJson(jsonResponse);
        print("succes getUserById");
        return user;
      } else {
        print("failure: ${resp.statusCode}");
      }
    } catch (error) {
      print("$error");
      throw Exception('Request failed .. $error');
    }
    throw Exception('Request failed.');
  }
}
