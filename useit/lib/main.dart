import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'Pages/Scan.dart';
import 'package:useit/Pages/Wallet.dart';
import 'package:useit/Pages/home.dart';

class AddCardPage extends StatelessWidget {
  const AddCardPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Add Card Manually')));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tpfhpmvwkoifggiqvarl.supabase.co',
    publishableKey: 'sb_publishable_zd84an_yWdq7EipqTdPbcA_Ir0jJBix',
  );

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
