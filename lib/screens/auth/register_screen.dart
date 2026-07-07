import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../home/home_shell.dart';

class _RoleOption {
  final String value;
  final String label;
  final String desc;
  final IconData icon;
  _RoleOption(this.value, this.label, this.desc, this.icon);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Multi-role: user boleh memilih lebih dari satu peran sekaligus
  final Set<String> _selectedRoles = {};
  bool _loading = false;
  String? _error;

  final _roles = [
    _RoleOption(AppRole.relawan, 'Relawan', 'Ikut serta dalam aksi nyata di lapangan.', Icons.volunteer_activism_outlined),
    _RoleOption(AppRole.organisasi, 'Organisasi', 'Kelola proyek dan rekrut kontributor.', Icons.apartment_outlined),
    _RoleOption(AppRole.sponsor, 'Sponsor', 'Dukung inisiatif sosial melalui pendanaan.', Icons.volunteer_activism),
  ];

  void _toggleRole(String value) {
    setState(() {
      if (_selectedRoles.contains(value)) {
        _selectedRoles.remove(value);
      } else {
        _selectedRoles.add(value);
      }
    });
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Lengkapi semua data terlebih dahulu.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }
    if (_selectedRoles.isEmpty) {
      setState(() => _error = 'Pilih minimal satu peran.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.signUp(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        roles: _selectedRoles.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (r) => false);
    } catch (e) {
      setState(() => _error = 'Registrasi gagal: $e');
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Gabung Bersama Kami', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Lengkapi data diri Anda untuk mulai berkontribusi pada perubahan positif.',
                  style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 20),
              const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'John Doe')),
              const SizedBox(height: 14),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'email@contoh.com'),
              ),
              const SizedBox(height: 14),
              const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
              const SizedBox(height: 14),
              const Text('Konfirmasi Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
              const SizedBox(height: 20),
              const Text('Pilih Peran Anda', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Kamu bisa memilih lebih dari satu peran, misalnya Relawan sekaligus Sponsor.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
              const SizedBox(height: 12),
              ..._roles.map((r) {
                final selected = _selectedRoles.contains(r.value);
                return GestureDetector(
                  onTap: () => _toggleRole(r.value),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: Icon(r.icon, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              const SizedBox(height: 2),
                              Text(r.desc, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftar'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? ', style: TextStyle(color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('Masuk di sini', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
