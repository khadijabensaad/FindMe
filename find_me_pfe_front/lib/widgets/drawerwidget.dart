<<<<<<< HEAD
import 'package:find_me/Core/Drawer_Items_Pages/categories.dart';
import 'package:find_me/Core/Drawer_Items_Pages/discounts.dart';
import 'package:find_me/Core/Drawer_Items_Pages/notifications.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/favorites/favorites_screen.dart';
import 'package:find_me/ui/profile/edit_profile_screen.dart';
import 'package:find_me/ui/profile/profile_widgets.dart';
import 'package:find_me/ui/stores/nearby_stores_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Side drawer of the older pages, in the unified profile design (real user data).
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});
=======

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

>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
<<<<<<< HEAD
  AppUser? _user;
=======
  late SharedPreferences prefs ;
  late String email = '';
  late String name= '';
  late String profilePic= '';
  late String identifier= "";
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    FindMeApi.instance.me().then((u) {
      if (mounted) setState(() => _user = u);
    }).catchError((_) {});
  }

  void _go(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
=======
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
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final u = _user;
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.lg))),
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: context.bg,
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
          Center(child: ProfileAvatar(image: u?.image ?? '', size: 92)),
          const SizedBox(height: 12),
          Text(u?.username ?? '', textAlign: TextAlign.center, style: AppTheme.display(19, color: context.fg)),
          Text(u?.email ?? '', textAlign: TextAlign.center, style: context.text.bodySmall),
          const SizedBox(height: 14),
          Divider(color: context.line),
          const SizedBox(height: 8),
          ProfileTile(CupertinoIcons.home, 'Home', () {
            Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder: (_) => const MainScreenPage()), (_) => false);
          }),
          ProfileTile(CupertinoIcons.person_circle, 'My Profile', () => _go(EditProfileScreen(user: u))),
          ProfileTile(CupertinoIcons.bell, 'Notifications', () => _go(const Notifications())),
          ProfileTile(CupertinoIcons.heart, 'Wishlist', () => _go(const FavoritesScreen())),
          ProfileTile(CupertinoIcons.location, 'Nearby stores', () => _go(const NearbyStoresScreen())),
          ProfileTile(CupertinoIcons.collections, 'Categories', () => _go(CategoriesPage())),
          ProfileTile(CupertinoIcons.tags, 'Promotions', () => _go(const DiscountPage())),
          const SizedBox(height: 18),
          CaramelButton('LOG OUT', onTap: () => confirmLogout(context)),
        ]),
      ),
    );
  }
=======
    
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
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
}
