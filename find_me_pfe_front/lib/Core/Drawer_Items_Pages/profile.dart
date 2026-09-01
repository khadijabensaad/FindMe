import 'package:find_me/Auth/login.dart';
import 'package:find_me/Services/auth_api.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key, required this.id});
  final String id;

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool isLoading = true;
  AuthCallAPi _authCallAPi = AuthCallAPi();
  late SharedPreferences prefs ;

  @override
  void initState() {
    // TODO: implement initState
    initSharedPref();
    super.initState();
  }
  void initSharedPref() async{
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      drawer: DrawerWidget(),
      appBar: AppBar(
        backgroundColor: Color(0xFFFDF1E1),
        title: Text("My Profile",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.black,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder(
            future: _authCallAPi.getUserById(widget.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Container(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 30,
                        ),
                        CircleAvatar(
                          backgroundColor: Color(0xFFFDF1E1),
                          radius: 80,
                          child: ClipOval(
                            child: Image.network(
                              snapshot.data!.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 0,right: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Username:",
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF965D1A)),
                              ),
                              Text("${snapshot.data?.username}",
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                'Email: ',
                                style: TextStyle(
                                  color: Color(0xFF965D1A),
                                  fontSize: 20,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  height: 0,
                                ),
                              ),
                              Text(
                                '${snapshot.data?.email}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 80,
                        ),
                        Container(
                          width: 170,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor:
                                    const Color(0xFFDF9A4F), // background color
                              ),
                              onPressed: () {
                                prefs.setBool("activated", false);
                                Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder:(context) => LoginPage(),), (route) => false);
                              },
                              child: Text(
                                "LOG OUT",
                                style: TextStyle(
                                    color: Color(0xFF965D1A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins'),
                              )),
                        ),
                        //Expanded(child: SizedBox(), flex: 1,),
                      ],
                    ),
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF965D1A),
                  ),
                );
              }
            },
          )
        ],
      )),
    );
  }
}
