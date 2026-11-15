import 'dart:convert';
import 'package:find_me/Models/category_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
<<<<<<< HEAD
import 'package:find_me/core/api_config.dart';
=======
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267

class CategoryApiCall {
  late SharedPreferences prefs;

  CategoryApiCall() {
    initSharedPref(); // Call initSharedPref in the constructor
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<List<CategoryModel>> getAllcategories() async {
    List<CategoryModel> categories = [];
<<<<<<< HEAD
    const String url = "${ApiConfig.baseUrl}/categories/getAllCategories";
=======
    const String url = "http://192.168.43.28:5000/categories/getAllCategories";
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
    final http.Response resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(resp.body);
      categories =
          jsonResponse.map((item) => CategoryModel.fromJson(item)).toList();
      print("success getAllcategories");
      print(categories);
    } else {
      print("failed: ${resp.statusCode}");
    }
    return categories;
  }

  Future<List<dynamic>> fetchCategoryProducts(String shopId) async {
    final url =
<<<<<<< HEAD
        '${ApiConfig.baseUrl}/categories/getCategoryProducts/$shopId';
=======
        'http://192.168.43.28:5000/categories/getCategoryProducts/$shopId';
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
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
        throw Exception('Failed to fetch category products');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
