import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../home/main_shell.dart';
import '../tenant/dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'payment_method_screen.dart';
import 'privacy_policy_screen.dart';

Widget _userImage(String path, double size, BoxFit fit) {
  final isNetwork = path.startsWith('http://') || path.startsWith('https://');
  if (isNetwork) {
    return Image.network(
      path,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.person,
        size: 44,
        color: AppColors.primary,
      ),
    );
  }

  return Image.file(
    File(path),
    width: size,
    height: size,
    fit: fit,
    errorBuilder: (_, __, ___) => const Icon(
      Icons.person,
      size: 44,
      color: AppColors.primary,
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final role = user?.role;
    final isGuest = user == null;
    final isStudent = role == 'mahasiswa' || role == 'dosen';
    final isOperator = role == 'tenant' || role == 'kasir';

    final helpTitle = !isGuest && role == 'admin'
        ? 'Bantuan & FAQ Admin'
        : isOperator
            ? 'Bantuan & FAQ Tenant/Kasir'
            : 'Bantuan & FAQ';
    final privacyTitle = !isGuest && role == 'admin'
        ? 'Kebijakan Privasi Admin'
        : isOperator
            ? 'Kebijakan Privasi Tenant/Kasir'
            : 'Kebijakan Privasi';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientHero,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isGuest) ...[
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: user.photoPath != null &&
                                      user.photoPath!.isNotEmpty
                                  ? ClipOval(
                                      child: _userImage(
                                        user.photoPath!,
                                        86,
                                        BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: AppColors.primary,
                                    ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                size: 44,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isGuest ? 'Menu Pelanggan' : user.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isGuest
                                    ? 'Belanja tanpa login • pantau pesanan di tab Order'
                                    : role == 'admin'
                                        ? 'Administrator'
                                        : role == 'tenant'
                                            ? 'Tenant • Kantin Kampus'
                                            : role == 'kasir'
                                                ? 'Kasir • Kantin Kampus'
                                                : role == 'dosen'
                                                    ? 'Dosen'
                                                    : 'Mahasiswa',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isGuest) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mahasiswa/civitas tidak perlu membuat akun. Masukkan identitas saat checkout dan pantau pesanan melalui menu Order.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SectionGap(),
                  const _SectionTitle(
                    icon: Icons.admin_panel_settings_outlined,
                    text: 'Portal Staf',
                  ),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.admin_panel_settings_outlined,
                        iconColor: AppColors.blue,
                        title: 'Portal Staf / Admin Log In',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SectionGap(),
                ],
                if (isStudent) ...[
                  const _SectionTitle(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'Pembayaran',
                  ),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.payment_outlined,
                        iconColor: AppColors.secondary,
                        title: 'Metode Pembayaran',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentMethodScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SectionGap(),
                ],
                if (isOperator) ...[
                  const _SectionTitle(
                    icon: Icons.dashboard_outlined,
                    text: 'Dashboard',
                  ),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.dashboard_outlined,
                        iconColor: AppColors.tertiary,
                        title: role == 'kasir'
                            ? 'Dashboard Kasir'
                            : 'Dashboard Tenant',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TenantDashboardScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SectionGap(),
                ],
                if (role == 'admin') ...[
                  const _SectionTitle(
                    icon: Icons.admin_panel_settings,
                    text: 'Dashboard',
                  ),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.admin_panel_settings,
                        iconColor: AppColors.rose,
                        title: 'Dashboard Admin',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SectionGap(),
                ],
                if (!isGuest) ...[
                  const _SectionTitle(
                    icon: Icons.badge_outlined,
                    text: 'Informasi Akun',
                  ),
                  _SectionCard(
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline,
                        iconColor: AppColors.primary,
                        title: 'Edit Profil',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SectionGap(),
                ],
                const _SectionTitle(
                  icon: Icons.live_help_outlined,
                  text: 'Bantuan & Kebijakan',
                ),
                _SectionCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.headset_mic_outlined,
                      iconColor: AppColors.blue,
                      title: helpTitle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        ),
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.purple,
                      title: privacyTitle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isGuest) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorContainer,
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar dari Portal'),
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();
                      final fav = context.read<FavoriteProvider>();
                      await auth.logout();
                      await fav.loadForUser(null);
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainShell(),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 18);
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<_ProfileTile> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: AppColors.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceMuted,
      ),
      onTap: onTap,
    );
  }
}