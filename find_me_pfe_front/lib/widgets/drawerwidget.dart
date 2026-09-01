
import 'package:find_me/Core/Drawer_Items_Pages/categories.dart';
import 'package:find_me/Core/Drawer_Items_Pages/discounts.dart';
import 'package:find_me/Core/Drawer_Items_Pages/favorites.dart';
import 'package:find_me/Core/Drawer_Items_Pages/nearest_shops.dart';
import 'package:find_me/Core/Drawer_Items_Pages/notifications.dart';
import 'package:find_me/Core/Drawer_Items_Pages/profile.dart';
import 'package:find_me/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';


class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  late SharedPreferences prefs ;
  late String email = '';
  late String name= '';
  late String profilePic= '';
  late String identifier= "";

  @override
  void initState() {
    super.initState();
    /*SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive); // tna7i barre mta3 wa9t wel buttons mel louta*/
        initSharedPref().then((_){
          var token =prefs.getString("userToken");
        Map<String,dynamic> jwtDecodedToken = JwtDecoder.decode(token!);
       setState(() {
          email = jwtDecodedToken['email'];
          name = jwtDecodedToken['name'];
          profilePic = jwtDecodedToken['image'];
          print(profilePic);
          identifier = jwtDecodedToken['id'];
       });
        });
        
  }

  Future<void> initSharedPref() async{
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    /*SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);*/
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Drawer(
      shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero
          ),
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: const Color(0xFFFDF1E1),
      child: ListView(children: <Widget>[
        
        buildHeader(context),
        const Divider(thickness: 0.5,color: Color(0xFF965D1A),),
        ListTile(
          onTap: () {
            Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder: (context) => MainScreenPage(),), (route) => false);
          } ,
          leading: const Icon(
            CupertinoIcons.home,
            color: Colors.black,
          ),
          title: const Text(
            "Home Page",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder:(context) => MyProfile(id: identifier),));
          } ,
          leading: const Icon(
            CupertinoIcons.person_circle,
            color: Colors.black,
          ),
          title: const Text(
            "My Profile",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => Notifications(),));
          } ,
          leading: const Icon(
            CupertinoIcons.bell,
            color: Colors.black,
          ),
          title: const Text(
            "Notifications",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
         ListTile(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => FavoritesPage(),));
          },
          leading: const Icon(
            CupertinoIcons.heart,
            color: Colors.black,
          ),
          title: const Text(
            "Favorites",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
        ListTile(
          onTap: () async {
            var status = await Permission.location.request();
            if(status.isGranted){
              Navigator.push(context, CupertinoPageRoute(builder: (context) => NearestShops()));
            }else {
              print("Location permission is required to use the app.");
            }
          } ,
          leading: const Icon(
            CupertinoIcons.cart,
            color: Colors.black,
          ),
          title: const Text(
            "Nearest shops",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => CategoriesPage()));
          },
          leading: const Icon(
            CupertinoIcons.collections,
            color: Colors.black,
          ),
          title: const Text(
            "Categories",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => DiscountPage(),));
          },
          leading: const Icon(
            CupertinoIcons.tags,
            color: Colors.black,
          ),
          title: const Text(
            "Promotions",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
          ),
        ),
        const SizedBox(
          height: 200,
        ),
        
      ]),
    );
  }

  Widget buildHeader(BuildContext context) => Material(
        color: const Color(0xFFFDF1E1),
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            padding: const EdgeInsets.only(bottom: 24,),
            child: Column(children: [
              profilePic !="" ?
              CircleAvatar(
                backgroundColor: Color(0xFFFDF1E1),
                radius: 50,
                child: ClipOval(
                  child: CachedNetworkImage(
                    placeholder:(context, url) => CircularProgressIndicator(color: Color(0xFF965D1A),),
                    errorWidget:(context, url, error) => Icon(Icons.error),
                    fit: BoxFit.cover,
                    width: double.infinity, imageUrl: profilePic,
                  ),
                ),
              ) : 
              CircleAvatar(
                backgroundColor: Color(0xFFFDF1E1),
                radius: 50,
                child: ClipOval(
                  child: Image.asset("assets/images/profile2.jpg"),
                ),
              ),
              const SizedBox(height: 12),
               Text(
                name,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(
                height: 9,
              ),
               Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
              ),
            ]),
          ),
        ),
      );
}
