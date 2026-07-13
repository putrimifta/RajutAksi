import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/reset_password_screen.dart';

/// Key global supaya kita bisa navigasi dari luar widget tree (dipakai saat
/// mendeteksi event "password recovery" dari Supabase Auth).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Dengarkan perubahan status auth. Ketika user klik link reset password
  // dari email, Supabase memicu event passwordRecovery -> arahkan ke halaman
  // "Buat Kata Sandi Baru".
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
    }
  });

  runApp(const RajutAksiApp());
}

class RajutAksiApp extends StatelessWidget {
  const RajutAksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'RajutAksi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
