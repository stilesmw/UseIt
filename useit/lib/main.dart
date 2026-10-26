import 'package:flutter/material.dart';
import 'auth_screen.dart';

// 1. Updated path using exact matching lowercase filenames
import 'pages/scan.dart'; 

// Placeholder classes marked as const layout instances
class HomeScreen extends StatelessWidget { const HomeScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home Screen'))); }
class AddCardPage extends StatelessWidget { const AddCardPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Card Manually'))); }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', 
      routes: {
        '/': (context) => const AuthScreen(),        
        '/home': (context) => const HomeScreen(),    
        '/scan': (context) => const ScanPage(), 
        '/add-card': (context) => const AddCardPage(), 
      },
    );
  }
}
