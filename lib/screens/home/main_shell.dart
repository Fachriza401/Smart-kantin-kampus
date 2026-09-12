import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../order/order_history_screen.dart';
import '../profile/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/voucher_screen.dart';
import '../qr/qr_scanner_screen.dart';
import '../tenant/dashboard_screen.dart';
import '../tenant/search_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openNotifications() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen(showBackButton: true)),
      );

  void _openQrScanner() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role;

    if (role == 'admin' || role == 'tenant' || role == 'kasir') {
      return _buildStaffShell(role!);
    }
    return _buildGuestStudentShell();
  }

  Widget _buildGuestStudentShell() {
    final pages = <Widget>[
      HomeScreen(onOpenNotifications: _openNotifications),
      const SearchScreen(),
      const OrderHistoryScreen(),
      const VoucherScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _ModernNavBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: const [
          _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
          _NavItem(icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: 'Cari'),
          _NavItem(icon: Icons.shopping_bag_outlined, selectedIcon: Icons.shopping_bag_rounded, label: 'Order'),
          _NavItem(icon: Icons.local_offer_outlined, selectedIcon: Icons.local_offer_rounded, label: 'Promo'),
          _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildStaffShell(String role) {
    final isAdmin = role == 'admin';
    final isKasir = role == 'kasir';
    final pages = [
      isAdmin ? const AdminDashboardScreen() : const TenantDashboardScreen(),
      const NotificationScreen(showBackButton: false),
      const ProfileScreen(),
    ];
    final labels = [
      isAdmin ? 'Admin' : isKasir ? 'Kasir' : 'Tenant',
      'Notifikasi',
      'Akun',
    ];

    return Scaffold(
      body: IndexedStack(index: _index.clamp(0, 2), children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _index == 0
          ? _GlassScanButton(
              label: isAdmin ? 'Scan QR Admin' : isKasir ? 'Scan QR Kasir' : 'Scan QR Tenant',
              onPressed: _openQrScanner,
            )
          : null,
      bottomNavigationBar: _ModernNavBar(
        currentIndex: _index.clamp(0, 2),
        onTap: (value) => setState(() => _index = value),
        items: [
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: labels[0],
          ),
          const _NavItem(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
            label: 'Notifikasi',
          ),
          const _NavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Bottom navigation bar modern dengan rounded card menonjol
class _ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _ModernNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: selected ? 1.1 : 1.0,
                        child: Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected
                              ? AppColors.primaryDark
                              : Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? AppColors.primaryDark
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _GlassScanButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GlassScanButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradientAccent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33EB7F00),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onPressed,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
