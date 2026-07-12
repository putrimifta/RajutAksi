import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../chat/chat_detail_screen.dart';

/// Dipakai Organisasi untuk melihat & menindaklanjuti tawaran sponsor yang
/// masuk ke event miliknya: menerima, menolak, atau chat langsung dengan
/// sponsor untuk negosiasi lebih lanjut sebelum memutuskan.
class ManageSponsorshipsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const ManageSponsorshipsScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  State<ManageSponsorshipsScreen> createState() => _ManageSponsorshipsScreenState();
}

class _ManageSponsorshipsScreenState extends State<ManageSponsorshipsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'Semua';
  final _filters = ['Semua', 'Menunggu', 'Diterima', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = SupabaseService.instance.fetchEventSponsorships(widget.eventId);
  }

  Future<void> _updateStatus(String sponsorshipId, String status) async {
    try {
      await SupabaseService.instance.updateSponsorshipStatus(sponsorshipId, status);
      setState(_load);
      if (mounted && status == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tawaran diterima! Dana otomatis tercatat pada progres event.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    }
  }

  Future<void> _chatWithSponsor(String sponsorId, String sponsorName, String? sponsorAvatar) async {
    try {
      final conversationId = await SupabaseService.instance.getOrCreateConversation(sponsorId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatDetailScreen(conversationId: conversationId, otherName: sponsorName, otherAvatar: sponsorAvatar),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Sponsor')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(widget.eventTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tinjau tawaran sponsor, chat untuk negosiasi, lalu terima atau tolak.', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
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
                    final target = {'Menunggu': 'pending', 'Diterima': 'accepted', 'Ditolak': 'rejected'}[_filter];
                    items = items.where((e) => e['status'] == target).toList();
                  }
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('Belum ada tawaran sponsor di kategori ini.', style: TextStyle(color: AppColors.textGrey))),
                    );
                  }
                  return Column(children: items.map((s) => _SponsorOfferCard(data: s, onUpdate: _updateStatus, onChat: _chatWithSponsor)).toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SponsorOfferCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(String id, String status) onUpdate;
  final void Function(String sponsorId, String name, String? avatar) onChat;
  const _SponsorOfferCard({required this.data, required this.onUpdate, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final sponsor = data['sponsor'] as Map<String, dynamic>?;
    final name = sponsor?['full_name'] ?? 'Sponsor';
    final email = sponsor?['email'] ?? '';
    final avatar = sponsor?['avatar_url'];
    final sponsorId = sponsor?['id']?.toString() ?? '';
    final status = data['status'] as String? ?? 'pending';
    final amount = (data['amount'] ?? 0).toDouble();
    final message = data['message'] as String? ?? '';
    final createdAt = DateTime.tryParse(data['created_at'] ?? '');
    final sponsorshipId = data['id'].toString();

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
                  ],
                ),
              ),
              AppBadge(text: _statusLabel(status), color: _statusColor(status)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nilai Tawaran', style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                Text(formatRupiahFull(amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ],
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"$message"', style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey, fontStyle: FontStyle.italic)),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text('Diajukan ${DateFormat('d MMM y', 'id_ID').format(createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onChat(sponsorId, name, avatar),
                  icon: const Icon(Icons.chat_bubble_outline, size: 15),
                  label: const Text('Chat', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              if (status == 'pending') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdate(sponsorshipId, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    icon: const Icon(Icons.close, size: 15),
                    label: const Text('Tolak', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onUpdate(sponsorshipId, 'accepted'),
                    icon: const Icon(Icons.check, size: 15),
                    label: const Text('Terima', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }
}
