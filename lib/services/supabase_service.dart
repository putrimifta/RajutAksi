import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

/// Satu service terpusat untuk semua interaksi dengan Supabase.
/// Dipanggil dari seluruh screen lewat SupabaseService.instance
class SupabaseService extends ChangeNotifier {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  Profile? currentProfile;

  User? get authUser => _client.auth.currentUser;
  bool get isLoggedIn => authUser != null;

  // ---------------- AUTH ----------------

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    await loadCurrentProfile();
  }

  /// Registrasi dengan dukungan MULTI-ROLE: [roles] bisa berisi lebih dari 1
  /// nilai dari AppRole (relawan, organisasi, sponsor).
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final userId = res.user?.id;
    if (userId == null) {
      throw Exception('Registrasi gagal, coba lagi.');
    }
    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'email': email,
      'roles': roles,
      'active_role': roles.first,
    });
    await loadCurrentProfile();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    currentProfile = null;
    notifyListeners();
  }

  Future<void> loadCurrentProfile() async {
    final uid = authUser?.id;
    if (uid == null) return;
    final data = await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (data != null) {
      currentProfile = Profile.fromMap(data);
      notifyListeners();
    }
  }

  /// Menambah / mengurangi peran milik user tanpa menghapus akun.
  /// Karena RajutAksi mendukung multi-peran, user boleh punya roles: ['relawan','sponsor']
  Future<void> updateRoles(List<String> newRoles) async {
    final uid = authUser!.id;
    await _client.from('profiles').update({'roles': newRoles}).eq('id', uid);
    await loadCurrentProfile();
  }

  Future<void> switchActiveRole(String role) async {
    final uid = authUser!.id;
    await _client.from('profiles').update({'active_role': role}).eq('id', uid);
    await loadCurrentProfile();
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? avatarUrl,
    List<String>? interests,
  }) async {
    final uid = authUser!.id;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (interests != null) updates['interests'] = interests;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', uid);
    await loadCurrentProfile();
  }

  // ---------------- EVENTS ----------------

  Future<List<EventItem>> fetchEvents({
    String? category,
    bool onlyNeedSponsor = false,
    String? organizerId,
    String? status,
  }) async {
    var query = _client.from('events').select('*, organizer:profiles(full_name, avatar_url)');
    if (category != null && category != 'Semua') {
      query = query.eq('category_label', category);
    }
    if (onlyNeedSponsor) {
      query = query.eq('need_sponsor', true);
    }
    if (organizerId != null) {
      query = query.eq('organizer_id', organizerId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => EventItem.fromMap(e)).toList();
  }

  Future<EventItem> fetchEventDetail(String id) async {
    final data = await _client
        .from('events')
        .select('*, organizer:profiles(full_name, avatar_url)')
        .eq('id', id)
        .single();
    return EventItem.fromMap(data);
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String sdgCategory,
    required String categoryLabel,
    required DateTime eventDate,
    required String location,
    required int quota,
    required bool needSponsor,
    String? posterUrl,
    double targetFunding = 0,
    bool asDraft = false,
  }) async {
    final uid = authUser!.id;
    await _client.from('events').insert({
      'organizer_id': uid,
      'title': title,
      'description': description,
      'sdg_category': sdgCategory,
      'category_label': categoryLabel,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'quota': quota,
      'need_sponsor': needSponsor,
      'poster_url': posterUrl,
      'target_funding': targetFunding,
      'status': asDraft ? 'draft' : 'published',
    });
  }

  Future<void> registerAsVolunteer(String eventId) async {
    final uid = authUser!.id;
    await _client.from('registrations').insert({
      'event_id': eventId,
      'volunteer_id': uid,
      'status': 'pending',
    });
  }

  Future<List<RegistrationItem>> fetchMyRegistrations() async {
    final uid = authUser!.id;
    final data = await _client.from('registrations').select().eq('volunteer_id', uid);
    return (data as List).map((e) => RegistrationItem.fromMap(e)).toList();
  }

  // ---------------- SPONSORSHIP ----------------

  Future<void> submitSponsorshipProposal({
    required String eventId,
    required double amount,
    required String message,
  }) async {
    final uid = authUser!.id;
    await _client.from('sponsorships').insert({
      'event_id': eventId,
      'sponsor_id': uid,
      'amount': amount,
      'message': message,
      'status': 'pending',
    });
  }

  Future<List<SponsorshipItem>> fetchMySponsorships() async {
    final uid = authUser!.id;
    final data = await _client.from('sponsorships').select().eq('sponsor_id', uid);
    return (data as List).map((e) => SponsorshipItem.fromMap(e)).toList();
  }

  // ---------------- CHAT ----------------

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final uid = authUser!.id;
    final data = await _client
        .from('conversations')
        .select('*, user_a:profiles!conversations_user_a_fkey(full_name, avatar_url), '
            'user_b:profiles!conversations_user_b_fkey(full_name, avatar_url)')
        .or('user_a.eq.$uid,user_b.eq.$uid')
        .order('last_message_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<MessageItem>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (data as List).map((e) => MessageItem.fromMap(e)).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    final uid = authUser!.id;
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': content,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
    });
    await _client.from('conversations').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  /// Realtime stream untuk pesan baru di sebuah percakapan
  Stream<List<Map<String, dynamic>>> messageStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  // ---------------- STORAGE ----------------

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
