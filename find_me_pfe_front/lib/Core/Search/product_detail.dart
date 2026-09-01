import 'dart:convert';

import 'package:find_me/Core/Search/osm_map.dart';
import 'package:find_me/Models/product_model.dart';
import 'package:find_me/Services/product_api.dart';
import 'package:find_me/widgets/colors_help.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.identifier});
  final String identifier;

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  ProductApiCall _productApiCall = ProductApiCall();
  HelperFunctions _helperFunctions = HelperFunctions();
  String id = "";
  int barcode = 0;
  bool isFavorite = false;
  late SharedPreferences prefs;
  late var token = "";
  String message = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFFDF1E1),
        drawer: DrawerWidget(),
        body: SafeArea(
            child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Column(children: [
            SizedBox(
              height: 20,
            ),
            /*
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height / 2.8,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 220, 198, 170)
                          .withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: 
                         InkWell(child: Image.asset("assets/images/profile2.jpg",fit: BoxFit.fill,),
                         onTap: () {
                           print("Detail page:  ${widget.identifier}");
                         },)
                                          
              ),
              ),*/
            FutureBuilder<ProductModel>(
              future: widget.identifier.length > 13
                  ? _productApiCall.getProductById(widget.identifier)
                  : _productApiCall.getProductByBarCode(widget.identifier),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  isFavorite = snapshot.data!.isFavorite;
                  //List<String> images = snapshot.data!.images;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height / 2.8,
                        width: MediaQuery.of(context).size.width,
                        child: ListView.separated(
                          separatorBuilder: (context, index) => SizedBox(
                            width: 5,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: snapshot.data!.images.length,
                          itemBuilder: (context, index) => Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors
                                    .transparent, // Set the border color here
                                width: 2.0, // Set the border width here
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 220, 198, 170)
                                          .withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  "${snapshot.data?.images[index]}",
                                  fit: BoxFit.fill,
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                )),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 20, bottom: 0),
                        child: Text(
                          "${snapshot.data?.name}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(
                                Icons.star_rate_rounded,
                                color: Color(0xFFFFBD59),
                              ),
                              onPressed: () {}),
                          Text(
                            "${snapshot.data?.rating}",
                            style: const TextStyle(
                                color: Color(0xFFFFBD59),
                                fontFamily: 'Poppins',
                                fontSize: 16),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Brand:    ",
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      fontSize: 16),
                                ),
                                Text(
                                  "${snapshot.data?.brand}",
                                  style: const TextStyle(
                                      color: Color(0xFFDF9A4F),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      fontSize: 16),
                                )
                              ],
                            ),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    addToFavorites(snapshot.data!.id)
                                        .whenComplete(() =>
                                            Fluttertoast.showToast(
                                              msg: message,
                                              toastLength: Toast.LENGTH_SHORT,
                                              backgroundColor:
                                                  Colors.black.withOpacity(0.7),
                                            ));
                                    ;
                                  });
                                },
                                icon: Icon(
                                  CupertinoIcons.heart_fill,
                                  color:
                                      isFavorite ? Colors.red : Colors.black26,
                                ))
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 255, 220, 169),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(255, 161, 155, 146)
                                    .withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 3,
                                offset: const Offset(0, 0),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(
                                    "Price",
                                    //  maxLines: 2,
                                    //  overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: 'poppins',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 16,
                                            ),
                                            Text(
                                              snapshot.data?.discountPrice == -1
                                                  ? '     '
                                                  : //condition remise discount promotion
                                                  ' ${snapshot.data?.price} DT',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall!
                                                  .apply(
                                                      decoration: TextDecoration
                                                          .lineThrough),
                                            ),

                                            const SizedBox(width: 10),

                                            /// Sale Price
                                            Text(
                                              snapshot.data?.discountPrice == -1
                                                  ? "${snapshot.data?.price}"
                                                      r" DT"
                                                  : "${snapshot.data?.discountPrice.toInt()} DT",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        /*
                                        const Row(children: [
                                          Text(
                                            "Stock:",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 6,
                                          ),
                                          Text(
                                            "In Stock",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ]),*/
                                      ]),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: const Text(
                                "Colors",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 40,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListView.separated(
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                    width: 5,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.colors.length,
                                  itemBuilder: (context, index) => Container(
                                    width: 40,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                      borderRadius: BorderRadius.circular(50),
                                      color: HelperFunctions.getColor(
                                          "${snapshot.data?.colors[index]}")!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Size",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0),
                                      child: ListView.separated(
                                        separatorBuilder: (context, index) =>
                                            SizedBox(
                                          width: 5,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: snapshot.data!.size.length,
                                        itemBuilder: (context, index) =>
                                            Container(
                                          alignment: Alignment.center,
                                          width: 50,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 255, 220, 169),
                                            border: Border.all(
                                                color: Colors.black38,
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "${snapshot.data?.size[index]}",
                                            style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Description",
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  ReadMoreText(
                                    "${snapshot.data?.description}",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    trimCollapsedText: "Show more",
                                    trimExpandedText: " less",
                                    trimLines: 2,
                                    trimMode: TrimMode.Line,
                                    colorClickableText: Colors.black,
                                    moreStyle: const TextStyle(
                                      color: Color(0xFFDF9A4F),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                    lessStyle: const TextStyle(
                                      color: Color(0xFFDF9A4F),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Shops",
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    height: snapshot.data!.shops.length * 150,
                                    width: MediaQuery.of(context).size.width,
                                    child: ListView.separated(
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: () async {
                                              var status = await Permission
                                                  .location
                                                  .request();
                                              if (status.isGranted) {
                                                Navigator.push(
                                                    context,
                                                    CupertinoPageRoute(
                                                        builder: (context) =>
                                                            ShopMap(
                                                              name:
                                                                  '${snapshot.data?.shops[index]}',
                                                            )));
                                              } else {
                                                print(
                                                    "Location permission is required to use the app.");
                                              }
                                            },
                                            child: Container(
                                              clipBehavior: Clip.antiAlias,
                                              height: 100,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors
                                                      .black, // Set the border color here
                                                  width:
                                                      1, // Set the border width here
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                            255, 220, 198, 170)
                                                        .withOpacity(0.5),
                                                    spreadRadius: 2,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 0),
                                                  ),
                                                ],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    "assets/images/marketplace.png",
                                                    width: 90,
                                                  ),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "${snapshot.data?.shops[index]}",
                                                        style: const TextStyle(
                                                            fontFamily:
                                                                'Poppins',
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 10),
                                        itemCount: snapshot.data!.shops.length),
                                  )
                                ],
                              ),
                            ),
                          ]),
                    ],
                  );
                } else {
                  print(
                      "Hello error fi product detail page: ${snapshot.error}");
                  return Center(
                      child:
                          //Text("hello ${snapshot.error}")
                          CircularProgressIndicator(
                    color: Color(0xFF965D1A),
                  ));
                }
              },
            )
          ]),
        ))));
  }
}
