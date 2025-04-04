import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final Map<String, dynamic>? currentUserData;
  final String groupName;
  final String? groupLogo;
  const GroupDetailsScreen({Key? key, required this.groupId, required this.currentUserId, required this.currentUserData, required this.groupName, this.groupLogo}) : super(key: key);
  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  Map<String, dynamic> groupData = {};
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }
  Future<void> _loadGroupData() async {
    DatabaseEvent event = await FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).once();
    if (event.snapshot.value != null) {
      setState(() {
        groupData = Map<String, dynamic>.from(event.snapshot.value as Map);
        loading = false;
      });
    }
  }
  void _toggleMemberAdmin(int index) {
    List<dynamic> members = groupData["members"] ?? [];
    String current = members[index]["admin"] ?? "false";
    members[index]["admin"] = current == "true" ? "false" : "true";
    FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).update({"members": members});
    setState(() {
      groupData["members"] = members;
    });
  }
  void _toggleGroupAccess(String key) {
    String current = groupData[key] ?? "false";
    groupData[key] = current == "true" ? "false" : "true";
    FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).update({key: groupData[key]});
    setState(() {});
  }
  void _openChat(Map member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserData?['name'] ?? "User",
          currentUserImage: widget.currentUserData?['image'] ?? "https://ui-avatars.com/api/?name=User",
          currentUserFcmToken: widget.currentUserData?['fcmToken'] ?? "",
          currentUserAbout: widget.currentUserData?['about'] ?? "",
          currentUserPhone: widget.currentUserData?['number'] ?? "",
          chatUserId: member["id"] ?? "",
          chatUserName: member["name"] ?? "",
          chatUserImage: member["image"] ?? "https://ui-avatars.com/api/?name=${Uri.encodeComponent(member["name"] ?? "User")}",
          chatUserToken: member["deviceToken"] ?? "",
          chatUserAbout: member["about"] ?? "",
          chatUserPhone: member["phoneno"] ?? "",
        ),
      ),
    );
  }
  Widget _buildAccessToggle(String title, String key, String currentValue) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: DropdownButton<String>(
          value: currentValue,
          underline: SizedBox(),
          items: <String>["true", "false"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value == "true" ? "Enabled" : "Disabled", style: TextStyle(color: value == "true" ? Colors.green : Colors.red)),
            );
          }).toList(),
          onChanged: widget.currentUserId == groupData["adminId"]
              ? (val) {
            groupData[key] = val!;
            FirebaseDatabase.instance.ref("GroupChat").child(widget.groupId).update({key: val});
            setState(() {});
          }
              : null,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text("Group Details", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey.shade200,
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.groupLogo ?? "https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.groupName)}"),
              ),
              SizedBox(height: 12),
              Text(widget.groupName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 16),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  title: Text("Admin: ${groupData["adminName"] ?? "Unknown"}", style: TextStyle(fontSize: 16)),
                  trailing: widget.currentUserId == groupData["adminId"]
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () => _toggleGroupAccess("editAccess"),
                    child: Text("Toggle Edit", style: TextStyle(fontSize: 14, color: Colors.white)),
                  )
                      : SizedBox(),
                ),
              ),
              _buildAccessToggle("Add Member Access", "addmemberacccess", groupData["addmemberacccess"] ?? "false"),
              _buildAccessToggle("Send Message Access", "sendmessageacccess", groupData["sendmessageacccess"] ?? "false"),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Members", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
              ListView.separated(
                separatorBuilder: (context, index) => Divider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: (groupData["members"] as List<dynamic>).length,
                itemBuilder: (context, index) {
                  var member = groupData["members"][index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(member["image"] != "" ? member["image"] : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(member["name"])}"),
                    ),
                    title: Text(member["name"] ?? "Unknown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text(member["about"] ?? "", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    trailing: (widget.currentUserId == groupData["adminId"] || (groupData["editAccess"] ?? "false") == "true")
                        ? DropdownButton<String>(
                      value: member["admin"] ?? "false",
                      underline: SizedBox(),
                      items: <String>["true", "false"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == "true" ? "Admin" : "User",
                              style: TextStyle(color: value == "true" ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        _toggleMemberAdmin(index);
                      },
                    )
                        : null,
                    onTap: () => _openChat(member),
                  );
                },
              ),
              SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }
}
