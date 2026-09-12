import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AccountManageScreen extends StatefulWidget {
  const AccountManageScreen({super.key});
  @override State<AccountManageScreen> createState() => _AccountManageScreenState();
}

class _AccountManageScreenState extends State<AccountManageScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'tenant';
  bool _loading = false;

  @override void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _create() async {
    setState(() => _loading = true);
    final error = await context.read<AuthProvider>().createManagedAccount(
      name: _name.text, email: _email.text, password: _password.text,
      role: _role, tenantName: 'Kantin Kampus',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Akun $_role berhasil dibuat')));
    if (error == null) { _name.clear(); _email.clear(); _password.clear(); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manajemen Tenant & Kasir')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Buat Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Satu form untuk membuat akun Tenant atau Kasir.', style: TextStyle(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(
        value: _role, decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
        items: const [DropdownMenuItem(value: 'tenant', child: Text('Tenant')), DropdownMenuItem(value: 'kasir', child: Text('Kasir'))],
        onChanged: (v) => setState(() => _role = v ?? 'tenant'),
      ),
      const SizedBox(height: 12),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 12),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 12),
      if (_role == 'tenant') ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.storefront, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tenant tetap: Kantin Kampus',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _loading ? null : _create, icon: const Icon(Icons.person_add), label: _loading ? const Text('Menyimpan...') : const Text('Buat Akun')),
    ]),
  );
}
