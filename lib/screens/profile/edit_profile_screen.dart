import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  final List<String> _interests = [];
  bool _loading = false;
  Uint8List? _newAvatarBytes;
  bool _uploadingAvatar = false;
  final _picker = ImagePicker();

  final _availableInterests = [
    'Tanpa Kemiskinan',
    'Pendidikan Bermutu',
    'Kesehatan',
    'Lingkungan',
    'Kesetaraan Gender',
    'Air Bersih',
  ];

  @override
  void initState() {
    super.initState();
    final p = SupabaseService.instance.currentProfile;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _interests.addAll(p?.interests ?? []);
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _newAvatarBytes = bytes);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      String? avatarUrl;
      if (_newAvatarBytes != null) {
        setState(() => _uploadingAvatar = true);
        final fileName = '${const Uuid().v4()}.jpg';
        avatarUrl = await SupabaseService.instance.uploadFile(
          bucket: SupabaseConfig.avatarBucket,
          path: fileName,
          bytes: _newAvatarBytes!,
        );
        setState(() => _uploadingAvatar = false);
      }
      await SupabaseService.instance.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        interests: _interests,
        avatarUrl: avatarUrl,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text('Simpan', style: TextStyle(color: _loading ? AppColors.textGrey : AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      _newAvatarBytes != null
                          ? CircleAvatar(radius: 46, backgroundImage: MemoryImage(_newAvatarBytes!))
                          : AppAvatar(url: profile?.avatarUrl, name: profile?.fullName ?? '?', radius: 46),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(radius: 15, backgroundColor: AppColors.primary, child: const Icon(Icons.camera_alt, size: 15, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Text(
                    _uploadingAvatar ? 'Mengunggah...' : 'Ubah Foto Profil',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _nameCtrl),
              const SizedBox(height: 14),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _emailCtrl, enabled: false, decoration: const InputDecoration(suffixIcon: Icon(Icons.mail_outline))),
              const SizedBox(height: 14),
              const Text('Nomor Telepon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(prefixText: '+62  ')),
              const SizedBox(height: 14),
              const Text('Bio', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _bioCtrl, maxLength: 200, maxLines: 3),
              const SizedBox(height: 10),
              const Text('Minat Aksi (SDG)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._interests.map((i) => Chip(
                        label: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: AppColors.primary,
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onDeleted: () => setState(() => _interests.remove(i)),
                      )),
                  ActionChip(
                    label: const Text('+ Tambah'),
                    onPressed: () => _showAddInterestSheet(),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.primary),
                    labelStyle: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'Menyimpan...' : 'Simpan Perubahan')),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                  label: const Text('Hapus Akun', style: TextStyle(color: AppColors.danger)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddInterestSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: _availableInterests
              .where((i) => !_interests.contains(i))
              .map((i) => ListTile(
                    title: Text(i),
                    onTap: () {
                      setState(() => _interests.add(i));
                      Navigator.of(context).pop();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
