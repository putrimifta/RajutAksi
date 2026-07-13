import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../review/rate_review_screen.dart';

/// Halaman ini dipakai Organisasi untuk melihat siapa saja yang mendaftar
/// sebagai relawan di event miliknya, lalu menyetujui/menolak, dan
/// menandai selesai setelah kegiatan berlangsung (supaya relawan bisa cetak sertifikat).
class ManageRegistrationsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const ManageRegistrationsScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  State<ManageRegistrationsScreen> createState() => _ManageRegistrationsScreenState();
}

class _ManageRegistrationsScreenState extends State<ManageRegistrationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'Semua';
  final _filters = ['Semua', 'Menunggu', 'Disetujui', 'Selesai', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = SupabaseService.instance.fetchEventRegistrations(widget.eventId);
  }

  Future<void> _updateStatus(String registrationId, String status) async {
    try {
      await SupabaseService.instance.updateRegistrationStatus(registrationId, status);
      setState(_load);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Relawan')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(widget.eventTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tinjau dan kelola relawan yang mendaftar pada event ini.', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    final selected = f == _filter;
                    return ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
                  var items = snap.data!;
                  if (_filter != 'Semua') {
                    final target = {'Menunggu': 'pending', 'Disetujui': 'approved', 'Selesai': 'completed', 'Ditolak': 'rejected'}[_filter];
                    items = items.where((e) => e['status'] == target).toList();
                  }
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('Belum ada relawan di kategori ini.', style: TextStyle(color: AppColors.textGrey))),
                    );
                  }
                  return Column(children: items.map((r) => _RegistrationCard(data: r, onUpdate: _updateStatus, eventId: widget.eventId, eventTitle: widget.eventTitle)).toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(String registrationId, String status) onUpdate;
  final String eventId;
  final String eventTitle;
  const _RegistrationCard({required this.data, required this.onUpdate, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    final volunteer = data['volunteer'] as Map<String, dynamic>?;
    final name = volunteer?['full_name'] ?? 'Relawan';
    final email = volunteer?['email'] ?? '';
    final phone = volunteer?['phone'];
    final avatar = volunteer?['avatar_url'];
    final volunteerId = volunteer?['id']?.toString() ?? '';
    final status = data['status'] as String? ?? 'pending';
    final registrationId = data['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(url: avatar, name: name, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    if (phone != null && phone.toString().isNotEmpty)
                      Text(phone.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              AppBadge(text: _statusLabel(status), color: _statusColor(status)),
            ],
          ),
          const SizedBox(height: 12),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdate(registrationId, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onUpdate(registrationId, 'approved'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Setujui'),
                  ),
                ),
              ],
            )
          else if (status == 'approved')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onUpdate(registrationId, 'completed'),
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Tandai Selesai (relawan bisa cetak sertifikat)'),
              ),
            )
          else if (status == 'completed')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RateReviewScreen(
                    eventId: eventId,
                    eventTitle: eventTitle,
                    revieweeId: volunteerId,
                    revieweeName: name,
                    revieweeAvatar: avatar,
                  ),
                )),
                icon: const Icon(Icons.star_outline_rounded, size: 16),
                label: const Text('Beri Ulasan Relawan Ini'),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pendaftaran relawan ini sudah ditolak.',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Disetujui';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }
}
