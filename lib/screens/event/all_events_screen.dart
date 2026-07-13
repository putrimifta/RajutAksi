import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'event_detail_screen.dart';

const int _pageSize = 8;

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  String _category = 'Semua';
  final _categories = ['Semua', 'Lingkungan', 'Pendidikan', 'Kesehatan', 'Sosial'];
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
      final result = await SupabaseService.instance.fetchEvents(
        category: _category == 'Semua' ? null : _category,
        page: _page,
        pageSize: _pageSize,
      );
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
        title: const Text('Semua Kegiatan'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _resetAndLoad,
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                        _resetAndLoad();
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    );
                  },
                ),
              ),
              Expanded(
                child: _initialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _events.isEmpty
                        ? const Center(child: Text('Belum ada kegiatan di kategori ini', style: TextStyle(color: AppColors.textGrey)))
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
                              return _EventListCard(event: _events[i]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  final EventItem event;
  const _EventListCard({required this.event});

  @override
  Widget build(BuildContext context) {
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
                left: 10,
                child: AppBadge(text: event.categoryLabel.toUpperCase(), color: AppColors.primaryDark.withOpacity(0.85)),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(event.location, style: const TextStyle(color: AppColors.textGrey, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                      ),
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
