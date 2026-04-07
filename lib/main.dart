import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/diagnosis_provider.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await DatabaseService.instance.database; // warm up SQLite
  runApp(
    ChangeNotifierProvider(
      create: (_) => DiagnosisProvider()..loadHistory(),
      child: const DecafiaApp(),
    ),
  );
}

class DecafiaApp extends StatelessWidget {
  const DecafiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DECAFIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C2A),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F4C2A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
