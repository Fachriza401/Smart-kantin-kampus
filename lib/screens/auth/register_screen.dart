import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'forgot_password_screen.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../home/main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _identityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _role = 'mahasiswa';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get _isDosen => _role == 'dosen';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identityCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      nirm: _identityCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      if (error.toLowerCase().contains('sudah terdaftar')) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Akun sudah terdaftar'),
            content: const Text(
              'ID akademik atau email tersebut sudah digunakan. Gunakan fitur Lupa Password untuk memulihkan akses.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text('Lupa Password'),
              ),
            ],
          ),
        );
      }
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Buat akun Smart Kantin Kampus',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih status Anda. ID akademik dan email harus unik.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Daftar sebagai',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'mahasiswa',
                    child: Text('Mahasiswa'),
                  ),
                  DropdownMenuItem(
                    value: 'dosen',
                    child: Text('Dosen'),
                  ),
                ],
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _role = value ?? 'mahasiswa'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.trim().length < 3
                        ? 'Nama lengkap wajib diisi'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _identityCtrl,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: _isDosen ? 'NIP / ID Dosen' : 'NIRM / NIM',
                  hintText: _isDosen ? 'Contoh: 198701012023011001' : 'Contoh: 2023020399',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'ID akademik wajib diisi';
                  if (v.length < 6) return 'ID akademik terlalu pendek';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) => !RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(value ?? '')
                    ? 'Password minimal 8 karakter dan harus mengandung huruf serta angka'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (value) =>
                    value != _passCtrl.text ? 'Password tidak sama' : null,
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
                    : const Text('Daftar Akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
