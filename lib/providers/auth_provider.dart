import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/db_helper.dart';
import '../models/user.dart';
import '../utils/password_hasher.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isGuest => _currentUser == null;
  String? _guestName;
  String? _guestEmail;
  String? get guestName => _guestName;
  String? get guestEmail => _guestEmail;

  final _db = DBHelper.instance;
  static const campusTenant = 'Kantin Kampus';
  static final RegExp _strongPassword = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  bool _validPassword(String password) => _strongPassword.hasMatch(password);

  Future<void> bootstrapData() async => _db.bootstrapData();

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;
    final user = await _db.getUserById(userId);
    if (user == null || !{'admin', 'tenant', 'kasir'}.contains(user.role)) {
      await prefs.remove('userId');
      return;
    }
    _currentUser = user;
    notifyListeners();
  }

  Future<String?> loginStaff(String identifier, String password) async {
    var value = identifier.trim();
    if (value.isEmpty || password.isEmpty) return 'Username/email staf dan kata sandi wajib diisi';
    const staffAliases = <String, String>{
      'admin': 'admin@kantin.app',
      'kasir': 'kasir@kantin.app',
      'tenant1': 'tenant1@kantin.app',
    };
    value = staffAliases[value.toLowerCase()] ?? value;
    final user = await _db.login(value, password);
    if (user == null) return 'Kredensial staf tidak cocok.';
    if (!{'admin', 'tenant', 'kasir'}.contains(user.role)) return 'Login mahasiswa/dosen telah dinonaktifkan. Gunakan Guest Checkout.';
    _currentUser = user;
    _guestName = null;
    _guestEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id!);
    notifyListeners();
    return null;
  }

  Future<String?> login(String identifier, String password) => loginStaff(identifier, password);

  Future<void> setGuestSession({required String name, required String email}) async {
    _currentUser = null;
    _guestName = name.trim();
    _guestEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.setString('guestName', _guestName!);
    await prefs.setString('guestEmail', _guestEmail!);
    notifyListeners();
  }

  Future<void> restoreGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    _guestName = prefs.getString('guestName');
    _guestEmail = prefs.getString('guestEmail');
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String nirm,
    String role = 'mahasiswa',
    String? tenantName,
  }) async => 'Pendaftaran mahasiswa/dosen tidak diperlukan. Gunakan Guest Checkout.';

  Future<String?> createManagedAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    String? tenantName,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) return 'Semua field wajib diisi';
    if (!_validPassword(password)) return 'Password minimal 8 karakter dan harus mengandung huruf serta angka';
    if (role != 'tenant' && role != 'kasir') return 'Role tidak valid';
    if (await _db.getUserByEmail(email.trim()) != null) return 'Email sudah terdaftar';
    await _db.registerUser(AppUser(name: name.trim(), email: email.trim(), password: hashPassword(password), role: role, tenantName: campusTenant, saldo: 0));
    return null;
  }

  Future<String?> requestStaffPasswordReset({required String identifier, required String role}) async {
    final user = await _db.findUserForPasswordReset(identifier.trim());
    if (user == null || user.role != role) return 'Akun staff tidak ditemukan atau role tidak sesuai';
    await _db.createPasswordResetRequest(user.id!, user.role);
    final admins = await _db.getAllUsersByRole('admin');
    for (final admin in admins) {
      await _db.createNotification(admin.id!, 'Permintaan Reset Password', '${user.name} (${user.role}) meminta bantuan reset password.', 'security');
    }
    return 'Permintaan reset password dikirim ke Admin.';
  }

  String _paymentPreferenceKey(int userId) => 'preferred_payment_mode_$userId';

  Future<String> getPreferredPaymentMode() async {
    final userId = _currentUser?.id;
    if (userId == null) return 'online';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_paymentPreferenceKey(userId)) == 'cash' ? 'cash' : 'online';
  }

  Future<void> setPreferredPaymentMode(String mode) async {
    final userId = _currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paymentPreferenceKey(userId), mode == 'cash' ? 'cash' : 'online');
    notifyListeners();
  }

  Future<void> updateProfile(AppUser updated) async {
    await _db.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<String?> resetPassword({required String identifier, required String newPassword, String? role}) async {
    if (identifier.trim().isEmpty) return 'Masukkan email atau ID';
    if (!_validPassword(newPassword)) return 'Password minimal 8 karakter dan harus mengandung huruf serta angka';
    final user = await _db.findUserForPasswordReset(identifier);
    if (user == null) return 'Akun tidak ditemukan';
    if (role != null && user.role != role) return 'Role akun tidak sesuai';
    await _db.resetPassword(userId: user.id!, newPassword: newPassword);
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}
