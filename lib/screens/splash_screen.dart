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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _blob(220, AppColors.primaryLight),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _blob(70, AppColors.primaryLight.withOpacity(0.7)),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _blob(220, AppColors.primaryLight),
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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.public, color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 20),
                const Text('RajutAksi',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 10),
                Container(width: 40, height: 3, color: AppColors.primary),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
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
                          color: i == 0 ? AppColors.primary : AppColors.border, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('COLLECTIVE PROGRESS',
                    style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
