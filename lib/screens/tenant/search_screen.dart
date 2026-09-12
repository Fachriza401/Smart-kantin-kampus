import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_card.dart';
import '../cart/cart_screen.dart';
import 'menu_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _category = 'Semua';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<List<MenuItem>> _loadMenus() async {
    final menus = await DBHelper.instance.getAllMenus();
    final q = _query.trim().toLowerCase();
    return menus.where((m) {
      final cat = _category == 'Semua' || m.category == _category;
      if (!cat) return false;
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.tenantName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            hintText: 'Cari makanan...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => IconButton(
              tooltip: 'Keranjang',
              onPressed: cart.items.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
              icon: Badge(
                isLabelVisible: cart.items.isNotEmpty,
                label: Text('${cart.totalQty}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Badge(
              label: Text(
                '${cart.totalQty}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: Text(
              'Keranjang • ${cart.totalQty}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        },
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _loadMenus(),
        builder: (context, snapshot) {
          final menus = snapshot.data ?? const <MenuItem>[];
          final cats = <String>{'Semua', ...menus.map((e) => e.category)}.toList();
          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = cats.elementAt(i);
                    final selected = _category == c;
                    return ChoiceChip(
                      label: Text(
                        c,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                      onSelected: (_) => setState(() => _category = c),
                    );
                  },
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : menus.isEmpty
                        ? const Center(child: Text('Menu tidak ditemukan'))
                        : RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: menus.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final m = menus[i];
                                return MenuListTile(
                                  item: m,
                                  isFavorite: context
                                      .watch<FavoriteProvider>()
                                      .isFavorite(m.id),
                                  onToggleFavorite: () => context
                                      .read<FavoriteProvider>()
                                      .toggle(m.id),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => MenuDetailScreen(item: m)),
                                  ),
                                  onAdd: () => context.read<CartProvider>().addItem(m),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

