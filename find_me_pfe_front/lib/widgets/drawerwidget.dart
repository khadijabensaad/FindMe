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
  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    FindMeApi.instance.me().then((u) {
      if (mounted) setState(() => _user = u);
    }).catchError((_) {});
  }

  void _go(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
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
}
