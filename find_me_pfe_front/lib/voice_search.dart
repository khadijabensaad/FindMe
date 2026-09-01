import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/material.dart';

class VoiceSearch extends StatelessWidget {
  const VoiceSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        title: Text("Voice Search",style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  fontSize: 18)),
                  centerTitle: true,
                  backgroundColor: Color(0xFFFDF1E1),
      ),
      drawer: DrawerWidget(),
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Press The Button To Start Speaking", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 24),textAlign: TextAlign.center,),
        RoundedImageButton(
                image: 'assets/images/mic.png',
                onPressed: () {
                  // Add your button functionality here
                  print('Button pressed!');
                },
              ),
      ],
    ),),
    );
  }
}

class RoundedImageButton extends StatelessWidget {
  final String image;
  final VoidCallback onPressed;

  RoundedImageButton({
    required this.image,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              image,
              width: 140,
              height: 140,
            ),
          ),
        ),
      ),
    );
  }
}