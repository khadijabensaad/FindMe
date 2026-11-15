<<<<<<< HEAD
import 'package:find_me/ui/geo/store_map_screen.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/outfits/outfits_screen.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:find_me/ui/geo/location_service.dart';
import 'package:readmore/readmore.dart';

/// 04 — Product Details (premium).
/// `identifier` can be a Mongo id (24 chars) or a barcode, as before.
class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.identifier, this.initial, this.heroTag});
  final String identifier;
  final RecoProduct? initial;
  final String? heroTag;
=======
import 'dart:convert';

import 'package:find_me/Core/Search/osm_map.dart';
import 'package:find_me/Models/product_model.dart';
import 'package:find_me/Services/product_api.dart';
import 'package:find_me/widgets/colors_help.dart';
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.identifier});
  final String identifier;
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
<<<<<<< HEAD
  final _api = FindMeApi.instance;
  RecoProduct? _p;
  String? _error;
  ScoreExplanation? _explain;
  List<RecoProduct> _similar = [];
  OutfitSuggestion? _look;
  List<ShopHit> _shops = [];
  bool _shopsByDistance = false;
  int _page = 0;
  String? _feedback;
  final _shopsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _p = widget.initial;
    _load();
  }

  Future<void> _load() async {
    try {
      final p = widget.identifier.length > 13 ? await _api.productById(widget.identifier) : await _api.productByBarcode(widget.identifier);
      if (!mounted) return;
      setState(() => _p = p);
      _loadAi(p.id);
    } catch (e) {
      if (mounted && _p == null) setState(() => _error = e.toString());
      if (_p != null) _loadAi(_p!.id);
    }
  }

  Future<void> _loadAi(String id) async {
    // independent calls, each one fills its own section when it arrives
    _api.explain(id).then((v) {
      if (mounted) setState(() => _explain = v);
    }).catchError((_) {});
    _api.similar(id).then((v) {
      if (mounted) setState(() => _similar = v);
    }).catchError((_) {});
    _api.completeLook(id).then((v) {
      if (mounted) setState(() => _look = v);
    }).catchError((_) {});
    _loadShops(id);
  }

  Future<void> _loadShops(String id, {bool askLocation = false}) async {
    // manual city first, then GPS (asks the permission only on user action)
    final me = await LocationService.instance.current(ask: askLocation);
    try {
      final shops = await _api.nearbyShops(id, lat: me?.lat, lng: me?.lng);
      if (mounted) {
        setState(() {
          _shops = shops;
          _shopsByDistance = me != null;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendFeedback(String value) async {
    final p = _p;
    if (p == null) return;
    String? reason;
    if (value == 'dislike') {
      reason = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Text('What does not fit?', style: AppTheme.display(20, color: ctx.fg))),
            for (final r in const [
              ('too_expensive', 'Too expensive'),
              ('not_my_style', 'Not my style'),
              ('wrong_color', 'Not the right colour'),
              ('wrong_size', 'Not my size'),
              ('already_have', 'I already have one'),
            ])
              ListTile(title: Text(r.$2), onTap: () => Navigator.pop(ctx, r.$1)),
            const SizedBox(height: 10),
          ]),
        ),
      );
      if (reason == null) return;
    }
    setState(() => _feedback = value);
    try {
      await _api.feedback(p.id, value, reason: reason, context: 'other');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value == 'like' ? 'Noted! Your Style DNA gets sharper ✨' : 'Thanks, we will show you fewer items like this.'),
        ));
      }
    } catch (_) {}
  }

  Future<void> _priceAlert() async {
    final p = _p;
    if (p == null) return;
    double target = (p.effectivePrice * 0.9).roundToDouble();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Price drop alert', style: AppTheme.display(22, color: ctx.fg)),
              const SizedBox(height: 6),
              Text('We will let you know when ${p.name} drops to your target price.', style: ctx.text.bodySmall),
              const SizedBox(height: 18),
              Text('Notify me at ${formatPrice(target)} TND or less', style: ctx.text.titleSmall),
              Slider(
                value: target,
                min: (p.effectivePrice * 0.3).floorToDouble(),
                max: p.effectivePrice,
                activeColor: AppColors.camel,
                onChanged: (v) => setSheet(() => target = v.roundToDouble()),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create alert'))),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _api.createAlert(p.id, targetPrice: target);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alert set at ${formatPrice(target)} TND 🔔')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create alert: $e')));
=======
  ProductApiCall _productApiCall = ProductApiCall();
  HelperFunctions _helperFunctions = HelperFunctions();
  String id = "";
  int barcode = 0;
  bool isFavorite = false;
  late SharedPreferences prefs;
  late var token = "";
  String message = '';

  @override
  void initState() {
    // TODO: implement initState
    initSharedPref().then((_) {
      setState(() {
        token = prefs.getString("userToken")!;
      });
    });
    super.initState();
  }

  Future<void> initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> addToFavorites(String prodId) async {
    await initSharedPref();
    var reqBody = jsonEncode({'prodId': prodId});
    String url = 'http://192.168.43.28:5000/auth/addToFavorites';
    var response = await http.put(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    setState(() {
      message = jsonResponse["message"];
    });
    if (jsonResponse["status"]) {
      if (message == "Product deleted from favorites.") {
        isFavorite = false;
      } else {
        isFavorite = true;
      }
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final p = _p;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null
            ? ErrorRetry(message: _error!, onRetry: () {
                setState(() => _error = null);
                _load();
              })
            : const Center(child: CircularProgressIndicator(color: AppColors.camel)),
      );
    }
    final gallery = p.gallery.isEmpty ? [''] : p.gallery;
    final heroTag = widget.heroTag ?? 'detail-${p.id}';
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.56,
            pinned: true,
            stretch: true,
            backgroundColor: context.bg,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: context.card.withOpacity(0.9),
                child: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.fg), onPressed: () => Navigator.pop(context)),
              ),
            ),
            actions: [Padding(padding: const EdgeInsets.only(right: 12), child: FavoriteButton(p, size: 40))],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(fit: StackFit.expand, children: [
                PageView.builder(
                  itemCount: gallery.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => i == 0 ? Hero(tag: heroTag, child: AppNetworkImage(gallery[i])) : AppNetworkImage(gallery[i]),
                ),
                if (gallery.length > 1)
                  Positioned(
                    bottom: 34,
                    left: 0,
                    right: 0,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < gallery.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(color: i == _page ? AppColors.ink : Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                        ),
                    ]),
                  ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -22, 0),
              decoration: BoxDecoration(color: context.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _titleBlock(p),
                if (p.colors.isNotEmpty || p.sizes.isNotEmpty) _variants(p),
                _matchCard(),
                _feedbackRow(),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('Description', style: context.text.titleMedium),
                  const SizedBox(height: 8),
                  ReadMoreText(
                    p.description,
                    trimLines: 3,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' more',
                    trimExpandedText: ' less',
                    style: context.text.bodyMedium?.copyWith(color: context.fgMuted, height: 1.5),
                    moreStyle: const TextStyle(color: AppColors.camel, fontWeight: FontWeight.w600),
                    lessStyle: const TextStyle(color: AppColors.camel, fontWeight: FontWeight.w600),
                  ),
                ],
                _shopsBlock(p),
              ]),
            ),
          ),
          if (_look != null && _look!.items.isNotEmpty) SliverToBoxAdapter(child: _completeTheLook(_look!)),
          if (_similar.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('You may also like', subtitle: 'Similar style, colour and price')),
            SliverToBoxAdapter(child: ProductRail(_similar, heroPrefix: 'sim-${p.id}', cardWidth: 150)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: _bottomBar(p),
    );
  }

  Widget _titleBlock(RecoProduct p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(p.brand.toUpperCase(), style: context.text.labelSmall?.copyWith(letterSpacing: 1.4))),
        for (final b in p.badges.take(2)) Padding(padding: const EdgeInsets.only(left: 6), child: BadgePill(b)),
      ]),
      const SizedBox(height: 6),
      Text(p.name, style: AppTheme.display(26, color: context.fg, height: 1.15)),
      const SizedBox(height: 10),
      Row(children: [
        PriceText(p, size: 20),
        if (p.hasDiscount) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFB3261E).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('-${p.discountPercent}%', style: const TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
        const Spacer(),
        RatingBarIndicator(rating: p.rating, itemSize: 16, itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.camel)),
        const SizedBox(width: 4),
        Text(p.rating.toStringAsFixed(1), style: context.text.labelMedium),
      ]),
    ]).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08);
  }

  Widget _variants(RecoProduct p) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (p.colors.isNotEmpty)
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Colours', style: context.text.labelSmall),
              const SizedBox(height: 8),
              ColorDots(p.colors, size: 22),
            ]),
          ),
        if (p.sizes.isNotEmpty)
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sizes', style: context.text.labelSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final s in p.sizes)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: context.line), borderRadius: BorderRadius.circular(10), color: context.card),
                    child: Text(s, style: context.text.labelMedium),
                  ),
              ]),
            ]),
          ),
      ]),
    );
  }

  /// "Why it matches you" — the explainable recommendation score.
  Widget _matchCard() {
    final e = _explain;
    if (e == null) {
      return const Padding(padding: EdgeInsets.only(top: 22), child: SkeletonBox(height: 120, radius: AppRadius.md));
    }
    const labels = {
      'category': 'Category',
      'style': 'Style & colour',
      'budget': 'Budget',
      'preference': 'Your preferences',
      'rating': 'Rating',
      'trend': 'Trend',
    };
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: 52,
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: e.matchPercent / 100),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CircularProgressIndicator(value: v, strokeWidth: 5, color: AppColors.camel, backgroundColor: context.line),
              ),
              Text('${e.matchPercent}%', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
          title: Text('Why it matches you', style: context.text.titleMedium),
          subtitle: Text(
            e.reasons.isEmpty ? 'Tap to see how the score is computed' : e.reasons.take(2).map((r) => r.label).join(' · '),
            style: context.text.bodySmall,
            maxLines: 2,
          ),
          children: [
            const SizedBox(height: 8),
            for (final r in e.reasons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.label, style: context.text.bodyMedium)),
                ]),
              ),
            const SizedBox(height: 12),
            for (final k in labels.keys)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 120, child: Text('${labels[k]} ×${((e.weights[k] ?? 0) * 100).round()}%', style: context.text.bodySmall)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: e.breakdown[k] ?? 0),
                        duration: const Duration(milliseconds: 700),
                        builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 7, color: AppColors.camel, backgroundColor: context.line),
                      ),
                    ),
                  ),
                  SizedBox(width: 38, child: Text(((e.breakdown[k] ?? 0) * 100).round().toString(), textAlign: TextAlign.right, style: context.text.labelMedium)),
                ]),
              ),
            const SizedBox(height: 6),
            Text('Score = 0.30·Category + 0.20·Style + 0.15·Budget + 0.15·Preferences + 0.10·Rating + 0.10·Trend',
                style: context.text.labelSmall),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _feedbackRow() {
    Widget btn(String value, IconData icon, IconData active) {
      final sel = _feedback == value;
      return IconButton(
        onPressed: _feedback == null ? () => _sendFeedback(value) : null,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(sel ? active : icon, key: ValueKey(sel), color: sel ? AppColors.camel : context.fgMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Expanded(child: Text(_feedback == null ? 'Is this a good pick for you?' : 'Thanks for your feedback!', style: context.text.bodySmall)),
        btn('like', Icons.thumb_up_alt_outlined, Icons.thumb_up_alt_rounded),
        btn('dislike', Icons.thumb_down_alt_outlined, Icons.thumb_down_alt_rounded),
      ]),
    );
  }

  Widget _shopsBlock(RecoProduct p) {
    return Column(key: _shopsKey, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: Text('Available in ${_shops.length} shop${_shops.length > 1 ? 's' : ''}', style: context.text.titleMedium)),
        if (!_shopsByDistance && _shops.isNotEmpty)
          TextButton.icon(
            onPressed: () => _loadShops(p.id, askLocation: true),
            icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.camel),
            label: const Text('Nearest first', style: TextStyle(color: AppColors.camel)),
          ),
      ]),
      if (_shops.any((s) => s.hasCoords))
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => StoreMapScreen(title: 'Where to buy', subtitle: p.name, stores: _shops))),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('View stores on the map'),
          ),
        ),
      const SizedBox(height: 6),
      if (_shops.isEmpty) Text(p.shops.isEmpty ? 'No shop listed yet.' : p.shops.join(' · '), style: context.text.bodySmall),
      for (final s in _shops)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.camel.withOpacity(0.12), child: const Icon(Icons.storefront_rounded, color: AppColors.camel)),
            title: Text(s.name, style: context.text.titleSmall),
            subtitle: Text([s.city, if (s.distanceKm != null) '${s.distanceKm!.toStringAsFixed(1)} km'].join(' · '), style: context.text.bodySmall),
            trailing: const Icon(Icons.directions_rounded, color: AppColors.camel),
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => StoreMapScreen(title: 'Where to buy', subtitle: p.name, stores: _shops, focusName: s.name, directionsOnOpen: true))),
          ),
        ),
    ]);
  }

  Widget _completeTheLook(OutfitSuggestion look) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('Complete the look', subtitle: 'Total ${formatPrice(look.totalPrice)} TND', action: 'Save outfit', onAction: () => _saveOutfit(look)),
      SizedBox(
        height: 285,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: look.items.length,
          separatorBuilder: (_, __) => const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Center(child: Icon(Icons.add_rounded, color: AppColors.camel))),
          itemBuilder: (_, i) {
            final it = look.items[i];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.slot.toUpperCase(), style: context.text.labelSmall),
              const SizedBox(height: 6),
              Expanded(child: ProductCard(it.product, heroPrefix: 'look-${look.anchor.id}', width: 130, showMatch: false)),
            ]).animate(delay: (120 * i).ms).fadeIn().slideX(begin: 0.1);
          },
        ),
      ),
    ]);
  }

  Future<void> _saveOutfit(OutfitSuggestion look) async {
    final name = await promptOutfitName(context, 'Look with ${look.anchor.name}');
    if (name == null) return;
    try {
      await _api.saveOutfit(name: name, source: 'complete_look', items: [OutfitItem('main', look.anchor, const []), ...look.items]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Outfit saved ✨'),
          action: SnackBarAction(label: 'View', textColor: AppColors.camel, onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const OutfitsScreen()))),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Widget _bottomBar(RecoProduct p) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(color: context.bg, border: Border(top: BorderSide(color: context.line))),
        child: Row(children: [
          OutlinedButton(
            onPressed: _priceAlert,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: const CircleBorder()),
            child: const Icon(Icons.notifications_active_outlined, size: 20),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              ShellController.askStylist('What goes well with ${p.name}?');
            },
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: const CircleBorder()),
            child: const Icon(Icons.auto_awesome, size: 20, color: AppColors.camel),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final ctx = _shopsKey.currentContext;
                if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
              },
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text('Find in store'),
            ),
          ),
        ]),
      ),
    );
