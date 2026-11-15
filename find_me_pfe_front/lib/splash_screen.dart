import 'package:find_me/Auth/login.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/starting.dart';
import 'package:find_me/theme/app_theme.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFDF1E1), Color(0xFFF8E3C8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(children: [
              const Spacer(flex: 2),
              const Icon(Icons.checkroom_rounded, color: AppColors.brown, size: 44),
              Image.asset('assets/images/find_me.PNG', height: 48, fit: BoxFit.contain),
              const SizedBox(height: 10),
              Text('Find Your Style ✨', style: AppTheme.display(20, color: AppColors.brown)),
              const Spacer(),
              Image.asset('assets/images/3.PNG', height: 260, fit: BoxFit.contain),
              const Spacer(),
              const Text('Loading your fashion world…', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 2900),
                  builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 5, color: AppColors.camel, backgroundColor: AppColors.sand),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}
