import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

ImageProvider _photoProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  final _picker = ImagePicker();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl.text = user?.name ?? '';
    _emailCtrl.text = user?.email ?? '';
    _photoPath = user?.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null && mounted) setState(() => _photoPath = file.path);
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan email wajib diisi')),
      );
      return;
    }

    setState(() => _loading = true);

    final updated = AppUser(
      id: user.id,
      name: name,
      email: email,
      password: password.isEmpty ? user.password : password,
      role: user.role,
      photoPath: _photoPath,
      saldo: user.saldo,
      tenantName: user.tenantName,
    );

    await auth.updateProfile(updated);

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: _photoPath == null
                      ? null
                      : _photoProvider(_photoPath!),
                  child: _photoPath == null
                      ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: _pickPhoto,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password Baru (kosongkan jika tidak diubah)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_loading ? 'Menyimpan...' : 'Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}
