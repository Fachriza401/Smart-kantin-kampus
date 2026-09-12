import 'package:flutter/material.dart';

import '../../db/db_helper.dart';
import '../../theme/app_theme.dart';

class PasswordResetRequestsScreen extends StatefulWidget {
  const PasswordResetRequestsScreen({super.key});

  @override
  State<PasswordResetRequestsScreen> createState() => _PasswordResetRequestsScreenState();
}

class _PasswordResetRequestsScreenState extends State<PasswordResetRequestsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await DBHelper.instance.getPendingPasswordResetRequests();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _resolve(Map<String, dynamic> row) async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset password ${row['name'] ?? ''}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password baru',
            hintText: 'Minimal 8 karakter',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(controller.text)) return;
              Navigator.pop(context, controller.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newPassword == null) return;

    await DBHelper.instance.resolvePasswordResetRequest(
      row['id'] as int,
      row['userId'] as int,
      newPassword,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password akun berhasil diubah.')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Reset Password'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(child: Text('Tidak ada permintaan reset password.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final row = _rows[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row['name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${row['email'] ?? '-'} • ${row['role'] ?? '-'}'),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _resolve(row),
                            icon: const Icon(Icons.key),
                            label: const Text('Ganti Password'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
