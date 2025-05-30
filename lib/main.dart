import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport_app/screens/HomePage.dart';
import 'package:transport_app/screens/admin_screen.dart';
import 'package:transport_app/screens/login_screen.dart';
import 'package:transport_app/screens/signup_screen.dart';
import 'package:transport_app/screens/welcome_screen.dart';
import 'package:transport_app/services/local_storage_service.dart';
import 'package:transport_app/providers/ticket_provider.dart';
import 'package:transport_app/screens/splash_screen.dart';
import 'package:transport_app/providers/ThemeProvider.dart'; // <-- Ajout pour ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await LocalStorageService.createAdminUser();
  debugPrintRebuildDirtyWidgets = false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // <-- Ajout
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport App',
      themeMode: themeProvider.themeMode, // <-- Gère dark/light
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeAnimationDuration: const Duration(milliseconds: 300),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminScreen(),
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
