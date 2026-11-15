import 'package:find_me/Core/Scan/barcode_scan_page.dart';
import 'package:find_me/data/api_client.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/alerts/price_alerts_screen.dart';
import 'package:find_me/ui/profile/style_dna_screen.dart';
import 'package:find_me/ui/profile/style_quiz_screen.dart';
import 'package:find_me/ui/search/visual_search_screen.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:find_me/voice_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 01 — Smart Home: personalized discovery in one screen.
class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});
  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  late Future<HomeFeed> _feed;
  String _name = '';
  int _unseenAlerts = 0;
  final _search = TextEditingController();

  static const _categories = [
    ('Dresses', Icons.checkroom_rounded, 'type:dress'),
    ('Shoes', Icons.directions_walk_rounded, 'type:shoes'),
    ('Bags', Icons.shopping_bag_outlined, 'type:bag'),
    ('Jewelry', Icons.diamond_outlined, 'type:necklace,bracelet,ring,earrings,watch'),
    ('Tops', Icons.dry_cleaning_outlined, 'type:shirt,tshirt'),
    ('Sport', Icons.sports_basketball_outlined, 'type:sportswear'),
  ];

  @override
  void initState() {
    super.initState();
    _feed = FindMeApi.instance.home();
    _loadHeader();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadHeader() async {
    try {
      final id = await ApiClient.instance.userId();
      if (id != null) {
        final u = await ApiClient.instance.get('/auth/getUser/$id');
        if (mounted && u is Map) setState(() => _name = (u['username'] ?? '').toString());
      }
      final (_, unseen) = await FindMeApi.instance.alerts();
      if (mounted) setState(() => _unseenAlerts = unseen);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() => _feed = FindMeApi.instance.home());
    await _feed.catchError((_) => HomeFeed.fromJson({}));
    _loadHeader();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _voice() async {
    final text = await Navigator.of(context).push<String>(CupertinoPageRoute(builder: (_) => const VoiceSearch(returnResult: true)));
    if (text != null && text.trim().isNotEmpty) ShellController.askStylist(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.camel,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _searchBar()),
            SliverToBoxAdapter(child: _heroCard()),
            SliverToBoxAdapter(child: _categoryRow()),
            SliverToBoxAdapter(
              child: FutureBuilder<HomeFeed>(
                future: _feed,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return _loadingSections();
                  if (snap.hasError) {
                    return ErrorRetry(message: 'We could not load your feed. Check that the server is running.', onRetry: _refresh);
                  }
                  return _sections(snap.data!);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Column(children: [
          Row(children: [
            IconButton(
              tooltip: 'Search with a photo',
              icon: Icon(Icons.photo_camera_outlined, color: context.isDark ? AppColors.camel : AppColors.brown),
              onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const VisualSearchScreen())),
            ),
            Expanded(
              child: Column(children: [
                Icon(Icons.checkroom_rounded, color: context.isDark ? AppColors.camel : AppColors.brown, size: 26),
                Image.asset('assets/images/find_me.PNG', height: 26, fit: BoxFit.contain),
              ]),
            ),
            Stack(clipBehavior: Clip.none, children: [
              IconButton(
                tooltip: 'Price alerts',
                icon: Icon(Icons.notifications_none_rounded, color: context.isDark ? AppColors.camel : AppColors.brown),
                onPressed: () async {
                  await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const PriceAlertsScreen()));
                  _loadHeader();
                },
              ),
              if (_unseenAlerts > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFC0502E), shape: BoxShape.circle),
                    child: Text('$_unseenAlerts', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 700.ms),
                ),
            ]),
          ]),
          const SizedBox(height: 6),
          Text(
            _name.isEmpty ? '$_greeting ✨' : '$_greeting, $_name ✨',
            style: context.text.bodyMedium?.copyWith(color: context.fgMuted),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: context.isDark ? null : AppColors.softShadow),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (q) {
                if (q.trim().isEmpty) return;
                ShellController.openDiscover(q.trim());
                _search.clear();
              },
              decoration: InputDecoration(
                hintText: 'Search for dresses, brands…',
                prefixIcon: Icon(Icons.search_rounded, color: context.fgMuted),
                suffixIcon: IconButton(tooltip: 'Voice search', icon: Icon(Icons.mic_none_rounded, color: context.accentText), onPressed: _voice),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: context.card,
          shape: CircleBorder(side: BorderSide(color: context.line)),
          child: IconButton(
            tooltip: 'Scan a barcode',
            icon: Icon(Icons.qr_code_scanner_rounded, color: context.accentText),
            onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const BarCodeScan())),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.15);
  }

  Widget _heroCard() {
    return Column(children: [
      // Discover Your Style — warm caramel banner with the original shopping illustration
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: GestureDetector(
          onTap: () => ShellController.openDiscover(''),
          child: Container(
            height: 176,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: AppColors.espresso,
              boxShadow: AppColors.softShadow,
            ),
            child: Stack(children: [
              Positioned(
                right: 12,
                top: 18,
                child: ClipOval(
                  child: Container(
                    width: 140,
                    height: 140,
                    color: const Color(0xFFF8E3C8),
                    child: Image.asset('assets/images/3.PNG', fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Discover\nYour Style', style: AppTheme.display(25, color: AppColors.cream, height: 1.1)),
                  const SizedBox(height: 6),
                  Text('Fashion, smarter\nwith FINDME ✨', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, height: 1.35, color: AppColors.cream.withOpacity(0.85))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(gradient: AppColors.caramel, borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Explore', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.ink),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
      // AI stylist card with the FINDME robot
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Material(
          color: context.isDark ? AppColors.nightCard : AppColors.peach,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => ShellController.askStylist(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: context.card, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(9),
                  child: Image.asset('assets/images/Group.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your AI Stylist', style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text('Tell me the occasion, I’ll find the look.', style: context.text.bodySmall),
                  ]),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(gradient: AppColors.caramel, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.ink),
                ),
              ]),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 220.ms, duration: 450.ms),
    ]);
  }

  Widget _categoryRow() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final (label, icon, query) = _categories[i];
          return GestureDetector(
            onTap: () => ShellController.openDiscover(query),
            child: Column(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.line),
                  boxShadow: context.isDark ? null : AppColors.softShadow,
                ),
                child: Icon(icon, color: context.isDark ? AppColors.camel : AppColors.brown, size: 24),
              ),
              const SizedBox(height: 6),
              Text(label, style: context.text.labelSmall?.copyWith(color: context.fg)),
            ]),
          ).animate(delay: (200 + 50 * i).ms).fadeIn().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
        },
      ),
    );
  }

  Widget _loadingSections() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 26, 20, 12), child: SkeletonBox(width: 160, height: 22, radius: 8)),
      const HorizontalSkeletonList(),
      const Padding(padding: EdgeInsets.fromLTRB(20, 26, 20, 12), child: SkeletonBox(width: 130, height: 22, radius: 8)),
      const HorizontalSkeletonList(),
    ]);
  }

  Widget _styleDnaBanner(HomeFeed f) {
    final hasDna = f.persona != null && !f.coldStart;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () async {
          await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => hasDna ? const StyleDnaScreen() : const StyleQuizScreen()));
          _refresh();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line), boxShadow: context.isDark ? null : AppColors.softShadow),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.camel.withOpacity(0.18), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.brown),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hasDna ? 'YOUR STYLE DNA' : 'DISCOVER YOUR STYLE DNA', style: context.text.labelSmall),
                const SizedBox(height: 2),
                Text(hasDna ? f.persona! : 'Take the 1-minute style quiz', style: context.text.titleMedium),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: context.fgMuted),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _sections(HomeFeed f) {
    final sections = <Widget>[_styleDnaBanner(f)];
    if (f.forYou.isNotEmpty) {
      sections.addAll([
        SectionHeader('For You', subtitle: f.coldStart ? 'Popular picks while we learn your style' : 'Ranked for your ${f.persona ?? 'style'}', action: 'See all', onAction: () => ShellController.openDiscover('')),
        ProductRail(f.forYou, heroPrefix: 'home-fy'),
      ]);
    }
    if (f.trending.isNotEmpty) {
      sections.addAll([
        SectionHeader('Trending now', subtitle: 'Most viewed and loved this fortnight', action: 'See all', onAction: () => ShellController.openDiscover('sort:popular')),
        ProductRail(f.trending, heroPrefix: 'home-tr', cardWidth: 150),
      ]);
    }
    if (f.budget.isNotEmpty) {
      sections.addAll([
        SectionHeader('Under ${formatPrice(f.budgetMax)} TND', subtitle: 'Best options within your usual budget', action: 'See all', onAction: () => ShellController.openDiscover('max:${f.budgetMax.round()}')),
        ProductRail(f.budget, heroPrefix: 'home-bd', cardWidth: 150),
      ]);
    }
    if (f.deals.isNotEmpty) {
      sections.addAll([
        const SectionHeader('Deals', subtitle: 'Biggest discounts right now'),
        ProductRail(f.deals, heroPrefix: 'home-dl', cardWidth: 150),
      ]);
    }
    if (f.newIn.isNotEmpty) {
      sections.addAll([
        SectionHeader('New in', action: 'See all', onAction: () => ShellController.openDiscover('sort:new')),
        ProductRail(f.newIn, heroPrefix: 'home-new', cardWidth: 150),
      ]);
    }
    if (sections.length == 1) {
      sections.add(const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products yet', message: 'Add products from the admin dashboard to see recommendations here.'));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }
}
