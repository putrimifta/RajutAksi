import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'event_detail_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = SupabaseService.instance.authUser?.id;
    _future = SupabaseService.instance.fetchEvents(organizerId: uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Event yang Dikelola'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: FutureBuilder<List<EventItem>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snap.data!;
              if (events.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SizedBox(height: 60),
                    Center(
                      child: Text(
                        'Anda belum membuat event.',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: events.length,
                itemBuilder: (context, i) => _ManagedEventCard(event: events[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ManagedEventCard extends StatelessWidget {
  final EventItem event;
  const _ManagedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDraft = event.status == 'draft';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: event.posterUrl != null
                    ? Image.network(event.posterUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        height: 140,
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.image_outlined, size: 36, color: AppColors.primary),
                      ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: AppBadge(
                  text: isDraft ? 'DRAFT' : 'BERLANGSUNG',
                  color: isDraft ? AppColors.textGrey : AppColors.primaryDark,
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(
                    text: '${event.sdgCategory}: ${event.categoryLabel}',
                    color: AppColors.primaryLight,
                    textColor: AppColors.primaryDark,
                  ),
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
                        Text(
                          event.eventDate != null ? DateFormat('d MMM y').format(event.eventDate!) : 'TBD',
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                        ),
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