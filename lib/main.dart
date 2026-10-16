import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:krushi/AuthWrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lwhdnxajpmgrvxffykhz.supabase.co',
    anonKey: 'sb_publishable_lk5fd-878k7yPJOq6ugKEQ_YJ3T0rv-',
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KrushiMitraApp());
}

class KrushiMitraApp extends StatelessWidget {
  const KrushiMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KrushiMitra',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF087F5B),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
      ),
      home: const Authwrapper(),
    );
  }
}