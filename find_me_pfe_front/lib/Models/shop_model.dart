import 'dart:convert';

ShopModel shopModelFromJson(String str) => ShopModel.fromJson(json.decode(str));

String shopModelToJson(ShopModel data) => json.encode(data.toJson());

class ShopModel {
    Coordinates coordinates;
    String id;
    String name;
    String city;
    String region;
    List<String> products;
    DateTime createdAt;
    DateTime updatedAt;
    int v;

    ShopModel({
        required this.coordinates,
        required this.id,
        required this.name,
        required this.city,
        required this.region,
        required this.products,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        coordinates: Coordinates.fromJson(json["coordinates"]),
        id: json["_id"],
        name: json["name"],
        city: json["city"],
        region: json["region"],
        products: List<String>.from(json["products"].map((x) => x)),
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "coordinates": coordinates.toJson(),
        "_id": id,
        "name": name,
        "city": city,
        "region": region,
        "products": List<dynamic>.from(products.map((x) => x)),
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
    };
}

class Coordinates {
    double longitude;
    double latitude;

    Coordinates({
        required this.longitude,
        required this.latitude,
    });

    factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
        longitude: json["longitude"]?.toDouble(),
        latitude: json["latitude"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "longitude": longitude,
        "latitude": latitude,
    };
}