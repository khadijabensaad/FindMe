import 'package:find_me/data/api_client.dart';
import 'package:find_me/data/models.dart';

/// All calls to the FINDME AI backend (recommendations, stylist, Style DNA, outfits, alerts…).
class FindMeApi {
  FindMeApi._();
  static final FindMeApi instance = FindMeApi._();
  final ApiClient _c = ApiClient.instance;

  // ---------------- Recommendations ----------------
  Future<HomeFeed> home() async => HomeFeed.fromJson(Map<String, dynamic>.from(await _c.get('/recommendations/home')));

  Future<List<RecoProduct>> similar(String productId) async {
    final r = await _c.get('/recommendations/similar/$productId');
    return RecoProduct.listFrom(r['products']);
  }

  Future<OutfitSuggestion?> completeLook(String productId) async {
    final r = await _c.get('/recommendations/complete-look/$productId');
    return r is Map ? OutfitSuggestion.fromJson(Map<String, dynamic>.from(r)) : null;
  }

  Future<List<RecoProduct>> trending({int days = 14, int limit = 20}) async {
    final r = await _c.get('/recommendations/trending', query: {'days': days, 'limit': limit});
    return RecoProduct.listFrom(r['products']);
  }

  Future<List<RecoProduct>> budget(double max, {List<String> types = const []}) async {
    final r = await _c.get('/recommendations/budget', query: {'max': max.round(), 'types': types, 'limit': 20});
    return RecoProduct.listFrom(r['products']);
  }

  /// Returns (products, hasMore, total)
  Future<(List<RecoProduct>, bool, int)> discover({
    String query = '',
    List<String> types = const [],
    List<String> colors = const [],
    List<String> styles = const [],
    List<String> sizes = const [],
    String? gender,
    double? minPrice,
    double? maxPrice,
    String sort = 'match',
    int page = 1,
  }) async {
    final r = await _c.get('/recommendations/discover', query: {
      'query': query,
      'types': types,
      'colors': colors,
      'styles': styles,
      'sizes': sizes,
      'gender': gender,
      'minPrice': minPrice?.round(),
      'maxPrice': maxPrice?.round(),
      'sort': sort,
      'page': page,
    });
    return (RecoProduct.listFrom(r['products']), r['hasMore'] == true, (r['total'] as num?)?.toInt() ?? 0);
  }

  Future<ScoreExplanation> explain(String productId) async =>
      ScoreExplanation.fromJson(Map<String, dynamic>.from(await _c.get('/recommendations/explain/$productId')));

