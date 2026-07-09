import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../activity/activity_history_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import 'home_volunteer.dart';
import 'home_organization.dart';
import 'home_sponsor.dart';

/// HomeShell menampung bottom navigation (Home / Activity / Chat / Profile).
/// Tab "Home" akan menampilkan layout berbeda tergantung `active_role` user
/// (relawan / organisasi / sponsor) — walau user boleh punya banyak peran sekaligus.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildHome() {
    final role = SupabaseService.instance.currentProfile?.activeRole ?? AppRole.relawan;
    switch (role) {
      case AppRole.organisasi:
        return const HomeOrganizationScreen();
      case AppRole.sponsor:
        return const HomeSponsorScreen();
      default:
        return const HomeVolunteerScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = SupabaseService.instance.currentProfile?.activeRole ?? AppRole.relawan;
    final pages = [
      _buildHome(),
      // ValueKey berdasarkan role -> memaksa Activity dibuat ulang (initState jalan lagi)
      // setiap kali peran aktif berganti, supaya datanya selalu sesuai peran terbaru.
      ActivityHistoryScreen(key: ValueKey('activity_$role')),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
