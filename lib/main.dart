import 'package:flutter/material.dart';
import 'package:transport_app/screens/HomePage.dart';
import 'package:transport_app/screens/admin_screen.dart';
import 'package:transport_app/screens/login_screen.dart';
import 'package:transport_app/screens/signup_screen.dart';
import 'package:transport_app/screens/welcome_screen.dart';
import 'package:transport_app/services/local_storage_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await LocalStorageService.createAdminUser();
  debugPrintRebuildDirtyWidgets = false;

  runApp(const MyApp());
  MaterialApp(
    debugShowCheckedModeBanner: false, // ← Ceci désactive la bannière
    home: LoginScreen(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ← Ceci désactive la bannière
      title: 'Transport App',
      theme: ThemeData(
        // Vos autres paramètres de thème existants
        primarySwatch: Colors.blue,

        // Ajoutez cette partie pour personnaliser les TabBar
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Colors.white,
              width: 2.0,
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(), // Ajoutez cette ligne
        '/admin': (context) => const AdminScreen(),
      },
      onGenerateRoute: (settings) {
        // Gestion des routes dynamiques si nécessaire
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Page non trouvée'),
            ),
          ),
        );
      },
    );
  }
}