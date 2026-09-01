import 'package:find_me/Core/Search/osm_map.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ShopsList extends StatefulWidget {
  final List<String> shops;
  const ShopsList({super.key, required this.shops});
  

  @override
  State<ShopsList> createState() => _ShopsListState();
}

class _ShopsListState extends State<ShopsList> {
  late String shopName;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF1E1),
        title: Text("Shops List",style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black),),
            centerTitle: true,
      ),
      drawer: DrawerWidget(),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
        child: ListView.separated(
          physics: NeverScrollableScrollPhysics(),
          itemBuilder:(context, index) => InkWell(
            onTap: ()async{
                                        var status = await Permission.location.request();
                                        if(status.isGranted){
                                          shopName=widget.shops[index];
                                          print("${shopName}");
                                          Navigator.push(context, CupertinoPageRoute(builder: (context) => ShopMap(name: shopName)));
                                        }else {
                                          print("Location permission is required to use the app.");
                                          }
                                      },
            child: Container(
             clipBehavior: Clip.antiAlias,
                                        height: 100,
                                        width: MediaQuery.of(context).size.width*0.8,
                                                                  decoration: BoxDecoration(
                                                                    border: Border.all(
                                                                      color:
                                      Colors.black, // Set the border color here
                                                                      width: 1, // Set the border width here
                                                                    ),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color:
                                        const Color.fromARGB(255, 220, 198, 170)
                                            .withOpacity(0.5),
                                                                        spreadRadius: 2,
                                                                        blurRadius: 3,
                                                                        offset: const Offset(0, 0),
                                                                      ),
                                                                    ],
                                                                    borderRadius: BorderRadius.circular(10),
                                                                  ),
            child: Row(
                                                                    children: [
                                                                      Image.asset("assets/images/marketplace.png",width: 90,),
                                                                      SizedBox(width: 10,),
                                                                      Column(
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        children: [
                                      Text("${widget.shops[index]}",style: const TextStyle(fontFamily: 'Poppins',fontSize: 18,fontWeight: FontWeight.w600),),
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                    ),
          ),
         separatorBuilder:(context, index) => SizedBox(height: 10,),
         itemCount: widget.shops.length)
      )),
    );
  }
}