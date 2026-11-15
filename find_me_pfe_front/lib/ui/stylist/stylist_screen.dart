import 'dart:typed_data';

import 'package:find_me/data/api_client.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/geo/findme_map.dart';
import 'package:find_me/ui/geo/location_service.dart';
import 'package:find_me/ui/geo/store_map_screen.dart';
import 'package:find_me/ui/profile/style_dna_screen.dart';
import 'package:find_me/ui/outfits/outfits_screen.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:find_me/ui/widgets/voice_input.dart';
import 'package:find_me/widgets/colors_help.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Entry {
  final bool fromUser;
  final String text;
  final StylistReply? reply;
  final Uint8List? image;
  final VisualSearchResult? visual;
  final bool welcome;
  _Entry.user(this.text, {this.image})
      : fromUser = true,
        reply = null,
        visual = null,
        welcome = false;
  _Entry.bot(this.text, {this.reply, this.visual, this.welcome = false})
      : fromUser = false,
        image = null;
}

/// 02 — AI Fashion Stylist.
class StylistScreen extends StatefulWidget {
  final bool embedded;
  final String? initialPrompt;
  const StylistScreen({super.key, this.embedded = false, this.initialPrompt});
  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  final _api = FindMeApi.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Entry> _entries = [];
  List<CriteriaChip> _chips = [];
  List<String> _quick = const ['Black dress for a party', 'Sneakers under 150 TND', 'An outfit for work', 'Robe chic pour un mariage'];
  String? _sessionId;
  bool _typing = false;
  bool _llm = false;

  static const _welcome =
      "Hi! ✨ I'm your personal FINDME stylist. Tell me what you're looking for, an occasion or a budget. You can also send me a photo or talk to me.\n\nSalut ! Tu peux aussi m'écrire en français.";

