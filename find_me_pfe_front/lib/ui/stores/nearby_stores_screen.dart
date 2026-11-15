import 'package:find_me/ui/geo/store_map_screen.dart';
import 'package:flutter/material.dart';

/// Smart Shop Locator: every FINDME shop, nearest first (unified map design).
class NearbyStoresScreen extends StatelessWidget {
  const NearbyStoresScreen({super.key});
  @override
  Widget build(BuildContext context) => const StoreMapScreen(title: 'Nearby Stores');
}
