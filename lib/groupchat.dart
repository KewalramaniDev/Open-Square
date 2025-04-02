import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final String groupName;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.currentUserId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final DatabaseReference _groupChatDetailsRef = FirebaseDatabase.instance.ref("GroupChatDetails");
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;
    String now = DateTime.now().toString();
    _groupChatDetailsRef.child(widget.groupId).push().set({
      "attachmentUploadFrom": "",
      "date": now.split(" ").first,
      "deleted": "No",
      "id": widget.groupId,
      "indexId": "",
      "mediaType": "M",
      "mediaURL": "",
      "members": [],
      "messageStatus": "Unread",
      "readMessageUserId": widget.currentUserId,
      "replayMessage": "",
      "replySendUserId": widget.currentUserId,
      "replySendUserName": "",
      "senderId": widget.currentUserId,
      "senderImage": "",
      "senderName": "",
      "sendtype": "Send",
      "staredmessage": "",
      "text": message,
      "time": now.split(" ").last,
      "timestamp": now,
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(fontSize: 16, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "Group messages will appear here.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Enter message",
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
