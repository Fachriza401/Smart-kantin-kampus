import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/menu_image.dart';
import '../tenant/search_screen.dart';
import 'checkout_screen.dart';

/// Halaman keranjang memakai CartProvider global dari MultiProvider.
/// Tidak membuat provider baru dan tidak menerima instance provider dari luar.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().loadActivePromo();
    });
  }

  void _goToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _openCheckout(CartProvider cart) {
    if (cart.items.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: const Text(
              'Keranjang',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (cart.items.isNotEmpty)
                IconButton(
                  tooltip: 'Kosongkan keranjang',
                  onPressed: () => _showClearCartDialog(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: cart.items.isEmpty ? _buildEmptyCart() : _buildCartList(cart),
          bottomNavigationBar: cart.items.isEmpty
              ? null
              : _buildCheckoutBar(cart),
        );
      },
    );
  }

  Widget _buildCartList(CartProvider cart) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 170),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CartItemCard(
        item: cart.items[index],
        cart: cart,
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: AppColors.gradientSoftGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryContainer,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Keranjang masih kosong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Menu yang kamu tambahkan akan muncul di sini lengkap dengan jumlah, subtotal, dan total pembayaran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToSearch,
                icon: const Icon(Icons.search),
                label: const Text(
                  'Cari Menu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(CartProvider cart) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${cart.totalQty} item dalam pesanan',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Text(
                  formatRupiah(cart.subtotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            if (cart.discount > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cart.promoTitle ?? 'Promo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${formatRupiah(cart.discount)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total pembayaran',
                        style: TextStyle(color: AppColors.onSurfaceMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(cart.total),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCheckout(cart),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text(
                      'Checkout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text(
          'Semua makanan dan minuman di keranjang akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;

  const _CartItemCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuImage(
                imageUrl: item.menuItem.imageUrl,
                icon: item.menuItem.icon,
                size: 78,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menuItem.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.menuItem.tenantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatRupiah(item.menuItem.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus item',
                onPressed: () => cart.removeItem(item.menuItem.id),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(color: AppColors.onSurfaceMuted),
              ),
              const Spacer(),
              _QuantityButton(
                icon: Icons.remove,
                onPressed: () => cart.decrement(item.menuItem.id),
              ),
              Container(
                width: 42,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                onPressed: () => cart.increment(item.menuItem.id),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal item',
                style: TextStyle(color: AppColors.onSurfaceMuted),
              ),
              Text(
                formatRupiah(item.subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}
