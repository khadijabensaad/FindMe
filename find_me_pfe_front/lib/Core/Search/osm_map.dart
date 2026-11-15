import 'package:find_me/ui/geo/store_map_screen.dart';
import 'package:flutter/material.dart';

/// Kept for the old call sites (`ShopMap(name: ...)`): opens the unified map
/// focused on that shop and draws the route from the user's position.
class ShopMap extends StatelessWidget {
  const ShopMap({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => StoreMapScreen(title: name, subtitle: 'Store location', focusName: name, directionsOnOpen: true);
}