  @override
  void initState() {
    super.initState();
    _entries.add(_Entry.bot(_welcome, welcome: true));
    _restore();
    ShellController.stylistPrompt.addListener(_onPrompt);
    if (widget.initialPrompt != null) WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialPrompt!));
  }

  @override
  void dispose() {
    ShellController.stylistPrompt.removeListener(_onPrompt);
    _input.dispose();
    _scroll.dispose();
    if (VoiceInput.instance.listening.value) VoiceInput.instance.stop();
    super.dispose();
  }

  void _onPrompt() {
    final p = ShellController.stylistPrompt.value;
    if (p != null && p.trim().isNotEmpty) {
      ShellController.stylistPrompt.value = null;
      _send(p);
    }
  }

  /// Contextual memory: restore the previous conversation of this user.
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('stylistSession');
    if (id == null) {
      if (ShellController.stylistPrompt.value != null) _onPrompt();
      return;
    }
    try {
      final h = await ApiClient.instance.get('/chatbot/sessions/$id');
      final msgs = (h['messages'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _sessionId = (h['sessionId'] ?? id).toString();
        _chips = ((h['criteriaChips'] as List?) ?? []).whereType<Map>().map((e) => CriteriaChip.fromJson(Map<String, dynamic>.from(e))).toList();
        for (final m in msgs.whereType<Map>().toList().reversed.take(20).toList().reversed) {
          final text = (m['text'] ?? '').toString();
          if (m['role'] == 'user') {
            _entries.add(_Entry.user(text));
          } else {
            final products = RecoProduct.listFrom(m['products']);
            _entries.add(_Entry.bot(text,
                reply: StylistReply(sessionId: _sessionId!, reply: text, intent: (m['intent'] ?? '').toString(), language: 'en', products: products, quickReplies: const [], chips: const [], outfit: null, shops: const [], shopsFor: null, llm: false)));
          }
        }
        if (msgs.isNotEmpty) _quick = const ['Cheaper', 'Another colour', 'Complete the look', 'Start over'];
      });
    } catch (_) {
      // session expired or server down: start fresh
    }
    if (ShellController.stylistPrompt.value != null) _onPrompt();
  }

  /// Manual city if chosen, else GPS (the permission is asked only when needed).
  Future<GeoPoint?> _location({bool ask = false}) => LocationService.instance.current(ask: ask);

  /// Products of the most recent bot message (for "similar" / "near me" quick actions).
  RecoProduct? get _lastProduct {
    for (final e in _entries.reversed) {
      final ps = e.reply?.products ?? e.visual?.products;
      if (ps != null && ps.isNotEmpty) return ps.first;
    }
    return null;
  }

  String? _lastUserText() {
    for (final e in _entries.reversed) {
      if (e.fromUser && e.image == null) return e.text;
    }
    return null;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    });
  }

  Future<void> _send(String raw, {GeoPoint? forcedLocation, bool echo = true}) async {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (echo) _entries.add(_Entry.user(text));
      _typing = true;
      _quick = const [];
    });
    _input.clear();
    _scrollToEnd();
    final wantsShops = RegExp(r'near|proche|pr[eè]s|autour|boutique|magasin|shop|store|où acheter|where|km', caseSensitive: false).hasMatch(text);
    final loc = forcedLocation ?? await _location(ask: wantsShops);
    await _ask(() => _api.chat(text, sessionId: _sessionId, location: loc));
  }

  /// Product buttons (Near me / Similar / Outfit): sent as structured actions,
  /// the backend does not have to guess which product is meant.
  Future<void> _action(String type, RecoProduct p) async {
    if (_typing) return;
    const labels = {'nearby': 'Where can I find', 'similar': 'Similar to', 'outfit': 'Build an outfit with'};
    HapticFeedback.selectionClick();
    setState(() {
      _entries.add(_Entry.user('${labels[type] ?? type} "${p.name}"'));
      _typing = true;
      _quick = const [];
    });
    _scrollToEnd();
    final loc = type == 'nearby' ? await _location(ask: true) : await _location(ask: false);
    await _ask(() => _api.chat('', sessionId: _sessionId, location: loc, actionType: type, productId: p.id));
  }

  /// The bot asked for a position: pick one, then replay the last request with it.
  Future<void> _provideLocation() async {
    final p = await pickLocation(context);
    if (p == null || !mounted) return;
    final last = _lastUserText();
    final label = p.source == 'gps' ? 'my current position' : p.label ?? 'this city';
    setState(() => _entries.add(_Entry.user('📍 Use $label')));
    await _send(last ?? 'Find products near me', forcedLocation: p, echo: false);
  }

  Future<void> _ask(Future<StylistReply> Function() call) async {
    try {
      final r = await call();
      await _remember(r.sessionId);
      if (!mounted) return;
      setState(() {
        _entries.add(_Entry.bot(r.reply, reply: r));
        _chips = r.chips;
        _quick = r.quickReplies;
        _llm = r.llm;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _entries.add(_Entry.bot("I couldn't reach the server. Please check your connection and try again. ($e)")));
    } finally {
      if (mounted) setState(() => _typing = false);
      _scrollToEnd();
    }
  }

  Future<void> _remember(String id) async {
    if (id.isEmpty) return;
    _sessionId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stylistSession', id);
  }

  Future<void> _removeChip(CriteriaChip c) async {
    final id = _sessionId;
    if (id == null || _typing) return;
    setState(() {
      _chips = _chips.where((x) => x != c).toList();
      _typing = true;
    });
    try {
      final r = await _api.removeCriterion(id, c.field, c.value);
      if (!mounted) return;
      setState(() {
        _entries.add(_Entry.bot(r.reply, reply: r));
        _chips = r.chips;
        _quick = r.quickReplies;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _typing = false);
      _scrollToEnd();
    }
  }

  Future<void> _reset() async {
    final id = _sessionId;
    if (id != null) {
      try {
        await _api.resetChat(id);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stylistSession');
    setState(() {
      _sessionId = null;
      _entries
        ..clear()
        ..add(_Entry.bot(_welcome, welcome: true));
      _chips = [];
      _quick = const ['Black dress for a party', 'Sneakers under 150 TND', 'An outfit for work', 'Robe chic pour un mariage'];
    });
  }

  Future<void> _photo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1280, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes(); // web + mobile
    setState(() {
      _entries.add(_Entry.user('Find items like this', image: bytes));
      _typing = true;
    });
    _scrollToEnd();
    try {
      final v = await _api.visualSearch(bytes, file.name.isEmpty ? 'photo.jpg' : file.name);
      final txt = !v.isFashion
          ? "I couldn't spot a fashion item in this photo. Try a clearer picture of the garment."
          : v.products.isEmpty
              ? 'I see ${v.description ?? 'this item'}, but nothing similar is in the catalogue yet.'
              : 'I see ${v.description ?? 'a ${v.colors.join('/')} ${v.type}'}. Here are the closest items in the catalogue 👇';
      if (mounted) setState(() => _entries.add(_Entry.bot(txt, visual: v)));
    } catch (e) {
      if (mounted) setState(() => _entries.add(_Entry.bot('Visual search is unavailable right now: $e')));
    } finally {
      if (mounted) setState(() => _typing = false);
      _scrollToEnd();
    }
  }

  Future<void> _mic() async {
    final v = VoiceInput.instance;
    if (v.listening.value) {
      await v.stop();
      return;
    }
    final ok = await v.start(onText: (text, isFinal) {
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
      if (isFinal && text.trim().isNotEmpty) {
        v.stop();
        _send(text);
      }
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition is not available on this device.')));
    }
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        titleSpacing: widget.embedded ? 20 : 0,
        title: Row(children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.peach, border: Border.all(color: AppColors.camel, width: 1.5)),
            child: Image.asset('assets/images/Group.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FINDME Stylist', style: AppTheme.display(18, color: context.fg)),
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Online', style: context.text.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ]),
        actions: [
          IconButton(tooltip: 'My outfits', icon: Icon(Icons.checkroom_outlined, color: context.isDark ? AppColors.camel : AppColors.brown), onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const OutfitsScreen()))),
          IconButton(tooltip: 'New conversation', icon: Icon(Icons.refresh_rounded, color: context.isDark ? AppColors.camel : AppColors.brown), onPressed: _reset),
        ],
      ),
      body: Column(children: [
        if (_chips.isNotEmpty) _chipsBar(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            itemCount: _entries.length + (_typing ? 1 : 0),
            itemBuilder: (_, i) {
              if (_typing && i == 0) return const _TypingBubble();
              final idx = _entries.length - 1 - (i - (_typing ? 1 : 0));
              return _entry(_entries[idx], idx);
            },
          ),
        ),
        if (_quick.isNotEmpty && !_typing) _quickReplies(),
        _inputBar(),
        // room for the floating nav bar (not needed while the keyboard is open)
        if (widget.embedded && View.of(context).viewInsets.bottom == 0) const SizedBox(height: 96),
      ]),
    );
  }

  Widget _chipsBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(color: context.card, border: Border(bottom: BorderSide(color: context.line))),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        scrollDirection: Axis.horizontal,
        children: [
          Center(child: Text('Looking for: ', style: context.text.labelSmall)),
          for (final c in _chips)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                label: Text(c.label, style: const TextStyle(fontSize: 12)),
                onDeleted: () => _removeChip(c),
                deleteIconColor: AppColors.camel,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _entry(_Entry e, int idx) {
    if (e.fromUser) return _UserBubble(e).animate().fadeIn(duration: 220.ms).slideX(begin: 0.1);
    final r = e.reply;
    final products = r?.products ?? e.visual?.products ?? const <RecoProduct>[];
    final near = r?.nearby;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _BotBubble(e.text),
      if (e.welcome && _entries.length == 1) _welcomeActions(),
      if (e.visual != null && e.visual!.isFashion) _detectedChips(e.visual!),
      if (near != null && near.needsLocation) _needsLocationCard()
      else if (near != null && near.stores.isNotEmpty) _nearbyCard(near, idx),
      if (r != null && r.looks.isNotEmpty)
        for (var li = 0; li < r.looks.length; li++) _LookCard(r.looks[li], 'look-$idx-$li')
      else if (r?.outfit != null && r!.outfit!.items.isNotEmpty)
        _OutfitCard(r.outfit!, idx)
      else if (products.isNotEmpty)
        _productCarousel(products, 'chat-$idx'),
      if (r != null && r.shops.isNotEmpty && near == null) _shopsCard(r),
      const SizedBox(height: 10),
    ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _detectedChips(VisualSearchResult v) {
    final tags = [if (v.type != null) v.type!, ...v.colors, ...v.styles];
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 8),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        for (final t in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.camel.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.camel, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  /// [prefix] is unique per message so Hero tags never collide.
  Widget _productCarousel(List<RecoProduct> products, String prefix) {
    return SizedBox(
      height: 336,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 40, right: 6),
        scrollDirection: Axis.horizontal,
        itemCount: products.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == products.length) return _showMoreTile();
          final p = products[i];
          return SizedBox(
            width: 150,
            child: Column(children: [
              Expanded(
                child: ProductCard(
                  p,
                  heroPrefix: prefix,
                  width: 150,
                  onTap: () {
                    _api.track('chat_click', productId: p.id);
                    openProduct(context, p, heroTag: '$prefix-${p.id}');
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                _MiniAction(icon: Icons.near_me_rounded, tooltip: 'Find nearby', onTap: () => _action('nearby', p)),
                const SizedBox(width: 6),
                _MiniAction(icon: Icons.auto_awesome_mosaic_outlined, tooltip: 'Similar products', onTap: () => _action('similar', p)),
                const SizedBox(width: 6),
                _MiniAction(icon: Icons.checkroom_rounded, tooltip: 'Build an outfit', onTap: () => _action('outfit', p)),
              ]),
            ]),
          ).animate(delay: (80 * i).ms).fadeIn(duration: 300.ms).slideX(begin: 0.15);
        },
      ),
    );
  }

  Widget _showMoreTile() {
    return SizedBox(
      width: 110,
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: _typing ? null : () => _send('Show more'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.camel)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.arrow_forward_rounded, color: AppColors.camel),
              const SizedBox(height: 6),
              Text('Show more', style: context.text.labelMedium?.copyWith(color: context.accentText, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }

  /// Quick actions on the welcome message.
  Widget _welcomeActions() {
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.dry_cleaning_rounded, 'Find a dress', () => _send('Find me a dress')),
      (Icons.checkroom_rounded, 'Build an outfit', () => _send('Build me a complete outfit')),
      (Icons.near_me_rounded, 'Find products near me', () => _send('Show me products available in stores near me')),
      (Icons.auto_awesome_mosaic_outlined, 'Find similar products', () {
        final p = _lastProduct;
        if (p != null) {
          _action('similar', p);
        } else {
          _input.text = 'Similar to ';
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search an item first (or send a photo 📷), then tap "Similar" under it.')));
        }
      }),
      (Icons.fingerprint_rounded, 'Discover my style', () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const StyleDnaScreen()))),
      (Icons.sell_outlined, 'Search under 100 TND', () => _send('Show me items under 100 TND')),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 6),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < actions.length; i++)
          ActionChip(
            avatar: Icon(actions[i].$1, size: 17, color: context.accentText),
            label: Text(actions[i].$2),
            labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: context.fg, fontWeight: FontWeight.w500),
            backgroundColor: context.card,
            side: BorderSide(color: context.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: _typing ? null : actions[i].$3,
          ).animate(delay: (60 * i).ms).fadeIn().slideY(begin: 0.3),
      ]),
    );
  }

  Widget _needsLocationCard() {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 2, bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line)),
      child: Row(children: [
        const Icon(Icons.location_searching_rounded, color: AppColors.camel),
        const SizedBox(width: 10),
        Expanded(child: Text('I need your position (GPS or a city) to compute real distances.', style: context.text.bodySmall?.copyWith(color: context.fg))),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.camel, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)),
          onPressed: _typing ? null : _provideLocation,
          child: const Text('Set location'),
        ),
      ]),
    );
  }

  /// Geolocated result: mini map + nearest stores (verified or "to confirm").
  Widget _nearbyCard(NearbyResult n, int idx) {
    final stores = n.stores.where((s) => s.hasCoords).toList();
    final originText = n.origin == null ? '' : n.origin!.source == 'gps' ? 'from your position' : 'from ${n.origin!.label ?? 'the chosen city'}';
    void openMap({String? focus, bool directions = false}) => Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => StoreMapScreen(title: 'Stores near you', subtitle: 'Within ${n.radiusKm.round()} km $originText', stores: stores, focusName: focus, directionsOnOpen: directions)));
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 2, bottom: 8),
      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: context.line), boxShadow: context.isDark ? null : AppColors.softShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 170,
          child: Stack(children: [
            // the mini map does not capture gestures (the chat scrolls); tap opens the full map
            Positioned.fill(child: IgnorePointer(child: FindMeMap(key: ValueKey('mini-$idx'), stores: stores, me: n.origin, selected: 0, onSelect: (_) {}))),
            Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () => openMap()))),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                child: Text('${stores.length} store${stores.length > 1 ? 's' : ''} · ${n.radiusKm.round()} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
            ),
          ]),
        ),
        for (final s in stores.take(3))
          ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_rounded, color: AppColors.camel),
            title: Text(s.name, style: context.text.titleSmall),
            subtitle: Text(
              [if (s.distanceKm != null) '${s.distanceKm!.toStringAsFixed(1)} km', if (s.city.isNotEmpty) s.city, s.verified ? 'available ✓' : 'availability to confirm'].join(' · '),
              style: context.text.bodySmall,
            ),
            trailing: IconButton(tooltip: 'Get Directions', icon: const Icon(Icons.directions_rounded, color: AppColors.camel), onPressed: () => openMap(focus: s.name, directions: true)),
            onTap: () => openMap(focus: s.name),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => openMap(), icon: const Icon(Icons.map_outlined, size: 18), label: const Text('View on map'))),
            const SizedBox(width: 8),
            TextButton(onPressed: _typing ? null : _provideLocation, child: const Text('Change location')),
          ]),
        ),
      ]),
    );
  }

  Widget _shopsCard(StylistReply r) {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 4),
      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line)),
      child: Column(children: [
        for (final s in r.shops.take(4))
          ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_rounded, color: AppColors.camel),
            title: Text(s.name, style: context.text.titleSmall),
            subtitle: Text([s.city, if (s.distanceKm != null) '${s.distanceKm!.toStringAsFixed(1)} km'].join(' · ')),
            trailing: const Icon(Icons.directions_rounded, color: AppColors.camel),
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => StoreMapScreen(title: 'Where to buy', subtitle: r.shopsFor, stores: r.shops, focusName: s.name, directionsOnOpen: true))),
          ),
      ]),
    );
  }

  Widget _quickReplies() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _quick.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => OutlinedButton(
          onPressed: () => _send(_quick[i]),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            minimumSize: const Size(0, 36),
            side: BorderSide(color: context.isDark ? AppColors.camel : AppColors.brown, width: 1.2),
            foregroundColor: context.fg,
            backgroundColor: context.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(_quick[i], style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w500)),
        ).animate(delay: (50 * i).ms).fadeIn().slideY(begin: 0.4),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      bottom: !widget.embedded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Row(children: [
          IconButton(
            tooltip: 'Search with a photo',
            onPressed: _typing ? null : _photo,
            icon: Icon(Icons.photo_camera_outlined, color: context.isDark ? AppColors.camel : AppColors.brown),
          ),
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Ask your stylist…',
                suffixIcon: ValueListenableBuilder<bool>(
                  valueListenable: VoiceInput.instance.listening,
                  builder: (_, listening, __) => GestureDetector(
                    onLongPress: () {
                      VoiceInput.instance.cycleLocale();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text('Voice language: ${VoiceInput.localeLabels[VoiceInput.instance.locale.value]}'),
                      ));
                    },
                    child: IconButton(
                      tooltip: 'Voice (long-press to change language)',
                      onPressed: _mic,
                      icon: Icon(listening ? Icons.stop_circle_rounded : Icons.mic_none_rounded, color: listening ? const Color(0xFFC0502E) : (context.isDark ? AppColors.camel : AppColors.brown)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.caramel, shape: BoxShape.circle, boxShadow: AppColors.softShadow),
            child: IconButton(
              tooltip: 'Send',
              icon: const Icon(Icons.send_rounded, color: AppColors.ink, size: 20),
              onPressed: _typing ? null : () => _send(_input.text),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _UserBubble extends StatelessWidget {
  final _Entry e;
  const _UserBubble(this.e);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 60, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          gradient: AppColors.espresso,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (e.image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(e.image!, width: 160, height: 200, fit: BoxFit.cover)),
            ),
          Text(e.text, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.cream, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;
  const _BotBubble(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 40),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.card, border: Border.all(color: context.line)),
          child: Image.asset('assets/images/Group.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.nightCard : AppColors.peach,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
            ),
            child: Text(text, style: context.text.bodyMedium?.copyWith(height: 1.45)),
          ),
        ),
      ]),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 38, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: context.isDark ? AppColors.nightCard : AppColors.peach, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(color: AppColors.camel, shape: BoxShape.circle),
            )
                .animate(onPlay: (c) => c.repeat())
                .moveY(begin: 0, end: -5, delay: (150 * i).ms, duration: 300.ms, curve: Curves.easeOut)
                .then()
                .moveY(begin: -5, end: 0, duration: 300.ms, curve: Curves.easeIn),
        ]),
      ),
    );
  }
}

