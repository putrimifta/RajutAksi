import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../activity/activity_history_screen.dart';
import 'edit_profile_screen.dart';
import 'switch_role_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notif = true;

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.public, color: AppColors.primary),
                SizedBox(width: 6),
                Text('RajutAksi', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              const Icon(Icons.notifications_none, color: AppColors.textDark),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                AppAvatar(url: profile?.avatarUrl, name: profile?.fullName ?? '?', radius: 48),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    child: const CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.edit, size: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(profile?.fullName ?? '-', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
          Center(child: Text(profile?.email ?? '-', style: const TextStyle(color: AppColors.textGrey, fontSize: 13))),
          const SizedBox(height: 8),
          if (profile != null)
            Center(
              child: Wrap(
                spacing: 6,
                alignment: WrapAlignment.center,
                children: profile.roles
                    .map((r) => AppBadge(
                          text: r == profile.activeRole ? '★ ${_roleLabel(r)}' : _roleLabel(r),
                          color: r == profile.activeRole ? AppColors.accent : AppColors.primaryLight,
                          textColor: r == profile.activeRole ? Colors.white : AppColors.primaryDark,
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statCard('128', 'DAYS')),
              const SizedBox(width: 10),
              Expanded(child: _statCard('42', 'ACTIVITIES')),
              const SizedBox(width: 10),
              Expanded(child: _statCard('8.4k', 'IMPACT')),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                _menuTile(Icons.edit_note_outlined, 'Edit Profile', 'Update your personal details',
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
                const Divider(height: 1, color: AppColors.border),
                _menuTile(Icons.sync_alt_outlined, 'Switch Role', 'Change to Volunteer, Organizer, or Sponsor',
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SwitchRoleScreen()))),
                const Divider(height: 1, color: AppColors.border),
                _menuTile(Icons.history_outlined, 'Action History', 'View your past contributions',
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('PREFERENCES', style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: const [Icon(Icons.notifications_outlined, color: AppColors.textDark), SizedBox(width: 10), Text('Push Notifications')]),
                Switch(value: _notif, activeThumbColor: AppColors.primary, onChanged: (v) => setState(() => _notif = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await SupabaseService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
              label: const Text('Logout Account', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'organisasi':
        return 'Organisasi';
      case 'sponsor':
        return 'Sponsor';
      default:
        return 'Relawan';
    }
  }

  Widget _statCard(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          ],
        ),
      );

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(icon, color: AppColors.primaryDark, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
        onTap: onTap,
      );
}