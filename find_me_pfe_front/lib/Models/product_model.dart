
import 'dart:convert';

ProductModel productModelFromJson(String str) => ProductModel.fromJson(json.decode(str));

String productModelToJson(ProductModel data) => json.encode(data.toJson());

class ProductModel {
    String id;
    String name;
    int price;
    double rating;
    int barcode;
    String thumbnail;
    List<String> images;
    List<String> colors;
    String description;
    List<String> size;
    String brand;
    List<String> shops;
    List<String> category;
    DateTime createdAt;
    DateTime updatedAt;
    int v;
    bool isFavorite;
    double discountPrice;

    ProductModel({
        required this.id,
        required this.name,
        required this.price,
        required this.rating,
        required this.barcode,
        required this.thumbnail,
        required this.images,
        required this.colors,
        required this.description,
        required this.size,
        required this.brand,
        required this.shops,
        required this.category,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
        required this.isFavorite,
        required this.discountPrice
    });

    factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json["_id"],
        name: json["name"],
        price: json["price"],
        rating: json["rating"]?.toDouble(),
        barcode: json["barcode"],
        thumbnail: json["thumbnail"],
        images: List<String>.from(json["images"].map((x) => x)),
        colors: List<String>.from(json["colors"].map((x) => x)),
        description: json["description"],
        size: List<String>.from(json["size"].map((x) => x)),
        brand: json["brand"],
        shops: List<String>.from(json["shops"].map((x) => x)),
        category: List<String>.from(json["category"].map((x) => x)),
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
        isFavorite: json["isFavorite"],
        discountPrice: json["discountPrice"]?.toDouble()
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "price": price,
        "rating": rating,
        "barcode": barcode,
        "thumbnail": thumbnail,
        "images": List<dynamic>.from(images.map((x) => x)),
        "colors": List<dynamic>.from(colors.map((x) => x)),
        "description": description,
        "size": List<dynamic>.from(size.map((x) => x)),
        "brand": brand,
        "shops": List<dynamic>.from(shops.map((x) => x)),
        "category": List<dynamic>.from(category.map((x) => x)),
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
    };
}