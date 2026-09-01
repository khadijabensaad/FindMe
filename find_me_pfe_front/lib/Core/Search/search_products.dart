import 'dart:convert';

import 'package:find_me/Core/Search/osm_map.dart';
import 'package:find_me/Core/Search/product_detail.dart';
import 'package:find_me/Core/Search/shops_list.dart';
import 'package:find_me/Models/prod_filter.dart';
import 'package:find_me/Models/product_model.dart';
import 'package:find_me/Services/product_api.dart';
import 'package:find_me/widgets/appbarwidget.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:find_me/widgets/searchfieldwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.req});
  final ProductFilter? req;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ProductApiCall _productApiCall = ProductApiCall();
  ProductFilter? requette = ProductFilter(
      name: '',
      size: [],
      colors: '',
      sortBy: '',
      sortOrder: 'desc',
      region: '');
  TextEditingController _searchController = TextEditingController();
  int? nb = 0;
  bool isFavorite = false;
  late SharedPreferences prefs;
  late var token = "";
  String message = '';

  void _handleFilterSubmitted(ProductFilter data) {
    setState(() {
      requette = data;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _searchController = TextEditingController();
    initSharedPref().then((_) {
      setState(() {
        token = prefs.getString("userToken")!;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _searchController.dispose();
    super.dispose();
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
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      color: Color(0xFF965D1A),
      backgroundColor: Color(0xFFFDF1E1),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF1E1),
        drawer: DrawerWidget(),
        appBar: AppBarWidget(
            title: 'Find Me', onFilterSubmitted: _handleFilterSubmitted),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchFieldWidget(cntrl: _searchController),
                  FutureBuilder<List<ProductModel>>(
                    future:
                        _productApiCall.searchProductsWithFilter(ProductFilter(
                      name: widget.req?.name,
                      colors: widget.req?.colors,
                      sortBy: widget.req?.sortBy,
                      sortOrder: widget.req?.sortOrder,
                      region: widget.req?.region,
                      size: widget.req?.size,
                    )),
                    builder: (context, snapshot) {
                      print(snapshot.data);
                      if (snapshot.hasData) {
                        nb = snapshot.data?.length;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      child: const Icon(
                                        CupertinoIcons.arrow_left,
                                        size: 20,
                                        color: Color(0xFFDF9A4F),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Text("  ${nb} Results Found",
                                        style: TextStyle(
                                          color: Color(0xFFDF9A4F),
                                          fontSize: 13,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ))
                                  ],
                                ),
                                IconButton(
                                    onPressed: () {
                                      requette = ProductFilter(
                                          name: _searchController.text,
                                          size: requette?.size,
                                          colors: requette?.colors,
                                          sortBy: requette?.sortBy,
                                          sortOrder: requette?.sortOrder,
                                          region: requette?.region);
                                      //name: textValue,
                                      Navigator.pushReplacement(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (context) =>
                                                SearchPage(req: requette),
                                          ));
                                    },
                                    icon: Icon(
                                      CupertinoIcons.arrow_2_circlepath,
                                      size: 25,
                                    ))
                              ],
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) => InkWell(
                                onTap: () {
                                  print(
                                      "Page search products: ${snapshot.data![index].id}");
                                  Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => ProductDetail(
                                            identifier:
                                                snapshot.data![index].id),
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
                                            "${snapshot.data![index].thumbnail}",
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
                                                    "${snapshot.data?[index].name}",
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
                                                    "${snapshot.data?[index].brand}",
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
                                                        Icons.star_rate_rounded,
                                                        color:
                                                            Color(0xFFFFBD59),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        "${snapshot.data?[index].rating}",
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFFFFBD59)),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    snapshot.data?[index]
                                                                .discountPrice ==
                                                            -1
                                                        ? "${snapshot.data?[index].price}"
                                                            r" DT"
                                                        : "${snapshot.data?[index].discountPrice.toInt()}"
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
                                                              .data![index].id)
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
                                                      color: snapshot
                                                              .data![index]
                                                              .isFavorite //khedmet khadija
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
                                                  snapshot.data![index].shops;
                                              Navigator.push(
                                                  context,
                                                  CupertinoPageRoute(
                                                      builder: (context) =>
                                                          ShopsList(
                                                              shops: shops)));
                                              print(
                                                  "${snapshot.data?[index].shops}");
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
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: 10,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.7,
                            ),
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF965D1A),
                              ), // Display loading indicator
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  /*Text("name: ${widget.req?.name}"),
                Text("size:${widget.req?.size}"),
                Text("colors: ${widget.req?.colors}"),
                Text("sortBy: ${widget.req?.sortBy}"),
                Text("sortOrder: ${widget.req?.sortOrder}"),
                Text("region: ${widget.req?.region}"),*/
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
