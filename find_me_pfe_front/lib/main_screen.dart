<<<<<<< HEAD
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/discover/discover_screen.dart';
import 'package:find_me/ui/favorites/favorites_screen.dart';
import 'package:find_me/ui/home/smart_home_screen.dart';
import 'package:find_me/ui/profile/profile_screen.dart';
import 'package:find_me/ui/stylist/stylist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lets any screen switch tab and hand data to another tab
/// (e.g. Home search → Discover, "Ask the stylist" → AI Stylist).
class ShellController {
  ShellController._();
  static final ValueNotifier<int> tab = ValueNotifier(0);
  static final ValueNotifier<String?> discoverQuery = ValueNotifier(null);
  static final ValueNotifier<String?> stylistPrompt = ValueNotifier(null);

  static void openDiscover([String? query]) {
    discoverQuery.value = query;
    tab.value = 1;
  }

  static void askStylist([String? prompt]) {
    stylistPrompt.value = prompt;
    tab.value = 2;
  }
}

/// The app shell. The class name is kept so the existing navigation
/// (login, splash, drawer → MainScreenPage) lands in the new experience.
=======

import 'package:find_me/Core/Scan/barcode_scan_page.dart';
import 'package:find_me/Core/Search/search_products.dart';
import 'package:find_me/Models/prod_filter.dart';
import 'package:find_me/chatbot.dart';
import 'package:find_me/widgets/appbarwidget.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:find_me/widgets/searchfieldWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
class MainScreenPage extends StatefulWidget {
  const MainScreenPage({super.key});

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage> {
<<<<<<< HEAD
  final Set<int> _built = {0};

  @override
  void initState() {
    super.initState();
    ShellController.tab.addListener(_onTab);
=======
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
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
  }

  @override
  void dispose() {
<<<<<<< HEAD
    ShellController.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() => _built.add(ShellController.tab.value));

  Widget _page(int i) {
    if (!_built.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return const SmartHomeScreen();
      case 1:
        return const DiscoverScreen();
      case 2:
        return const StylistScreen(embedded: true);
      case 3:
        return const FavoritesScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ShellController.tab.value;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: index, children: List.generate(5, _page)),
        bottomNavigationBar: _FindMeNavBar(
          index: index,
          onTap: (i) {
            if (i == index) return;
            HapticFeedback.selectionClick();
            ShellController.tab.value = i;
          },
=======
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
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
        ),
      ),
    );
  }
}
<<<<<<< HEAD

class _FindMeNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _FindMeNavBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
    (Icons.checkroom_outlined, Icons.checkroom_rounded, 'Stylist'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Wishlist'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final idle = context.isDark ? const Color(0xFFBFAE9C) : AppColors.muted;
    final active = context.isDark ? AppColors.camel : AppColors.brown;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 14),
      child: SizedBox(
        height: 84,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: context.line),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final (icon, activeIcon, label) = _items[i];
                final selected = i == index;
                if (i == 2) return const Expanded(child: SizedBox());
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    onTap: () => onTap(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(selected ? activeIcon : icon, key: ValueKey(selected), color: selected ? active : idle, size: 24),
                      ),
                      const SizedBox(height: 3),
                      Text(label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? active : idle,
                          )),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: selected ? 16 : 0,
                        height: 3,
                        decoration: BoxDecoration(color: AppColors.camel, borderRadius: BorderRadius.circular(2)),
                      ),
                    ]),
                  ),
                );
              }),
            ),
          ),
          // raised AI Stylist button (FINDME hanger)
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: 'AI Stylist',
              child: GestureDetector(
                onTap: () => onTap(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.caramel,
                    border: Border.all(color: context.bg, width: 4),
                    boxShadow: [BoxShadow(color: AppColors.camel.withOpacity(index == 2 ? 0.6 : 0.4), blurRadius: index == 2 ? 20 : 12, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
=======
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
