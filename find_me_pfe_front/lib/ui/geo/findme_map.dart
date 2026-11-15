import 'dart:convert';

import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Warm beige tint applied to the OpenStreetMap tiles (keeps streets readable).
const _warmTiles = ColorFilter.matrix(<double>[
  0.90, 0.10, 0.02, 0, 12, //
  0.06, 0.86, 0.06, 0, 6,
  0.02, 0.08, 0.72, 0, 0,
  0, 0, 0, 1, 0,
]);

/// A route drawn on the map (OSRM, public HTTPS demo server, no API key).
class MapRoute {
  final List<LatLng> points;
  final double km;
  final double minutes;
  const MapRoute(this.points, this.km, this.minutes);

  static Future<MapRoute?> fetch(GeoPoint from, ShopHit to) async {
    if (!to.hasCoords) return null;
    final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/'
        '${from.lng},${from.lat};${to.lng},${to.lat}?overview=full&geometries=geojson');
    try {
      final r = await http.get(url).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      final routes = j['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final coords = routes.first['geometry']['coordinates'] as List;
      return MapRoute(
        coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList(),
        (routes.first['distance'] as num).toDouble() / 1000,
        (routes.first['duration'] as num).toDouble() / 60,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The one map of the app.
///
/// Zoom fix: the [MapController] is created ONCE in the state, the camera is fitted
/// ONCE when the first stores arrive, and selecting a store only pans (the zoom the
/// user chose with pinch / buttons is kept). Rebuilds from the parent never reset it.
class FindMeMap extends StatefulWidget {
  final List<ShopHit> stores;
  final GeoPoint? me;
  final int selected;
  final ValueChanged<int> onSelect;
  final MapRoute? route;
  const FindMeMap({super.key, required this.stores, required this.selected, required this.onSelect, this.me, this.route});

  @override
  State<FindMeMap> createState() => FindMeMapState();
}

class FindMeMapState extends State<FindMeMap> {
  final MapController _map = MapController();
  bool _ready = false;
  bool _fitted = false;

  List<ShopHit> get _placed => widget.stores.where((s) => s.hasCoords).toList();

  @override
  void didUpdateWidget(covariant FindMeMap old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    if (!_fitted && _placed.isNotEmpty) {
      _fit();
    } else if (old.selected != widget.selected && widget.selected < widget.stores.length) {
      _panTo(widget.stores[widget.selected]);
    } else if (old.route != widget.route && widget.route != null) {
      _fitPoints(widget.route!.points);
    } else if (!identical(old.me, widget.me) && widget.me != null) {
      _fit(); // the user chose another position: show it with the stores
    }
  }

  void _onReady() {
    _ready = true;
    if (_placed.isNotEmpty) _fit();
  }

  void _panTo(ShopHit s) {
    if (!s.hasCoords) return;
    _map.move(LatLng(s.lat!, s.lng!), _map.camera.zoom); // keep the user's zoom
  }

  void _fitPoints(List<LatLng> pts) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _map.move(pts.first, 14);
    } else {
      _map.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(56), maxZoom: 15));
    }
  }

  /// Fit the stores (and the user if known) once.
  void _fit() {
    final pts = _placed.map((s) => LatLng(s.lat!, s.lng!)).toList();
    if (widget.me != null) pts.add(LatLng(widget.me!.lat, widget.me!.lng));
    _fitPoints(pts);
    _fitted = pts.isNotEmpty;
  }

  /// Public: "show everything again" and "centre on me".
  void fitAll() => _fit();
  void centerOnMe() {
    if (widget.me != null) _map.move(LatLng(widget.me!.lat, widget.me!.lng), _map.camera.zoom < 13 ? 13 : _map.camera.zoom);
  }

  void _zoom(double delta) {
    final z = (_map.camera.zoom + delta).clamp(3.0, 18.0);
    _map.move(_map.camera.center, z);
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placed = _placed;
    // First frame only: centre of the stores, else the whole of Tunisia (no fake user position).
    final LatLng start = placed.isNotEmpty ? LatLng(placed.first.lat!, placed.first.lng!) : const LatLng(34.4, 9.6);
    return Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: start,
          initialZoom: placed.isNotEmpty ? 12 : 6,
          minZoom: 3,
          maxZoom: 18,
          onMapReady: _onReady,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.findme.app',
            maxZoom: 19,
            tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: _warmTiles, child: tile),
          ),
          if (widget.route != null)
            PolylineLayer(polylines: [
              Polyline(points: widget.route!.points, strokeWidth: 5, color: AppColors.brown.withOpacity(0.85)),
            ]),
          MarkerLayer(markers: [
            if (widget.me != null)
              Marker(
                point: LatLng(widget.me!.lat, widget.me!.lng),
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x553B82F6), blurRadius: 10, spreadRadius: 4)],
                  ),
                ),
              ),
            for (var i = 0; i < widget.stores.length; i++)
              if (widget.stores[i].hasCoords)
                Marker(
                  point: LatLng(widget.stores[i].lat!, widget.stores[i].lng!),
                  width: i == widget.selected ? 52 : 40,
                  height: i == widget.selected ? 52 : 40,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => widget.onSelect(i),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: i == widget.selected ? 52 : 40,
                      color: i == widget.selected ? AppColors.ink : AppColors.camel,
                      shadows: const [Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
                    ),
                  ),
                ),
          ]),
          RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
        ],
      ),
      Positioned(
        right: 12,
        top: 12,
        child: Column(children: [
          _MapButton(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: () => _zoom(1)),
          const SizedBox(height: 8),
          _MapButton(icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: () => _zoom(-1)),
          const SizedBox(height: 8),
          _MapButton(icon: Icons.zoom_out_map_rounded, tooltip: 'Show all stores', onTap: fitAll),
          if (widget.me != null) ...[
            const SizedBox(height: 8),
            _MapButton(icon: Icons.my_location_rounded, tooltip: 'My position', onTap: centerOnMe),
          ],
        ]),
      ),
    ]);
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, color: AppColors.brown, size: 22)),
        ),
      ),
    );
  }
}