  Future<List<ShopHit>> nearbyShops(String productId, {double? lat, double? lng, double? radiusKm}) async {
    final r = await _c.get('/recommendations/nearby-shops/$productId', query: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm});
    return ShopHit.listFrom(r['shops']);
  }

  /// Every shop with valid coordinates, nearest first when a position is given.
  Future<List<ShopHit>> stores({double? lat, double? lng}) async {
    final r = await _c.get('/recommendations/stores', query: {'lat': lat, 'lng': lng});
    return ShopHit.listFrom(r['stores']);
  }

  /// Cities for the manual location picker.
  Future<List<GeoPoint>> places() async {
    final r = await _c.get('/recommendations/places');
    final list = r['places'];
    return list is List
        ? list.whereType<Map>().map((e) => GeoPoint((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble(), label: e['name']?.toString(), source: 'manual')).toList()
        : <GeoPoint>[];
  }

  Future<NearbyResult> nearbyProducts({GeoPoint? origin, String? query, List<String> productIds = const [], double radiusKm = 25}) async {
    final r = await _c.get('/recommendations/nearby-products', query: {
      'lat': origin?.lat,
      'lng': origin?.lng,
      'label': origin?.label,
      'query': query,
      'productIds': productIds,
      'radiusKm': radiusKm.round(),
    });
    return NearbyResult.fromJson(Map<String, dynamic>.from(r));
  }

  // ---------------- Account ----------------
  Future<AppUser> me() async {
    final r = await _c.get('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(r['user']));
  }

  Future<AppUser> updateProfile({String? username, List<int>? photoBytes, String? photoName}) async {
    final fields = <String, String>{if (username != null && username.trim().isNotEmpty) 'username': username.trim()};
    final r = photoBytes != null
        ? await _c.uploadBytes('/auth/updateProfile', bytes: photoBytes, filename: photoName ?? 'profile.jpg', field: 'file', method: 'PUT', fields: fields)
        : await _c.multipartFields('/auth/updateProfile', fields);
    return AppUser.fromJson(Map<String, dynamic>.from(r['user']));
  }

  Future<void> changePassword(String current, String next) => _c.put('/auth/changePassword', {'currentPassword': current, 'newPassword': next});

  Future<void> feedback(String productId, String value, {String? reason, String context = 'other'}) =>
      _c.post('/recommendations/feedback', {'productId': productId, 'value': value, 'reason': reason, 'context': context});

  Future<void> track(String type, {String? productId, Map<String, dynamic>? meta}) async {
    try {
      await _c.post('/interactions', {'type': type, 'productId': productId, 'meta': meta});
    } catch (_) {
      // tracking must never break the UI
    }
  }

  // ---------------- Products & favorites (existing endpoints) ----------------
  Future<RecoProduct> productById(String id) async => RecoProduct.fromJson(Map<String, dynamic>.from(await _c.get('/products/getProduct/$id')));

  Future<RecoProduct> productByBarcode(String code) async =>
      RecoProduct.fromJson(Map<String, dynamic>.from(await _c.get('/products/getProductByBarCode', query: {'barcode': code})));

  /// Toggles a favorite; returns the new state.
  Future<bool> toggleFavorite(String productId) async {
    final r = await _c.put('/auth/addToFavorites', {'prodId': productId});
    return !(r['message']?.toString().contains('deleted') ?? false);
  }

  Future<List<RecoProduct>> favorites() async {
    final r = await _c.get('/auth/getFavorites');
    final raw = r is Map ? (r['favorites'] ?? r['products'] ?? r['data']) : r;
    final list = RecoProduct.listFrom(raw);
    for (final p in list) {
      p.isFavorite = true;
    }
    return list;
  }

  // ---------------- AI Stylist ----------------
  Future<StylistReply> chat(String message, {String? sessionId, GeoPoint? location, String? actionType, String? productId}) async {
    final r = await _c.post('/chatbot', {
      if (message.isNotEmpty) 'message': message,
      'sessionId': sessionId,
      if (location != null) 'location': location.toJson(),
      if (actionType != null && productId != null) 'action': {'type': actionType, 'productId': productId},
    });
    return StylistReply.fromJson(Map<String, dynamic>.from(r));
  }

  Future<StylistReply> removeCriterion(String sessionId, String field, dynamic value) async {
    final r = await _c.patch('/chatbot/sessions/$sessionId/criteria', {'field': field, 'value': value});
    return StylistReply.fromJson(Map<String, dynamic>.from(r));
  }

  Future<void> resetChat(String sessionId) => _c.delete('/chatbot/sessions/$sessionId');

  // ---------------- Style DNA & quiz ----------------
  Future<StyleDna> styleDna() async => StyleDna.fromJson(Map<String, dynamic>.from(await _c.get('/preferences/style-dna')));

  Future<StyleDna> saveQuiz(Map<String, dynamic> answers) async {
    final r = await _c.put('/preferences', answers);
    return StyleDna.fromJson(Map<String, dynamic>.from(r['styleDna']));
  }

  // ---------------- Outfits ----------------
  Future<List<SavedOutfit>> outfits() async {
    final r = await _c.get('/outfits');
    return r is List ? r.whereType<Map>().map((e) => SavedOutfit.fromJson(Map<String, dynamic>.from(e))).toList() : <SavedOutfit>[];
  }

  Future<SavedOutfit> saveOutfit({required String name, String? occasion, DateTime? plannedFor, String source = 'manual', required List<OutfitItem> items}) async {
    final r = await _c.post('/outfits', {
      'name': name,
      'occasion': occasion,
      'plannedFor': plannedFor?.toIso8601String(),
      'source': source,
      'items': items.map((i) => {'slot': i.slot, 'productId': i.product.id}).toList(),
    });
    return SavedOutfit.fromJson(Map<String, dynamic>.from(r));
  }

  Future<void> deleteOutfit(String id) => _c.delete('/outfits/$id');

  // ---------------- Price alerts ----------------
  Future<(List<PriceAlertItem>, int)> alerts() async {
    final r = await _c.get('/alerts');
    final list = r['alerts'];
    final items = list is List ? list.whereType<Map>().map((e) => PriceAlertItem.fromJson(Map<String, dynamic>.from(e))).toList() : <PriceAlertItem>[];
    return (items, (r['unseenCount'] as num?)?.toInt() ?? 0);
  }

  Future<PriceAlertItem> createAlert(String productId, {double? targetPrice}) async =>
      PriceAlertItem.fromJson(Map<String, dynamic>.from(await _c.post('/alerts', {'productId': productId, 'targetPrice': targetPrice})));

  Future<void> deleteAlert(String id) => _c.delete('/alerts/$id');
  Future<void> markAlertsSeen() => _c.put('/alerts/seen', {});

  // ---------------- Visual search ----------------
  Future<VisualSearchResult> visualSearch(List<int> bytes, String filename) async =>
      VisualSearchResult.fromJson(Map<String, dynamic>.from(await _c.uploadBytes('/search/visual', bytes: bytes, filename: filename)));
}
