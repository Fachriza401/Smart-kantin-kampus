import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_stats_carousel.dart';
import 'account_manage_screen.dart';
import 'menu_manage_screen.dart';
import 'password_reset_requests_screen.dart';
import 'promo_manage_screen.dart';
import 'tenant_manage_screen.dart';
import '../staff/customer_payments_screen.dart';
import '../profile/notification_screen.dart';
import '../profile/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> ratings = [];
  List<Map<String, dynamic>> daily = [];
  List<Map<String, dynamic>> monthly = [];
  List<Map<String, dynamic>> categories = [];
  List<CampusOrder> orders = [];
  Map<String, int> userStats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<AdminProvider>().loadAll();
    final r = await DBHelper.instance.getRatingsSummary();
    final d = await DBHelper.instance.getDailySales();
    final m = await DBHelper.instance.getMonthlySales();
    final c = await DBHelper.instance.getMenuCategorySales();
    final o = await DBHelper.instance.getAllOrders();
    final u = await DBHelper.instance.getUserStatistics();
    if (!mounted) return;
    setState(() {
      ratings = r;
      daily = d;
      monthly = m;
      categories = c;
      orders = o;
      userStats = u;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final active = orders.where((o) => o.status != 'Selesai' && o.status != 'Dibatalkan').toList();
    final payments = orders.where((o) => o.status != 'Dibatalkan' && o.paymentStatus == 'Lunas').fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              _Header(name: user?.name ?? 'Administrator'),
              const SizedBox(height: 14),
              _HeroBanner(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _MetricCard(icon: Icons.receipt_long_rounded, title: 'Pesanan Aktif', value: '${active.length}', color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricCard(icon: Icons.account_balance_wallet_rounded, title: 'Pembayaran Masuk', value: formatRupiah(payments), color: AppColors.blue)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MetricCard(icon: Icons.groups_rounded, title: 'Pengguna', value: '${userStats['total'] ?? 0}', color: AppColors.purple)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricCard(icon: Icons.restaurant_menu_rounded, title: 'Total Menu', value: '${admin.menus.length}', color: AppColors.tertiary)),
                ],
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Akses Cepat',
                subtitle: 'Menu pengelolaan Admin',
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.22,
                  children: [
                    _Action(icon: Icons.restaurant_menu_rounded, label: 'Kelola Menu', sub: '${admin.menus.length} menu', color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManageScreen()))),
                    _Action(icon: Icons.local_offer_rounded, label: 'Kelola Promo', sub: '${admin.promos.where((p) => p.active).length} promo', color: AppColors.secondaryContainer, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoManageScreen()))),
                    _Action(icon: Icons.storefront_rounded, label: 'Kantin Kampus', sub: '1 tenant resmi', color: AppColors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantManageScreen()))),
                    _Action(icon: Icons.manage_accounts_rounded, label: 'Tenant & Kasir', sub: 'Kelola akun', color: AppColors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManageScreen()))),
                    _Action(icon: Icons.lock_reset_rounded, label: 'Reset Password', sub: 'Permintaan staff', color: AppColors.rose, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordResetRequestsScreen()))),
                    _Action(icon: Icons.payments_rounded, label: 'Data Pembeli', sub: 'Pesanan & pembayaran', color: AppColors.secondary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPaymentsScreen(role: 'admin')))),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Pembayaran Diterima Admin',
                subtitle: 'Tenant dan Kasir tidak memegang saldo pembayaran di aplikasi',
                child: _PaymentSummary(amount: payments, orders: orders),
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Pesanan Terbaru',
                subtitle: '${active.length} pesanan aktif',
                child: active.isEmpty ? const _Empty(text: 'Belum ada pesanan aktif') : Column(children: active.take(8).map((o) => _OrderRow(order: o)).toList()),
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Statistik Admin',
                subtitle: 'Geser ke samping — otomatis setiap 5 detik',
                child: DashboardStatsCarousel(
                  pages: [
                    DashboardStatPage(title: 'Pengguna Aplikasi', subtitle: 'Mahasiswa • Dosen • Tenant • Kasir • Admin', donut: true, colors: const [AppColors.primary, AppColors.blue, AppColors.secondaryContainer, AppColors.tertiary, AppColors.purple], values: {for (final e in userStats.entries) e.key: e.value.toDouble()}),
                    DashboardStatPage(title: 'Kepuasan Pelanggan', subtitle: 'Sebaran rating', donut: true, colors: const [AppColors.primary, AppColors.blue, AppColors.secondaryContainer, AppColors.tertiary], values: {for (final e in ratings) 'Rating ${e['rating']}': ((e['total'] ?? 0) as num).toDouble()}),
                    DashboardStatPage(title: 'Transaksi Harian', subtitle: 'Jumlah pesanan per hari', colors: const [AppColors.primary, AppColors.blue, AppColors.secondaryContainer], values: {for (final e in daily) (e['day'] ?? '').toString(): ((e['totalOrders'] ?? 0) as num).toDouble()}),
                    DashboardStatPage(title: 'Transaksi Bulanan', subtitle: 'Jumlah pesanan per bulan', colors: const [AppColors.blue, AppColors.tertiary, AppColors.primary], values: {for (final e in monthly) (e['month'] ?? '').toString(): ((e['totalOrders'] ?? 0) as num).toDouble()}),
                    DashboardStatPage(title: 'Kategori Terlaris', subtitle: 'Makanan dan minuman favorit', donut: true, colors: const [AppColors.primary, AppColors.blue, AppColors.secondaryContainer, AppColors.tertiary], values: {for (final e in categories) (e['category'] ?? 'Lainnya').toString(): ((e['total'] ?? 0) as num).toDouble()}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});
  @override
  Widget build(BuildContext context) {
    final id = context.watch<AuthProvider>().currentUser?.id;
    return Row(children: [
      InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
        child: CircleAvatar(radius: 27, backgroundColor: AppColors.primaryContainer, child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryDark, size: 30)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hai, ${name.split(' ').first} 👋', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
        const Text('Selamat datang kembali, Admin!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ])),
      if (id != null)
        FutureBuilder<int>(
          future: DBHelper.instance.getUnreadNotificationCount(id),
          builder: (context, snap) => Badge(
            isLabelVisible: (snap.data ?? 0) > 0,
            backgroundColor: AppColors.rose,
            label: Text('${snap.data ?? 0}'),
            child: IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())), icon: const Icon(Icons.notifications_none_rounded, size: 28)),
          ),
        ),
    ]);
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: AppColors.gradientHero,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Row(children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), shape: BoxShape.circle), child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 32)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kontrol Penuh Kantin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Pantau transaksi, pembayaran, menu, promo, dan pesanan dari satu dashboard.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35))]))
    ]),
  );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  const _MetricCard({required this.icon, required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.20)), boxShadow: [BoxShadow(color: color.withOpacity(.08), blurRadius: 12, offset: const Offset(0, 5))]),
    child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle), child: Icon(icon, color: color)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)), const SizedBox(height: 4), FittedBox(alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))]))]),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Section({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.outlineVariant.withOpacity(.65))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)), const SizedBox(height: 12), child]),
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 25), const Spacer(), Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant))]),
    ),
  );
}

