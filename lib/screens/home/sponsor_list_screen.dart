import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import 'home_sponsor.dart' show SponsorProjectCard;

class SponsorListScreen extends StatefulWidget {
  const SponsorListScreen({super.key});

  @override
  State<SponsorListScreen> createState() => _SponsorListScreenState();
}

class _SponsorListScreenState extends State<SponsorListScreen> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchEvents(onlyNeedSponsor: true);
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
        onRefresh: () async => setState(() {
          _future = SupabaseService.instance.fetchEvents(onlyNeedSponsor: true);
        }),
        child: FutureBuilder<List<EventItem>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final events = snap.data!;
            if (events.isEmpty) {
              return ListView(
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
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: events.map((e) => SponsorProjectCard(event: e)).toList(),
            );
          },
        ),
      ),
    );
  }
}