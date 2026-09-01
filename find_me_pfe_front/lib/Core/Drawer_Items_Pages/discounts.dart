import 'dart:convert';
import 'package:find_me/Core/Search/product_detail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:find_me/Services/product_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  List<dynamic> prods = [];
  ProductApiCall _productApiCall = ProductApiCall();
  bool isLoading = true;
  bool isFavorite = false;
  late SharedPreferences prefs;
  late var token = "";
  String message = '';

  @override
  void initState() {
    super.initState();
    fetchDiscountedProducts();
    initSharedPref().then((_) {
      setState(() {
        token = prefs.getString("userToken")!;
      });
    });
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> addToFavorites(String prodId) async {
    await initSharedPref();
    var reqBody = jsonEncode({'prodId': prodId});
    String url = 'http://192.168.43.28:5000/auth/addToFavorites';
    var response = await http.put(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    setState(() {
      message = jsonResponse["message"];
    });
    if (jsonResponse["status"]) {
      if (message == "Product deleted from favorites.") {
        isFavorite = false;
      } else {
        isFavorite = true;
      }
    }
  }

  Future<void> fetchDiscountedProducts() async {
    try {
      final apiService = ProductApiCall();

      final prods = await apiService
          .getDiscountedProducts()
          .whenComplete(() => setState(() {
                isLoading = false;
              })); // Replace with actual lat and long values

      setState(() {
        this.prods = prods;
      });
    } catch (error) {
      // Handle errors
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      color: Color(0xFF965D1A),
      backgroundColor: Color(0xFFFDF1E1),
      child: Scaffold(
        backgroundColor: Color(0xFFFDF1E1),
        appBar: AppBar(
            title: Text("Promotions",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 18)),
            centerTitle: true,
            backgroundColor: Color(0xFFFDF1E1)),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(color: Color(0xFF965D1A)),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<List<dynamic>>(
                        future: _productApiCall.getDiscountedProducts(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final prod = prods[index];
                                  final thumbnail = prod['thumbnail'];
                                  final name = prod['name'];
                                  final id = prod['id'];
                                  final brand = prod['brand'];
                                  final rating = prod['rating'];
                                  final discountPrice = prod['discountPrice'];
                                  return InkWell(
                                    onTap: () {
                                      print("Page search products: $id");
                                      Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (context) =>
                                                ProductDetail(identifier: id),
                                          ));
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 2),
                                      child: Row(
                                        children: [
                                          Container(
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Image.network(
                                              "$thumbnail",
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                              width: 110,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10, left: 20),
                                              child: SizedBox(
                                                height: 120,
                                                width: 120,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    Text(
                                                      "$name",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      "$brand",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 11,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .star_rate_rounded,
                                                          color:
                                                              Color(0xFFFFBD59),
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Text(
                                                          "$rating",
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFFFFBD59)),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      "$discountPrice"
                                                      r" DT",
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 13,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 3,
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        addToFavorites(snapshot
                                                                    .data![
                                                                index]["id"])
                                                            .whenComplete(() =>
                                                                Fluttertoast
                                                                    .showToast(
                                                                  msg: message,
                                                                  toastLength: Toast
                                                                      .LENGTH_SHORT,
                                                                  backgroundColor: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.7),
                                                                ));
                                                        ;
                                                      },
                                                      child: Icon(
                                                        Icons.favorite_rounded,
                                                        color: snapshot.data![
                                                                    index][
                                                                "isFavorite"] //khedmet khadija
                                                            ? Colors.red
                                                            : Colors.grey,
                                                        /*isInFavorites                           //khedmet khadija
                                                      ? Colors.red
                                                      : null,*/
                                                        size: 20,
                                                      ),
                                                    ),

                                                    /* InkWell(
                                                onTap: () {
                                                  if (isFavorite) {
                                                    controller.removeFromFavorites(
                                                        controller.productsModel!
                                                            .products![index]);
                                                  } else {
                                                    controller.addToFavorites(
                                                        controller.productsModel!
                                                            .products![index]);
                                                  }
                                                  Get.to(() => FavoritesPage());
                                                },
                                                child: Icon(
                                                  Icons.favorite_rounded,
                                                  color: isFavorite
                                                      ? Colors.red
                                                      : null,
                                                  size: 20,
                                                ),
                                              ),*/
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) => SizedBox(
                                      height: 10,
                                    ),
                                itemCount: snapshot.data!.length);
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF965D1A),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
