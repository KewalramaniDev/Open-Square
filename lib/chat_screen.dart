import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;
  final String chatUserName;
  final String chatUserImage;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.chatUserId,
    required this.chatUserName,
    required this.chatUserImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _chatRef = FirebaseDatabase.instance.ref("Chat");
  final DatabaseReference _lastChatRef = FirebaseDatabase.instance.ref("LastChat");

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    String messageText = _messageController.text.trim();
    String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    Map<String, dynamic> messageData = {
      "attachmentUploadFrom": "",
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "deleted": "No",
      "id": "${widget.currentUserId}_${widget.chatUserId}",
      "indexId": _chatRef.push().key,
      "mediatype": "T",
      "mediaurl": "",
      "message": messageText,
      "messageStatus": "Unread",
      "receiverID": widget.chatUserId,
      "receiverImage": widget.chatUserImage,
      "receiverName": widget.chatUserName,
      "senderName": "User", // Fetch from FirebaseAuth if needed
      "sentID": widget.currentUserId,
      "time": DateFormat('HH:mm:ss').format(DateTime.now()),
      "timestamp": timestamp,
      "unReadMessageCount": "0"
    };

    _chatRef.child("${widget.currentUserId}_${widget.chatUserId}").push().set(messageData);
    _chatRef.child("${widget.chatUserId}_${widget.currentUserId}").push().set(messageData);
    _lastChatRef.child("${widget.currentUserId}_${widget.chatUserId}").set(messageData);
    _lastChatRef.child("${widget.chatUserId}_${widget.currentUserId}").set(messageData);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.chatUserImage),
            ),
            const SizedBox(width: 10),
            Text(widget.chatUserName),
          ],
        ),
        backgroundColor: const Color(0xFF004474),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatRef.onValue, // Listen to the entire "Chat" node
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet"));
                }

                Map<dynamic, dynamic> rawMessages =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                List<Map<String, dynamic>> messageList = [];

                if (rawMessages.containsKey("${widget.currentUserId}_${widget.chatUserId}")) {
                  messageList.addAll((rawMessages["${widget.currentUserId}_${widget.chatUserId}"] as Map<dynamic, dynamic>)
                      .values
                      .map((e) => Map<String, dynamic>.from(e as Map)));
                }
                if (rawMessages.containsKey("${widget.chatUserId}_${widget.currentUserId}")) {
                  messageList.addAll((rawMessages["${widget.chatUserId}_${widget.currentUserId}"] as Map<dynamic, dynamic>)
                      .values
                      .map((e) => Map<String, dynamic>.from(e as Map)));
                }

                messageList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                return ListView.builder(
                  reverse: true,
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> message = messageList[index];
                    bool isMe = message['sentID'] == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              message['time'],
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
