import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'chat_screen.dart';
import 'groupchat.dart';
class MessageScreen extends StatefulWidget {
  final String currentUserId;
  const MessageScreen({Key? key, required this.currentUserId}) : super(key: key);
  @override
  State<MessageScreen> createState() => _MessageScreenState();
}
class _MessageScreenState extends State<MessageScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("Users");
  final DatabaseReference _lastChatRef = FirebaseDatabase.instance.ref("LastChat");
  final DatabaseReference _groupChatRef = FirebaseDatabase.instance.ref("GroupChat");
  Map<String, dynamic>? currentUserData;
  Map<String, dynamic>? _selectedChat;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "Recent";
  List<String> _selectedUserIds = [];
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }
  Future<void> _loadCurrentUser() async {
    final snapshot = await _usersRef.child(widget.currentUserId).get();
    if (snapshot.exists) {
      setState(() {
        currentUserData = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }
  void _showCreateGroupDialog() {
    String groupName = "";
    String groupDescription = "";
    _selectedUserIds = [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create Group",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Group Name",
                        hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      onChanged: (value) => groupName = value.trim(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Group Description",
                        hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      onChanged: (value) => groupDescription = value.trim(),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Members",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: StreamBuilder(
                        stream: _usersRef.onValue,
                        builder: (context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
                          if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          Map<String, dynamic> users = Map<String, dynamic>.from(
                            userSnapshot.data!.snapshot.value as Map,
                          );
                          List<String> userIds = users.keys.where((id) => id != widget.currentUserId).toList();
                          return ListView.builder(
                            itemCount: userIds.length,
                            itemBuilder: (context, index) {
                              String userId = userIds[index];
                              Map<String, dynamic> user = Map<String, dynamic>.from(users[userId]);
                              bool isSelected = _selectedUserIds.contains(userId);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(
                                  user['name'] ?? "Unknown",
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                secondary: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(
                                    user['image'] ?? "https://ui-avatars.com/api/?name=${user['name'] ?? 'User'}",
                                  ),
                                ),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    if (val == true) {
                                      _selectedUserIds.add(userId);
                                    } else {
                                      _selectedUserIds.remove(userId);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.blue)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (groupName.isNotEmpty && _selectedUserIds.isNotEmpty) {
                              List<Map<String, dynamic>> members = [];
                              members.add({
                                "id": widget.currentUserId,
                                "name": currentUserData?['name'] ?? "User",
                                "image": currentUserData?['image'] ?? "",
                                "about": currentUserData?['about'] ?? "",
                                "admin": "true",
                                "deviceToken": currentUserData?['fcmToken'] ?? "",
                                "phoneno": currentUserData?['number'] ?? "",
                                "deleteMessage": "",
                                "messageStatus": "read",
                                "unReadMessageCount": "0",
                              });
                              final snapshot = await _usersRef.get();
                              if (snapshot.exists) {
                                Map<String, dynamic> allUsers = Map<String, dynamic>.from(snapshot.value as Map);
                                for (String id in _selectedUserIds) {
                                  if (allUsers.containsKey(id)) {
                                    Map<String, dynamic> user = Map<String, dynamic>.from(allUsers[id]);
                                    members.add({
                                      "id": id,
                                      "name": user['name'] ?? "User",
                                      "image": user['image'] ?? "",
                                      "about": user['about'] ?? "",
                                      "admin": "false",
                                      "deviceToken": user['fcmToken'] ?? "",
                                      "phoneno": user['number'] ?? "",
                                      "deleteMessage": "",
                                      "messageStatus": "Unread",
                                      "unReadMessageCount": "0",
                                    });
                                  }
                                }
                              }
                              String now = DateTime.now().toString();
                              DatabaseReference newGroupRef = _groupChatRef.push();
                              Map<String, dynamic> groupData = {
                                "_id": newGroupRef.key,
                                "addmemberacccess": "true",
                                "adminId": widget.currentUserId,
                                "adminName": currentUserData?['name'] ?? "User",
                                "createdAt": now,
                                "editAccess": "true",
                                "groupIcon": "",
                                "groupName": groupName,
                                "groupdescription": groupDescription,
                                "lastmessage": "",
                                "lastmessagedate": "",
                                "lastmessagesenderdid": "",
                                "lastmessagesendername": "",
                                "lastmessagetime": "",
                                "lastmessagetype": "",
                                "mediatype": "",
                                "mediaurl": "",
                                "members": members,
                                "readMessageUserId": widget.currentUserId,
                                "sendmessageacccess": "true"
                              };
                              await newGroupRef.set(groupData);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                    groupId: newGroupRef.key!,
                                    currentUserId: widget.currentUserId,
                                    groupName: groupName,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text("Create", style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
  Widget _buildChatList(bool isLargeScreen) {
    return StreamBuilder<DatabaseEvent>(
      stream: _lastChatRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> lastChatSnapshot) {
        if (!lastChatSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        Map<String, dynamic> lastChats = {};
        if (lastChatSnapshot.data!.snapshot.value != null) {
          lastChats = Map<String, dynamic>.from(lastChatSnapshot.data!.snapshot.value as Map);
        }
        Map<String, Map<String, dynamic>> personalChats = {};
        for (var entry in lastChats.entries) {
          List<String> ids = entry.key.split("_");
          if (ids.contains(widget.currentUserId)) {
            String chatPartnerId = ids.first == widget.currentUserId ? ids.last : ids.first;
            if (!personalChats.containsKey(chatPartnerId)) {
              personalChats[chatPartnerId] = Map<String, dynamic>.from(entry.value);
              personalChats[chatPartnerId]!['chatType'] = "single";
            }
          }
        }
        return StreamBuilder<DatabaseEvent>(
          stream: _groupChatRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> groupChatSnapshot) {
            Map<String, dynamic> groupChats = {};
            if (groupChatSnapshot.hasData &&
                groupChatSnapshot.data!.snapshot.value != null) {
              groupChats = Map<String, dynamic>.from(groupChatSnapshot.data!.snapshot.value as Map);
            }
            Map<String, Map<String, dynamic>> groupChatList = {};
            groupChats.forEach((groupId, value) {
              Map<String, dynamic> groupData = Map<String, dynamic>.from(value);
              if (groupData.containsKey("members")) {
                List<dynamic> members = groupData["members"];
                bool isMember = members.any((member) =>
                member is Map && member["id"] == widget.currentUserId);
                if (isMember) {
                  String formattedMessage = "";
                  if ((groupData["lastmessage"] as String).isNotEmpty) {
                    formattedMessage =
                    "${groupData["lastmessagesendername"]} : ${groupData["lastmessage"]}";
                  }
                  groupData["message"] = formattedMessage;
                  groupData["chatType"] = "group";
                  groupChatList[groupId] = groupData;
                }
              }
            });
            List<Map<String, dynamic>> combinedChats = [];
            combinedChats.addAll(personalChats.values);
            combinedChats.addAll(groupChatList.values);
            for (var chat in combinedChats) {
              DateTime dt;
              if (chat["chatType"] == "single") {
                dt = DateTime.tryParse(chat["timestamp"] ?? "") ?? DateTime.now();
              } else {
                String dateStr = chat["lastmessagedate"] ?? "";
                String timeStr = chat["lastmessagetime"] ?? "";
                if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
                  try {
                    dt = DateFormat("dd-MM-yyyy HH:mm:ss").parse("$dateStr $timeStr");
                  } catch (e) {
                    dt = DateTime.now();
                  }
                } else {
                  dt = DateTime.tryParse(chat["createdAt"] ?? "") ?? DateTime.now();
                }
              }
              chat["combinedTimestamp"] = dt;
            }
            if (_selectedFilter == "Unread") {
              combinedChats = combinedChats.where((chat) => chat['messageStatus'] == "Unread").toList();
            }
            if (_searchQuery.isNotEmpty) {
              combinedChats = combinedChats.where((chat) {
                String chatName;
                if (chat["chatType"] == "single") {
                  bool isMe = chat['sentID'] == widget.currentUserId;
                  chatName = isMe ? (chat['receiverName'] ?? "User") : (chat['senderName'] ?? "User");
                } else {
                  chatName = chat["groupName"] ?? "Group";
                }
                return chatName.toLowerCase().contains(_searchQuery);
              }).toList();
            }
            combinedChats.sort((a, b) => b["combinedTimestamp"].compareTo(a["combinedTimestamp"]));
            if (combinedChats.isEmpty) {
              return const Center(
                child: Text(
                  "No chats found.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              itemCount: combinedChats.length,
              itemBuilder: (context, index) {
                var chat = combinedChats[index];
                if (chat["chatType"] == "single") {
                  bool isMe = chat['sentID'] == widget.currentUserId;
                  String chatUserId = isMe ? chat['receiverID'] : chat['sentID'];
                  String chatUserName = isMe ? (chat['receiverName'] ?? "User") : (chat['senderName'] ?? "User");
                  String chatUserImage = isMe
                      ? (chat['receiverImage'] ?? "https://ui-avatars.com/api/?name=$chatUserName")
                      : (chat['senderImage'] ?? "https://ui-avatars.com/api/?name=$chatUserName");
                  String chatUserToken = isMe ? (chat['receiverToken'] ?? "") : (chat['senderFcmToken'] ?? "");
                  String chatUserAbout = isMe ? (chat['receiverabout'] ?? "") : (chat['sentabout'] ?? "");
                  String chatUserPhone = isMe ? (chat['receiverphone'] ?? "") : (chat['sentphone'] ?? "");
                  bool isUnread = chat['messageStatus'] == "Unread";
                  return InkWell(
                    onTap: () {
                      if (isLargeScreen) {
                        setState(() {
                          _selectedChat = {
                            'chatUserId': chatUserId,
                            'chatUserName': chatUserName,
                            'chatUserImage': chatUserImage,
                            'chatUserToken': chatUserToken,
                            'chatUserAbout': chatUserAbout,
                            'chatUserPhone': chatUserPhone,
                            'chatType': "single"
                          };
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUserId: widget.currentUserId,
                              currentUserName: currentUserData!['name'] ?? "User",
                              currentUserImage: currentUserData!['image'] ??
                                  "https://ui-avatars.com/api/?name=User",
                              currentUserFcmToken: currentUserData!['fcmToken'] ?? "",
                              currentUserAbout: currentUserData!['about'] ?? "",
                              currentUserPhone: currentUserData!['number'] ?? "",
                              chatUserId: chatUserId,
                              chatUserName: chatUserName,
                              chatUserImage: chatUserImage,
                              chatUserToken: chatUserToken,
                              chatUserAbout: chatUserAbout,
                              chatUserPhone: chatUserPhone,
                            ),
                          ),
                        );
                      }
                    },
                    child: _buildChatListItem(
                      image: chatUserImage,
                      name: chatUserName,
                      message: chat['message'] ?? "",
                      time: DateFormat("HH:mm").format(chat["combinedTimestamp"]),
                      isUnread: isUnread,
                    ),
                  );
                } else {
                  String groupId = chat["_id"];
                  String groupName = chat["groupName"] ?? "Group";
                  String groupImage = chat["groupIcon"] != ""
                      ? chat["groupIcon"]
                      : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(groupName)}";
                  bool isUnread = chat['messageStatus'] == "Unread";
                  return InkWell(
                    onTap: () {
                      if (isLargeScreen) {
                        setState(() {
                          _selectedChat = {
                            'groupId': groupId,
                            'groupName': groupName,
                            'groupImage': groupImage,
                            'chatType': "group",
                          };
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupChatScreen(
                              groupId: groupId,
                              currentUserId: widget.currentUserId,
                              groupName: groupName,
                            ),
                          ),
                        );
                      }
                    },
                    child: _buildChatListItem(
                      image: groupImage,
                      name: groupName,
                      message: chat['message'] ?? "",
                      time: DateFormat("HH:mm").format(chat["combinedTimestamp"]),
                      isUnread: isUnread,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
  Widget _buildChatListItem({
    required String image,
    required String name,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnread ? Colors.black : Colors.grey[700],
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              const SizedBox(height: 6),
              if (isUnread)
                const Icon(Icons.circle, color: Colors.black, size: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatDetailOrPlaceholder() {
    if (_selectedChat == null) {
      return const Center(
        child: Text(
          "Welcome to Open-Square!!\nSelect a conversation or start a new one.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }
    if (_selectedChat!['chatType'] == "group") {
      return GroupChatScreen(
        groupId: _selectedChat!['groupId'],
        currentUserId: widget.currentUserId,
        groupName: _selectedChat!['groupName'],
      );
    } else {
      return ChatScreen(
        currentUserId: widget.currentUserId,
        currentUserName: currentUserData!['name'] ?? "User",
        currentUserImage: currentUserData!['image'] ??
            "https://ui-avatars.com/api/?name=User",
        currentUserFcmToken: currentUserData!['fcmToken'] ?? "",
        currentUserAbout: currentUserData!['about'] ?? "",
        currentUserPhone: currentUserData!['number'] ?? "",
        chatUserId: _selectedChat!['chatUserId'],
        chatUserName: _selectedChat!['chatUserName'],
        chatUserImage: _selectedChat!['chatUserImage'],
        chatUserToken: _selectedChat!['chatUserToken'],
        chatUserAbout: _selectedChat!['chatUserAbout'],
        chatUserPhone: _selectedChat!['chatUserPhone'],
      );
    }
  }
  void _showUserListDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: TextField(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search users...",
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const Divider(),
                StreamBuilder(
                  stream: _usersRef.onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
                    if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                      return const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    Map<String, dynamic> users = Map<String, dynamic>.from(
                      userSnapshot.data!.snapshot.value as Map,
                    );
                    List<String> userIds = users.keys.where((id) => id != widget.currentUserId).toList();
                    return Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userIds.length,
                        itemBuilder: (context, index) {
                          String userId = userIds[index];
                          Map<String, dynamic> user = Map<String, dynamic>.from(users[userId]);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                user['image'] ??
                                    "https://ui-avatars.com/api/?name=${user['name'] ?? "User"}",
                              ),
                            ),
                            title: Text(
                              user['name'] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              if (MediaQuery.of(context).size.width > 800) {
                                setState(() {
                                  _selectedChat = {
                                    'chatUserId': userId,
                                    'chatUserName': user['name'] ?? "User",
                                    'chatUserImage': user['image'] ??
                                        "https://ui-avatars.com/api/?name=User",
                                    'chatUserToken': user['fcmToken'] ?? "",
                                    'chatUserAbout': user['about'] ?? "",
                                    'chatUserPhone': user['number'] ?? "",
                                    'chatType': "single"
                                  };
                                });
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      currentUserId: widget.currentUserId,
                                      currentUserName: currentUserData!['name'] ?? "User",
                                      currentUserImage: currentUserData!['image'] ??
                                          "https://ui-avatars.com/api/?name=User",
                                      currentUserFcmToken: currentUserData!['fcmToken'] ?? "",
                                      currentUserAbout: currentUserData!['about'] ?? "",
                                      currentUserPhone: currentUserData!['number'] ?? "",
                                      chatUserId: userId,
                                      chatUserName: user['name'] ?? "User",
                                      chatUserImage: user['image'] ??
                                          "https://ui-avatars.com/api/?name=User",
                                      chatUserToken: user['fcmToken'] ?? "",
                                      chatUserAbout: user['about'] ?? "",
                                      chatUserPhone: user['number'] ?? "",
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (currentUserData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Chat",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.mode_edit_outline),
            color: Colors.black,
            tooltip: "New Chat",
            iconSize: 24,
            onPressed: _showUserListDialog,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            color: Colors.black,
            tooltip: "New Group",
            iconSize: 24,
            onPressed: _showCreateGroupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            color: Colors.black,
            tooltip: "Logout",
            iconSize: 24,
            onPressed: _logout,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = constraints.maxWidth > 800;
          return Row(
            children: [
              SizedBox(
                width: isLargeScreen ? 350 : constraints.maxWidth,
                child: Column(
                  children: [
                    _buildSearchAndFilter(),
                    Expanded(child: _buildChatList(isLargeScreen)),
                  ],
                ),
              ),
              if (isLargeScreen)
                Expanded(
                  child: _buildChatDetailOrPlaceholder(),
                ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            decoration: InputDecoration(
              hintText: "Search chats...",
              hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Filter:",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedFilter,
                items: const [
                  DropdownMenuItem(value: "Recent", child: Text("Recent", style: TextStyle(fontSize: 16))),
                  DropdownMenuItem(value: "Unread", child: Text("Unread", style: TextStyle(fontSize: 16))),
                  DropdownMenuItem(value: "All", child: Text("All", style: TextStyle(fontSize: 16))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  }
                },
                underline: const SizedBox(),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
