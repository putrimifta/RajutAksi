import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';

/// Dipakai untuk 2 mode sekaligus:
/// - Mode BUAT: [existingEvent] null -> judul "Buat Event Aksi Baru"
/// - Mode EDIT: [existingEvent] diisi -> form terisi otomatis, ada tombol Hapus
class CreateEventScreen extends StatefulWidget {
  final EventItem? existingEvent;
  const CreateEventScreen({super.key, this.existingEvent});

  bool get isEditing => existingEvent != null;

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
  bool _deleting = false;
  Uint8List? _posterBytes;
  String? _existingPosterUrl;
  bool _uploadingPoster = false;
  String? _titleError;
  String? _descError;
  String? _dateError;

  final _sdgOptions = {
    'SDG 1': 'Sosial',
    'SDG 4': 'Pendidikan',
    'SDG 13': 'Lingkungan',
    'SDG 3': 'Kesehatan',
  };
  String? _selectedSdg;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final e = widget.existingEvent;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location == 'Lokasi belum ditentukan' ? '' : e.location;
      _quota = e.quota.toDouble().clamp(5, 200);
      _needSponsor = e.needSponsor;
      _selectedSdg = _sdgOptions.containsKey(e.sdgCategory) ? e.sdgCategory : null;
      _existingPosterUrl = e.posterUrl;
      if (e.eventDate != null) {
        _selectedDate = e.eventDate;
        _dateCtrl.text = '${e.eventDate!.month.toString().padLeft(2, '0')}/${e.eventDate!.day.toString().padLeft(2, '0')}/${e.eventDate!.year}';
      }
    }
  }

  Future<void> _pickPoster() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _posterBytes = bytes);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
        _dateCtrl.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  bool _validate() {
    setState(() {
      _titleError = _titleCtrl.text.trim().length < 5 ? 'Judul minimal 5 karakter.' : null;
      _descError = _descCtrl.text.trim().length < 20 ? 'Deskripsi minimal 20 karakter agar calon relawan paham konteksnya.' : null;
      _dateError = _selectedDate == null ? 'Pilih tanggal pelaksanaan.' : null;
    });
    if (_selectedSdg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori SDG terlebih dahulu.')));
      return false;
    }
    return _titleError == null && _descError == null && _dateError == null;
  }

  Future<void> _submit({required bool asDraft}) async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      String? posterUrl = _existingPosterUrl;
      if (_posterBytes != null) {
        setState(() => _uploadingPoster = true);
        final fileName = '${const Uuid().v4()}.jpg';
        posterUrl = await SupabaseService.instance.uploadFile(
          bucket: SupabaseConfig.posterBucket,
          path: fileName,
          bytes: _posterBytes!,
        );
        setState(() => _uploadingPoster = false);
      }

      if (widget.isEditing) {
        await SupabaseService.instance.updateEvent(
          eventId: widget.existingEvent!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          sdgCategory: _selectedSdg!,
          categoryLabel: _sdgOptions[_selectedSdg!]!,
          eventDate: _selectedDate!,
          location: _locationCtrl.text.trim().isEmpty ? 'Lokasi belum ditentukan' : _locationCtrl.text.trim(),
          quota: _quota.round(),
          needSponsor: _needSponsor,
          posterUrl: posterUrl,
          status: asDraft ? 'draft' : 'published',
        );
      } else {
        await SupabaseService.instance.createEvent(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          sdgCategory: _selectedSdg!,
          categoryLabel: _sdgOptions[_selectedSdg!]!,
          eventDate: _selectedDate!,
          location: _locationCtrl.text.trim().isEmpty ? 'Lokasi belum ditentukan' : _locationCtrl.text.trim(),
          quota: _quota.round(),
          needSponsor: _needSponsor,
          posterUrl: posterUrl,
          asDraft: asDraft,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan event: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event Ini?'),
        content: const Text('Semua data pendaftaran relawan dan tawaran sponsor yang terkait dengan event ini akan ikut terhapus permanen. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await SupabaseService.instance.deleteEvent(widget.existingEvent!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus event: $e')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RajutAksi'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: _deleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                  : const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _deleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.isEditing ? 'Edit Event' : 'Buat Event Aksi Baru',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 6),
              Text(
                widget.isEditing
                    ? 'Perbarui informasi event kamu. Perubahan langsung terlihat oleh calon relawan & sponsor.'
                    : 'Publikasikan gerakan sosial Anda dan temukan relawan yang tepat untuk menciptakan dampak nyata bagi SDGs.',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text('Judul Event', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                onChanged: (_) => setState(() => _titleError = null),
                decoration: InputDecoration(hintText: 'Contoh: Penanaman Mangrove Pesisir Utara', errorText: _titleError),
              ),
              const SizedBox(height: 16),
              const Text('Deskripsi Aksi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                onChanged: (_) => setState(() => _descError = null),
                decoration: InputDecoration(
                  hintText: 'Ceritakan detail aksi, tujuan, dan apa yang akan dilakukan para relawan...',
                  errorText: _descError,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickPoster,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _posterBytes != null
                      ? Image.memory(_posterBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : (_existingPosterUrl != null
                          ? Image.network(_existingPosterUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                                  SizedBox(height: 6),
                                  Text('Unggah Poster Event', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kategori SDG', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSdg,
                items: _sdgOptions.keys.map((k) => DropdownMenuItem(value: k, child: Text('$k — ${_sdgOptions[k]}'))).toList(),
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
                decoration: InputDecoration(hintText: 'mm/dd/yyyy', suffixIcon: const Icon(Icons.calendar_today_outlined), errorText: _dateError),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _submit(asDraft: false),
                icon: const Icon(Icons.send, size: 18),
                label: Text(_uploadingPoster
                    ? 'Mengunggah foto...'
                    : (_loading ? 'Menyimpan...' : (widget.isEditing ? 'Simpan Perubahan' : 'Publikasikan Event'))),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => _submit(asDraft: true),
                  child: Text(widget.isEditing ? 'Simpan sebagai Draft' : 'Simpan sebagai Draft', style: const TextStyle(color: AppColors.primary)),
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
