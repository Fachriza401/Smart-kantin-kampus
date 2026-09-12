import 'package:flutter/material.dart';

import '../../db/db_helper.dart';
import '../../models/menu_item.dart';
import '../../models/promo.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/menu_image.dart';
import 'menu_detail_screen.dart';

class PromoMenuScreen extends StatelessWidget {
  final Promo promo;

  const PromoMenuScreen({
    super.key,
    required this.promo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Promo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(.2)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.local_offer, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${promo.description} • Diskon ${promo.discount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Menu yang dapat menggunakan promo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<MenuItem>>(
            future: DBHelper.instance.getAllMenus(),
            builder: (context, snapshot) {
              final menus = snapshot.data ?? const <MenuItem>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (menus.isEmpty) {
                return const Text(
                  'Belum ada menu yang tersedia.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                );
              }

              return Column(
                children: menus
                    .map(
                      (menu) => _PromoMenuTile(
                        menu: menu,
                        discount: promo.discount,
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

class _PromoMenuTile extends StatelessWidget {
  final MenuItem menu;
  final double discount;

  const _PromoMenuTile({
    required this.menu,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final discounted = menu.price * (1 - discount / 100);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MenuDetailScreen(item: menu),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            MenuImage(
              imageUrl: menu.imageUrl,
              icon: menu.icon,
              size: 72,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu.tenantName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatRupiah(discounted),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatRupiah(menu.price),
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
