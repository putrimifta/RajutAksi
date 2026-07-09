import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class AllFeaturedEventsScreen extends StatefulWidget {
  const AllFeaturedEventsScreen({super.key});

  @override
  State<AllFeaturedEventsScreen> createState() => _AllFeaturedEventsScreenState();
}

class _AllFeaturedEventsScreenState extends State<AllFeaturedEventsScreen> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text('Semua Kegiatan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<EventItem>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final events = snap.data!;
            if (events.isEmpty) {
              return const Center(child: Text('Belum ada kegiatan tersedia.', style: TextStyle(color: AppColors.textGrey)));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, i) => FeaturedEventCard(event: events[i]),
            );
          },
        ),
      ),
    );
  }
}