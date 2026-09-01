import 'package:find_me/Auth/login.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/starting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin{
  //teb3a splash screen hiya wel option  fi star elli lfou9 (with SingleTickerProviderStateMixin)
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive); // tna7i barre mta3 wa9t wel buttons mel louta
    Future.delayed(const Duration(seconds: 3), (){
      //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> const OnBoardingOne(),));
      checkTokenValidity();
    });
    
  }

  Future<void> checkTokenValidity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('userToken');
    if (token == null){
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnBoardingOne()));
    }else{
      var active = prefs.getBool("activated");
      bool isTokenExpired = JwtDecoder.isExpired(token);// Check if the token is expired

    if (isTokenExpired || active==false) {
      // Token is expired, navigate to PageOne
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      // lenna bech nzidou fazet isactivated
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreenPage()));
    }
    }
    
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/splash.png"),fit: BoxFit.cover),
        ),
      ),
    );
  }
}