import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Masukkan format email yang valid.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // redirectTo memakai origin saat ini supaya link email membawa kembali
      // ke aplikasi (bekerja baik untuk versi web / localhost).
      final redirectTo = Uri.base.origin;
      await SupabaseService.instance.sendPasswordResetEmail(email, redirectTo: redirectTo);
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = 'Gagal mengirim email reset: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lupa Kata Sandi')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.lock_reset_outlined, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 18),
              const Text('Reset Kata Sandi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Masukkan email akun kamu. Kami akan mengirimkan link untuk membuat kata sandi baru.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (!_sent) ...[
                const Text('Alamat Email', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'nama@email.com', prefixIcon: Icon(Icons.mail_outline)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _send,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Link Reset'),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 32),
                      const SizedBox(height: 10),
                      Text(
                        'Email berhasil dikirim ke ${_emailCtrl.text.trim()}. Buka email tersebut dan klik link untuk membuat kata sandi baru.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.success, fontSize: 12.5),
                      ),
                      const SizedBox(height: 14),
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kembali ke Login')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
