import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'event_detail_screen.dart';

const int _pageSize = 8;

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final _scrollCtrl = ScrollController();
  final List<EventItem> _events = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _resetAndLoad();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _resetAndLoad() async {
    setState(() {
      _events.clear();
      _page = 0;
      _hasMore = true;
      _initialLoading = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final uid = SupabaseService.instance.authUser?.id;
      final result = await SupabaseService.instance.fetchEvents(organizerId: uid, page: _page, pageSize: _pageSize);
      setState(() {
        _events.addAll(result);
        _page++;
        _hasMore = result.length == _pageSize;
      });
    } finally {
      if (mounted) setState(() {
        _loading = false;
        _initialLoading = false;
      });
    }
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
          onRefresh: _resetAndLoad,
          child: _initialLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? ListView(
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
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: _events.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _events.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _ManagedEventCard(event: _events[i]);
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