import 'package:find_me/ui/geo/store_map_screen.dart';
import 'package:flutter/material.dart';

/// Drawer entry "Nearest shops": same screen as Nearby Stores.
class NearestShops extends StatelessWidget {
  const NearestShops({super.key});
  @override
  Widget build(BuildContext context) => const StoreMapScreen(title: 'Nearest Shops');
}
