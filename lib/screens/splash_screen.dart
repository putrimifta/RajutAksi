import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/supabase_service.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final service = SupabaseService.instance;
    if (service.isLoggedIn) {
      await service.loadCurrentProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Foto latar asli, bukan lagi lingkaran-lingkaran kosong
          Image.network(
            'https://images.unsplash.com/photo-1565803974275-dccd2f933cbb?auto=format&fit=crop&w=1200&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(color: AppColors.primaryDark),
          ),
          // Gradasi warna brand di atas foto supaya logo & teks tetap jelas terbaca
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark.withOpacity(0.75),
                  AppColors.primaryDark.withOpacity(0.55),
                  AppColors.primaryDark.withOpacity(0.85),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.public, color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 20),
                const Text('RajutAksi',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Langkah kecil untuk aksi nyata dunia.',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Container(width: 40, height: 3, color: Colors.white),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: i == 0 ? Colors.white : Colors.white38, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('COLLECTIVE PROGRESS',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1.2, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
