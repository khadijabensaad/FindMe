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
class MainScreenPage extends StatefulWidget {
  const MainScreenPage({super.key});

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage> {
  final Set<int> _built = {0};

  @override
  void initState() {
    super.initState();
    ShellController.tab.addListener(_onTab);
  }

  @override
  void dispose() {
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
        ),
      ),
    );
  }
}

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
