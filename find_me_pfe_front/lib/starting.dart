import 'package:find_me/Auth/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnBoardingOne extends StatefulWidget {
  const OnBoardingOne({super.key});

  @override
  State<OnBoardingOne> createState() => _OnBoardingOneState();
}

class _OnBoardingOneState extends State<OnBoardingOne> {
  int currentPage = 0;
  List<Map<String, String>> splashData = [
    {
      "text1": "Choose Your Product",
      "text2":
          "Welcome to a World of Limitless Choices, Your Perfect Product Awaits!",
      "image": "assets/images/slide_two.json"
    },
    {
      "text1": "Discover the Nearby Salepoints",
      "text2":
          "Discover Discount in Products, and Find the Salepoints in your Area!",
      "image": "assets/images/gps.json"
    },
    {
      "text1": "Interact with ChatBot",
      "text2":
          "Our Application offers New Features to users, like interacting with ChatBot!",
      "image": "assets/images/chat.json"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color((0xFFFDF1E1)),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Image.asset(
              "assets/images/Find_me_name.PNG",
              width: 250,
            ),
            Expanded(
              flex: 2,
              child: PageView.builder(
                onPageChanged: (value) {
                  setState(() {
                    currentPage = value;
                  });
                },
                itemCount: splashData.length,
                itemBuilder: (context, index) => SplashContent(
                  text1: splashData[index]["text1"] ?? "",
                  text2: splashData[index]["text2"] ?? "",
                  image: splashData[index]["image"] ?? "",
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      splashData.length,
                      (index) => buildDot(index: index),
                    ),
                  ),
                  const SizedBox(height: 80,),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, bottom: 20),
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const LoginPage()));
                        },
                        backgroundColor: const Color(0xFFFFBD59),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: const Icon(CupertinoIcons.chevron_right),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 7,
      width: currentPage == index ? 60 : 8,
      decoration: BoxDecoration(
        color: currentPage == index
            ? const Color(0xFFDF9A4F)
            : const Color.fromARGB(255, 151, 145, 139),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class SplashContent extends StatelessWidget {
  const SplashContent({
    Key? key,
    required this.text1,
    required this.text2,
    required this.image,
  }) : super(key: key);
  final String text1, text2, image;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //const SizedBox(height: 0),
        LottieBuilder.asset(image, height: 250,),
        Text(
          text1,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          textAlign: TextAlign.center,
        ), //color: Color(0xFF965D1A)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 10),
          child: Text(
            text2,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Color.fromARGB(131, 0, 0, 0)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
