import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:find_me/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late ChatUser user;
  late ChatUser bot;
  late List<ChatMessage> messages;

  @override
  void initState() {
    super.initState();
    user = ChatUser(
      id: '1',
      firstName: 'Khadija',
      lastName: 'bensaad',
      customProperties: {'avatar': 'https://example.com/charles_avatar.png'},
    );

    bot = ChatUser(
      id: '2',
      firstName: 'Chatbot',
      lastName: 'Assistant',
      customProperties: {'avatar': 'assets/images/Group.png'},
    );

    messages = <ChatMessage>[];
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      messages.insert(0, message);
    });
  }

  void _sendMessage(String text, ChatUser user) {
    final message = ChatMessage(
      text: text,
      user: user,
      createdAt: DateTime.now(),
    );
    _addMessage(message);
  }

  Future<void> _handleSend(ChatMessage message) async {
    _addMessage(message);
    //lenna appel back
    var reqBody = jsonEncode({"message": message.text});
    String url = 'http://192.168.43.28:5000/chatbot/';
    var response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: reqBody);
    var jsonResponse = jsonDecode(response.body);
    String bot_message = jsonResponse["chatbot"];
    print(jsonResponse["chatbot"]);
    // Simulate a bot response after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _sendMessage("${bot_message}", bot);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        title: const ListTile(
          title: Text(
            "Chatbot",
            style: TextStyle(
              color: Color(0xFF8F5622),
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green,
                radius: 3,
              ),
              SizedBox(
                width: 6,
              ),
              Text(
                "Online",
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFFFDF1E1),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF8F5622),
          ),
          onPressed: () {
            Navigator.pop(
              context,
              CupertinoPageRoute(
                builder: ((context) => const MainScreenPage()),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/chatbot_image.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), // Adjust opacity here
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Divider(
                color: Color.fromARGB(255, 220, 197, 167),
                thickness: 0.5,
              ),
              /*  ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                child: Image.asset(
                  "assets/images/Capture.PNG",
                  height: 150,
                ),
              ),*/
              const SizedBox(
                height: 15,
              ),
              Container(
                height: MediaQuery.of(context).size.height -
                    120, // Adjust as needed
                child: DashChat(
                  currentUser: user,
                  onSend: _handleSend,
                  messages: messages,
                  messageOptions: MessageOptions(
                    //showCurrentUserAvatar: true,
                    currentUserContainerColor: Color(0xFF965D1A),
                    containerColor: Color.fromARGB(255, 245, 210, 165),
                    textColor: Colors.black,
                    currentUserTextColor: Colors.white,
                    avatarBuilder: (ChatUser user, Function? onPress,
                        Function? onLongPress) {
                      final avatarUrl =
                          user.customProperties?['avatar'] as String?;
                      if (avatarUrl != null) {
                        return GestureDetector(
                          onTap: onPress != null ? () => onPress() : null,
                          onLongPress:
                              onLongPress != null ? () => onLongPress() : null,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 8.0, left: 8.0),
                            child: Image.asset(
                              "assets/images/Group.png",
                              width: 50,
                            ),
                          ),
                        );
                      } else {
                        return GestureDetector(
                          onTap: onPress != null ? () => onPress() : null,
                          onLongPress:
                              onLongPress != null ? () => onLongPress() : null,
                          child: CircleAvatar(
                            child: Text(user.firstName?[0] ?? ''),
                          ),
                        );
                      }
                    },
                  ),
                  /*  inputOptions: InputOptions(
                    inputDecoration: InputDecoration(
                      labelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      alignLabelWithHint: true,
                      hintText: "Message chatbot",
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    inputTextStyle: TextStyle(color: Colors.black),
                    cursorStyle: CursorStyle(color: darkBrown),
                    inputToolbarStyle: BoxDecoration(
                      border: Border.all(color: Color(0xFF8F5622), width: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      color: Color.fromARGB(255, 250, 230, 205),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    onTextChange: (text) {
                      print("Text changed: $text");
                    },
                    textInputAction: TextInputAction.send,
                  ),*/
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
