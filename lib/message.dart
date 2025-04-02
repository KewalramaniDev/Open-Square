import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  final String currentUserId;
  const MessageScreen({super.key, required this.currentUserId});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("Users");
  final DatabaseReference _lastChatRef = FirebaseDatabase.instance.ref("LastChat");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset("assets/images/logo.png", height: 70),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _lastChatRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> lastChats = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          Map<String, Map<String, dynamic>> uniqueChats = {};

          for (var entry in lastChats.entries) {
            List<String> ids = entry.key.split("_");
            if (ids.contains(widget.currentUserId)) {
              String chatKey = ids.first == widget.currentUserId ? ids.last : ids.first;
              if (!uniqueChats.containsKey(chatKey)) {
                uniqueChats[chatKey] = Map<String, dynamic>.from(entry.value);
              }
            }
          }

          List<Map<String, dynamic>> chatList = uniqueChats.values.toList();
          chatList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              var chat = chatList[index];
              bool isMe = chat['sentID'] == widget.currentUserId;
              String chatUserId = isMe ? chat['receiverID'] : chat['sentID'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(chat['receiverImage'] ?? "https://ui-avatars.com/api/?name=${chat['receiverName'] ?? "User"}"),
                  ),
                  title: Text(
                    chat['receiverName'] ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    chat['message'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat['messageStatus'] == "Unread" ? Colors.blue : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        chat['time'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (chat['messageStatus'] == "Unread")
                        const Icon(Icons.circle, color: Colors.blue, size: 10)
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: widget.currentUserId,
                          chatUserId: chatUserId,
                          chatUserName: chat['receiverName'] ?? "User",
                          chatUserImage: chat['receiverImage'] ?? "",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: StreamBuilder(
                    stream: _usersRef.onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
                      if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      Map<String, dynamic> users = Map<String, dynamic>.from(userSnapshot.data!.snapshot.value as Map);
                      List<String> userIds = users.keys.where((id) => id != widget.currentUserId).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: userIds.length,
                        itemBuilder: (context, index) {
                          String userId = userIds[index];
                          Map<String, dynamic> user = Map<String, dynamic>.from(users[userId]);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['image'] ?? "https://ui-avatars.com/api/?name=${user['name'] ?? "User"}"),
                            ),
                            title: Text(user['name'] ?? "Unknown"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    currentUserId: widget.currentUserId,
                                    chatUserId: userId,
                                    chatUserName: user['name'] ?? "User",
                                    chatUserImage: user['image'] ?? "",
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
