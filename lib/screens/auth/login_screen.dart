import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smart_logo.dart';
import '../home/main_shell.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_identifierCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Email/ID staf dan kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context
        .read<AuthProvider>()
        .loginStaff(_identifierCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final userId = context.read<AuthProvider>().currentUser?.id;
    await context.read<FavoriteProvider>().loadForUser(userId);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.gradientSplash),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: SmartLogo(
                              size: 84,
                              background: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Portal Staf',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Masuk sebagai Admin, Tenant, atau Kasir',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _identifierCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined),
                              hintText: 'Username / Email staf',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              hintText: 'Kata sandi',
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              child: const Text('Lupa Password Staf?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Masuk sebagai Staf'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainShell(),
                                  ),
                                  (_) => false,
                                ),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Kembali ke Pengaturan'),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Akun Demo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'admin / admin123\n'
                                  'tenant1 / tenant123\n'
                                  'kasir / kasir123',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceMuted,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
