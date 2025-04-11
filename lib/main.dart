import 'package:flutter/material.dart';
import 'package:transport_app/screens/admin_screen.dart';
import 'package:transport_app/screens/home_screen.dart';
import 'package:transport_app/screens/login_screen.dart';
import 'package:transport_app/screens/signup_screen.dart';
import 'package:transport_app/screens/welcome_screen.dart';
import 'package:transport_app/services/local_storage_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await LocalStorageService.createAdminUser();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport App',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(), // Ajoutez cette ligne
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