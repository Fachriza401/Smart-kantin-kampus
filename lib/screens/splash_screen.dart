import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_logo.dart';
import 'home/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _scaleController.forward();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    final fav = context.read<FavoriteProvider>();
    await auth.bootstrapData();
    await auth.tryAutoLogin();
    await auth.restoreGuestSession();
    await fav.loadForUser(auth.currentUser?.id);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.gradientSplash,
          ),
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo circle with subtle glow
                        Container(
                          width: 130,
                          height: 130,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const SmartLogo(size: 130),
                        ),
                        const SizedBox(height: 28),
                        // App name
                        const Text(
                          'SMART KANTIN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'KAMPUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Pre-order makanan & minuman kampus',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Loading indicator
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(0.9),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
