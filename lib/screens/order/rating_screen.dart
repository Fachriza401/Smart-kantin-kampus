import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RatingScreen extends StatefulWidget {
  final CampusOrder order;

  const RatingScreen({super.key, required this.order});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 5;
  final _review = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = DBHelper.instance;
    final auth = context.read<AuthProvider>();
    final menus = await db.getAllMenus();
    final byName = {for (final m in menus) m.name: m.id};
    final review = _review.text.trim().isEmpty ? null : _review.text.trim();
    // Guest memakai userId 0; akun staf memakai id asli.
    final userId = auth.currentUser?.id ?? 0;
    // Beri rating untuk setiap menu dalam pesanan.
    for (final item in widget.order.items) {
      final menuId = byName[item.menuName];
      if (menuId == null) continue;
      await db.createRating(
        userId: userId,
        menuId: menuId,
        orderId: widget.order.id ?? 0,
        rating: _rating,
        review: review,
      );
      await db.updateMenuRating(menuId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas rating & ulasan Anda')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beri Rating')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Rate pesanan ${widget.order.orderCode}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 4,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.tertiary,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '$_rating / 5',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _review,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ulasan (opsional)',
              hintText: 'Bagaimana makananmu?',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Menyimpan...' : 'Kirim Rating'),
          ),
        ],
      ),
    );
  }
}