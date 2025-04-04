import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'GroupDetailsScreen.dart';
import 'chat_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final String groupName;
  final String? groupLogo;
  const GroupChatScreen({Key? key, required this.groupId, required this.currentUserId, required this.groupName, this.groupLogo}) : super(key: key);
  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final DatabaseReference _groupChatDetailsRef = FirebaseDatabase.instance.ref("GroupChatDetails");
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("Users");
  final TextEditingController _messageController = TextEditingController();
  Map<String, String> _reactions = {};
  Map<String, dynamic>? _currentUserData;
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
  Future<void> _loadCurrentUser() async {
    DatabaseEvent event = await _usersRef.child(widget.currentUserId).once();
    if (event.snapshot.value != null) {
      setState(() {
        _currentUserData = Map<String, dynamic>.from(event.snapshot.value as Map);
      });
    }
  }
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;
    String now = DateFormat("dd-MM-yyyy HH:mm:ss").format(DateTime.now());
    DatabaseEvent event = await FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).once();
    List<dynamic> members = [];
    if (event.snapshot.value != null) {
      Map groupData = event.snapshot.value as Map;
      if (groupData.containsKey("members")) members = groupData["members"];
    }
    Map<String, dynamic> messageData = {
      "attachmentUploadFrom": "",
      "date": now.split(" ").first,
      "deleted": "No",
      "id": widget.groupId,
      "indexId": "",
      "mediaType": "M",
      "mediaURL": "",
      "members": members,
      "messageStatus": "Unread",
      "readMessageUserId": widget.currentUserId,
      "replayMessage": "",
      "replySendUserId": widget.currentUserId,
      "replySendUserName": "",
      "senderId": widget.currentUserId,
      "senderImage": _currentUserData != null ? _currentUserData!["image"] ?? "" : "",
      "senderName": _currentUserData != null ? _currentUserData!["name"] ?? "" : "",
      "sendtype": "Send",
      "staredmessage": "",
      "text": message,
      "time": now.split(" ").last,
      "timestamp": now,
      "senderAbout": _currentUserData != null ? _currentUserData!["about"] ?? "" : "",
      "senderPhone": _currentUserData != null ? _currentUserData!["number"] ?? "" : ""
    };
    DatabaseReference newMsgRef = _groupChatDetailsRef.child(widget.groupId).push();
    messageData["indexId"] = newMsgRef.key;
    newMsgRef.set(messageData);
    _messageController.clear();
  }
  Future<void> _scheduleMessage(String text, DateTime scheduledTime) async {
    String scheduledStr = DateFormat("dd-MM-yyyy HH:mm:ss").format(scheduledTime);
    DatabaseEvent event = await FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).once();
    List<dynamic> members = [];
    if (event.snapshot.value != null) {
      Map groupData = event.snapshot.value as Map;
      if (groupData.containsKey("members")) members = groupData["members"];
    }
    Map<String, dynamic> messageData = {
      "attachmentUploadFrom": "",
      "date": scheduledStr.split(" ").first,
      "deleted": "No",
      "id": widget.groupId,
      "indexId": "",
      "mediaType": "M",
      "mediaURL": "",
      "members": members,
      "messageStatus": "Unread",
      "readMessageUserId": widget.currentUserId,
      "replayMessage": "",
      "replySendUserId": widget.currentUserId,
      "replySendUserName": "",
      "senderId": widget.currentUserId,
      "senderImage": _currentUserData != null ? _currentUserData!["image"] ?? "" : "",
      "senderName": _currentUserData != null ? _currentUserData!["name"] ?? "" : "",
      "sendtype": "Send",
      "staredmessage": "",
      "text": text,
      "time": scheduledStr.split(" ").last,
      "timestamp": scheduledStr,
      "senderAbout": _currentUserData != null ? _currentUserData!["about"] ?? "" : "",
      "senderPhone": _currentUserData != null ? _currentUserData!["number"] ?? "" : "",
      "isScheduled": "true",
      "scheduledTime": scheduledStr
    };
    DatabaseReference newMsgRef = _groupChatDetailsRef.child(widget.groupId).push();
    messageData["indexId"] = newMsgRef.key;
    newMsgRef.set(messageData);
    Fluttertoast.showToast(msg: "Message scheduled for $scheduledStr");
  }
  Future<void> _showScheduleMessageDialog() async {
    TextEditingController scheduleController = TextEditingController(text: _messageController.text.trim());
    DateTime? selectedDateTime;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Schedule Message", style: TextStyle(color: Color(0xFF075E54))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scheduleController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter message",
                  hintStyle: TextStyle(color: Colors.black54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF075E54))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF075E54)),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF075E54),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.pink,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                    }
                  }
                  setState(() {});
                },
                child: Text("Pick Date & Time", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 10),
              if (selectedDateTime != null)
                Text(DateFormat("dd-MM-yyyy HH:mm:ss").format(selectedDateTime!), style: TextStyle(color: Colors.black))
              else
                Text("No Date Selected", style: TextStyle(color: Colors.black)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); },
              child: Text("Cancel", style: TextStyle(color: Colors.pink)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF075E54)),
              onPressed: () {
                if (selectedDateTime != null && scheduleController.text.trim().isNotEmpty) {
                  _scheduleMessage(scheduleController.text.trim(), selectedDateTime!);
                  Navigator.pop(context);
                  _messageController.clear();
                } else {
                  Fluttertoast.showToast(msg: "Please enter message and pick date/time");
                }
              },
              child: Text("Schedule", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }
  DateTime _parseDate(String timestamp) {
    try {
      return DateFormat("dd-MM-yyyy HH:mm:ss").parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return DateFormat('d MMM yyyy').format(date);
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
              _buildReactionIcon(indexId, "😮")
            ],
          ),
        );
      },
    );
  }
  Widget _buildReactionIcon(String indexId, String emoji) {
    return InkWell(
      onTap: () {
        setState(() { _reactions[indexId] = emoji; });
        Navigator.pop(context);
      },
      child: Text(emoji, style: TextStyle(fontSize: 24)),
    );
  }
  Future<void> _deleteMessage(String messageKey) async {
    await _groupChatDetailsRef.child(widget.groupId).child(messageKey).update({"deleted": "Yes"});
  }
  Widget _buildMessageStatusIcon(String status) {
    if (status == "Unread") return Icon(Icons.check, size: 12, color: Colors.grey);
    if (status == "Delivered") return Icon(Icons.done_all, size: 12, color: Colors.grey);
    if (status == "Read") return Icon(Icons.done_all, size: 12, color: Colors.blue);
    return SizedBox();
  }
  Future<void> _showEditMessageDialog(String messageKey, String currentText) async {
    TextEditingController editController = TextEditingController(text: currentText);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Edit Scheduled Message", style: TextStyle(color: Color(0xFF075E54))),
          content: TextField(
            controller: editController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: "Edit message",
              hintStyle: TextStyle(color: Colors.black54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF075E54))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); },
              child: Text("Cancel", style: TextStyle(color: Colors.pink)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF075E54)),
              onPressed: () {
                FirebaseDatabase.instance.ref("GroupChatDetails").child(widget.groupId).child(messageKey).update({"text": editController.text.trim()});
                Navigator.pop(context);
              },
              child: Text("Edit", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }
  void _openGroupDetails() {
    Navigator.push(context, PageRouteBuilder(transitionDuration: Duration(milliseconds: 300), pageBuilder: (_, __, ___) => GroupDetailsScreen(groupId: widget.groupId, currentUserId: widget.currentUserId, currentUserData: _currentUserData, groupName: widget.groupName, groupLogo: widget.groupLogo)));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
        title: InkWell(
          onTap: _openGroupDetails,
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              String memberNames = "";
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map groupData = snapshot.data!.snapshot.value as Map;
                List<dynamic> members = groupData["members"] ?? [];
                memberNames = members.map((m) => m["name"]).take(3).join(", ");
                if(members.length > 3) memberNames += ", ...";
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(widget.groupLogo ?? "https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.groupName)}"),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.groupName, style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      )
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(memberNames, style: TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis)
                ],
              );
            },
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.call, color: Color(0xFF075E54), size: 18), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam, color: Color(0xFF075E54), size: 18), onPressed: () {})
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _groupChatDetailsRef.child(widget.groupId).onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return Center(child: Text("No messages yet", style: TextStyle(fontSize: 14)));
                Map<dynamic, dynamic> rawMessages = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> allMessages = [];
                final seen = <String>{};
                rawMessages.forEach((key, value) {
                  Map<String, dynamic> msg = Map<String, dynamic>.from(value as Map);
                  String uniqueId = "${msg['senderId']}_${msg['timestamp']}_${msg['text']}";
                  if (!seen.contains(uniqueId)) { seen.add(uniqueId); allMessages.add(msg); }
                });
                allMessages = allMessages.where((msg) {
                  if (msg["isScheduled"] == "true") {
                    DateTime scheduledTime = _parseDate(msg["scheduledTime"]);
                    if (msg["senderId"] != widget.currentUserId && DateTime.now().isBefore(scheduledTime)) return false;
                  }
                  return true;
                }).toList();
                allMessages.sort((a, b) => _parseDate(a['timestamp']).compareTo(_parseDate(b['timestamp'])));
                List<dynamic> groupedItems = [];
                String? lastDateLabel;
                for (var message in allMessages) {
                  String tsString = message['timestamp'] ?? '';
                  DateTime dt = _parseDate(tsString);
                  String dateLabel = _getDateLabel(dt);
                  if (dateLabel != lastDateLabel) { groupedItems.add({'type': 'dateHeader', 'label': dateLabel}); lastDateLabel = dateLabel; }
                  groupedItems.add({'type': 'message', 'data': message});
                }
                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(bottom: 8, top: 8),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = groupedItems[groupedItems.length - 1 - index];
                    if (item['type'] == 'dateHeader') {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                            child: Text(item['label'], style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      );
                    } else {
                      Map<String, dynamic> message = item['data'];
                      bool isMe = message['senderId'] == widget.currentUserId;
                      bool isDeleted = message['deleted'] == "Yes";
                      String indexId = message['indexId'] ?? '';
                      String messageText = isDeleted ? "This message was deleted" : message['text'];
                      String timeText = message['time'] ?? '';
                      String? reaction = _reactions[indexId];
                      String senderDisplayName = isMe ? "You" : (message['senderName'] ?? "Unknown");
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
                                        leading: Icon(Icons.delete, color: Colors.red, size: 18),
                                        title: Text("Delete Message", style: TextStyle(fontSize: 14)),
                                        onTap: () async { Navigator.pop(context); await _deleteMessage(indexId); },
                                      ),
                                    if (!isDeleted)
                                      ListTile(
                                        leading: Icon(Icons.emoji_emotions_outlined, color: Colors.amber, size: 18),
                                        title: Text("React", style: TextStyle(fontSize: 14)),
                                        onTap: () { Navigator.pop(context); _showReactionPicker(indexId); },
                                      ),
                                    if (message["isScheduled"] == "true" && isMe && DateTime.now().isBefore(_parseDate(message["scheduledTime"])))
                                      ListTile(
                                        leading: Icon(Icons.edit, color: Colors.blue, size: 18),
                                        title: Text("Edit", style: TextStyle(fontSize: 14)),
                                        onTap: () { Navigator.pop(context); _showEditMessageDialog(indexId, message['text']); },
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
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? Color(0xFFDCF8C6) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(isMe ? 12 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 12),
                              ),
                              border: isMe ? null : Border.all(color: Colors.grey.shade300, width: 0.8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: Offset(0, 1))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 4.0),
                                    child: Text(senderDisplayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(child: Text(messageText, style: TextStyle(fontSize: 14, color: Colors.black87))),
                                    if (reaction != null && reaction.isNotEmpty)
                                      Padding(padding: EdgeInsets.only(left: 4.0), child: Text(reaction, style: TextStyle(fontSize: 20))),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(timeText, style: TextStyle(fontSize: 10, color: Colors.black54)),
                                    if (isMe)
                                      Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: _buildMessageStatusIcon(message["messageStatus"] ?? "Unread"),
                                      ),
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
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 20), onPressed: () {}),
                IconButton(icon: Icon(Icons.attach_file, color: Color(0xFF075E54), size: 20), onPressed: () {}),
                IconButton(icon: Icon(Icons.schedule, color: Colors.pink, size: 20), onPressed: _showScheduleMessageDialog),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(fontSize: 14), border: InputBorder.none),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF075E54)),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


