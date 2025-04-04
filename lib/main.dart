import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:open_square/SplashScreen.dart';
import 'firebase_options.dart';
import 'register.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF004474);
const Color secondaryColor = Color(0xFF660000);
const Color accentColor = Color(0xFFf2ca5c);
const Color lightColor = Colors.white;
const Color backgroundColor = Color(0xFFfbf5de);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open-Square',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: secondaryColor,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: backgroundColor,
          onBackground: Colors.black,
          surface: lightColor,
          onSurface: Colors.black,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
