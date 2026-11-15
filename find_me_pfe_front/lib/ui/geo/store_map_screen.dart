import 'dart:math' as math;

import 'package:find_me/Core/Drawer_Items_Pages/products_list.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/geo/findme_map.dart';
import 'package:find_me/ui/geo/location_service.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The single geolocation screen design of FINDME (Nearby Stores mockup):
/// cream background, centred title + location icon, rounded warm map,
/// caramel markers (selected = dark), store cards with "Get Directions".
///
/// * [stores] == null → every FINDME shop (GET /recommendations/stores).
/// * [stores] given   → only those (e.g. shops selling one product).
/// * [focusName]      → pre-select the shop with this name.
class StoreMapScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<ShopHit>? stores;
  final String? focusName;
  final bool directionsOnOpen;
  const StoreMapScreen({super.key, this.title = 'Nearby Stores', this.subtitle, this.stores, this.focusName, this.directionsOnOpen = false});

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  final _api = FindMeApi.instance;
  final _pages = PageController(viewportFraction: 0.9);
  GeoPoint? _me;
  List<ShopHit> _stores = [];
  int _selected = 0;
  bool _loading = true;
  String? _error;
  String? _locationNote;
  MapRoute? _route;
  bool _routing = false;

  @override
  void initState() {
    super.initState();
    _load(ask: true);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _load({bool ask = false, GeoPoint? forced}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final me = forced ?? await LocationService.instance.current(ask: ask);
    _locationNote = me == null ? LocationService.instance.issueText() : null;
    try {
      List<ShopHit> list;
      if (widget.stores == null) {
        list = await _api.stores(lat: me?.lat, lng: me?.lng);
      } else {
        list = widget.stores!.where((s) => s.hasCoords).map((s) => _withDistance(s, me)).toList();
        if (me != null) list.sort((a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
      }
      if (!mounted) return;
      var sel = 0;
      if (widget.focusName != null) {
        final i = list.indexWhere((s) => s.name.toLowerCase() == widget.focusName!.toLowerCase());
        if (i >= 0) sel = i;
      }
      setState(() {
        _me = me;
        _stores = list;
        _selected = sel;
        _route = null;
        _loading = false;
      });
      {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pages.hasClients) _pages.jumpToPage(sel);
        });
      }
      if (widget.directionsOnOpen && me != null && list.isNotEmpty) _directions(list[sel]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  /// Distance for shops passed in by the caller (same Haversine as the backend).
  ShopHit _withDistance(ShopHit s, GeoPoint? me) {
    if (me == null || !s.hasCoords) return s;
    final d = const _Haversine().km(me.lat, me.lng, s.lat!, s.lng!);
    return ShopHit(s.id, s.name, s.city, s.region, s.lat, s.lng, d, verified: s.verified, productCount: s.productCount, productIds: s.productIds);
  }

  void _select(int i, {bool fromMap = false}) {
    if (i == _selected) return;
    setState(() {
      _selected = i;
      _route = null;
    });
    if (fromMap && _pages.hasClients) _pages.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _chooseLocation() async {
    final p = await pickLocation(context);
    if (p != null && mounted) _load(forced: p);
  }

  Future<void> _directions(ShopHit s) async {
    var me = _me;
    if (me == null) {
      me = await pickLocation(context);
      if (me == null || !mounted) return;
      await _load(forced: me);
      if (!mounted) return;
    }
    setState(() => _routing = true);
    final r = await MapRoute.fetch(me, s);
    if (!mounted) return;
    setState(() {
      _routing = false;
      _route = r;
    });
    if (r == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The route service is not reachable right now. Distance shown is a straight line.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.isDark ? AppColors.camel : AppColors.brown;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(children: [
          // Header: back · centred title · location icon
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(children: [
              if (Navigator.of(context).canPop())
                IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.fg, size: 20), onPressed: () => Navigator.pop(context))
              else
                const SizedBox(width: 48),
              Expanded(
                child: Column(children: [
                  Text(widget.title, textAlign: TextAlign.center, style: AppTheme.display(24, color: context.fg)),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                ]),
              ),
              IconButton(tooltip: 'Change location', icon: Icon(Icons.location_on_rounded, color: accent, size: 26), onPressed: _chooseLocation),
            ]),
          ),
          _LocationBar(me: _me, note: _locationNote, onTap: _chooseLocation),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg + 4),
                  border: Border.all(color: context.line),
                  boxShadow: AppColors.softShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg + 4),
                  child: _error != null
                      ? ErrorRetry(message: _error!, onRetry: () => _load())
                      : Stack(children: [
                          Positioned.fill(
                            child: FindMeMap(stores: _stores, me: _me, selected: _selected, route: _route, onSelect: (i) => _select(i, fromMap: true)),
                          ),
                          if (_loading)
                            const Positioned(top: 14, left: 14, child: _Pill(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.camel)))),
                          if (_route != null)
                            Positioned(
                              left: 14,
                              top: 14,
                              child: _Pill(
                                child: Text('${_route!.km.toStringAsFixed(1)} km · ${_route!.minutes.round()} min by car',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                              ),
                            ),
                        ]),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 168,
            child: _loading && _stores.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonBox(height: 150, radius: AppRadius.lg))
                : _stores.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: Text(
                            widget.stores == null ? 'No store with a map position yet.' : 'The shops of this item have no map position yet.',
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium,
                          ),
                        ),
                      )
                    : PageView.builder(
                        controller: _pages,
                        itemCount: _stores.length,
                        onPageChanged: _select,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
                          child: StoreInfoCard(
                            store: _stores[i],
                            selected: i == _selected,
                            routing: _routing && i == _selected,
                            onDirections: () {
                              _select(i);
                              _directions(_stores[i]);
                            },
                            onProducts: _stores[i].id.isEmpty
                                ? null
                                : () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => ShopProductsList(id: _stores[i].id))),
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final GeoPoint? me;
  final String? note;
  final VoidCallback onTap;
  const _LocationBar({required this.me, required this.note, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final String text;
    if (me == null) {
      text = '${note == null || note!.isEmpty ? 'Location unknown.' : note} Tap to choose a city.';
    } else if (me!.source == 'gps') {
      text = 'Distances from your current position';
    } else {
      text = 'Distances from ${me!.label ?? 'the chosen city'} · change';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(me == null ? Icons.location_off_rounded : Icons.near_me_rounded, size: 15, color: me == null ? const Color(0xFFA8321F) : AppColors.camel),
            const SizedBox(width: 6),
            Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall)),
          ]),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.softShadow),
        child: child,
      );
}

