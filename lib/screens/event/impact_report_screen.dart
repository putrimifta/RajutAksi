import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

/// Laporan dampak sederhana untuk sponsor: menunjukkan hasil nyata dari
/// kontribusi dana mereka di sebuah event (relawan yang terlibat, progres
/// dana, status kegiatan). Dirangkum dari data yang sudah ada di database,
/// bukan laporan manual terpisah.
class ImpactReportScreen extends StatefulWidget {
  final String eventId;
  final double sponsorshipAmount;
  const ImpactReportScreen({super.key, required this.eventId, required this.sponsorshipAmount});

  @override
  State<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends State<ImpactReportScreen> {
  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final event = await SupabaseService.instance.fetchEventDetail(widget.eventId);
    final registrations = await SupabaseService.instance.fetchEventRegistrations(widget.eventId);
    final completed = registrations.where((r) => r['status'] == 'completed').length;
    final approved = registrations.where((r) => r['status'] == 'approved').length;
    return _ReportData(event: event, totalVolunteers: registrations.length, completedVolunteers: completed, approvedVolunteers: approved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Laporan Dampak')),
      body: SafeArea(
        child: FutureBuilder<_ReportData>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final data = snap.data!;
            final event = data.event;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: event.posterUrl != null
                      ? Image.network(event.posterUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 160, color: AppColors.primaryLight, child: const Icon(Icons.image_outlined, size: 40, color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                Text(event.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${event.categoryLabel} • ${event.sdgCategory}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kontribusi Anda', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(formatRupiahFull(widget.sponsorshipAmount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('dari total dana terkumpul ${formatRupiahFull(event.collectedFunding)} (target ${formatRupiahFull(event.targetFunding)})',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _statTile('Total Relawan Terlibat', '${data.totalVolunteers}', Icons.groups_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _statTile('Kegiatan Selesai Diikuti', '${data.completedVolunteers}', Icons.check_circle_outline)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statTile('Status Kegiatan', _statusLabel(event.status), Icons.event_available_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statTile(
                        'Tanggal Kegiatan',
                        event.eventDate != null ? DateFormat('d MMM y', 'id_ID').format(event.eventDate!) : '-',
                        Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryDark, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Laporan ini dirangkum otomatis dari data kegiatan real-time di RajutAksi: jumlah relawan yang mendaftar dan menyelesaikan kegiatan, serta progres dana yang terkumpul.',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'draft':
        return 'Draft';
      case 'done':
        return 'Selesai';
      default:
        return 'Berlangsung';
    }
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

class _ReportData {
  final EventItem event;
  final int totalVolunteers;
  final int completedVolunteers;
  final int approvedVolunteers;
  _ReportData({required this.event, required this.totalVolunteers, required this.completedVolunteers, required this.approvedVolunteers});
}
