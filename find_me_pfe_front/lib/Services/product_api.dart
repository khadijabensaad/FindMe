import 'package:find_me/Models/prod_filter.dart';
import 'package:find_me/Models/product_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductApiCall {
  late SharedPreferences prefs;

  ProductApiCall() {
    initSharedPref(); // Call initSharedPref in the constructor
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<List<ProductModel>> searchProductsWithFilter(
      ProductFilter filtre) async {
    await initSharedPref();
    List<ProductModel> products = [];
    var token = prefs.getString("userToken");
    try {
      const String url =
          "http://192.168.43.28:5000/products/searchProductsWithFilter";

      final http.Response resp = await http.post(Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${token}'
          },
          body: jsonEncode(filtre.toJson()));

      if (resp.statusCode == 200) {
        /*print("name ${filtre.name}");
      
      print("colors ${filtre.colors}");
      print("sortBy ${filtre.sortBy}");
      print("sortOrder ${filtre.sortOrder}");
      print("region ${filtre.region}");
      print("size: ${filtre.size}");*/
        List<dynamic> jsonResponse = json.decode(resp.body);
        print(jsonResponse);
        products =
            jsonResponse.map((item) => ProductModel.fromJson(item)).toList();
        //print("${products.length} Products recieved");
        //print("${resp.body}");

        return products;
      } else {
        print("failed: ${resp.statusCode}");
      }
    } catch (error) {
      print("erreur: ${error}");
    }
    return [];
  }

  Future<ProductModel> getProductById(String identifier) async {
    await initSharedPref();
    ProductModel product;
    var token = prefs.getString("userToken");
    try {
      String url =
          "http://192.168.43.28:5000/products/getProduct/${identifier}";
      final http.Response resp = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${token}'
        },
      );
      if (resp.statusCode == 200) {
        dynamic jsonResponse = json.decode(resp.body);
        product = ProductModel.fromJson(jsonResponse);
        print("succes getProductById");
        return product;
      } else {
        print("failure: ${resp.statusCode}");
      }
    } catch (error) {
      print("$error");
      throw Exception('Request failed .. $error');
    }
    throw Exception('Request failed.');
  }

  Future<ProductModel> getProductByBarCode(String identifier) async {
    await initSharedPref();
    ProductModel product;
    var token = prefs.getString("userToken");
    try {
      String url =
          "http://192.168.43.28:5000/products/getProductByBarCode?barcode=${identifier}";
      final http.Response resp = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${token}'
        },
      );
      if (resp.statusCode == 200) {
        dynamic jsonResponse = json.decode(resp.body);
        product = ProductModel.fromJson(jsonResponse);
        print("succes");
        return product;
      } else {
        print("failure: ${resp.statusCode}");
      }
      return ProductModel(
          id: '',
          price: -1,
          name: '',
          rating: -1,
          barcode: -1,
          thumbnail: '',
          images: [],
          colors: [],
          v: -1,
          brand: '',
          size: [],
          shops: [],
          description: '',
          category: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFavorite: false,
          discountPrice: -1);
    } catch (error) {
      print("$error");
      return ProductModel(
          id: '',
          price: -1,
          name: '',
          rating: -1,
          barcode: -1,
          thumbnail: '',
          images: [],
          colors: [],
          v: -1,
          brand: '',
          size: [],
          shops: [],
          description: '',
          category: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFavorite: false,
          discountPrice: -1);
    }
  }

  Future<List<dynamic>> getDiscountedProducts() async {
    final url = 'http://192.168.43.28:5000/discounts/getDiscountedProducts';
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
        List<dynamic> prods = data['products'];
        return prods;
      } else {
        throw Exception('Failed to get discounted products');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
