// FINDME AI layer — tolerant JSON models (missing / null fields never crash the UI).

double _d(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

int _i(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

List<String> _sl(dynamic v) => v is List ? v.where((e) => e != null).map((e) => e.toString()).toList() : <String>[];

Map<String, dynamic> _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    v is List ? v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList() : <T>[];

class Reason {
  final String code;
  final String label;
  const Reason(this.code, this.label);
  factory Reason.fromJson(Map<String, dynamic> j) => Reason(j['code']?.toString() ?? '', j['label']?.toString() ?? '');
}

class RecoProduct {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final double effectivePrice;
  final double rating;
  final String thumbnail;
  final List<String> images;
  final List<String> colors;
  final List<String> sizes;
  final String brand;
  final List<String> shops;
  final List<String> category;
  final String description;
  final String type;
  bool isFavorite;
  final int? matchPercent;
  final Map<String, double> breakdown;
  final List<Reason> reasons;
  final List<String> badges;
  final bool alternative;
  final DateTime? createdAt;

  RecoProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPrice,
    required this.effectivePrice,
    required this.rating,
    required this.thumbnail,
    required this.images,
    required this.colors,
    required this.sizes,
    required this.brand,
    required this.shops,
    required this.category,
    required this.description,
    required this.type,
    required this.isFavorite,
    required this.matchPercent,
    required this.breakdown,
    required this.reasons,
    required this.badges,
    required this.alternative,
    required this.createdAt,
  });

  bool get hasDiscount => discountPrice > 0 && discountPrice < price;
  int get discountPercent => hasDiscount ? ((1 - discountPrice / price) * 100).round() : 0;
  List<String> get gallery {
    final all = <String>[if (thumbnail.isNotEmpty) thumbnail, ...images.where((e) => e.isNotEmpty && e != thumbnail)];
    return all;
  }

  factory RecoProduct.fromJson(Map<String, dynamic> j) {
    final price = _d(j['price']);
    final discount = _d(j['discountPrice'], -1);
    final eff = j['effectivePrice'] != null ? _d(j['effectivePrice']) : (discount > 0 && discount < price ? discount : price);
    final bd = <String, double>{};
    _m(j['breakdown']).forEach((k, v) => bd[k] = _d(v));
    return RecoProduct(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: j['name']?.toString() ?? '',
      price: price,
      discountPrice: discount,
      effectivePrice: eff,
      rating: _d(j['rating']),
      thumbnail: j['thumbnail']?.toString() ?? '',
      images: _sl(j['images']),
      colors: _sl(j['colors']),
      sizes: _sl(j['size']),
      brand: j['brand']?.toString() ?? '',
      shops: _sl(j['shops']),
      category: _sl(j['category']),
      description: j['description']?.toString() ?? '',
      type: j['type']?.toString() ?? 'other',
      isFavorite: j['isFavorite'] == true,
      matchPercent: j['matchPercent'] == null ? null : _i(j['matchPercent']),
      breakdown: bd,
      reasons: _list(j['reasons'], Reason.fromJson),
      badges: _sl(j['badges']),
      alternative: j['alternative'] == true,
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
    );
  }

  static List<RecoProduct> listFrom(dynamic v) => _list(v, RecoProduct.fromJson);
}

/// A shop on the map (also used for "where to buy" results).
class ShopHit {
  final String id;
  final String name;
  final String city;
  final String region;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final bool verified;
  final int productCount;
  final List<String> productIds;
  ShopHit(this.id, this.name, this.city, this.region, this.lat, this.lng, this.distanceKm,
      {this.verified = false, this.productCount = 0, this.productIds = const []});
  bool get hasCoords => lat != null && lng != null;
  factory ShopHit.fromJson(Map<String, dynamic> j) {
    final c = _m(j['coordinates']);
    return ShopHit(
      (j['_id'] ?? '').toString(),
      j['name']?.toString() ?? '',
      j['city']?.toString() ?? '',
      j['region']?.toString() ?? '',
      c['latitude'] == null ? null : _d(c['latitude']),
      c['longitude'] == null ? null : _d(c['longitude']),
      (j['distanceKm'] ?? j['distance']) == null ? null : _d(j['distanceKm'] ?? j['distance']),
      verified: j['verified'] == true,
      productCount: _i(j['productCount'], _sl(j['productIds']).length),
      productIds: _sl(j['productIds']),
    );
  }
  static List<ShopHit> listFrom(dynamic v) => _list(v, ShopHit.fromJson);
}

