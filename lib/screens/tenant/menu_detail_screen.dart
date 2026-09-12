import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/menu_image.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItem item;

  const MenuDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  int qty = 1;

  void _addToCart() {
    final cart = context.read<CartProvider>();

    debugPrint(
      'MENU DETAIL PROVIDER: '
      '${identityHashCode(cart)}',
    );

    if (!widget.item.tersedia) {
      return;
    }

    cart.addItem(
      widget.item,
      quantity: qty,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Menu',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          0,
          0,
          0,
          110,
        ),
        children: [
          // ======================================================
          // IMAGE
          // ======================================================

          SizedBox(
            height: 220,
            width: double.infinity,
            child: MenuImage(
              imageUrl: item.imageUrl,
              icon: item.icon,
              size: 220,
              borderRadius: BorderRadius.zero,
            ),
          ),

          // ======================================================
          // DETAIL
          // ======================================================

          Container(
            transform: Matrix4.translationValues(
              0,
              -16,
              0,
            ),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatRupiah(
                        item.price,
                      ),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            '${item.rating} '
                            '(${item.reviewCount})',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 28,
                ),
                const Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimasi',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.estimasi,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stok',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.tersedia ? 'Tersedia' : 'Habis',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ========================================================
      // BOTTOM ADD CART
      // ========================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              // ==================================================
              // QUANTITY
              // ==================================================

              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (qty > 1) {
                          setState(() {
                            qty--;
                          });
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.remove,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          qty++;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // ==================================================
              // TAMBAH KE KERANJANG
              // ==================================================

              Expanded(
                child: ElevatedButton(
                  onPressed: item.tersedia ? _addToCart : null,
                  child: const Text(
                    'Tambah ke Keranjang',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
