import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String desc;
  const _OnboardData(this.icon, this.title, this.desc);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardData(
      Icons.receipt_long,
      'Pesan Makanan Tanpa Antri',
      'Pre-order makanan favoritmu dari mana saja dan ambil tanpa perlu mengantri.',
    ),
    _OnboardData(
      Icons.notifications_active,
      'Ambil Cepat',
      'Dapatkan notifikasi saat pesanan siap dan langsung ambil di tenant pilihanmu.',
    ),
    _OnboardData(
      Icons.qr_code_scanner,
      'Metode Pembayaran Mudah',
      'Bayar pesananmu dengan Saldo Kampus, QRIS, atau metode pembayaran lainnya dengan aman.',
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLogin,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            data.icon,
                            size: 90,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
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
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  if (_page == _pages.length - 1) {
                    _goToLogin();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  _page == _pages.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