/// Bottom card of the map: image, name, distance, availability, Get Directions.
/// Opening hours and ratings are NOT in the shop data, so they are not shown.
class StoreInfoCard extends StatelessWidget {
  final ShopHit store;
  final bool selected;
  final bool routing;
  final VoidCallback onDirections;
  final VoidCallback? onProducts;
  const StoreInfoCard({super.key, required this.store, required this.onDirections, this.onProducts, this.selected = false, this.routing = false});

  @override
  Widget build(BuildContext context) {
    final place = [store.city, if (store.region.isNotEmpty && store.region != store.city) store.region].where((e) => e.isNotEmpty).join(', ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: selected ? AppColors.camel : context.line, width: selected ? 1.4 : 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 92,
            height: double.infinity,
            color: AppColors.peach,
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/images/marketplace.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.display(18, color: context.fg)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.place_outlined, size: 14, color: context.fgMuted),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  [if (store.distanceKm != null) '${store.distanceKm!.toStringAsFixed(1)} km', if (place.isNotEmpty) place].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (store.verified) const _Tag(icon: Icons.verified_rounded, text: 'Item confirmed', color: Color(0xFF3F7D4E)),
              if (store.productCount > 0) _Tag(icon: Icons.checkroom_rounded, text: '${store.productCount} items', color: context.accentText),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.camel,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                    ),
                    onPressed: routing ? null : onDirections,
                    icon: routing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Get Directions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              if (onProducts != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Products of this store',
                  onPressed: onProducts,
                  style: IconButton.styleFrom(side: BorderSide(color: context.line)),
                  icon: Icon(Icons.storefront_rounded, color: context.accentText, size: 20),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Tag({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
      ]);
}

class _Haversine {
  const _Haversine();
  double km(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