/// A position used for distances: GPS, a city picked manually, or a city named in the chat.
class GeoPoint {
  final double lat;
  final double lng;
  final String? label;
  final String source; // gps | manual | place
  const GeoPoint(this.lat, this.lng, {this.label, this.source = 'gps'});
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'label': label, 'source': source};
  factory GeoPoint.fromJson(Map<String, dynamic> j) =>
      GeoPoint(_d(j['lat']), _d(j['lng']), label: j['label']?.toString(), source: j['source']?.toString() ?? 'gps');
}

class NearbyItem {
  final RecoProduct product;
  final List<ShopHit> stores;
  NearbyItem(this.product, this.stores);
  factory NearbyItem.fromJson(Map<String, dynamic> j) => NearbyItem(RecoProduct.fromJson(_m(j['product'])), ShopHit.listFrom(j['stores']));
}

/// Result of a geolocated product search (chatbot or /recommendations/nearby-products).
class NearbyResult {
  final GeoPoint? origin;
  final bool needsLocation;
  final double radiusKm;
  final List<NearbyItem> results;
  final List<ShopHit> stores;
  final String? outsideShop;
  final double? outsideKm;
  NearbyResult(this.origin, this.needsLocation, this.radiusKm, this.results, this.stores, this.outsideShop, this.outsideKm);
  factory NearbyResult.fromJson(Map<String, dynamic> j) {
    final o = j['origin'] is Map ? GeoPoint.fromJson(_m(j['origin'])) : null;
    final out = _m(j['nearestOutside']);
    return NearbyResult(o, j['needsLocation'] == true, _d(j['radiusKm'], 25), _list(j['results'], NearbyItem.fromJson), ShopHit.listFrom(j['stores']),
        out['shop']?.toString(), out['distanceKm'] == null ? null : _d(out['distanceKm']));
  }
}

class AppUser {
  final String id;
  final String username;
  final String email;
  final String image;
  final String role;
  AppUser(this.id, this.username, this.email, this.image, this.role);
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        (j['_id'] ?? '').toString(),
        j['username']?.toString() ?? '',
        j['email']?.toString() ?? '',
        j['image']?.toString() ?? '',
        j['role']?.toString() ?? 'Client',
      );
}

class OutfitItem {
  final String slot;
  final RecoProduct product;
  final List<RecoProduct> alternatives;
  OutfitItem(this.slot, this.product, this.alternatives);
  factory OutfitItem.fromJson(Map<String, dynamic> j) =>
      OutfitItem(j['slot']?.toString() ?? '', RecoProduct.fromJson(_m(j['product'])), RecoProduct.listFrom(j['alternatives']));
}

class OutfitSuggestion {
  final RecoProduct anchor;
  final List<OutfitItem> items;
  final double totalPrice;
  OutfitSuggestion(this.anchor, this.items, this.totalPrice);
  factory OutfitSuggestion.fromJson(Map<String, dynamic> j) =>
      OutfitSuggestion(RecoProduct.fromJson(_m(j['anchor'])), _list(j['items'], OutfitItem.fromJson), _d(j['totalPrice']));
}

/// One piece of a look imagined by the stylist; [product] is the matching catalogue item, if any.
class LookPiece {
  final String? type;
  final String? color;
  final String description;
  final RecoProduct? product;
  final bool exact;
  LookPiece(this.type, this.color, this.description, this.product, this.exact);
  factory LookPiece.fromJson(Map<String, dynamic> j) => LookPiece(
        j['type']?.toString(),
        j['color']?.toString(),
        j['description']?.toString() ?? '',
        j['product'] is Map ? RecoProduct.fromJson(_m(j['product'])) : null,
        j['exact'] == true,
      );
}

