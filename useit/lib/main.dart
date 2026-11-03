import 'package:flutter/material.dart';
import 'auth_screen.dart';

// 1. Updated path using exact matching lowercase filenames
import 'Pages/Scan.dart'; 
import 'package:useit/Pages/Wallet.dart';
import 'package:useit/Pages/home.dart';



// Placeholder classes marked as const layout instances
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
        '/wallet': (context) => WalletPage(session: walletSession),
      },
    );
  }
}
