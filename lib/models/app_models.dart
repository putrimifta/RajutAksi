/// Semua model data aplikasi RajutAksi.
/// Struktur field mengikuti skema tabel di supabase/schema.sql

class AppRole {
  static const relawan = 'relawan';
  static const organisasi = 'organisasi';
  static const sponsor = 'sponsor';

  static const all = [relawan, organisasi, sponsor];

  static String label(String role) {
    switch (role) {
      case relawan:
        return 'Relawan';
      case organisasi:
        return 'Organisasi';
      case sponsor:
        return 'Sponsor';
      default:
        return role;
    }
  }
}

class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final List<String> roles; // bisa lebih dari satu: relawan, organisasi, sponsor
  final String activeRole;
  final List<String> interests; // minat SDG
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.bio,
    this.avatarUrl,
    required this.roles,
    required this.activeRole,
    this.interests = const [],
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      bio: map['bio'],
      avatarUrl: map['avatar_url'],
      roles: List<String>.from(map['roles'] ?? []),
      activeRole: map['active_role'] ?? AppRole.relawan,
      interests: List<String>.from(map['interests'] ?? []),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'bio': bio,
        'avatar_url': avatarUrl,
        'roles': roles,
        'active_role': activeRole,
        'interests': interests,
      };
}

class EventItem {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String sdgCategory; // contoh: "SDG 13", "SDG 4"
  final String categoryLabel; // contoh: "Lingkungan", "Pendidikan"
  final DateTime? eventDate;
  final String location;
  final String meetingPoint;
  final int quota;
  final int filledCount;
  final String? posterUrl;
  final bool needSponsor;
  final double targetFunding;
  final double collectedFunding;
  final String status; // draft, published, ongoing, done
  final DateTime createdAt;
  final String? organizerName;
  final String? organizerAvatar;

  EventItem({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.sdgCategory,
    required this.categoryLabel,
    this.eventDate,
    required this.location,
    this.meetingPoint = '',
    required this.quota,
    this.filledCount = 0,
    this.posterUrl,
    this.needSponsor = false,
    this.targetFunding = 0,
    this.collectedFunding = 0,
    this.status = 'published',
    required this.createdAt,
    this.organizerName,
    this.organizerAvatar,
  });

  double get progress => quota == 0 ? 0 : (filledCount / quota).clamp(0, 1);
  double get fundingProgress =>
      targetFunding == 0 ? 0 : (collectedFunding / targetFunding).clamp(0, 1);

  factory EventItem.fromMap(Map<String, dynamic> map) {
    final organizer = map['organizer'] as Map<String, dynamic>?;
    return EventItem(
      id: map['id'].toString(),
      organizerId: map['organizer_id'].toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      sdgCategory: map['sdg_category'] ?? '',
      categoryLabel: map['category_label'] ?? '',
      eventDate: map['event_date'] != null ? DateTime.tryParse(map['event_date']) : null,
      location: map['location'] ?? '',
      meetingPoint: map['meeting_point'] ?? '',
      quota: map['quota'] ?? 0,
      filledCount: map['filled_count'] ?? 0,
      posterUrl: map['poster_url'],
      needSponsor: map['need_sponsor'] ?? false,
      targetFunding: (map['target_funding'] ?? 0).toDouble(),
      collectedFunding: (map['collected_funding'] ?? 0).toDouble(),
      status: map['status'] ?? 'published',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      organizerName: organizer?['full_name'],
      organizerAvatar: organizer?['avatar_url'],
    );
  }
}

class RegistrationItem {
  final String id;
  final String eventId;
  final String volunteerId;
  final String status; // pending, approved, rejected, completed
  final DateTime registeredAt;

  RegistrationItem({
    required this.id,
    required this.eventId,
    required this.volunteerId,
    required this.status,
    required this.registeredAt,
  });

  factory RegistrationItem.fromMap(Map<String, dynamic> map) => RegistrationItem(
        id: map['id'].toString(),
        eventId: map['event_id'].toString(),
        volunteerId: map['volunteer_id'].toString(),
        status: map['status'] ?? 'pending',
        registeredAt: DateTime.tryParse(map['registered_at'] ?? '') ?? DateTime.now(),
      );
}

class SponsorshipItem {
  final String id;
  final String eventId;
  final String sponsorId;
  final double amount;
  final String message;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  SponsorshipItem({
    required this.id,
    required this.eventId,
    required this.sponsorId,
    required this.amount,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SponsorshipItem.fromMap(Map<String, dynamic> map) => SponsorshipItem(
        id: map['id'].toString(),
        eventId: map['event_id'].toString(),
        sponsorId: map['sponsor_id'].toString(),
        amount: (map['amount'] ?? 0).toDouble(),
        message: map['message'] ?? '',
        status: map['status'] ?? 'pending',
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );
}

class ConversationItem {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroup;

  ConversationItem({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroup = false,
  });
}

class MessageItem {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime createdAt;

  MessageItem({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    this.attachmentName,
    required this.createdAt,
  });

  factory MessageItem.fromMap(Map<String, dynamic> map) => MessageItem(
        id: map['id'].toString(),
        conversationId: map['conversation_id'].toString(),
        senderId: map['sender_id'].toString(),
        content: map['content'] ?? '',
        attachmentUrl: map['attachment_url'],
        attachmentName: map['attachment_name'],
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? relatedEventId;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedEventId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) => NotificationItem(
        id: map['id'].toString(),
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        type: map['type'] ?? 'general',
        relatedEventId: map['related_event_id']?.toString(),
        isRead: map['is_read'] ?? false,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );
}

class ReviewItem {
  final String id;
  final String eventId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? reviewerName;
  final String? reviewerAvatar;

  ReviewItem({
    required this.id,
    required this.eventId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
  });

  factory ReviewItem.fromMap(Map<String, dynamic> map) {
    final reviewer = map['reviewer'] as Map<String, dynamic>?;
    return ReviewItem(
      id: map['id'].toString(),
      eventId: map['event_id'].toString(),
      reviewerId: map['reviewer_id'].toString(),
      revieweeId: map['reviewee_id'].toString(),
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      reviewerName: reviewer?['full_name'],
      reviewerAvatar: reviewer?['avatar_url'],
    );
  }
}
