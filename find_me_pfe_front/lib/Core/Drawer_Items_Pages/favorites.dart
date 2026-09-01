import 'dart:convert';

import 'package:find_me/Core/Search/product_detail.dart';
import 'package:find_me/Core/Search/shops_list.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool isLoading = true;
  late SharedPreferences prefs;
  late var token = "";
  String message = '';
  bool isFavorite = true;

  @override
  void initState() {
    // TODO: implement initState
    initSharedPref().then((_) {
      setState(() {
        token = prefs.getString("userToken")!;
      });
    });
    super.initState();
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<dynamic> getFavorites() async {
    await initSharedPref();
    List<dynamic> favorites = [];
    String url = 'http://192.168.43.28:5000/auth/getFavorites';
    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token}'
      },
    );
    var jsonResponse = jsonDecode(response.body);
    //print(jsonResponse);
    if (jsonResponse["status"]) {
      favorites = jsonResponse["favorites"];
    }
    print(favorites);
    return favorites;
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

  Future<void> deleteAllFavorites() async {
    await initSharedPref();
    String url = 'http://192.168.43.28:5000/auth/deleteAllFavorites';
    var response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token}'
      },
    );
    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse["status"]) {
      setState(() {
        message = jsonResponse["message"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFFDF1E1),
        appBar: AppBar(
          backgroundColor: Color(0xFFFDF1E1),
          elevation: 1,
          title: Text(
            "Favorites",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.black),
          ),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            icon: Icon(Icons.warning_amber_rounded, size: 50),
                            iconColor: Color(0xFF965D1A),
                            backgroundColor: Color(0xFFFDF1E1),
                            title: const Text(
                              'Delete All Favorites',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  color: Colors.black,
                                  fontSize: 20),
                            ),
                            content: const Text(
                              'Are you sure you want to delete your favorite list?',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  // Close the dialog when cancel button is pressed
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF965D1A),
                                        fontWeight: FontWeight.bold)),
                              ),
                              TextButton(
                                onPressed: () {
                                  deleteAllFavorites().whenComplete(
                                      () => Fluttertoast.showToast(
                                            msg: message,
                                            toastLength: Toast.LENGTH_SHORT,
                                            backgroundColor:
                                                Colors.black.withOpacity(0.7),
                                          ));
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Yes',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF965D1A),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ));
                  //getFavorites();
                  print("Bonjour");
                },
                icon: Icon(
                  CupertinoIcons.trash_fill,
                  color: Color(0xFF965D1A),
                ))
          ],
        ),
        drawer: DrawerWidget(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: FutureBuilder<dynamic>(
                future: getFavorites(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) => InkWell(
                              onTap: () {
                                print(
                                    "Page search products: ${snapshot.data![index]["_id"]}");
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ProductDetail(
                                          identifier: snapshot.data![index]
                                              ["_id"]),
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
                                          "${snapshot.data![index]["thumbnail"]}",
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
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "${snapshot.data?[index]["name"]}",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "${snapshot.data?[index]["brand"]}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 11,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star_rate_rounded,
                                                      color: Color(0xFFFFBD59),
                                                    ),
                                                    const SizedBox(
                                                      width: 2,
                                                    ),
                                                    Text(
                                                      "${snapshot.data?[index]["rating"]}",
                                                      style: const TextStyle(
                                                          color: Color(
                                                              0xFFFFBD59)),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  snapshot.data?[index][
                                                              "discountPrice"] ==
                                                          -1
                                                      ? "${snapshot.data?[index]["price"]}"
                                                          r" DT"
                                                      : "${snapshot.data?[index]["discountPrice"]}"
                                                          r" DT",
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 13,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 3,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    addToFavorites(snapshot
                                                                .data![index]
                                                            ["_id"])
                                                        .whenComplete(() =>
                                                            Fluttertoast
                                                                .showToast(
                                                              msg: message,
                                                              toastLength: Toast
                                                                  .LENGTH_SHORT,
                                                              backgroundColor:
                                                                  Colors.black
                                                                      .withOpacity(
                                                                          0.7),
                                                            ));
                                                    ;
                                                    /*
                                              // Check if the product is in the favorite list
                                              if (isInFavorites) {
                                                // If the product is already in favorites, remove it
                                                controller.removeFromFavorites(
                                                    controller.productsModel!
                                                        .products![index]);
                                              } else {
                                                // If the product is not in favorites, add it
                                                controller.addToFavorites(
                                                    controller.productsModel!
                                                        .products![index]);
                                              }
                                              //  Get.to(() => FavoritesPage());
                                              */
                                                  },
                                                  child: Icon(
                                                    Icons.favorite_rounded,
                                                    color: snapshot.data![index]
                                                            [
                                                            "isFavorite"] //khedmet khadija
                                                        ? Colors.red
                                                        : Colors.grey,
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
                                      Container(
                                        width: 40,
                                        height: 40,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            List<String> shops =
                                                (snapshot.data![index]["shops"]
                                                        as List<dynamic>)
                                                    .cast<String>();
                                            Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                    builder: (context) =>
                                                        ShopsList(
                                                            shops: shops)));
                                            print(
                                                "${snapshot.data?[index]["shops"]}");
                                          },
                                        ),
                                        decoration: const ShapeDecoration(
                                          color: Color(0xFFFFBD59),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                    ],
                                  )
                                  /*Column(
                                children: [
                                  ListTile(
                                    title: Text(snapshot.data![index].name),
                                    subtitle: Text("${snapshot.data![index].price}"),
                                  )
                                ],
                              ),*/
                                  ),
                            ),
                        separatorBuilder: (context, index) => SizedBox(
                              height: 10,
                            ),
                        itemCount: snapshot.data.length);
                  } else {
                    return Center(
                        child: CircularProgressIndicator(
                      color: Color(0xFF965D1A),
                    ));
                  }
                },
              ),
            ),
          ),
        ));
  }
}
