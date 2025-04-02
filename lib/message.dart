import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_square/login.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  final String currentUserId;

  const MessageScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("Users");
  final DatabaseReference _lastChatRef = FirebaseDatabase.instance.ref("LastChat");

  Map<String, dynamic>? currentUserData;
  Map<String, dynamic>? _selectedChat;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "Recent";

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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.mode_edit_outline),
            color: Colors.black,
            tooltip: "New Chat",
            iconSize: 20,
            onPressed: _showUserListDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            color: Colors.black,
            tooltip: "Logout",
            iconSize: 20,
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
                width: isLargeScreen ? 320 : constraints.maxWidth,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Search chats...",
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 16),
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Filter:",
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              const SizedBox(width: 4),
              DropdownButton<String>(
                value: _selectedFilter,
                items: const [
                  DropdownMenuItem(value: "Recent", child: Text("Recent", style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: "Unread", child: Text("Unread", style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: "All", child: Text("All", style: TextStyle(fontSize: 12))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  }
                },
                underline: const SizedBox(),
                iconSize: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(bool isLargeScreen) {
    return StreamBuilder(
      stream: _lastChatRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, dynamic> lastChats =
        Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        Map<String, Map<String, dynamic>> uniqueChats = {};

        for (var entry in lastChats.entries) {
          List<String> ids = entry.key.split("_");
          if (ids.contains(widget.currentUserId)) {
            String chatPartnerId = ids.first == widget.currentUserId ? ids.last : ids.first;
            if (!uniqueChats.containsKey(chatPartnerId)) {
              uniqueChats[chatPartnerId] = Map<String, dynamic>.from(entry.value);
            }
          }
        }

        List<Map<String, dynamic>> chatList = uniqueChats.values.toList();

        if (_selectedFilter == "Unread") {
          chatList = chatList.where((chat) => chat['messageStatus'] == "Unread").toList();
        } else if (_selectedFilter == "Recent") {
          chatList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        }

        if (_searchQuery.isNotEmpty) {
          chatList = chatList.where((chat) {
            bool isMe = chat['sentID'] == widget.currentUserId;
            String chatUserName = isMe ? (chat['receiverName'] ?? "User") : (chat['senderName'] ?? "User");
            return chatUserName.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (chatList.isEmpty) {
          return const Center(
            child: Text(
              "No chats found.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          itemCount: chatList.length,
          itemBuilder: (context, index) {
            var chat = chatList[index];
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(chatUserImage),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatUserName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            chat['message'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnread ? Colors.black : Colors.grey[700],
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          chat['time'],
                          style: const TextStyle(fontSize: 10, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        if (isUnread)
                          const Icon(Icons.circle, color: Colors.black, size: 8),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatDetailOrPlaceholder() {
    if (_selectedChat == null) {
      return const Center(
        child: Text(
          "Welcome to Open-Square!!\nSelect a conversation or start a new one.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      );
    }
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

  void _showUserListDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: TextField(
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Search users...",
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                    if (!userSnapshot.hasData ||
                        userSnapshot.data!.snapshot.value == null) {
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
                              radius: 16,
                              backgroundImage: NetworkImage(
                                user['image'] ??
                                    "https://ui-avatars.com/api/?name=${user['name'] ?? "User"}",
                              ),
                            ),
                            title: Text(
                              user['name'] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
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
}
