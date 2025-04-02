import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_square/register.dart';
import 'message.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  Future<void> _checkUserAuthentication() async {
    await Future.delayed(const Duration(seconds: 3));

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(currentUserId: uid),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: MediaQuery.of(context).size.height * 0.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                const Text(
                  "From",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/logo2.png',
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
