import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadAfterScan extends StatelessWidget {
  const LoadAfterScan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      body: SafeArea(child: Center(child: CircularProgressIndicator(color: Color(0xFF965D1A),),)),
    );
  }
}