import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/alerts/price_alerts_screen.dart';
import 'package:find_me/ui/outfits/outfits_screen.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Favorites tab (Smart Wishlist): favorites + quick access to price alerts and outfits.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<RecoProduct>> _future = FindMeApi.instance.favorites();

  @override
  void initState() {
    super.initState();
    // refresh when the user comes back to this tab
    ShellController.tab.addListener(_onTab);
  }

  @override
  void dispose() {
    ShellController.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (ShellController.tab.value == 3) _reload();
  }

  void _reload() => setState(() => _future = FindMeApi.instance.favorites());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.camel,
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Row(children: [
                    Icon(Icons.favorite_rounded, color: context.isDark ? AppColors.camel : AppColors.brown, size: 26),
                    const SizedBox(width: 8),
                    Text('Wishlist', style: AppTheme.display(30, color: context.fg)),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(children: [
                    Expanded(child: _shortcut(Icons.notifications_active_outlined, 'Price alerts', () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const PriceAlertsScreen())))),
                    const SizedBox(width: 12),
                    Expanded(child: _shortcut(Icons.checkroom_rounded, 'My wardrobe', () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const OutfitsScreen())))),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<List<RecoProduct>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(padding: EdgeInsets.all(20), child: Row(children: [Expanded(child: ProductCardSkeleton(width: double.infinity)), SizedBox(width: 14), Expanded(child: ProductCardSkeleton(width: double.infinity))]));
                    }
                    if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
                    final list = snap.data!;
                    if (list.isEmpty) {
                      return EmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: 'No favorites yet',
                        message: 'Tap the heart on any product. Favorites also teach FINDME your Style DNA.',
                        action: 'Discover products',
                        onAction: () => ShellController.openDiscover(''),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: ProductGrid(list, heroPrefix: 'fav'),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcut(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line), boxShadow: context.isDark ? null : AppColors.softShadow),
        child: Row(children: [
          Icon(icon, color: context.isDark ? AppColors.camel : AppColors.brown, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: context.text.titleSmall)),
          Icon(Icons.chevron_right_rounded, color: context.fgMuted, size: 18),
        ]),
      ),
    );
  }
}
