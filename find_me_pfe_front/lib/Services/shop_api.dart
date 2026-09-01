import 'dart:convert';
import 'package:find_me/Models/shop_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ShopApiCall {
  late SharedPreferences prefs;

  ShopApiCall() {
    initSharedPref(); // Call initSharedPref in the constructor
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<dynamic> getShopByName(String name) async {
    late ShopModel shop;
    try {
      String url = "http://192.168.43.28:5000/shops/getShopByName?name=${name}";
      final http.Response resp = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      );
      if (resp.statusCode == 200) {
        dynamic jsonResponse = json.decode(resp.body);
        if (jsonResponse is List && jsonResponse.length > 0) {
          shop = ShopModel.fromJson(jsonResponse[0]);
          print("succes getShopByName");
          print(shop.coordinates.latitude);
          return shop;
        }
      } else {
        print("failure: ${resp.statusCode}");
        throw Exception('Failed to get shop: ${resp.statusCode}');
      }
    } catch (error) {
      print("$error");
      return null;
    }
  }

  Future<ShopModel> getShopById(String id) async {
    late ShopModel shop;
    try {
      String url = "http://192.168.43.28:5000/shops/getShop/${id}";
      final http.Response resp = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      );
      if (resp.statusCode == 200) {
        dynamic jsonResponse = json.decode(resp.body);
        if (jsonResponse is List && jsonResponse.length > 0) {
          shop = ShopModel.fromJson(jsonResponse[0]);
          print("succes getShopById");

          return shop;
        }
      } else {
        print("failure: ${resp.statusCode}");
        throw Exception('Failed to get shop: ${resp.statusCode}');
      }
    } catch (error) {
      print("$error");
      throw Exception('Request failed .. $error');
    }
    throw Exception('Request failed .');
  }

  Future<List<dynamic>> CalculateDistance(
      double latitude, double longitude) async {
    String url = "http://192.168.43.28:5000/shops/CalculateDistance";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': latitude, 'long': longitude}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> shops = data['shops'];
        return shops;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<dynamic>> fetchShopProducts(String shopId) async {
    final url = 'http://192.168.43.28:5000/shops/getShopProducts/$shopId';
    await initSharedPref();
    var token = prefs.getString("userToken");
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${token}'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> prods = data['prods'];
        return prods;
      } else {
        throw Exception('Failed to fetch shop products');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