/// Outfit generator result inside the chat.
class _OutfitCard extends StatelessWidget {
  final OutfitSuggestion look;
  final int idx;
  const _OutfitCard(this.look, this.idx);

  @override
  Widget build(BuildContext context) {
    final pieces = [OutfitItem('main', look.anchor, const []), ...look.items];
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.checkroom_rounded, color: AppColors.camel, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text('Complete look', style: context.text.titleSmall)),
          Text('${formatPrice(look.totalPrice)} TND', style: context.text.titleSmall?.copyWith(color: AppColors.camel)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pieces.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = pieces[i].product;
              return GestureDetector(
                onTap: () => openProduct(context, p, heroTag: 'outfit-chat-$idx-${p.id}'),
                child: SizedBox(
                  width: 96,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Hero(tag: 'outfit-chat-$idx-${p.id}', child: AppNetworkImage(p.thumbnail, radius: 12)),
                    ),
                    const SizedBox(height: 4),
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall?.copyWith(color: context.fg)),
                    Text('${formatPrice(p.effectivePrice)} TND', style: context.text.labelSmall),
                  ]),
                ),
              ).animate(delay: (100 * i).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text('Save this outfit'),
            onPressed: () async {
              final name = await promptOutfitName(context, 'Look with ${look.anchor.name}');
              if (name == null) return;
              try {
                await FindMeApi.instance.saveOutfit(name: name, source: 'chatbot', items: pieces);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outfit saved ✨')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
              }
            },
          ),
        ),
      ]),
    );
  }
}


