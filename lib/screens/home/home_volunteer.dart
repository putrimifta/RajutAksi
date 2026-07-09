import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../event/event_detail_screen.dart';
import '../event/all_featured_events_screen.dart';

class HomeVolunteerScreen extends StatefulWidget {
  const HomeVolunteerScreen({super.key});

  @override
  State<HomeVolunteerScreen> createState() => _HomeVolunteerScreenState();
}

class _HomeVolunteerScreenState extends State<HomeVolunteerScreen> {
  String _category = 'Semua';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late Future<List<EventItem>> _future;
  final _categories = ['Semua', 'Lingkungan', 'Pendidikan', 'Kesehatan', 'Sosial'];

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchEvents(category: _category);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = SupabaseService.instance.fetchEvents(category: _category);
    });
  }

  List<EventItem> _applySearch(List<EventItem> events) {
    if (_searchQuery.trim().isEmpty) return events;
    final q = _searchQuery.toLowerCase();
    return events.where((e) {
      final title = e.title.toLowerCase();
      final location = e.location.toLowerCase();
      final category = e.categoryLabel.toLowerCase();
      return title.contains(q) || location.contains(q) || category.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = SupabaseService.instance.currentProfile;
    final name = profile?.fullName.split(' ').first ?? 'Sahabat';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
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
                const Icon(Icons.notifications_none, color: AppColors.textDark),
              ],
            ),
            const SizedBox(height: 16),
            Text('Halo, $name!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                final count = _applySearch(snap.data ?? []).length;
                return RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    children: [
                      TextSpan(text: '$count kegiatan ', style: const TextStyle(color: AppColors.primary)),
                      const TextSpan(text: 'sedang menunggu'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari aksi kebaikan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = c == _category;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _category = c);
                      _reload();
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Unggulan Untukmu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllFeaturedEventsScreen())),
                  child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: FutureBuilder<List<EventItem>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final events = _applySearch(snap.data!);
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty ? 'Tidak ada hasil untuk "$_searchQuery"' : 'Belum ada kegiatan di kategori ini',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => FeaturedEventCard(event: events[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Agenda Terdekat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<EventItem>>(
              future: _future,
              builder: (context, snap) {
                final events = _applySearch(snap.data ?? []);
                final upcoming = events.isNotEmpty ? events.first : null;
                if (upcoming == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upcoming.eventDate != null
                            ? DateFormat("EEEE, HH:mm 'WIB'", 'id_ID').format(upcoming.eventDate!)
                            : 'Segera',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(upcoming.title,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.people_alt_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text('${upcoming.filledCount} Relawan lainnya ikut serta',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: upcoming.id))),
                          child: const Text('Lihat Detail'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}