class _PaymentSummary extends StatelessWidget {
  final double amount;
  final List<CampusOrder> orders;
  const _PaymentSummary({required this.amount, required this.orders});
  @override
  Widget build(BuildContext context) {
    final virtual = orders.where((o) => o.paymentMethod == 'Pembayaran Virtual' && o.status != 'Dibatalkan').fold<double>(0, (s, o) => s + o.total);
    final direct = orders.where((o) => o.paymentMethod == 'Bayar Langsung' && o.status != 'Dibatalkan').fold<double>(0, (s, o) => s + o.total);
    return Column(children: [
      Row(children: [
        Expanded(child: _PayBox(label: 'Total', value: formatRupiah(amount), color: AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _PayBox(label: 'Virtual', value: formatRupiah(virtual), color: AppColors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _PayBox(label: 'Langsung', value: formatRupiah(direct), color: AppColors.secondaryContainer)),
      ]),
      const SizedBox(height: 10),
      const Row(children: [Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18), SizedBox(width: 8), Expanded(child: Text('Admin menjadi penerima dan pemantau pembayaran. Tenant/Kasir fokus pada operasional pesanan.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)))]),
    ]);
  }
}

class _PayBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PayBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)), const SizedBox(height: 3), FittedBox(alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)))]));
}

class _OrderRow extends StatelessWidget {
  final CampusOrder order;
  const _OrderRow({required this.order});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withOpacity(.75))), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(.1), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(order.items.map((e) => '${e.quantity}x ${e.menuName}').join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant))])), Text(formatRupiah(order.total), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))]));
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(text, style: const TextStyle(color: AppColors.onSurfaceVariant))));
}
