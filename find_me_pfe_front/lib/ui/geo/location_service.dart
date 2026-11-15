import 'dart:convert';

import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why we could not get a GPS position (shown to the user, honestly).
enum GpsIssue { none, serviceOff, denied, deniedForever, error }

/// One place for every location need of the app:
/// GPS with a proper permission flow, then the city the user picked manually.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const _prefKey = 'manualLocation';
  GeoPoint? _lastGps;
  GpsIssue lastIssue = GpsIssue.none;

  /// GPS position. [ask] = request the permission if it was never asked.
  Future<GeoPoint?> gps({bool ask = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        lastIssue = GpsIssue.serviceOff;
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && ask) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        lastIssue = GpsIssue.deniedForever;
        return null;
      }
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
        lastIssue = GpsIssue.denied;
        return null;
      }
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 12));
      lastIssue = GpsIssue.none;
      return _lastGps = GeoPoint(pos.latitude, pos.longitude, label: null, source: 'gps');
    } catch (_) {
      lastIssue = GpsIssue.error;
      return _lastGps; // keep the last good fix if the new one times out
    }
  }

  Future<GeoPoint?> manual() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return null;
    try {
      return GeoPoint.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveManual(GeoPoint? p) async {
    final prefs = await SharedPreferences.getInstance();
    if (p == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, jsonEncode(p.toJson()));
    }
  }

  /// The manual city if the user chose one, else GPS.
  Future<GeoPoint?> current({bool ask = true}) async {
    final m = await manual();
    if (m != null) return m;
    return gps(ask: ask);
  }

  String issueText() {
    switch (lastIssue) {
      case GpsIssue.serviceOff:
        return 'Location services are off.';
      case GpsIssue.denied:
        return 'Location permission was not granted.';
      case GpsIssue.deniedForever:
        return 'Location is blocked for FINDME in the settings.';
      case GpsIssue.error:
        return 'Your position could not be found.';
      case GpsIssue.none:
        return '';
    }
  }
}

/// Bottom sheet: "use my GPS" or pick a city. Returns the chosen point (or null).
Future<GeoPoint?> pickLocation(BuildContext context) {
  return showModalBottomSheet<GeoPoint>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LocationSheet(),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final Future<List<GeoPoint>> _places = FindMeApi.instance.places();
  String _q = '';
  bool _locating = false;
  String? _gpsError;

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _gpsError = null;
    });
    final p = await LocationService.instance.gps(ask: true);
    if (!mounted) return;
    if (p == null) {
      setState(() {
        _locating = false;
        _gpsError = '${LocationService.instance.issueText()} Pick a city below instead.';
      });
      return;
    }
    await LocationService.instance.saveManual(null); // GPS again from now on
    if (mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: context.line, borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: context.isDark ? AppColors.camel : AppColors.brown),
            const SizedBox(width: 8),
            Text('Choose your location', style: AppTheme.display(22, color: context.fg)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: context.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: context.line)),
              leading: _locating
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.camel))
                  : const Icon(Icons.my_location_rounded, color: AppColors.camel),
              title: Text('Use my current location', style: context.text.titleSmall),
              subtitle: _gpsError == null ? null : Text(_gpsError!, style: context.text.bodySmall?.copyWith(color: const Color(0xFFA8321F))),
              onTap: _locating ? null : _useGps,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: TextField(
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            decoration: const InputDecoration(hintText: 'Search a city', prefixIcon: Icon(Icons.search_rounded)),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<GeoPoint>>(
            future: _places,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.camel));
              if (snap.hasError) return Center(child: Text('Cities could not be loaded: ${snap.error}'));
              final list = snap.data!.where((p) => _q.isEmpty || (p.label ?? '').toLowerCase().contains(_q)).toList();
              return ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(Icons.location_city_rounded, color: context.fgMuted),
                  title: Text(list[i].label ?? '', style: context.text.bodyLarge),
                  onTap: () async {
                    await LocationService.instance.saveManual(list[i]);
                    if (context.mounted) Navigator.pop(context, list[i]);
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
