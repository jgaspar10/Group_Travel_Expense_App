// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- Direct imports for all pages used in routes ---
import 'pages/login_page.dart';
import 'pages/registration_page.dart';
import 'pages/home_page.dart';
import 'pages/add_trips_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// --- NEW: Reusable function to create a slide animation route ---
Route _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Animate from right to left (x-axis from 1.0 to 0.0)
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease; // A smooth animation curve

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350), // Animation speed
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Expense App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF204051),
      ),
      // We set the starting route name
      initialRoute: '/login',

      // --- MODIFIED: We use onGenerateRoute instead of the 'routes' map ---
      // onGenerateRoute gives us control over the transition animation.
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
          // The login page itself doesn't need a special animation when it first loads
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
          // Use our custom slide animation for the registration page
            return _createSlideRoute(const RegistrationPage());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/add_trip':
            return MaterialPageRoute(builder: (_) => const AddTripsPage());
          default:
          // If the route name is not found, default to login page
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
