import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  _OnboardData(this.icon, this.title, this.desc, this.color);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = [
    _OnboardData(Icons.handshake_rounded, 'Connecting Volunteers',
        'Temukan kegiatan sosial lokal dan aksi bermakna yang sesuai passion kamu. Jadilah perubahan yang kamu inginkan.',
        AppColors.primary),
    _OnboardData(Icons.groups_2_rounded, 'Empowering Organizations',
        'Perluas dampakmu dengan menjangkau lebih banyak orang. Kelola event, pantau kontribusi, dan bangun komunitas yang berkembang.',
        AppColors.primaryDark),
    _OnboardData(Icons.volunteer_activism_rounded, 'Strategic Sponsorship',
        'Dorong perubahan nyata lewat transparansi dan pendanaan yang tepat sasaran. Bermitra untuk dampak berkelanjutan yang terukur.',
        AppColors.accent),
  ];

  void _next() {
    if (_index == _pages.length - 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RajutAksi',
                      style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Skip', style: TextStyle(color: AppColors.textGrey)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.45),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            height: 220,
                            width: 220,
                            decoration: BoxDecoration(
                              color: p.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(p.icon, size: 96, color: p.color),
                          ),
                          const SizedBox(height: 28),
                          Text(p.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          const SizedBox(height: 12),
                          Text(p.desc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textGrey, fontSize: 15, height: 1.4)),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_index == _pages.length - 1 ? 'Mulai' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
