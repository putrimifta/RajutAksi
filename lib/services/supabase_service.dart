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

  /// Mengirim email berisi link untuk reset password.
  /// Supabase akan mengarahkan user kembali ke [redirectTo] dengan token
  /// pemulihan di URL, lalu app mendeteksinya lewat onAuthStateChange.
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  /// Dipanggil di halaman "Buat Kata Sandi Baru" setelah user klik link dari email.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
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
    int page = 0,
    int pageSize = 10,
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
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final data = await query.order('created_at', ascending: false).range(from, to);
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

  /// Dipakai Organisasi untuk mengedit event miliknya. Hanya field yang
  /// tidak null yang akan diperbarui.
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? sdgCategory,
    String? categoryLabel,
    DateTime? eventDate,
    String? location,
    int? quota,
    bool? needSponsor,
    String? posterUrl,
    double? targetFunding,
    String? status,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (sdgCategory != null) updates['sdg_category'] = sdgCategory;
    if (categoryLabel != null) updates['category_label'] = categoryLabel;
    if (eventDate != null) updates['event_date'] = eventDate.toIso8601String();
    if (location != null) updates['location'] = location;
    if (quota != null) updates['quota'] = quota;
    if (needSponsor != null) updates['need_sponsor'] = needSponsor;
    if (posterUrl != null) updates['poster_url'] = posterUrl;
    if (targetFunding != null) updates['target_funding'] = targetFunding;
    if (status != null) updates['status'] = status;
    if (updates.isEmpty) return;
    await _client.from('events').update(updates).eq('id', eventId);
  }

  /// Dipakai Organisasi untuk menghapus event miliknya secara permanen
  /// (pendaftaran relawan & tawaran sponsor terkait ikut terhapus otomatis).
  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<void> registerAsVolunteer(String eventId) async {
    final uid = authUser!.id;
    await _client.from('registrations').insert({
      'event_id': eventId,
      'volunteer_id': uid,
      'status': 'pending',
    });
  }

  /// Dipakai Organisasi: melihat daftar relawan yang mendaftar ke event miliknya
  Future<List<Map<String, dynamic>>> fetchEventRegistrations(String eventId) async {
    final data = await _client
        .from('registrations')
        .select('*, volunteer:profiles(id, full_name, email, avatar_url, phone)')
        .eq('event_id', eventId)
        .order('registered_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Dipakai Organisasi: menyetujui / menolak / menandai selesai seorang relawan
  Future<void> updateRegistrationStatus(String registrationId, String status) async {
    await _client.from('registrations').update({'status': status}).eq('id', registrationId);
  }

  Future<List<RegistrationItem>> fetchMyRegistrations() async {
    final uid = authUser!.id;
    final data = await _client.from('registrations').select().eq('volunteer_id', uid);
    return (data as List).map((e) => RegistrationItem.fromMap(e)).toList();
  }

  /// Riwayat aktivitas Relawan: event yang sudah didaftar, lengkap dengan status pendaftaran
  Future<List<Map<String, dynamic>>> fetchMyRegisteredEventsDetailed() async {
    final uid = authUser!.id;
    final data = await _client
        .from('registrations')
        .select('*, event:events(*, organizer:profiles(full_name, avatar_url))')
        .eq('volunteer_id', uid)
        .order('registered_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Riwayat aktivitas Sponsor: penawaran sponsor yang sudah diajukan, lengkap data event-nya
  Future<List<Map<String, dynamic>>> fetchMySponsorshipsDetailed() async {
    final uid = authUser!.id;
    final data = await _client
        .from('sponsorships')
        .select('*, event:events(*, organizer:profiles(full_name, avatar_url))')
        .eq('sponsor_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Total nilai sponsorship yang SUDAH DITERIMA (accepted) oleh sponsor ini,
  /// dipakai untuk kartu "Total Kontribusi Saya" di Home Sponsor.
  Future<double> fetchMyAcceptedSponsorshipTotal() async {
    final uid = authUser!.id;
    final data = await _client.from('sponsorships').select('amount').eq('sponsor_id', uid).eq('status', 'accepted');
    final list = List<Map<String, dynamic>>.from(data);
    return list.fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0).toDouble());
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

  /// Dipakai Organisasi: melihat semua tawaran sponsor yang masuk untuk event miliknya
  Future<List<Map<String, dynamic>>> fetchEventSponsorships(String eventId) async {
    final data = await _client
        .from('sponsorships')
        .select('*, sponsor:profiles(id, full_name, email, avatar_url, phone)')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Dipakai Organisasi: menerima / menolak tawaran sponsor.
  /// Kalau diterima, trigger di database otomatis menambah collected_funding pada event.
  Future<void> updateSponsorshipStatus(String sponsorshipId, String status) async {
    await _client.from('sponsorships').update({'status': status}).eq('id', sponsorshipId);
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

  /// Mencari percakapan yang sudah ada dengan [otherUserId], atau membuat
  /// yang baru kalau belum pernah ada. Dipakai tombol "Chat Penyelenggara".
  Future<String> getOrCreateConversation(String otherUserId) async {
    final uid = authUser!.id;
    if (uid == otherUserId) {
      throw Exception('Tidak bisa memulai chat dengan diri sendiri.');
    }
    final existing = await _client
        .from('conversations')
        .select('id')
        .or('and(user_a.eq.$uid,user_b.eq.$otherUserId),and(user_a.eq.$otherUserId,user_b.eq.$uid)')
        .maybeSingle();
    if (existing != null) return existing['id'].toString();

    final inserted = await _client
        .from('conversations')
        .insert({'user_a': uid, 'user_b': otherUserId})
        .select('id')
        .single();
    return inserted['id'].toString();
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

  // ---------------- NOTIFICATIONS ----------------

  Future<List<NotificationItem>> fetchNotifications({int limit = 50}) async {
    final uid = authUser!.id;
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => NotificationItem.fromMap(e)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllNotificationsRead() async {
    final uid = authUser!.id;
    await _client.from('notifications').update({'is_read': true}).eq('user_id', uid).eq('is_read', false);
  }

  /// Stream realtime jumlah notifikasi belum dibaca — dipakai untuk badge merah di lonceng.
  Stream<int> unreadNotificationCountStream() {
    final uid = authUser?.id;
    if (uid == null) return Stream.value(0);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .map((rows) => rows.where((r) => r['is_read'] == false).length);
  }

  // ---------------- REVIEWS ----------------

  Future<void> submitReview({
    required String eventId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final uid = authUser!.id;
    await _client.from('reviews').insert({
      'event_id': eventId,
      'reviewer_id': uid,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<ReviewItem>> fetchReviewsForUser(String userId) async {
    final data = await _client
        .from('reviews')
        .select('*, reviewer:profiles!reviews_reviewer_id_fkey(full_name, avatar_url)')
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ReviewItem.fromMap(e)).toList();
  }

  Future<double?> fetchAverageRating(String userId) async {
    final data = await _client.from('reviews').select('rating').eq('reviewee_id', userId);
    final list = List<Map<String, dynamic>>.from(data);
    if (list.isEmpty) return null;
    final total = list.fold<int>(0, (sum, r) => sum + (r['rating'] as int? ?? 0));
    return total / list.length;
  }

  Future<bool> hasReviewed({required String eventId, required String revieweeId}) async {
    final uid = authUser!.id;
    final data = await _client
        .from('reviews')
        .select('id')
        .eq('event_id', eventId)
        .eq('reviewer_id', uid)
        .eq('reviewee_id', revieweeId)
        .maybeSingle();
    return data != null;
  }
}
