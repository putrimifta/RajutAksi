import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'sponsorship_form_screen.dart';
import 'manage_registrations_screen.dart';
import 'create_event_screen.dart';
import 'manage_sponsorships_screen.dart';
import '../chat/chat_detail_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final bool openSponsorForm;
  const EventDetailScreen({super.key, required this.eventId, this.openSponsorForm = false});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<EventItem> _future;
  bool _registering = false;
  bool _registered = false;
  bool _startingChat = false;

  Future<void> _chatWithOrganizer(EventItem event) async {
    setState(() => _startingChat = true);
    try {
      final conversationId = await SupabaseService.instance.getOrCreateConversation(event.organizerId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversationId: conversationId,
          otherName: event.organizerName ?? 'Organisasi',
          otherAvatar: event.organizerAvatar,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.instance.fetchEventDetail(widget.eventId);
    if (widget.openSponsorForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openSponsor());
    }
  }

  Future<void> _openSponsor() async {
    final event = await _future;
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SponsorshipFormScreen(event: event)));
  }

  Future<void> _daftarRelawan(EventItem event) async {
    setState(() => _registering = true);
    try {
      await SupabaseService.instance.registerAsVolunteer(event.id);
      setState(() => _registered = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mendaftar sebagai relawan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendaftar, coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<EventItem>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final event = snap.data!;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primary), onPressed: () => Navigator.of(context).pop()),
                          const Text('RajutAksi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ]),
                        Row(children: [
                          if (SupabaseService.instance.authUser?.id == event.organizerId)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              onPressed: () async {
                                final changed = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(builder: (_) => CreateEventScreen(existingEvent: event)),
                                );
                                if (changed == true && mounted) {
                                  setState(() => _future = SupabaseService.instance.fetchEventDetail(widget.eventId));
                                }
                              },
                            ),
                          const Icon(Icons.share_outlined, color: AppColors.primary),
                        ]),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      ClipRRect(
                        child: event.posterUrl != null
                            ? Image.network(event.posterUrl!, height: 220, width: double.infinity, fit: BoxFit.cover)
                            : Container(height: 220, width: double.infinity, color: AppColors.primaryLight,
                                child: const Icon(Icons.image_outlined, size: 48, color: AppColors.primary)),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBadge(text: '${event.categoryLabel} & ${event.sdgCategory}', color: Colors.black.withOpacity(0.45)),
                            const SizedBox(height: 8),
                            Text(event.title,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 6, color: Colors.black54)])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: const [Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary), SizedBox(width: 4), Text('Relawan', style: TextStyle(fontSize: 12, color: AppColors.textGrey))]),
                                    const SizedBox(height: 4),
                                    Text('${event.filledCount}/${event.quota}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    const SizedBox(height: 6),
                                    AppProgressBar(value: event.progress),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: const [Icon(Icons.savings_outlined, size: 16, color: AppColors.primary), SizedBox(width: 4), Text('Dana Terkumpul', style: TextStyle(fontSize: 12, color: AppColors.textGrey))]),
                                    const SizedBox(height: 4),
                                    Text(formatRupiah(event.collectedFunding), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    const SizedBox(height: 6),
                                    Text('Target: ${formatRupiah(event.targetFunding)}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('Tentang Aksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(event.description, style: const TextStyle(color: AppColors.textGrey, height: 1.5)),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          children: ['#${event.categoryLabel}', '#${event.sdgCategory.replaceAll(' ', '')}', '#RajutAksi']
                              .map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 11)), backgroundColor: AppColors.primaryLight))
                              .toList(),
                        ),
                        const SizedBox(height: 18),
                        const Text('PENYELENGGARA', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              AppAvatar(url: event.organizerAvatar, name: event.organizerName ?? 'O', radius: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(event.organizerName ?? 'Organisasi', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    FutureBuilder<double?>(
                                      future: SupabaseService.instance.fetchAverageRating(event.organizerId),
                                      builder: (context, snap) {
                                        final rating = snap.data;
                                        if (rating == null) {
                                          return const Text('Organisasi • Belum ada ulasan', style: TextStyle(fontSize: 11, color: AppColors.textGrey));
                                        }
                                        return Row(children: [
                                          const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                                          const SizedBox(width: 2),
                                          Text('${rating.toStringAsFixed(1)} • Organisasi', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                        ]);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (SupabaseService.instance.authUser?.id != event.organizerId)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(90, 36), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                  onPressed: _startingChat ? null : () => _chatWithOrganizer(event),
                                  icon: _startingChat
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.chat_bubble_outline, size: 15),
                                  label: const Text('Chat', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.eventDate != null
                                      ? DateFormat("EEEE, d MMMM y", 'id_ID').format(event.eventDate!)
                                      : 'Tanggal belum ditentukan',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (event.eventDate != null)
                                  Text(
                                    'Pukul ${DateFormat('HH:mm').format(event.eventDate!)} WIB',
                                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        Row(children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.location, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (event.meetingPoint.isNotEmpty)
                                  Text(event.meetingPoint, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        Builder(builder: (context) {
                          final isOwner = SupabaseService.instance.authUser?.id == event.organizerId;

                          // PEMILIK EVENT: kelola relawan & sponsor
                          if (isOwner) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => ManageRegistrationsScreen(eventId: event.id, eventTitle: event.title))),
                                    icon: const Icon(Icons.groups_outlined, size: 18),
                                    label: const Text('Kelola Relawan'),
                                  ),
                                ),
                                if (event.needSponsor) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => ManageSponsorshipsScreen(eventId: event.id, eventTitle: event.title))),
                                      icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                                      label: const Text('Kelola Sponsor'),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }

                          final activeRole = SupabaseService.instance.currentProfile?.activeRole ?? AppRole.relawan;

                          // POV SPONSOR: cuma bisa ajukan sponsor, bukan daftar relawan
                          if (activeRole == AppRole.sponsor) {
                            if (!event.needSponsor) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                                child: const Text(
                                  'Kegiatan ini tidak membutuhkan sponsor.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.primaryDark, fontSize: 12.5),
                                ),
                              );
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SponsorshipFormScreen(event: event))),
                                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                                label: const Text('Ajukan Sponsor'),
                              ),
                            );
                          }

                          // POV ORGANISASI melihat event organisasi lain: cuma bisa lihat & chat
                          if (activeRole == AppRole.organisasi) {
                            return const SizedBox.shrink();
                          }

                          // POV RELAWAN (default)
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _registering || _registered ? null : () => _daftarRelawan(event),
                              icon: Icon(_registered ? Icons.check : Icons.volunteer_activism_outlined, size: 18),
                              label: Text(_registered ? 'Terdaftar' : 'Daftar Relawan'),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}