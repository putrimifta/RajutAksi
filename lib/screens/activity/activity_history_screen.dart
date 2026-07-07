import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _filter = 'Semua';
  final _filters = ['Semua', 'Diikuti', 'Dibuat', 'Disponsori'];

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.search, color: AppColors.textDark),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Riwayat Aktivitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Pantau kontribusi dan aksi sosial yang kamu ikuti.', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
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
          const SizedBox(height: 18),
          // Data contoh riwayat aktivitas (idealnya diambil dari gabungan
          // tabel registrations, events milik user, dan sponsorships)
          _ActivityCard(
            imageIcon: Icons.forest_outlined,
            statusBadge: 'Berlangsung',
            statusColor: AppColors.primary,
            title: 'Restorasi Mangrove Teluk Jakarta',
            subtitle: '24 Okt - 10 Nov 2023',
            progressLabel: 'Progress Aksi: 65%',
            progressValue: 0.65,
            trailingLabel: '12/20 Relawan',
          ),
          _ActivityCard(
            imageIcon: Icons.menu_book_outlined,
            statusBadge: 'Seleksi',
            statusColor: AppColors.accent,
            title: 'Edukasi Literasi Digital Desa',
            subtitle: 'Sukabumi, Jawa Barat',
            description: 'Pendaftaran ditutup. Tim sedang melakukan kurasi terhadap 150+ calon relawan pengajar.',
            actionLabel: 'Lihat Status Pendaftaran',
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBadge(text: 'DISPONSORI', color: AppColors.primaryLight, textColor: AppColors.primaryDark),
                    AppBadge(text: 'Selesai', color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Pangan Sehat untuk Lansia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('45 Orang terbantu', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(children: [Icon(Icons.verified_outlined, size: 14, color: AppColors.primary), SizedBox(width: 4), Text('Laporan Terverifikasi', style: TextStyle(fontSize: 12, color: AppColors.primary))]),
                    Text('Sertifikat ↓', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_task_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inisiasi: Clean Up Car Free Day', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      const Text('Draft • Terakhir diedit 2 jam lalu', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      const SizedBox(height: 2),
                      const Text('LANJUTKAN', style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData imageIcon;
  final String statusBadge;
  final Color statusColor;
  final String title;
  final String subtitle;
  final String? description;
  final String? progressLabel;
  final double? progressValue;
  final String? trailingLabel;
  final String? actionLabel;

  const _ActivityCard({
    required this.imageIcon,
    required this.statusBadge,
    required this.statusColor,
    required this.title,
    required this.subtitle,
    this.description,
    this.progressLabel,
    this.progressValue,
    this.trailingLabel,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
                child: Icon(imageIcon, size: 40, color: AppColors.primary),
              ),
              Positioned(top: 10, left: 10, child: AppBadge(text: statusBadge, color: statusColor)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ]),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description!, style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
                ],
                if (progressValue != null) ...[
                  const SizedBox(height: 12),
                  AppProgressBar(value: progressValue!),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(progressLabel ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      Text(trailingLabel ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {}, child: Text(actionLabel!)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
