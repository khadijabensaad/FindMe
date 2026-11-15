import 'dart:convert';
import 'package:find_me/Models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_me/core/api_config.dart';

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
      String url = "${ApiConfig.baseUrl}/auth/getUser/${identifier}";
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
