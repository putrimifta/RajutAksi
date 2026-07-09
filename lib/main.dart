import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const RajutAksiApp());
}

class RajutAksiApp extends StatelessWidget {
  const RajutAksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RajutAksi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
