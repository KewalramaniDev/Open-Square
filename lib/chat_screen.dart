import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

import 'web_signaling_client.dart';
import 'video_call_page.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserImage;
  final String currentUserFcmToken;
  final String currentUserAbout;
  final String currentUserPhone;

  final String chatUserId;
  final String chatUserName;
  final String chatUserImage;
  final String chatUserToken;
  final String chatUserAbout;
  final String chatUserPhone;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserImage,
    required this.currentUserFcmToken,
    required this.currentUserAbout,
    required this.currentUserPhone,
    required this.chatUserId,
    required this.chatUserName,
    required this.chatUserImage,
    required this.chatUserToken,
    required this.chatUserAbout,
    required this.chatUserPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _chatRef = FirebaseDatabase.instance.ref("Chat");
  final DatabaseReference _lastChatRef = FirebaseDatabase.instance.ref("LastChat");

  Map<String, String> _reactions = {};

  StreamSubscription<DatabaseEvent>? _incomingCallSub;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCall();
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _listenForIncomingCall() {
    String convKey = "${widget.chatUserId}_${widget.currentUserId}";
    _incomingCallSub = _chatRef.child(convKey).onChildAdded.listen((event) {
      var msgData = event.snapshot.value;
      if (msgData != null) {
        Map<String, dynamic> msg = Map<String, dynamic>.from(msgData as Map);
        if (msg['mediatype'] == "VideoCallStart" &&
            msg['receiverID'] == widget.currentUserId) {
          _showIncomingCallDialog(msg);
        }
      }
    });
  }

  void _showIncomingCallDialog(Map<String, dynamic> callMsg) {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Incoming Video Call", style: TextStyle(fontSize: 14)),
          content: Text("Video call from ${widget.chatUserName}", style: const TextStyle(fontSize: 12)),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Call rejected");
              },
              child: const Icon(Icons.call_end, color: Colors.red, size: 20),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                String roomId = callMsg['mediaurl'] ?? '';
                if (roomId.isNotEmpty) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallPage(
                        roomId: roomId,
                        currentUserId: widget.currentUserId,
                        currentUserFcmToken: widget.currentUserFcmToken,
                        chatUserId: widget.chatUserId,
                        currentUserName: widget.currentUserName,
                        chatUserName: widget.chatUserName,
                        isCaller: false,
                      ),
                    ),
                  );
                  await _sendVideoCallMessage("VideoCallEnd", roomId);
                }
              },
              child: const Icon(Icons.call, color: Colors.green, size: 20),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String messageText = _messageController.text.trim();
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    String fullTimestamp = "$currentDate $currentTime";

    Map<String, dynamic> messageData = {
      "attachmentUploadFrom": "",
      "date": currentDate,
      "deleted": "No",
      "id": "${widget.currentUserId}_${widget.chatUserId}",
      "indexId": "",
      "mediatype": "M",
      "mediaurl": "",
      "message": messageText,
      "messageStatus": "Unread",
      "receiverID": widget.chatUserId,
      "receiverImage": widget.chatUserImage,
      "receiverName": widget.chatUserName,
      "receiverToken": widget.chatUserToken,
      "receiverabout": widget.chatUserAbout,
      "receiverphone": widget.chatUserPhone,
      "replyIndexId": "",
      "replyMessage": "",
      "replySendUserId": widget.currentUserId,
      "sendType": "Send",
      "senderFcmToken": widget.currentUserFcmToken,
      "senderImage": widget.currentUserImage,
      "senderName": widget.currentUserName,
      "sentID": widget.currentUserId,
      "sentabout": widget.currentUserAbout,
      "sentphone": widget.currentUserPhone,
      "staredmessage": "",
      "time": currentTime,
      "timestamp": fullTimestamp,
      "unReadMessageCount": "0"
    };

    String convKey1 = "${widget.currentUserId}_${widget.chatUserId}";
    String convKey2 = "${widget.chatUserId}_${widget.currentUserId}";
    DatabaseReference msgRef1 = _chatRef.child(convKey1).push();
    String messageKey1 = msgRef1.key!;
    messageData["indexId"] = messageKey1;
    await msgRef1.set(messageData);
    await _chatRef.child(convKey2).push().set(messageData);
    await _lastChatRef.child(convKey1).set(messageData);
    await _lastChatRef.child(convKey2).set(messageData);
    _messageController.clear();
  }

  Future<void> _sendVideoCallMessage(String mediatype, String roomId) async {
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    String fullTimestamp = "$currentDate $currentTime";

    Map<String, dynamic> callData = {
      "attachmentUploadFrom": "",
      "date": currentDate,
      "deleted": "",
      "devicetype": widget.currentUserFcmToken,
      "id": "${widget.currentUserId}_${widget.chatUserId}",
      "indexId": "",
      "mediatype": mediatype,
      "mediaurl": roomId,
      "message": mediatype == "VideoCallStart" ? "Video Call Started" : "Video Call Ended",
      "messageStatus": "read",
      "receiverID": widget.chatUserId,
      "receiverImage": widget.chatUserImage,
      "receiverName": widget.chatUserName,
      "receiverToken": widget.chatUserToken,
      "receiverabout": widget.chatUserAbout,
      "receiverphone": widget.chatUserPhone,
      "replyIndexId": "",
      "replyMessage": "",
      "replySendUserId": widget.currentUserId,
      "sendType": "VideoCall",
      "senderFcmToken": widget.currentUserFcmToken,
      "senderImage": widget.currentUserImage,
      "senderName": widget.currentUserName,
      "sentID": widget.currentUserId,
      "sentabout": widget.currentUserAbout,
      "sentphone": widget.currentUserPhone,
      "staredmessage": "",
      "time": currentTime,
      "timestamp": fullTimestamp,
      "unReadMessageCount": "0"
    };

    String convKey1 = "${widget.currentUserId}_${widget.chatUserId}";
    String convKey2 = "${widget.chatUserId}_${widget.currentUserId}";
    DatabaseReference msgRef1 = _chatRef.child(convKey1).push();
    String messageKey = msgRef1.key!;
    callData["indexId"] = messageKey;
    await msgRef1.set(callData);
    await _chatRef.child(convKey2).push().set(callData);
    await _lastChatRef.child(convKey1).set(callData);
    await _lastChatRef.child(convKey2).set(callData);
  }

  Future<void> _deleteMessage(String convKey, String messageKey) async {
    await _chatRef.child(convKey).child(messageKey).update({"deleted": "Yes"});
    await _lastChatRef.child(convKey).update({"deleted": "Yes"});
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split(' ');
    final datePart = parts.first;
    return DateFormat('dd-MM-yyyy').parse(datePart);
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return DateFormat('d MMM yyyy').format(date);
  }

  Widget _buildReadReceiptIcon(String status) {
    switch (status) {
      case "Unread":
        return const Icon(Icons.check, color: Colors.grey, size: 14);
      case "Delivered":
        return const Icon(Icons.done_all, color: Colors.grey, size: 14);
      case "Read":
        return const Icon(Icons.done_all, color: Colors.blue, size: 14);
      default:
        return const Icon(Icons.check, color: Colors.grey, size: 14);
    }
  }

  void _showReactionPicker(String indexId) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildReactionIcon(indexId, "❤️"),
              _buildReactionIcon(indexId, "👍"),
              _buildReactionIcon(indexId, "👎"),
              _buildReactionIcon(indexId, "😂"),
              _buildReactionIcon(indexId, "😮"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactionIcon(String indexId, String emoji) {
    return InkWell(
      onTap: () {
        setState(() {
          _reactions[indexId] = emoji;
        });
        Navigator.pop(context);
      },
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 30,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.chatUserImage),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.chatUserName,
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF075E54), size: 18),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF075E54), size: 18),
            onPressed: _startVideoCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet", style: TextStyle(fontSize: 14)));
                }
                Map<dynamic, dynamic> rawMessages = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> allMessages = [];
                final seen = <String>{};

                for (var key in [
                  "${widget.currentUserId}_${widget.chatUserId}",
                  "${widget.chatUserId}_${widget.currentUserId}"
                ]) {
                  if (rawMessages.containsKey(key)) {
                    (rawMessages[key] as Map<dynamic, dynamic>).forEach((msgKey, value) {
                      Map<String, dynamic> msg = Map<String, dynamic>.from(value as Map);
                      String uniqueId = "${msg['sentID']}_${msg['timestamp']}_${msg['message']}";
                      if (!seen.contains(uniqueId)) {
                        seen.add(uniqueId);
                        allMessages.add(msg);
                      }
                    });
                  }
                }

                allMessages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
                List<dynamic> groupedItems = [];
                String? lastDateLabel;
                for (var message in allMessages) {
                  String tsString = message['timestamp'] ?? '';
                  DateTime dt = _parseDate(tsString);
                  String dateLabel = _getDateLabel(dt);
                  if (dateLabel != lastDateLabel) {
                    groupedItems.add({
                      'type': 'dateHeader',
                      'label': dateLabel,
                    });
                    lastDateLabel = dateLabel;
                  }
                  groupedItems.add({
                    'type': 'message',
                    'data': message,
                  });
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = groupedItems[groupedItems.length - 1 - index];
                    if (item['type'] == 'dateHeader') {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['label'],
                              style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      );
                    } else {
                      Map<String, dynamic> message = item['data'];
                      bool isMe = message['sentID'] == widget.currentUserId;
                      bool isDeleted = message['deleted'] == "Yes";
                      String indexId = message['indexId'] ?? '';
                      String messageText = isDeleted ? "This message was deleted" : message['message'];
                      String timeText = message['time'] ?? '';
                      String status = message['messageStatus'] ?? 'Unread';
                      String? reaction = _reactions[indexId];

                      return GestureDetector(
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMe && !isDeleted)
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        title: const Text("Delete Message", style: TextStyle(fontSize: 14)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await _deleteMessage("${widget.currentUserId}_${widget.chatUserId}", indexId);
                                          await _deleteMessage("${widget.chatUserId}_${widget.currentUserId}", indexId);
                                        },
                                      ),
                                    if (!isDeleted)
                                      ListTile(
                                        leading: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber, size: 18),
                                        title: const Text("React", style: TextStyle(fontSize: 14)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showReactionPicker(indexId);
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                            padding: const EdgeInsets.all(8),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isMe ? 12 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 12),
                              ),
                              border: isMe ? null : Border.all(color: Colors.grey.shade300, width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        messageText,
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                    ),
                                    if (reaction != null && reaction.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0),
                                        child: Text(
                                          reaction,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timeText,
                                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isMe && !isDeleted)
                                      _buildReadReceiptIcon(status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 20),
                  onPressed: () {
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF075E54),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _startVideoCall() async {
    String roomId = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    await _sendVideoCallMessage("VideoCallStart", roomId);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallPage(
          roomId: roomId,
          currentUserId: widget.currentUserId,
          currentUserFcmToken: widget.currentUserFcmToken,
          chatUserId: widget.chatUserId,
          currentUserName: widget.currentUserName,
          chatUserName: widget.chatUserName,
          isCaller: true,
        ),
      ),
    );
    await _sendVideoCallMessage("VideoCallEnd", roomId);
  }
}
