
import 'package:find_me/Core/Scan/barcode_scan_page.dart';
import 'package:find_me/Core/Search/search_products.dart';
import 'package:find_me/Models/prod_filter.dart';
import 'package:find_me/chatbot.dart';
import 'package:find_me/widgets/appbarwidget.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:find_me/widgets/searchfieldWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainScreenPage extends StatefulWidget {
  const MainScreenPage({super.key});

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage> {
  ProductFilter? requette = ProductFilter(name: '', size: [],colors: '', sortBy: '', sortOrder: 'desc', region: '');
  TextEditingController _searchController = TextEditingController();
  

  void _handleFilterSubmitted(ProductFilter data) {
    setState(() {
      requette = data;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    // Dispose the controller when the page is disposed
    _searchController.dispose();
    super.dispose();
  }
  /*int _selectedIndex=0;
  void _onItemTapped(int index){
    setState(() {
      _selectedIndex=index;
    });
  }*/
  
  /*List<String> locations = [
    'Ariana',
    'Ben Arous',
    'Bizerte',
    'Béja',
    'Gabès',
    'Gafsa',
    'Jendouba',
    ' Kairouan',
    'Kasserine',
    'Kébili',
    'LA Manouba',
    'Le Kef',
    'Mahdia',
    'Monastir',
    'Médenine',
    'Nabeul',
    ' Sfax',
    'Sidi Bouzid',
    'Siliana',
    'Sousse',
    'Tataouine',
    'Tozeur',
    'Tunis',
    'Zaghouane',
  ];*/
  
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1E1),
      drawer: const DrawerWidget(),
      appBar:  AppBarWidget(
        title: 'Home', onFilterSubmitted: _handleFilterSubmitted,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 30,
              ),
              const Text(
                'Welcome to this app',
                style: TextStyle(
                  color: Color(0xFF965D1A),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  height: 0.07,
                  letterSpacing: -0.24,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                'What are you searching for ?',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  height: 0.09,
                  letterSpacing: -0.18,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
                Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: SearchFieldWidget(cntrl: _searchController),
              ),
              /*ElevatedButton(
                onPressed: (){
                  String textValue = _searchController.text;
                  print(textValue);
              }, child: Icon(Icons.print)),*/
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 250,
                height: 45,
                child: CupertinoButton(
                  color: const Color(0xFFDF9A4F),
                  onPressed: () {
                    String textValue = _searchController.text;
                    
                    requette =ProductFilter(name: textValue, size: requette?.size,colors: requette?.colors, sortBy: requette?.sortBy, sortOrder: requette?.sortOrder, region: requette?.region);
                    
                    /*print("Appel: ${requette?.size}");
                    print("Appel: ${requette?.colors}");
                    print("Appel: ${requette?.sortBy}");
                    print("Appel: ${requette?.sortOrder}");
                    print("Appel: ${requette?.region}");*/
                    //print("Appel: ${requette?.size}");
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => SearchPage(req: requette),));
                    
                    /*Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: ((context) => SearchFakeProducts())));*/
                  },
                  child: const Text(
                    "Search",
                    style: TextStyle(
                      color: Color(0xFF965D1A),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 250,
                height: 45,
                child: CupertinoButton(
                  color: const Color(0xFFDF9A4F),
                  onPressed: () {
                    //var token= _prefs.getString("token");
                    //print("home token: ${token}");
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: ((context) => const BarCodeScan())));
                  },
                  child: const Text(
                    "Scan Barcode",
                    style: TextStyle(
                      color: Color(0xFF965D1A),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Image.asset(
                "assets/images/home_page.png",
                //height: 160,
                width: MediaQuery.of(context).size.width * 0.55,
                //  height: MediaQuery.of(context).size.height * 0.4,*/
              ),
              const SizedBox(
                height: 10,
              ),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Start your experience  \nwith',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 19,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        height: 0,
                      ),
                    ),
                    TextSpan(
                      text: ' chatbot.',
                      style: TextStyle(
                        color: Color(0xFFEFBC73),
                        fontSize: 19,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        height: 0,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                "Research involving the use of chat.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  height: 0,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              SizedBox(
                width: 250,
                height: 45,
                child: CupertinoButton(
                  color: const Color(0xFFDF9A4F),
                  onPressed: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: ((context) => const ChatbotPage())));
                  },
                  child: const Text(
                    "Start",
                    style: TextStyle(
                      color: Color(0xFF965D1A),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
