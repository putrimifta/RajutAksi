import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'auth/login_screen.dart';

class _OnboardData {
  final String imageUrl;
  final String title;
  final String desc;
  _OnboardData(this.imageUrl, this.title, this.desc);
}

/// Desain terinspirasi dari kartu "Hello, welcome!" — foto penuh layar dengan
/// judul besar & tombol di atasnya, tapi warnanya disesuaikan ke brand RajutAksi (#4E8EA2)
/// dan dibuat vertikal untuk layar mobile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = [
    _OnboardData(
      'https://images.unsplash.com/photo-1565803974275-dccd2f933cbb?auto=format&fit=crop&w=1000&q=80',
      'Connecting\nVolunteers',
      'Temukan kegiatan sosial lokal dan aksi bermakna yang sesuai passion kamu. Jadilah perubahan yang kamu inginkan.',
    ),
    _OnboardData(
      'https://images.unsplash.com/photo-1758518731706-be5d5230e5a5?auto=format&fit=crop&w=1000&q=80',
      'Empowering\nOrganizations',
      'Perluas dampakmu dengan menjangkau lebih banyak orang. Kelola event, pantau kontribusi, dan bangun komunitas.',
    ),
    _OnboardData(
      'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=1000&q=80',
      'Strategic\nSponsorship',
      'Dorong perubahan nyata lewat transparansi dan pendanaan yang tepat sasaran. Bermitra untuk dampak berkelanjutan.',
    ),
  ];

  void _next() {
    if (_index == _pages.length - 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  void _skip() => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final p = _pages[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(color: AppColors.primaryDark),
                  ),
                  // Gradasi warna brand supaya teks tetap terbaca jelas di atas foto
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          AppColors.primaryDark.withOpacity(0.55),
                          AppColors.primaryDark.withOpacity(0.35),
                          AppColors.primaryDark.withOpacity(0.92),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Logo & nama app di pojok kiri atas (seperti "YOUR LOGO" di referensi)
          Positioned(
            top: 56,
            left: 24,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.public, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('RajutAksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          Positioned(
            top: 56,
            right: 24,
            child: TextButton(
              onPressed: _skip,
              child: const Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ),
          ),
          // Judul besar & deskripsi, gaya "Hello, welcome!" tapi warna brand
          Positioned(
            left: 28,
            right: 28,
            bottom: 132,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(_index),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pages[_index].title,
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _pages[_index].desc,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 56,
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: Size.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_index == _pages.length - 1 ? 'Mulai' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
