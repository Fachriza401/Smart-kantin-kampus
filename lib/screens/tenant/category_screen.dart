import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dummy_data.dart';
import '../../db/db_helper.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_card.dart';
import 'menu_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String? initialCategory;

  const CategoryScreen({super.key, this.initialCategory});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late String? selectedCategory = widget.initialCategory;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MenuItem>> _loadMenus() async {
    final menus = await DBHelper.instance.getAllMenus();
    final query = _query.trim().toLowerCase();

    return menus.where((menu) {
      final matchesCategory = selectedCategory == null ||
          selectedCategory!.isEmpty ||
          menu.category == selectedCategory;

      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      return menu.name.toLowerCase().contains(query) ||
          menu.category.toLowerCase().contains(query) ||
          menu.tenantName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCategory == null ? 'Semua Menu' : selectedCategory!,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari makanan atau minuman...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: DummyData.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final active = selectedCategory == null;
                  return ChoiceChip(
                    label: const Text('Semua'),
                    selected: active,
                    onSelected: (_) => setState(() => selectedCategory = null),
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: active
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }

                final cat = DummyData.categories[index - 1];
                final active = cat == selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: active,
                  onSelected: (_) => setState(() => selectedCategory = cat),
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: active
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<MenuItem>>(
              future: _loadMenus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat menu. Silakan coba lagi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? const <MenuItem>[];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Belum ada menu yang tersedia.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final menu = items[index];
                    return MenuListTile(
                      item: menu,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MenuDetailScreen(item: menu),
                        ),
                      ),
                      onAdd: () {
                        context.read<CartProvider>().addItem(menu);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
