import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dummy_data.dart';
import '../../db/db_helper.dart';
import '../../models/menu_item.dart';
import '../../models/tenant.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_card.dart';
import 'menu_detail_screen.dart';

class TenantDetailScreen extends StatelessWidget {
  final Tenant tenant;
  const TenantDetailScreen({super.key, required this.tenant});

  Future<List<MenuItem>> _loadMenus() async {
    final all = await DBHelper.instance.getAllMenus();
    return all.where((m) => m.tenantId == tenant.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tenant.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: tenant.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      tenant.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 160,
                      errorBuilder: (_, __, ___) => Icon(
                        DummyData.iconFor(tenant.icon),
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    DummyData.iconFor(tenant.icon),
                    size: 64,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(height: 16),
          Text(tenant.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star,
                  size: 16, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Text(
                  '${tenant.rating} (${tenant.reviewCount}) • ${tenant.etaText}'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tenant.isOpen
                      ? AppColors.primaryContainer.withOpacity(0.15)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tenant.isOpen ? 'Buka' : 'Tutup',
                  style: TextStyle(
                    color: tenant.isOpen ? AppColors.primary : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Menu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          FutureBuilder<List<MenuItem>>(
            future: _loadMenus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Gagal memuat menu',
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                );
              }
              final menu = snapshot.data ?? [];
              if (menu.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Belum ada menu tersedia',
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                );
              }
              return Column(
                children: menu
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MenuListTile(
                          item: m,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => MenuDetailScreen(item: m)),
                          ),
                          onAdd: () {
                            context.read<CartProvider>().addItem(m);
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