class StyleLook {
  final String title;
  final String occasion;
  final String tip;
  final List<LookPiece> pieces;
  StyleLook(this.title, this.occasion, this.tip, this.pieces);
  factory StyleLook.fromJson(Map<String, dynamic> j) =>
      StyleLook(j['title']?.toString() ?? 'Look', j['occasion']?.toString() ?? '', j['tip']?.toString() ?? '', _list(j['pieces'], LookPiece.fromJson));
}

class CriteriaChip {
  final String field;
  final dynamic value;
  final String label;
  CriteriaChip(this.field, this.value, this.label);
  factory CriteriaChip.fromJson(Map<String, dynamic> j) => CriteriaChip(j['field']?.toString() ?? '', j['value'], j['label']?.toString() ?? '');
}

class StylistReply {
  final String sessionId;
  final String reply;
  final String intent;
  final String language;
  final List<RecoProduct> products;
  final List<String> quickReplies;
  final List<CriteriaChip> chips;
  final OutfitSuggestion? outfit;
  final List<StyleLook> looks;
  final NearbyResult? nearby;
  final List<ShopHit> shops;
  final String? shopsFor;
  final bool llm;

  StylistReply({
    required this.sessionId,
    required this.reply,
    required this.intent,
    required this.language,
    required this.products,
    required this.quickReplies,
    required this.chips,
    required this.outfit,
    this.looks = const [],
    this.nearby,
    required this.shops,
    required this.shopsFor,
    required this.llm,
  });

  factory StylistReply.fromJson(Map<String, dynamic> j) {
    final shops = _m(j['shops']);
    return StylistReply(
      sessionId: j['sessionId']?.toString() ?? '',
      reply: (j['reply'] ?? j['chatbot'] ?? '').toString(),
      intent: j['intent']?.toString() ?? 'search',
      language: j['language']?.toString() ?? 'en',
      products: RecoProduct.listFrom(j['products']),
      quickReplies: _sl(j['quickReplies']),
      chips: _list(j['criteriaChips'], CriteriaChip.fromJson),
      outfit: j['outfit'] is Map ? OutfitSuggestion.fromJson(_m(j['outfit'])) : null,
      looks: _list(j['looks'], StyleLook.fromJson),
      nearby: j['nearby'] is Map ? NearbyResult.fromJson(_m(j['nearby'])) : null,
      shops: _list(shops['shops'], ShopHit.fromJson),
      shopsFor: shops['productName']?.toString(),
      llm: _m(j['engine'])['llm'] == true,
    );
  }
}

class StyleDna {
  final String persona;
  final Map<String, int> styles;
  final List<String> topStyles;
  final List<String> topColors;
  final List<String> topBrands;
  final List<String> topTypes;
  final double? budgetMin;
  final double? budgetMax;
  final double confidence;
  final int signals;
  final bool hasQuiz;
  final Map<String, dynamic> preferences;

  StyleDna({
    required this.persona,
    required this.styles,
    required this.topStyles,
    required this.topColors,
    required this.topBrands,
    required this.topTypes,
    required this.budgetMin,
    required this.budgetMax,
    required this.confidence,
    required this.signals,
    required this.hasQuiz,
    required this.preferences,
  });

  factory StyleDna.fromJson(Map<String, dynamic> j) {
    final styles = <String, int>{};
    _m(j['styles']).forEach((k, v) => styles[k] = _i(v));
    final b = _m(j['budget']);
    return StyleDna(
      persona: j['persona']?.toString() ?? 'Style Explorer',
      styles: styles,
      topStyles: _sl(j['topStyles']),
      topColors: _sl(j['topColors']),
      topBrands: _sl(j['topBrands']),
      topTypes: _sl(j['topTypes']),
      budgetMin: b['min'] == null ? null : _d(b['min']),
      budgetMax: b['max'] == null ? null : _d(b['max']),
      confidence: _d(j['confidence']),
      signals: _i(j['signals']),
      hasQuiz: j['hasQuiz'] == true,
      preferences: _m(j['preferences']),
    );
  }
}

