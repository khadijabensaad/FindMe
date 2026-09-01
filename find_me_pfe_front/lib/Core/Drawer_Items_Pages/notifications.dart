import 'dart:convert';

import 'package:find_me/Models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  //_isEmpty variable bech nchofou biha famma notifications walle
  bool _isEmpty = false;

  Future<List<NotificationModel>> getAllNotiifications() async {
    List<NotificationModel> notifications = [];
    const String url = "http://192.168.43.28:5000/notifications/";
    final http.Response resp = await http.get(Uri.parse(url));
    var jsonResponse = jsonDecode(resp.body);

    if (resp.statusCode == 200) {
      if (jsonResponse["data"] is List) {
        notifications = (jsonResponse["data"] as List)
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      }
    } else if (resp.statusCode == 201) {
      setState(() {
        _isEmpty = true;
      });
    } else {
      print("Error: ${resp.statusCode}, ${jsonResponse["message"]}");
    }
    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
          title: Text("Notifications",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: Color(0xFFFDF1E1)),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: FutureBuilder<List<NotificationModel>>(
          future: getAllNotiifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                color: Color(0xFF965D1A),
              ));
            } else if (snapshot.hasError) {
              return const Center(child: Text('Failed to load notifications'));
            } else if (!snapshot.hasData || _isEmpty == true) {
              return const Center(child: Text('No notifications available'));
            } else {
              return ListView.separated(
                  itemBuilder: (context, index) => Container(
                        color: const Color(0xFFFDF1E1),
                        child: Column(
                          children: [
                            ListTile(
                              leading: ClipOval(
                                child: Image.network(
                                  "${snapshot.data?[index].productPic}",
                                ),
                              ),
                              title: Text(
                                "New Discount!",
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${snapshot.data?[index].content}",
                                style: TextStyle(
                                    fontFamily: 'Poppins', color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                  separatorBuilder: (context, index) => SizedBox(
                        height: 15,
                      ),
                  itemCount: snapshot.data!.length);
            }
          },
        ),
      )),
    );
  }
}
