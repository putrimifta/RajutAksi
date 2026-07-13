import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import 'home_sponsor.dart' show SponsorProjectCard;

const int _pageSize = 8;

class SponsorListScreen extends StatefulWidget {
  const SponsorListScreen({super.key});

  @override
  State<SponsorListScreen> createState() => _SponsorListScreenState();
}

class _SponsorListScreenState extends State<SponsorListScreen> {
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
      final result = await SupabaseService.instance.fetchEvents(onlyNeedSponsor: true, page: _page, pageSize: _pageSize);
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
        title: const Text('Proyek Butuh Sponsor'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _resetAndLoad,
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'Belum ada proyek yang membutuhkan sponsor saat ini.',
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: _events.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _events.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return SponsorProjectCard(event: _events[i]);
                    },
                  ),
      ),
    );
  }
}
