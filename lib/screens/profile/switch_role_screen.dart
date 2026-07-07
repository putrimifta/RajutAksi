import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../home/home_shell.dart';

class _RoleInfo {
  final String value;
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final List<String> tags;
  _RoleInfo(this.value, this.label, this.desc, this.icon, this.color, this.tags);
}

/// Screen ini mendukung dua hal sekaligus:
/// 1. Toggle untuk MENGAKTIFKAN/MENONAKTIFKAN kepemilikan sebuah peran (multi-role)
/// 2. Memilih salah satu peran yang aktif saat ini untuk menentukan tampilan Home
class SwitchRoleScreen extends StatefulWidget {
  const SwitchRoleScreen({super.key});

  @override
  State<SwitchRoleScreen> createState() => _SwitchRoleScreenState();
}

class _SwitchRoleScreenState extends State<SwitchRoleScreen> {
  late Set<String> _ownedRoles;
  late String _selectedActive;
  bool _loading = false;

  final _roles = [
    _RoleInfo(AppRole.relawan, 'Relawan', 'Cari aksi sosial, bergabung dalam komunitas, dan mulai berdampak langsung.',
        Icons.volunteer_activism_outlined, AppColors.primary, ['Aksi Lokal', 'Komunitas']),
    _RoleInfo(AppRole.organisasi, 'Organisasi', 'Kelola proyek SDG, rekrut relawan, dan publikasikan laporan dampak Anda.',
        Icons.apartment_outlined, const Color(0xFF9C6B2E), ['Manajemen Proyek', 'SDG Tracking']),
    _RoleInfo(AppRole.sponsor, 'Sponsor', 'Berikan pendanaan, dukung inisiatif berkelanjutan, dan tingkatkan profil ESG.',
        Icons.account_balance_outlined, AppColors.primaryDark, ['Hibah & Dana', 'ESG Impact']),
  ];

  @override
  void initState() {
    super.initState();
    final p = SupabaseService.instance.currentProfile;
    _ownedRoles = {...(p?.roles ?? [AppRole.relawan])};
    _selectedActive = p?.activeRole ?? AppRole.relawan;
  }

  void _toggleOwned(String role) {
    setState(() {
      if (_ownedRoles.contains(role)) {
        if (_ownedRoles.length == 1) return; // minimal harus punya 1 peran
        _ownedRoles.remove(role);
        if (_selectedActive == role) {
          _selectedActive = _ownedRoles.first;
        }
      } else {
        _ownedRoles.add(role);
      }
    });
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.updateRoles(_ownedRoles.toList());
      await SupabaseService.instance.switchActiveRole(_selectedActive);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (r) => false);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('RajutAksi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Peran Anda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Aktifkan lebih dari satu peran dan pilih salah satu sebagai tampilan utama Anda saat ini.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              const SizedBox(height: 18),
              ..._roles.map((r) {
                final owned = _ownedRoles.contains(r.value);
                final isActive = _selectedActive == r.value;
                return GestureDetector(
                  onTap: owned ? () => setState(() => _selectedActive = r.value) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: isActive ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: r.color.withOpacity(0.15), child: Icon(r.icon, color: r.color)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                                  Text(r.desc, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Switch(value: owned, activeThumbColor: AppColors.primary, onChanged: (_) => _toggleOwned(r.value)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: r.tags
                              .map((t) => Chip(
                                    label: Text(t, style: const TextStyle(fontSize: 10.5)),
                                    backgroundColor: AppColors.background,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                        if (owned && isActive) ...[
                          const SizedBox(height: 8),
                          Row(children: const [
                            Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Sedang aktif', style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ]),
                        ] else if (owned) ...[
                          const SizedBox(height: 8),
                          const Text('Ketuk untuk jadikan peran aktif', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loading ? null : _confirm,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(_loading ? 'Menyimpan...' : 'Ganti Peran Sekarang'),
              ),
              const SizedBox(height: 12),
              const Text('Mengubah peran akan menyesuaikan tampilan dashboard dan fitur yang tersedia sesuai dengan kebutuhan spesifik Anda.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 11.5)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
