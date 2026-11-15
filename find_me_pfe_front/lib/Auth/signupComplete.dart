import 'package:find_me/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SignUpComplete extends StatelessWidget {
  const SignUpComplete({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor:const Color(0xFFFDF1E1),
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(flex: 1,child: SizedBox(),),
          const Text("Congratulations,",style: TextStyle(fontFamily: "Poppins",fontSize: 28,fontWeight: FontWeight.bold,color: Color(0xFFDF9A4F)),),
          const SizedBox(height: 10,),
          const Text("You Have Successfully Created Your Account",style: TextStyle(fontFamily: "Poppins",fontSize: 14,fontWeight: FontWeight.bold,color: Color.fromARGB(255, 133, 128, 124),),),
          const SizedBox(height: 50,),
          Image.asset("assets/images/signup_complete.PNG",width: 250,),
          const SizedBox(height: 50,),
          const Text("We are delighted to have you",style: TextStyle(fontFamily: "Poppins",fontSize: 14,fontWeight: FontWeight.bold,color: Color.fromARGB(255, 133, 128, 124),),),
          const Text("with us now.",style: TextStyle(fontFamily: "Poppins",fontSize: 14,fontWeight: FontWeight.bold,color: Color.fromARGB(255, 133, 128, 124),),),
          const Expanded(flex: 1,child: SizedBox(),),
          SizedBox(
                height: 50,
                width: 250,
                child: ElevatedButton(
                  onPressed: (){
                    
                    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const MainScreenPage(),));
                  },
                  style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: const Color(0xFFDF9A4F), // background color
                  ),
                 child:const Text(
                        'Continue',
                        style: TextStyle(color: Color(0xFF965D1A),fontSize: 18,fontWeight: FontWeight.bold,fontFamily: 'Poppins'),
                                      ),),
              ),

          const Expanded(flex: 3,child: SizedBox(),),
            ],
          ),
        ) 
      ),
    );
  }
}