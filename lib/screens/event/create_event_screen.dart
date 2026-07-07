import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  DateTime? _selectedDate;
  double _quota = 20;
  bool _needSponsor = true;
  bool _loading = false;

  final _sdgOptions = {
    'SDG 1': 'Sosial',
    'SDG 4': 'Pendidikan',
    'SDG 13': 'Lingkungan',
    'SDG 3': 'Kesehatan',
  };
  String? _selectedSdg;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _submit({required bool asDraft}) async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty || _selectedSdg == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua data terlebih dahulu.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.createEvent(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        sdgCategory: _selectedSdg!,
        categoryLabel: _sdgOptions[_selectedSdg!]!,
        eventDate: _selectedDate!,
        location: _locationCtrl.text.trim().isEmpty ? 'Lokasi belum ditentukan' : _locationCtrl.text.trim(),
        quota: _quota.round(),
        needSponsor: _needSponsor,
        asDraft: asDraft,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat event, coba lagi.')));
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
              const Text('Buat Event Aksi Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 6),
              const Text('Publikasikan gerakan sosial Anda dan temukan relawan yang tepat untuk menciptakan dampak nyata bagi SDGs.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              const SizedBox(height: 20),
              const Text('Judul Event', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Contoh: Penanaman Mangrove Pesisir Utara')),
              const SizedBox(height: 16),
              const Text('Deskripsi Aksi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Ceritakan detail aksi, tujuan, dan apa yang akan dilakukan para relawan...'),
              ),
              const SizedBox(height: 16),
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                      SizedBox(height: 6),
                      Text('Unggah Poster Event', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kategori SDG', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSdg,
                items: _sdgOptions.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text('$k — ${_sdgOptions[k]}')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSdg = v),
                decoration: const InputDecoration(hintText: 'Pilih Kategori...'),
              ),
              const SizedBox(height: 16),
              const Text('Tanggal Pelaksanaan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(hintText: 'mm/dd/yyyy', suffixIcon: Icon(Icons.calendar_today_outlined)),
              ),
              const SizedBox(height: 16),
              const Text('Lokasi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(controller: _locationCtrl, decoration: const InputDecoration(hintText: 'Cari Kota/Tempat', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kuota Relawan', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${_quota.round()} Orang', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(value: _quota, min: 5, max: 200, divisions: 39, activeColor: AppColors.primary, onChanged: (v) => setState(() => _quota = v)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Butuh Sponsor?', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Tampilkan event Anda di radar mitra korporat kami.', style: TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    Switch(value: _needSponsor, activeThumbColor: AppColors.primary, onChanged: (v) => setState(() => _needSponsor = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.primaryDark, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Tips Publikasi\nPastikan deskripsi event mencantumkan jadwal spesifik dan perlengkapan yang harus dibawa oleh relawan untuk meningkatkan tingkat kehadiran.',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _submit(asDraft: false),
                icon: const Icon(Icons.send, size: 18),
                label: Text(_loading ? 'Memublikasikan...' : 'Publikasikan Event'),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => _submit(asDraft: true),
                  child: const Text('Simpan sebagai Draft', style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
