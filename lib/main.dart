import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'screens/home_screen.dart';
import 'screens/admin_import_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/update_role_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NDC95',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/admin-import': (context) => const AdminImportScreen(),
        '/update-role': (context) => const UpdateRoleScreen(),
      },
    );
  }
}

// Check if user is already signed in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    
    if (user != null) {
      return const HomeScreen();
    }
    
    return const SignInScreen();
  }
}
