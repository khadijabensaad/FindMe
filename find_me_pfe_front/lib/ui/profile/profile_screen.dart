import 'package:find_me/Core/Drawer_Items_Pages/categories.dart';
import 'package:find_me/Core/Drawer_Items_Pages/discounts.dart';
import 'package:find_me/ui/stores/nearby_stores_screen.dart';
import 'package:find_me/Core/Drawer_Items_Pages/notifications.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/alerts/price_alerts_screen.dart';
import 'package:find_me/ui/outfits/outfits_screen.dart';
import 'package:find_me/ui/profile/edit_profile_screen.dart';
import 'package:find_me/ui/profile/profile_widgets.dart';
import 'package:find_me/ui/favorites/favorites_screen.dart';
import 'package:find_me/ui/profile/style_dna_screen.dart';
import 'package:find_me/ui/profile/style_quiz_screen.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  StyleDna? _dna;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await FindMeApi.instance.me(); // real data of the signed-in user
      if (mounted) {
        setState(() {
          _user = u;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    try {
      final dna = await FindMeApi.instance.styleDna();
      if (mounted) setState(() => _dna = dna);
    } catch (_) {}
  }

  void _push(Widget page) => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => page)).then((_) => _load());

  @override
  Widget build(BuildContext context) {
    final iconColor = context.isDark ? AppColors.camel : AppColors.brown;
    final u = _user;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.camel,
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 130), children: [
            ProfileHeader(
              'My Profile',
              showBack: false,
              trailing: IconButton(
                tooltip: 'Edit profile',
                icon: Icon(Icons.settings_outlined, color: iconColor),
                onPressed: u == null ? null : () => _push(EditProfileScreen(user: u)),
              ),
            ),
            const SizedBox(height: 18),
            Center(child: ProfileAvatar(image: u?.image ?? '', onEdit: u == null ? null : () => _push(EditProfileScreen(user: u))))
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 22),
            if (_error != null && u == null)
              ErrorRetry(message: 'Your profile could not be loaded.\n$_error', onRetry: _load)
            else ...[
              ProfileInfoRow(Icons.person_rounded, 'Username', u?.username ?? ''),
              ProfileInfoRow(Icons.mail_rounded, 'Email', u?.email ?? ''),
            ],
            const SizedBox(height: 14),
            _dnaCard(),
            const SizedBox(height: 18),
            ProfileTile(Icons.manage_accounts_outlined, 'Edit profile', () {
              if (u != null) _push(EditProfileScreen(user: u));
            }),
            ProfileTile(Icons.checkroom_rounded, 'My wardrobe', () => _push(const OutfitsScreen())),
            ProfileTile(Icons.favorite_border_rounded, 'Wishlist', () => _push(const FavoritesScreen())),
            ProfileTile(Icons.notifications_active_outlined, 'Price alerts', () => _push(const PriceAlertsScreen())),
            ProfileTile(Icons.storefront_rounded, 'Nearby stores', () => _push(const NearbyStoresScreen())),
            ProfileTile(Icons.grid_view_rounded, 'Categories', () => _push(CategoriesPage())),
            ProfileTile(Icons.local_offer_outlined, 'Discounts', () => _push(const DiscountPage())),
            ProfileTile(Icons.campaign_outlined, 'Notifications', () => _push(const Notifications())),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (_, mode, __) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line)),
                child: SwitchListTile(
                  secondary: Icon(Icons.dark_mode_outlined, color: iconColor),
                  title: Text('Dark mode', style: context.text.titleSmall),
                  value: mode == ThemeMode.dark,
                  activeColor: AppColors.camel,
                  onChanged: (_) => ThemeController.toggle(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            CaramelButton('LOG OUT', onTap: () => confirmLogout(context)),
          ]),
        ),
      ),
    );
  }

  Widget _dnaCard() {
    final StyleDna? d = (_dna != null && _dna!.signals > 0) ? _dna : null;
    return Material(
      color: context.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _push(d != null ? const StyleDnaScreen() : const StyleQuizScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.line),
            boxShadow: context.isDark ? null : AppColors.softShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.camel.withOpacity(0.18), shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.camel, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Style DNA', style: context.text.titleSmall),
                  Text(d != null ? d.persona : 'Take the 1-minute quiz', style: AppTheme.display(18, color: context.fg)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: context.fgMuted),
            ]),
            if (d != null) ...[
              const SizedBox(height: 12),
              for (final s in d.topStyles.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(width: 90, child: Text(StyleDnaScreen.styleLabel(s), style: context.text.bodySmall?.copyWith(color: context.fg))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: (d.styles[s] ?? 0) / 100, minHeight: 6, color: AppColors.camel, backgroundColor: context.line),
                      ),
                    ),
                    SizedBox(width: 40, child: Text('${d.styles[s] ?? 0}%', textAlign: TextAlign.right, style: context.text.labelMedium)),
                  ]),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}
