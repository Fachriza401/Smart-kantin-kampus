import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _idCtrl = TextEditingController();
  String _role = 'tenant';
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    final result = await context
        .read<AuthProvider>()
        .requestStaffPasswordReset(
          identifier: _idCtrl.text,
          role: _role,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null || result.contains('dikirim')) {
        _message = result;
      } else {
        _error = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _role == 'tenant' ? 'Tenant' : 'Kasir';
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password Staf')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
            const SizedBox(height: 14),
            const Text(
              'Pulihkan Akses Staf',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pelanggan (mahasiswa/civitas) tidak perlu login. '
              'Layanan ini khusus akun Tenant dan Kasir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Role Staf',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
              ],
              onChanged: _loading
                  ? null
                  : (v) => setState(() {
                        _role = v ?? 'tenant';
                        _message = null;
                        _error = null;
                      }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(
                labelText: 'Email / ID Akun $roleLabel',
                prefixIcon: const Icon(Icons.person_search_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Minta Bantuan Admin'),
            ),
          ],
        ),
      ),
    );
  }
}