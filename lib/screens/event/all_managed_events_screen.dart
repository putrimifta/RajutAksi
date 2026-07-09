import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class AllManagedEventsScreen extends StatefulWidget {
  const AllManagedEventsScreen({super.key});

  @override
  State<AllManagedEventsScreen> createState() => _AllManagedEventsScreenState();
}

class _AllManagedEventsScreenState extends State<AllManagedEventsScreen> {
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    final uid = SupabaseService.instance.authUser?.id;
    _future = SupabaseService.instance.fetchEvents(organizerId: uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text('Semua Event', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<EventItem>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final events = snap.data!;
            if (events.isEmpty) {
              return const Center(child: Text('Belum ada event yang dikelola.', style: TextStyle(color: AppColors.textGrey)));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: events.map((e) => ManagedEventCard(event: e)).toList(),
            );
          },
        ),
      ),
    );
  }
}