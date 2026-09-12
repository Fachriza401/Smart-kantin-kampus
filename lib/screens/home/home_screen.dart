import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dummy_data.dart';
import '../../db/db_helper.dart';
import '../../models/menu_item.dart';
import '../../models/promo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/tenant_card.dart';
import '../profile/notification_screen.dart';
import '../cart/cart_screen.dart';
import '../tenant/category_screen.dart';
import '../tenant/menu_detail_screen.dart';
import '../tenant/promo_menu_screen.dart';
import '../tenant/tenant_detail_screen.dart';
import '../tenant/tenant_list_screen.dart';

Widget _profileImage(String path, double size) {
  final isNetwork = path.startsWith('http://') || path.startsWith('https://');
  if (isNetwork) {
    return Image.network(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary),
    );
  }
  return Image.file(
    File(path),
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenNotifications,
    this.onShowStudentQr,
  });

  final VoidCallback? onOpenNotifications;
  final VoidCallback? onShowStudentQr;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _promoController = PageController(
    viewportFraction: 0.92,
    initialPage: 1000,
  );
  final TextEditingController _searchController = TextEditingController();

  Timer? _promoTimer;
  Timer? _notificationTimer;
  int _notificationCount = 0;
  String _searchQuery = '';

  final Map<String, IconData> _categoryIcons = const {
    'Makanan': Icons.restaurant,
    'Minuman': Icons.local_cafe,
    'Snacks': Icons.tapas,
    'Aneka': Icons.eco,
    'Nasi': Icons.rice_bowl,
    'Mie': Icons.ramen_dining,
    'Ayam': Icons.restaurant,
    'Gorengan': Icons.tapas,
    'Dessert': Icons.cake,
    'Kopi': Icons.coffee,
    'Teh': Icons.local_cafe,
    'Jus': Icons.local_drink,
    'Minuman Dingin': Icons.icecream,
    'Paket Hemat': Icons.fastfood,
  };

  final List<Color> _categoryColors = const [
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFF0D9488),
    Color(0xFFFBBF24),
    Color(0xFF15803D),
    Color(0xFFFB923C),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotificationCount();
      _notificationTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _refreshNotificationCount(),
      );
      _startPromoAutoSlide();
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _notificationTimer?.cancel();
    _promoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotificationCount() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      if (mounted && _notificationCount != 0) {
        setState(() => _notificationCount = 0);
      }
      return;
    }

    final count = await DBHelper.instance.getUnreadNotificationCount(userId);
    if (!mounted || count == _notificationCount) return;
    setState(() => _notificationCount = count);
  }

  void _openNotifications() {
    if (widget.onOpenNotifications != null) {
      widget.onOpenNotifications!();
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const NotificationScreen(),
          ),
        )
        .then((_) => _refreshNotificationCount());
  }

  void _startPromoAutoSlide() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_promoController.hasClients) return;
        final current = _promoController.page?.round() ?? 1000;
        _promoController.animateToPage(
          current + 1,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Future<List<MenuItem>> _searchMenus() async {
    final query = _searchQuery.toLowerCase().trim();
    final menus = await DBHelper.instance.getAllMenus();
    if (query.isEmpty) return const [];

    return menus.where((m) {
      return m.name.toLowerCase().contains(query) ||
          m.category.toLowerCase().contains(query) ||
          m.tenantName.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildHeader(AuthProvider auth) {
    final name = auth.currentUser?.name.split(' ').first ?? auth.guestName?.split(' ').first ?? 'Pelanggan';
    final photo = auth.currentUser?.photoPath;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A16A34A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              if (auth.currentUser != null) ...[
                GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 220,
                              height: 220,
                              child: photo != null && photo.isNotEmpty
                                  ? _profileImage(photo, 220)
                                  : const Icon(Icons.person, size: 120, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: photo != null && photo.isNotEmpty
                          ? _profileImage(photo, 48)
                          : Container(
                              color: Colors.white.withOpacity(0.2),
                              child: const Icon(Icons.person, color: Colors.white, size: 26),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hai, $name',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mau makan apa hari ini?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onShowStudentQr != null)
                _HeaderButton(
                  icon: Icons.qr_code_2_rounded,
                  tooltip: 'QR Identitas',
                  onPressed: widget.onShowStudentQr!,
                ),
              const SizedBox(width: 6),
              Badge(
                isLabelVisible: _notificationCount > 0,
                label: Text(
                  _notificationCount > 99 ? '99+' : '$_notificationCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                child: _HeaderButton(
                  icon: Icons.notifications_outlined,
                  tooltip: 'Notifikasi',
                  onPressed: _openNotifications,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(auth),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildSearchResults(),
                  if (_searchQuery.isEmpty) ...[
                    _buildPromoSection(),
                    const SizedBox(height: 20),
                    _buildCategorySection(),
                    const SizedBox(height: 18),
                    _buildFavoriteSection(),
                    const SizedBox(height: 18),
                    _buildTenantSection(),
                    const SizedBox(height: 18),
                    _buildRecommendationSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: cart.items.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: Badge(
                  backgroundColor: AppColors.tertiary,
                  label: Text(
                    '${cart.totalQty}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded),
                ),
                label: Text(
                  'Keranjang (${cart.totalQty})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari makanan, minuman, kategori...',
        prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceMuted),
        suffixIcon: _searchQuery.isEmpty
            ? IconButton(
                tooltip: 'Buka Pencarian',
                icon: const Icon(Icons.tune, color: AppColors.onSurfaceMuted),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                ),
              )
            : IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.close, color: AppColors.onSurfaceMuted),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<MenuItem>>(
      future: _searchMenus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final results = snapshot.data ?? const <MenuItem>[];
        if (results.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.onSurfaceMuted),
                SizedBox(height: 12),
                Text(
                  'Menu tidak ditemukan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Coba kata kunci lain atau lihat kategori',
                  style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Hasil Pencarian',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${results.length} ditemukan',
                  style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...results.take(10).map(
                  (menu) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MenuListTile(
                      item: menu,
                      isFavorite:
                          context.watch<FavoriteProvider>().isFavorite(menu.id),
                      onToggleFavorite: () =>
                          context.read<FavoriteProvider>().toggle(menu.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuDetailScreen(item: menu),
                        ),
                      ),
                      onAdd: () {
                        context.read<CartProvider>().addItem(menu);
                      },
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _buildPromoSection() {
    return FutureBuilder<List<Promo>>(
      future: DBHelper.instance.getAllPromos(),
      builder: (context, snapshot) {
        final promos = (snapshot.data ?? []).where((p) => p.active).toList();
        if (promos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer_rounded, size: 20, color: AppColors.tertiary),
                SizedBox(width: 8),
                Text(
                  'Promo Hari Ini',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _promoController,
                itemCount: 1000000,
                itemBuilder: (context, index) {
                  final promo = promos[index % promos.length];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PromoMenuScreen(promo: promo),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: AppColors.gradientPromo,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: -20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            if (promo.imageUrl.isNotEmpty)
                              Positioned.fill(
                                child: Image.network(
                                  promo.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 100, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Discount badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'DISKON ${promo.discount.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    promo.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    promo.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 14,
                              bottom: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection() {
    final categories = DummyData.categories.take(7).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: 20, color: AppColors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                ),
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text('Semua'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final color = _categoryColors[index % _categoryColors.length];
                return _CategoryChip(
                  label: cat,
                  icon: _categoryIcons[cat] ?? Icons.fastfood,
                  color: color,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryScreen(initialCategory: cat),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Quick link to all categories
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Lihat Semua Kategori'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantSection() {
    final tenant = DummyData.tenants.isEmpty ? null : DummyData.tenants.first;
    if (tenant == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.storefront_rounded, size: 20, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Tenant Populer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TenantListScreen(),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TenantCard(
          tenant: tenant,
          width: MediaQuery.of(context).size.width - 32,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TenantDetailScreen(tenant: tenant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteSection() {
    final favIds = context.watch<FavoriteProvider>().favoriteIds;
    if (favIds.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<MenuItem>>(
      future: _favoriteMenus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final favs = snapshot.data ?? const <MenuItem>[];
        if (favs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, size: 20, color: AppColors.rose),
                SizedBox(width: 8),
                Text(
                  'Favorit Kamu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...favs.take(4).map(
                  (menu) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MenuListTile(
                      item: menu,
                      isFavorite: true,
                      onToggleFavorite: () =>
                          context.read<FavoriteProvider>().toggle(menu.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuDetailScreen(item: menu),
                        ),
                      ),
                      onAdd: () {
                        context.read<CartProvider>().addItem(menu);
                      },
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<List<MenuItem>> _favoriteMenus() async {
    final favIds = context.watch<FavoriteProvider>().favoriteIds;
    if (favIds.isEmpty) return const [];
    final menus = await DBHelper.instance.getAllMenus();
    return menus.where((m) => favIds.contains(m.id)).toList();
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: AppColors.purple),
            SizedBox(width: 8),
            Text(
              'Rekomendasi Untukmu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<MenuItem>>(
          future: DBHelper.instance.getAllMenus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final menus = (snapshot.data ?? []).take(6).toList();
            if (menus.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada menu tersedia',
                    style: TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                ),
              );
            }

            return Column(
              children: menus
                  .map(
                    (menu) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MenuListTile(
                        item: menu,
                        isFavorite: context
                            .watch<FavoriteProvider>()
                            .isFavorite(menu.id),
                        onToggleFavorite: () => context
                            .read<FavoriteProvider>()
                            .toggle(menu.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuDetailScreen(item: menu),
                          ),
                        ),
                        onAdd: () {
                          context.read<CartProvider>().addItem(menu);
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