=======
    return Scaffold(
        backgroundColor: Color(0xFFFDF1E1),
        drawer: DrawerWidget(),
        body: SafeArea(
            child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Column(children: [
            SizedBox(
              height: 20,
            ),
            /*
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height / 2.8,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 220, 198, 170)
                          .withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: 
                         InkWell(child: Image.asset("assets/images/profile2.jpg",fit: BoxFit.fill,),
                         onTap: () {
                           print("Detail page:  ${widget.identifier}");
                         },)
                                          
              ),
              ),*/
            FutureBuilder<ProductModel>(
              future: widget.identifier.length > 13
                  ? _productApiCall.getProductById(widget.identifier)
                  : _productApiCall.getProductByBarCode(widget.identifier),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  isFavorite = snapshot.data!.isFavorite;
                  //List<String> images = snapshot.data!.images;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height / 2.8,
                        width: MediaQuery.of(context).size.width,
                        child: ListView.separated(
                          separatorBuilder: (context, index) => SizedBox(
                            width: 5,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: snapshot.data!.images.length,
                          itemBuilder: (context, index) => Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors
                                    .transparent, // Set the border color here
                                width: 2.0, // Set the border width here
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 220, 198, 170)
                                          .withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  "${snapshot.data?.images[index]}",
                                  fit: BoxFit.fill,
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                )),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 20, bottom: 0),
                        child: Text(
                          "${snapshot.data?.name}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(
                                Icons.star_rate_rounded,
                                color: Color(0xFFFFBD59),
                              ),
                              onPressed: () {}),
                          Text(
                            "${snapshot.data?.rating}",
                            style: const TextStyle(
                                color: Color(0xFFFFBD59),
                                fontFamily: 'Poppins',
                                fontSize: 16),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Brand:    ",
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      fontSize: 16),
                                ),
                                Text(
                                  "${snapshot.data?.brand}",
                                  style: const TextStyle(
                                      color: Color(0xFFDF9A4F),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      fontSize: 16),
                                )
                              ],
                            ),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    addToFavorites(snapshot.data!.id)
                                        .whenComplete(() =>
                                            Fluttertoast.showToast(
                                              msg: message,
                                              toastLength: Toast.LENGTH_SHORT,
                                              backgroundColor:
                                                  Colors.black.withOpacity(0.7),
                                            ));
                                    ;
                                  });
                                },
                                icon: Icon(
                                  CupertinoIcons.heart_fill,
                                  color:
                                      isFavorite ? Colors.red : Colors.black26,
                                ))
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 255, 220, 169),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(255, 161, 155, 146)
                                    .withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 3,
                                offset: const Offset(0, 0),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(
                                    "Price",
                                    //  maxLines: 2,
                                    //  overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: 'poppins',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 16,
                                            ),
                                            Text(
                                              snapshot.data?.discountPrice == -1
                                                  ? '     '
                                                  : //condition remise discount promotion
                                                  ' ${snapshot.data?.price} DT',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall!
                                                  .apply(
                                                      decoration: TextDecoration
                                                          .lineThrough),
                                            ),

                                            const SizedBox(width: 10),

                                            /// Sale Price
                                            Text(
                                              snapshot.data?.discountPrice == -1
                                                  ? "${snapshot.data?.price}"
                                                      r" DT"
                                                  : "${snapshot.data?.discountPrice.toInt()} DT",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        /*
                                        const Row(children: [
                                          Text(
                                            "Stock:",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 6,
                                          ),
                                          Text(
                                            "In Stock",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ]),*/
                                      ]),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: const Text(
                                "Colors",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 40,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListView.separated(
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                    width: 5,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.colors.length,
                                  itemBuilder: (context, index) => Container(
                                    width: 40,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                      borderRadius: BorderRadius.circular(50),
                                      color: HelperFunctions.getColor(
                                          "${snapshot.data?.colors[index]}")!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Size",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0),
                                      child: ListView.separated(
                                        separatorBuilder: (context, index) =>
                                            SizedBox(
                                          width: 5,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: snapshot.data!.size.length,
                                        itemBuilder: (context, index) =>
                                            Container(
                                          alignment: Alignment.center,
                                          width: 50,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 255, 220, 169),
                                            border: Border.all(
                                                color: Colors.black38,
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "${snapshot.data?.size[index]}",
                                            style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Description",
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  ReadMoreText(
                                    "${snapshot.data?.description}",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    trimCollapsedText: "Show more",
                                    trimExpandedText: " less",
                                    trimLines: 2,
                                    trimMode: TrimMode.Line,
                                    colorClickableText: Colors.black,
                                    moreStyle: const TextStyle(
                                      color: Color(0xFFDF9A4F),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                    lessStyle: const TextStyle(
                                      color: Color(0xFFDF9A4F),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Shops",
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    height: snapshot.data!.shops.length * 150,
                                    width: MediaQuery.of(context).size.width,
                                    child: ListView.separated(
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: () async {
                                              var status = await Permission
                                                  .location
                                                  .request();
                                              if (status.isGranted) {
                                                Navigator.push(
                                                    context,
                                                    CupertinoPageRoute(
                                                        builder: (context) =>
                                                            ShopMap(
                                                              name:
                                                                  '${snapshot.data?.shops[index]}',
                                                            )));
                                              } else {
                                                print(
                                                    "Location permission is required to use the app.");
                                              }
                                            },
                                            child: Container(
                                              clipBehavior: Clip.antiAlias,
                                              height: 100,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors
                                                      .black, // Set the border color here
                                                  width:
                                                      1, // Set the border width here
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                            255, 220, 198, 170)
                                                        .withOpacity(0.5),
                                                    spreadRadius: 2,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 0),
                                                  ),
                                                ],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    "assets/images/marketplace.png",
                                                    width: 90,
                                                  ),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "${snapshot.data?.shops[index]}",
                                                        style: const TextStyle(
                                                            fontFamily:
                                                                'Poppins',
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 10),
                                        itemCount: snapshot.data!.shops.length),
                                  )
                                ],
                              ),
                            ),
                          ]),
                    ],
                  );
                } else {
                  print(
                      "Hello error fi product detail page: ${snapshot.error}");
                  return Center(
                      child:
                          //Text("hello ${snapshot.error}")
                          CircularProgressIndicator(
                    color: Color(0xFF965D1A),
                  ));
                }
              },
            )
          ]),
        ))));
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
  }
}
