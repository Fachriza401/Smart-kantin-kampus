import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/dummy_data.dart';
import '../../models/menu_item.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class MenuManageScreen extends StatelessWidget {
  const MenuManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, menu: null),
          ),
        ],
      ),
      body: admin.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admin.menus.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final menu = admin.menus[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: MenuThumb(
                                imageUrl: menu.imageUrl,
                                icon: menu.icon,
                                fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(menu.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text('${menu.tenantName} • ${menu.category}',
                                    style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12)),
                                Text(formatRupiah(menu.price),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.primary),
                            onPressed: () => _showForm(context, menu: menu),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () => _confirmDelete(context, menu),
                          ),
                        ],
                      ),
                      if (!menu.tersedia)
                        _StatusBadge(
                          icon: Icons.error_outline,
                          label: 'HABIS — Ketuk untuk aktifkan',
                          color: AppColors.error,
                          bgColor: AppColors.errorContainer,
                          onTap: () => context
                              .read<AdminProvider>()
                              .setMenuAvailability(menu.id, true),
                        )
                      else
                        _StatusBadge(
                          icon: Icons.check_circle,
                          label: 'TERSEDIA — Ketuk untuk nonaktifkan',
                          color: AppColors.primaryDark,
                          bgColor: AppColors.primaryContainer,
                          onTap: () => context
                              .read<AdminProvider>()
                              .setMenuAvailability(menu.id, false),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MenuItem menu) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Hapus "${menu.name}" dari daftar menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AdminProvider>().deleteMenu(menu.id);
    }
  }

  Future<void> _showForm(BuildContext context,
      {required MenuItem? menu}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuFormScreen(menu: menu),
      ),
    );
  }
}

class MenuFormScreen extends StatefulWidget {
  final MenuItem? menu;
  const MenuFormScreen({super.key, this.menu});

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _tenantName;
  late final TextEditingController _estimasi;
  late String _category;
  late String _icon;
  late bool _tersedia;
  late int _nextId;
  late String _imageUrl;

  bool get _isEdit => widget.menu != null;

  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    _name = TextEditingController(text: m?.name ?? '');
    _price = TextEditingController(text: m != null ? '${m.price.toInt()}' : '');
    _description = TextEditingController(text: m?.description ?? '');
    _tenantName = TextEditingController(text: 'Kantin Kampus');
    _estimasi = TextEditingController(text: m?.estimasi ?? '15-20 menit');
    _category = m?.category ?? 'Makanan';
    _icon = m?.icon ?? 'restaurant';
    _tersedia = m?.tersedia ?? true;
    _nextId = m?.id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    _imageUrl = m?.imageUrl ?? DummyData.fallbackAssetForCategory(_category);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _tenantName.dispose();
    _estimasi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = DummyData.categories;
    final icons = <String, IconData>{
      'restaurant': Icons.restaurant,
      'ramen_dining': Icons.ramen_dining,
      'coffee': Icons.coffee,
      'local_cafe': Icons.local_cafe,
      'tapas': Icons.tapas,
      'rice_bowl': Icons.rice_bowl,
      'nutrition': Icons.eco,
      'fastfood': Icons.fastfood,
    };

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Menu' : 'Tambah Menu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama Menu'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama menu wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenantName,
              decoration: const InputDecoration(labelText: 'Tenant'),
              readOnly: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama tenant wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) return 'Harga tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _estimasi,
              decoration: const InputDecoration(labelText: 'Estimasi'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            const Text('Ikon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icons.entries.map((e) {
                final selected = _icon == e.key;
                return InkWell(
                  onTap: () => setState(() => _icon = e.key),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Icon(e.value, color: AppColors.primary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Foto Menu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageUrl.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fastfood_outlined,
                            size: 54,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada foto — ikon otomatis ditampilkan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _imagePreview(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Foto dari Perangkat'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Tersedia'),
              value: _tersedia,
              onChanged: (v) => setState(() => _tersedia = v),
              secondary: Icon(_tersedia ? Icons.check_circle : Icons.cancel,
                  color: _tersedia ? AppColors.primary : AppColors.error),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Widget _imagePreview() {
    if (_imageUrl.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(_imageUrl.split(',').last),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } catch (_) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.outline,
          ),
        );
      }
    }

    if (_imageUrl.startsWith('assets/')) {
      return Image.asset(
        _imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.outline,
          ),
        ),
      );
    }

    return Image.network(
      _imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: AppColors.outline,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = context.read<AdminProvider>();
    final price = double.parse(_price.text.trim());
    final menu = MenuItem(
      id: _nextId,
      tenantId: _isEdit ? widget.menu!.tenantId : 1,
      tenantName: _tenantName.text.trim(),
      name: _name.text.trim(),
      price: price,
      category: _category,
      description: _description.text.trim(),
      rating: _isEdit ? widget.menu!.rating : 0,
      reviewCount: _isEdit ? widget.menu!.reviewCount : 0,
      estimasi: _estimasi.text.trim(),
      tersedia: _tersedia,
      icon: _icon,
      imageUrl: _imageUrl,
    );
    if (_isEdit) {
      await admin.updateMenu(menu);
    } else {
      await admin.addMenu(menu);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Menu diperbarui' : 'Menu ditambahkan')),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail menu yang aman untuk semua sumber gambar
/// (aset lokal, upload base64, atau URL jaringan).
class MenuThumb extends StatelessWidget {
  final String imageUrl;
  final String icon;
  final BoxFit fit;

  const MenuThumb({
    super.key,
    required this.imageUrl,
    required this.icon,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      DummyData.iconFor(icon),
      color: Colors.white,
    );

    final url = imageUrl.trim();

    if (url.isEmpty) return placeholder;

    if (url.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(url.split(',').last),
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }
}
