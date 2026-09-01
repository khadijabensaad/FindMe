import 'dart:convert';

NotificationModel notificationModelFromJson(String str) => NotificationModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationModel data) => json.encode(data.toJson());

class NotificationModel {
    String id;
    String content;
    String productId;
    String productPic;
    DateTime createdAt;
    DateTime updatedAt;
    int v;

    NotificationModel({
        required this.id,
        required this.content,
        required this.productId,
        required this.productPic,
        required this.createdAt,
        required this.updatedAt,
        required this.v,
    });

    factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json["_id"],
        content: json["content"],
        productId: json["productId"],
        productPic: json["productPic"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "content": content,
        "productId": productId,
        "productPic": productPic,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
    };
}