class HomeFeed {
  final String? persona;
  final List<String> topStyles;
  final bool coldStart;
  final List<RecoProduct> forYou;
  final List<RecoProduct> trending;
  final double budgetMax;
  final List<RecoProduct> budget;
  final List<RecoProduct> deals;
  final List<RecoProduct> newIn;

  HomeFeed({
    required this.persona,
    required this.topStyles,
    required this.coldStart,
    required this.forYou,
    required this.trending,
    required this.budgetMax,
    required this.budget,
    required this.deals,
    required this.newIn,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> j) {
    final dna = _m(j['styleDna']);
    final fy = _m(j['forYou']);
    final b = _m(j['budget']);
    return HomeFeed(
      persona: dna['persona']?.toString(),
      topStyles: _sl(dna['topStyles']),
      coldStart: fy['coldStart'] == true,
      forYou: RecoProduct.listFrom(fy['products']),
      trending: RecoProduct.listFrom(j['trending']),
      budgetMax: _d(b['max'], 100),
      budget: RecoProduct.listFrom(b['products']),
      deals: RecoProduct.listFrom(j['deals']),
      newIn: RecoProduct.listFrom(j['newIn']),
    );
  }
}

class SavedOutfit {
  final String id;
  final String name;
  final String? occasion;
  final DateTime? plannedFor;
  final List<OutfitItem> items;
  final double totalPrice;
  SavedOutfit(this.id, this.name, this.occasion, this.plannedFor, this.items, this.totalPrice);
  factory SavedOutfit.fromJson(Map<String, dynamic> j) => SavedOutfit(
        (j['_id'] ?? '').toString(),
        j['name']?.toString() ?? '',
        j['occasion']?.toString(),
        DateTime.tryParse(j['plannedFor']?.toString() ?? ''),
        _list(j['items'], (m) => OutfitItem(m['slot']?.toString() ?? '', RecoProduct.fromJson(_m(m['product'])), const [])),
        _d(j['totalPrice']),
      );
}

class PriceAlertItem {
  final String id;
  final double targetPrice;
  final double currentPrice;
  final double priceAtCreation;
  final bool reached;
  final bool unseen;
  final int dropPercent;
  final RecoProduct product;
  PriceAlertItem(this.id, this.targetPrice, this.currentPrice, this.priceAtCreation, this.reached, this.unseen, this.dropPercent, this.product);
  factory PriceAlertItem.fromJson(Map<String, dynamic> j) => PriceAlertItem(
        (j['_id'] ?? '').toString(),
        _d(j['targetPrice']),
        _d(j['currentPrice']),
        _d(j['priceAtCreation']),
        j['reached'] == true,
        j['unseen'] == true,
        _i(j['dropPercent']),
        RecoProduct.fromJson(_m(j['product'])),
      );
}

class VisualSearchResult {
  final bool isFashion;
  final String? type;
  final List<String> colors;
  final List<String> styles;
  final String? description;
  final List<RecoProduct> products;
  VisualSearchResult(this.isFashion, this.type, this.colors, this.styles, this.description, this.products);
  factory VisualSearchResult.fromJson(Map<String, dynamic> j) {
    final d = _m(j['detected']);
    return VisualSearchResult(
      d['isFashion'] != false,
      d['type']?.toString(),
      _sl(d['colors']),
      _sl(d['styles']),
      d['description']?.toString(),
      RecoProduct.listFrom(j['products']),
    );
  }
}

class ScoreExplanation {
  final int matchPercent;
  final Map<String, double> breakdown;
  final Map<String, double> weights;
  final List<Reason> reasons;
  final String? persona;
  ScoreExplanation(this.matchPercent, this.breakdown, this.weights, this.reasons, this.persona);
  factory ScoreExplanation.fromJson(Map<String, dynamic> j) {
    final bd = <String, double>{};
    _m(j['breakdown']).forEach((k, v) => bd[k] = _d(v));
    final w = <String, double>{};
    _m(j['weights']).forEach((k, v) => w[k] = _d(v));
    return ScoreExplanation(_i(j['matchPercent']), bd, w, _list(j['reasons'], Reason.fromJson), j['persona']?.toString());
  }
}
