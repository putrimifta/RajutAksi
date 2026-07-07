import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';

class SponsorshipFormScreen extends StatefulWidget {
  final EventItem event;
  const SponsorshipFormScreen({super.key, required this.event});

  @override
  State<SponsorshipFormScreen> createState() => _SponsorshipFormScreenState();
}

class _SponsorshipFormScreenState extends State<SponsorshipFormScreen> {
  final _amountCtrl = TextEditingController(text: '0');
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  void _setQuick(double value) {
    setState(() => _amountCtrl.text = value.round().toString());
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nilai kontribusi yang valid.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.submitSponsorshipProposal(
        eventId: widget.event.id,
        amount: amount,
        message: _messageCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penawaran sponsor berhasil dikirim!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim penawaran.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('RajutAksi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: event.posterUrl != null
                    ? Image.network(event.posterUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 160, color: AppColors.primaryLight, child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 40)),
              ),
              const SizedBox(height: 12),
              Text('${event.categoryLabel} & ${event.sdgCategory}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              Text(event.description, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
              const SizedBox(height: 20),
              const Text('Formulir Penawaran Sponsor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const Text('Sampaikan visi kolaborasi perusahaan Anda untuk aksi kolektif ini.', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
              const SizedBox(height: 16),
              const Text('Event Terpilih', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.title, overflow: TextOverflow.ellipsis)),
                ]),
              ),
              const SizedBox(height: 16),
              const Text('Nilai Kontribusi (IDR)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: 'Rp  '),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _quickChip('5jt', 5000000),
                  const SizedBox(width: 8),
                  _quickChip('15jt', 15000000),
                  const SizedBox(width: 8),
                  _quickChip('50jt', 50000000),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Pesan Penawaran', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Jelaskan bagaimana perusahaan Anda ingin berkontribusi atau branding yang diharapkan...'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.send, size: 18),
                label: Text(_loading ? 'Mengirim...' : 'Kirim Penawaran'),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text('Tim RajutAksi akan meninjau penawaran Anda dalam 2×24 jam.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ),
              const SizedBox(height: 24),
              const Text('Benefit Sponsorship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: const [
                  _BenefitTile(icon: Icons.campaign_outlined, label: 'Digital Exposure'),
                  _BenefitTile(icon: Icons.workspace_premium_outlined, label: 'Sertifikat SDG'),
                  _BenefitTile(icon: Icons.groups_outlined, label: 'Engagement'),
                  _BenefitTile(icon: Icons.bar_chart_outlined, label: 'Impact Report'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickChip(String label, double value) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _setQuick(value),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: EdgeInsets.zero),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BenefitTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
