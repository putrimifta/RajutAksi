import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/supabase_service.dart';

/// Dipakai dua arah: Relawan menilai Organisasi setelah kegiatan selesai,
/// dan Organisasi menilai Relawan yang sudah berkontribusi.
class RateReviewScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String revieweeId;
  final String revieweeName;
  final String? revieweeAvatar;

  const RateReviewScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.revieweeId,
    required this.revieweeName,
    this.revieweeAvatar,
  });

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.submitReview(
        eventId: widget.eventId,
        revieweeId: widget.revieweeId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terima kasih atas ulasannya!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim ulasan: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Beri Ulasan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: widget.revieweeAvatar != null ? NetworkImage(widget.revieweeAvatar!) : null,
                  child: widget.revieweeAvatar == null
                      ? Text(widget.revieweeName.isNotEmpty ? widget.revieweeName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.revieweeName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('Untuk kegiatan "${widget.eventTitle}"', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
              const SizedBox(height: 24),
              const Center(child: Text('Bagaimana pengalamanmu?', style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = starIndex),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 34,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Komentar (opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Ceritakan pengalamanmu...'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Ulasan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