/// A look imagined by the AI stylist: pieces available in FINDME shops are linked,
/// the others are shown as ideas.
class _LookCard extends StatelessWidget {
  final StyleLook look;
  final String tagPrefix;
  const _LookCard(this.look, this.tagPrefix);

  @override
  Widget build(BuildContext context) {
    final available = look.pieces.where((p) => p.product != null).toList();
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.line),
        boxShadow: context.isDark ? null : AppColors.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.checkroom_rounded, color: AppColors.camel, size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text(look.title, style: AppTheme.display(17, color: context.fg))),
        ]),
        if (look.occasion.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(look.occasion, style: context.text.bodySmall),
        ],
        const SizedBox(height: 10),
        for (final p in look.pieces) _piece(context, p),
        if (look.tip.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: context.isDark ? AppColors.nightLine : AppColors.peach, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.brown),
              const SizedBox(width: 8),
              Expanded(child: Text(look.tip, style: context.text.bodySmall?.copyWith(color: context.fg))),
            ]),
          ),
        if (available.length >= 2) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text('Save the ${available.length} available pieces'),
              onPressed: () async {
                final name = await promptOutfitName(context, look.title);
                if (name == null) return;
                try {
                  await FindMeApi.instance.saveOutfit(
                    name: name,
                    occasion: look.occasion,
                    source: 'chatbot',
                    items: available.map((p) => OutfitItem(p.type ?? 'item', p.product!, const [])).toList(),
                  );
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Look saved to your wardrobe ✨')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
                }
              },
            ),
          ),
        ],
      ]),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05);
  }

  Widget _piece(BuildContext context, LookPiece p) {
    final prod = p.product;
    final dot = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: p.color == null ? Colors.transparent : (HelperFunctions.getColor(p.color!) ?? Colors.grey),
        shape: BoxShape.circle,
        border: Border.all(color: context.line),
      ),
    );
    if (prod == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: context.isDark ? AppColors.nightLine : AppColors.peach, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: AppColors.camel, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [dot, const SizedBox(width: 6), Expanded(child: Text(p.description, style: context.text.bodyMedium))]),
              const SizedBox(height: 2),
              Text('Idea · not in our shops yet', style: context.text.labelSmall),
            ]),
          ),
        ]),
      );
    }
    final tag = '$tagPrefix-${prod.id}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          FindMeApi.instance.track('chat_click', productId: prod.id);
          openProduct(context, prod, heroTag: tag);
        },
        child: Row(children: [
          SizedBox(width: 52, height: 52, child: Hero(tag: tag, child: AppNetworkImage(prod.thumbnail, radius: 12))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [dot, const SizedBox(width: 6), Expanded(child: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium))]),
              const SizedBox(height: 2),
              Text('${prod.name} · ${formatPrice(prod.effectivePrice)} TND', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelMedium?.copyWith(color: context.accentText)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFDCEBDD), borderRadius: BorderRadius.circular(20)),
            child: Text(p.exact ? 'In our shops' : 'Similar', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2F5E3E))),
          ),
        ]),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniAction({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: context.isDark ? AppColors.nightCard : AppColors.peach,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(height: 32, child: Icon(icon, size: 17, color: context.isDark ? AppColors.camel : AppColors.brown)),
          ),
        ),
      ),
    );
  }
}
