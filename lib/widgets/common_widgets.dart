import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../screens/event/event_detail_screen.dart';

/// Avatar bulat dengan fallback inisial nama jika tidak ada foto
class AppAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  const AppAvatar({super.key, this.url, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: CachedNetworkImageProvider(url!),
      );
    }
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

/// Badge kecil berwarna, contoh: "Butuh Sponsor", "Lingkungan", "Draft"
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const AppBadge({super.key, required this.text, required this.color, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Bar progress tipis dipakai untuk kuota relawan / dana sponsorship
class AppProgressBar extends StatelessWidget {
  final double value;
  const AppProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: AppColors.border,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

/// Bottom navigation umum dipakai di semua peran (Home / Activity / Chat / Profile)
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Activity'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

String formatRupiah(num value) {
  if (value >= 1000000000) {
    return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
  } else if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
  }
  return 'Rp $value';
}

/// Card event yang dikelola organisasi, dipakai di Home Organisasi & Semua Event
class ManagedEventCard extends StatelessWidget {
  final EventItem event;
  const ManagedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isDraft = event.status == 'draft';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: event.posterUrl != null
                    ? Image.network(event.posterUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 140, color: AppColors.primaryLight, child: const Icon(Icons.image_outlined, size: 36, color: AppColors.primary)),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: AppBadge(text: isDraft ? 'DRAFT' : 'BERLANGSUNG', color: isDraft ? AppColors.textGrey : AppColors.primaryDark),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(text: '${event.sdgCategory}: ${event.categoryLabel}', color: AppColors.primaryLight, textColor: AppColors.primaryDark),
                  const SizedBox(height: 8),
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text('${event.filledCount} Relawan', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ]),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(event.eventDate != null ? DateFormat('d MMM y').format(event.eventDate!) : 'TBD',
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card event unggulan, dipakai di Home Relawan & Semua Event Unggulan
class FeaturedEventCard extends StatelessWidget {
  final EventItem event;
  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: event.posterUrl != null
                      ? Image.network(event.posterUrl!, height: 110, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 110, color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 32)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: AppBadge(text: event.categoryLabel.toUpperCase(), color: AppColors.primaryDark.withOpacity(0.85)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 2),
                    Expanded(child: Text(event.location, style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 12.5)),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
                      child: const Text('Daftar Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}