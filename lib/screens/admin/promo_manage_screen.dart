import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dummy_data.dart';
import '../../models/promo.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class PromoManageScreen extends StatelessWidget {
  const PromoManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Promo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, promo: null),
          ),
        ],
      ),
      body: admin.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admin.promos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final promo = admin.promos[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          DummyData.iconFor(promo.icon),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(promo.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('Diskon ${promo.discount.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text(promo.active ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: promo.active
                                        ? AppColors.primaryContainer
                                        : AppColors.error)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => _showForm(context, promo: promo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () => _confirmDelete(context, promo),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Promo promo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Promo'),
        content: Text('Hapus promo "${promo.title}"?'),
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
      await context.read<AdminProvider>().deletePromo(promo.id);
    }
  }

  Future<void> _showForm(BuildContext context, {required Promo? promo}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PromoFormScreen(promo: promo),
      ),
    );
  }
}

class PromoFormScreen extends StatefulWidget {
  final Promo? promo;
  const PromoFormScreen({super.key, this.promo});

  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _discount;
  late bool _active;
  late String _icon;
  late int _nextId;

  bool get _isEdit => widget.promo != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _discount =
        TextEditingController(text: p != null ? '${p.discount.toInt()}' : '');
    _active = p?.active ?? true;
    _icon = p?.icon ?? 'local_offer';
    _nextId =
        p != null ? p.id : (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = <String, IconData>{
      'local_offer': Icons.local_offer,
      'fastfood': Icons.fastfood,
      'account_balance_wallet': Icons.account_balance_wallet,
      'percent': Icons.percent,
      'confirmation_number': Icons.confirmation_number,
      'celebration': Icons.celebration,
    };

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Promo' : 'Tambah Promo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Judul Promo'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discount,
              decoration: const InputDecoration(
                labelText: 'Diskon (%)',
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val < 0 || val > 100) {
                  return 'Diskon tidak valid (0-100)';
                }
                return null;
              },
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
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Aktif'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              secondary: Icon(_active ? Icons.visibility : Icons.visibility_off,
                  color:
                      _active ? AppColors.primaryContainer : AppColors.error),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Promo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = context.read<AdminProvider>();
    final discount = double.parse(_discount.text.trim());
    final promo = Promo(
      id: _nextId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      discount: discount,
      active: _active,
      icon: _icon,
    );
    if (_isEdit) {
      await admin.updatePromo(promo);
    } else {
      await admin.addPromo(promo);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_isEdit ? 'Promo diperbarui' : 'Promo ditambahkan')),
    );
  }
}
