import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_square/message.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'BottomNavBar.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _aboutController =
  TextEditingController(text: "Hey There! I am using Open-Square");
  final _formKey = GlobalKey<FormState>();
  File? _image;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("Users");
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid uuid = const Uuid();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(String userId) async {
    final ref = _storage.ref().child("profile_images/$userId.jpg");
    await ref.putFile(_image!);
    return await ref.getDownloadURL();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match!")),
        );
        return;
      }
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        String uid = userCredential.user!.uid;

        String imageUrl =
            "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text)}";
        if (_image != null) {
          imageUrl = await _uploadImage(uid);
        }

        String platform = "";
        if (kIsWeb) {
          platform = "Web";
        } else if (Platform.isAndroid) {
          platform = "Android";
        } else if (Platform.isIOS) {
          platform = "iOS";
        } else {
          platform = "Unknown";
        }

        Map<String, String> userData = {
          "id": uid,
          "name": _nameController.text,
          "number": _numberController.text,
          "email": _emailController.text,
          "about": _aboutController.text,
          "image": imageUrl,
          "platform": platform,
          "incall": "false",
          "isonline": "online",
        };

        await _dbRef.child(uid).set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar(currentUserId: uid)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool obscureText = false,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.black87),
        prefixIcon: Icon(icon, color: Colors.grey, size: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.grey, width: 0.8),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (value) => value!.isEmpty ? "Please enter your $label" : null,
      style: const TextStyle(fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : NetworkImage("https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text)}")
                      as ImageProvider,
                      child: _image == null
                          ? const Icon(Icons.camera_alt, size: 24, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, "Name", Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField(_numberController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildTextField(_emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildTextField(_passwordController, "Password", Icons.lock, obscureText: true),
                  const SizedBox(height: 12),
                  _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock, obscureText: true),
                  const SizedBox(height: 12),
                  _buildTextField(_aboutController, "About", Icons.info),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
