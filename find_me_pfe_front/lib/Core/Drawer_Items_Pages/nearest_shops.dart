import 'package:find_me/Core/Drawer_Items_Pages/products_list.dart';
import 'package:find_me/Core/Search/osm_map.dart';
import 'package:find_me/Services/shop_api.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NearestShops extends StatefulWidget {
  const NearestShops({super.key});

  @override
  State<NearestShops> createState() => _NearestShopsState();
}

class _NearestShopsState extends State<NearestShops> {
  List<dynamic> shops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    callCalculateDistanceAPI();
  }

  Future<void> callCalculateDistanceAPI() async {
    try {
      final apiService = ShopApiCall();
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final lat = position.latitude;
      final long = position.longitude;
      final shops = await apiService.CalculateDistance(
          lat, long).whenComplete(() => setState(() {
              isLoading = false;
            }));// Replace with actual lat and long values

      setState(() {
        this.shops = shops;
      });
    } catch (error) {
      // Handle errors
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        title: Text('Nearest Shops',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.black,
                fontSize: 18)),
        centerTitle: true,
        backgroundColor: Color(0xFFFDF1E1),
      ),
      drawer: DrawerWidget(),
      body: isLoading ? Center(
        child: CircularProgressIndicator(color: Color(0xFF965D1A)),
      ): Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: ListView.separated(
          separatorBuilder: (context, index) => SizedBox(
            height: 10,
          ),
          itemCount: shops.length,
          itemBuilder: (context, index) {
            final shop = shops[index];
            final distance = shop['distance'];
            final name = shop['name'];
            final id = shop['_id'];

            return InkWell(
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder:(context) => ShopProductsList(id: id)));
              },
              child: Container(
                  clipBehavior: Clip.antiAlias,
                  height: 100,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black, // Set the border color here
                      width: 1, // Set the border width here
                    ),
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
                  child: Padding(
                    padding: const EdgeInsets.only(right:8.0, top: 5, bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row( children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                          "assets/images/marketplace.png",width: 80,
                                            ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(
                            '$name',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.start,
                          ),
                          Text(
                            'Distance: $distance km',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.start,
                          ),
                          ] 
                        ),
                      ]),
                        Row(
                          children: [
                            Container(
                                        width: 40,
                                        height: 40,
                                        child: IconButton(
                                          icon: Icon(Icons.location_on_outlined,
                                          color: Colors.white,),
                                           onPressed: () {
                                            Navigator.push(context, CupertinoPageRoute(builder:(context) => ShopMap(name: name),));
                                           },
                                        ),
                                        decoration: const ShapeDecoration(
                                          color: Color(0xFFFFBD59),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                          ],
                        ),
                      ],
                    ),
                  )),
            );
          },
        ),
      ),
    );
  }
}