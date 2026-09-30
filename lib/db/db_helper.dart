import 'package:flutter/foundation.dart';

import '../data/dummy_data.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/promo.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../utils/password_hasher.dart';

/// Akses data aplikasi melalui REST API backend (Laravel).
///
/// Dulu class ini membungkus SQLite lokal. Nama class dan semua method
/// publik dipertahankan supaya screen & provider tidak perlu diubah;
/// sekarang setiap method memanggil endpoint `/api/...` yang sepadan.
///
/// Semua method dapat melempar [ApiException] bila server tidak dapat
/// dihubungi atau mengembalikan error.
class DBHelper {
  DBHelper._internal(this._api);

  static final DBHelper instance = DBHelper._internal(ApiClient.instance);

  @visibleForTesting
  factory DBHelper.withClient(ApiClient api) => DBHelper._internal(api);

  final ApiClient _api;

  // ============================================================
  // RESPONSE HELPERS
  // ============================================================

  Map<String, dynamic>? _dataMap(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  List<Map<String, dynamic>> _dataList(dynamic body) {
    final data = body is Map ? body['data'] : null;
    if (data is! List) return const [];
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  int _createdId(dynamic body) => (_dataMap(body)?['id'] as num?)?.toInt() ?? 0;

  int _affected(dynamic body) =>
      body is Map ? (body['affected'] as num?)?.toInt() ?? 0 : 0;

  CampusOrder _orderFromJson(Map<String, dynamic> map) {
    final items = (map['items'] as List? ?? const [])
        .map((row) => OrderItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    return CampusOrder.fromMap(map, items: items);
  }

  List<CampusOrder> _ordersFrom(dynamic body) =>
      _dataList(body).map(_orderFromJson).toList();

  AppUser? _userFrom(dynamic body) {
    final map = _dataMap(body);
    return map == null ? null : AppUser.fromMap(map);
  }

  // ============================================================
  // BOOTSTRAP
  // ============================================================

  /// Dipanggil splash screen. Server membuat akun demo, menu, dan promo
  /// bila belum ada (idempoten).
  Future<void> bootstrapData() async {
    await _api.post('bootstrap');
  }

  // ============================================================
  // USERS
  // ============================================================

  /// Statistik pengguna untuk dashboard admin.
  Future<Map<String, int>> getUserStatistics() async {
    final body = await _api.get('statistics/users');
    const keys = ['total', 'mahasiswa', 'dosen', 'tenant', 'kasir', 'admin'];
    final map = body is Map ? body : const {};
    return {for (final key in keys) key: (map[key] as num?)?.toInt() ?? 0};
  }

  Future<AppUser?> getUserByEmail(String email) async =>
      _userFrom(await _api.get('users', query: {'email': email}));

  Future<AppUser?> getUserByNirm(String nirm) async =>
      _userFrom(await _api.get('users', query: {'nirm': nirm.trim()}));

  Future<AppUser?> findUserForPasswordReset(String identifier) async {
    final value = identifier.trim();
    if (value.isEmpty) return null;
    return _userFrom(await _api.get('users', query: {'identifier': value}));
  }

  Future<AppUser?> getUserById(int id) async =>
      _userFrom(await _api.get('users/$id'));

  Future<List<AppUser>> getAllUsersByRole(String role) async {
    final body = await _api.get('users', query: {'role': role});
    return _dataList(body).map(AppUser.fromMap).toList();
  }

  /// Mengembalikan `null` bila kredensial salah (HTTP 401/422).
  Future<AppUser?> login(String email, String password) async {
    try {
      final body = await _api.post(
        'auth/login',
        body: {'identifier': email.trim(), 'password': password},
      );
      return _userFrom(body);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 422) return null;
      rethrow;
    }
  }

  /// `user.password` harus sudah di-hash (lihat [hashPassword]).
  Future<int> registerUser(AppUser user) async {
    final data = user.toMap()..remove('id');
    return _createdId(await _api.post('users', body: data));
  }

  Future<int> updateUser(AppUser user) async {
    final data = user.toMap()..remove('id');
    return _affected(await _api.put('users/${user.id}', body: data));
  }

  Future<bool> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final body = await _api.put(
      'users/$userId/password',
      body: {'password': hashPassword(newPassword)},
    );
    return _affected(body) > 0;
  }

  // ============================================================
  // PASSWORD RESET REQUESTS
  // ============================================================

  Future<int> createPasswordResetRequest(int userId, String role) async {
    final body = await _api.post(
      'password-reset-requests',
      body: {'userId': userId, 'role': role},
    );
    return _createdId(body);
  }

  Future<List<Map<String, dynamic>>> getPendingPasswordResetRequests() async {
    final body = await _api.get(
      'password-reset-requests',
      query: {'status': 'pending'},
    );
    return _dataList(body);
  }

  Future<void> resolvePasswordResetRequest(
    int requestId,
    int userId,
    String newPassword,
  ) async {
    await _api.put(
      'password-reset-requests/$requestId',
      body: {'userId': userId, 'password': hashPassword(newPassword)},
    );
  }

  // ============================================================
  // ORDERS
  // ============================================================

  /// Server menyimpan pesanan + item + mengirim notifikasi ke pembeli,
  /// staf tenant, dan admin dalam satu request.
  Future<int> createOrder(CampusOrder order) async {
    final data = order.toMap()
      ..remove('id')
      ..['items'] = [
        for (final item in order.items)
          {
            'menuName': item.menuName,
            'price': item.price,
            'quantity': item.quantity,
          },
      ];
    return _createdId(await _api.post('orders', body: data));
  }

  Future<List<CampusOrder>> getOrdersByUser(int userId) async =>
      _ordersFrom(await _api.get('orders', query: {'user_id': userId}));

  Future<List<CampusOrder>> getOrdersByGuestEmail(String email) async {
    final body = await _api.get(
      'orders',
      query: {'guest_email': email.trim().toLowerCase()},
    );
    return _ordersFrom(body);
  }

  Future<List<CampusOrder>> getOrdersByTenant(String tenantName) async =>
      _ordersFrom(await _api.get('orders', query: {'tenant_name': tenantName}));

  Future<List<CampusOrder>> getAllOrders() async =>
      _ordersFrom(await _api.get('orders'));

  Future<CampusOrder?> getOrderByCode(String orderCode) async {
    final body = await _api.get(
      'orders',
      query: {'order_code': orderCode.trim()},
    );
    final map = _dataMap(body);
    return map == null ? null : _orderFromJson(map);
  }

  Future<CampusOrder?> getOrderById(int orderId) async {
    final map = _dataMap(await _api.get('orders/$orderId'));
    return map == null ? null : _orderFromJson(map);
  }

  Future<int> confirmCashPayment(int orderId) async =>
      _affected(await _api.post('orders/$orderId/confirm-cash-payment'));

  Future<int> markVirtualPaymentPaid(int orderId) async =>
      _affected(await _api.post('orders/$orderId/mark-virtual-paid'));

  /// Mengembalikan 0 bila pesanan tidak ditemukan.
  Future<int> updateOrderStatus(int orderId, String status) async {
    try {
      final body = await _api.put(
        'orders/$orderId/status',
        body: {'status': status},
      );
      return _affected(body);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return 0;
      rethrow;
    }
  }

  // ============================================================
  // MENUS
  // ============================================================

  Future<List<MenuItem>> getAllMenus() async =>
      _dataList(await _api.get('menus')).map(MenuItem.fromMap).toList();

  /// Foto default dipakai saat menu disimpan tanpa URL gambar.
  Map<String, dynamic> _menuPayload(MenuItem menu) {
    final data = menu.toMap()..remove('id');
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    if (imageUrl.isEmpty) data['imageUrl'] = DummyData.photoAssetFor(menu.name);
    return data;
  }

  Future<int> insertMenu(MenuItem menu) async =>
      _createdId(await _api.post('menus', body: _menuPayload(menu)));

  Future<int> updateMenu(MenuItem menu) async =>
      _affected(await _api.put('menus/${menu.id}', body: _menuPayload(menu)));

  Future<int> deleteMenu(int id) async =>
      _affected(await _api.delete('menus/$id'));

  Future<int> setMenuAvailability(int id, bool tersedia) async {
    final body = await _api.patch(
      'menus/$id/availability',
      body: {'tersedia': tersedia ? 1 : 0},
    );
    return _affected(body);
  }

  /// Hitung ulang rata-rata rating & jumlah ulasan sebuah menu.
  Future<void> updateMenuRating(int menuId) async {
    await _api.post('menus/$menuId/recalculate-rating');
  }

  // ============================================================
  // PROMOS
  // ============================================================

  Future<List<Promo>> getAllPromos() async =>
      _dataList(await _api.get('promos')).map(Promo.fromMap).toList();

  Future<Promo?> getBestActivePromo() async {
    final map = _dataMap(await _api.get('promos/best-active'));
    return map == null ? null : Promo.fromMap(map);
  }

  Future<int> insertPromo(Promo promo) async {
    final data = promo.toMap()..remove('id');
    return _createdId(await _api.post('promos', body: data));
  }

  Future<int> updatePromo(Promo promo) async {
    final data = promo.toMap()..remove('id');
    return _affected(await _api.put('promos/${promo.id}', body: data));
  }

  Future<int> deletePromo(int id) async =>
      _affected(await _api.delete('promos/$id'));

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<int> createNotification(
    int userId,
    String title,
    String message,
    String type,
  ) async {
    final body = await _api.post(
      'notifications',
      body: {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
      },
    );
    return _createdId(body);
  }

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async =>
      _dataList(await _api.get('notifications', query: {'user_id': userId}));

  Future<void> markNotificationsRead(int userId) async {
    await _api.put('notifications/read-all', query: {'user_id': userId});
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    final body = await _api.get(
      'notifications/unread-count',
      query: {'user_id': userId},
    );
    return (_dataMap(body)?['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> deleteNotification(int id) async =>
      _affected(await _api.delete('notifications/$id'));

  Future<int> deleteAllNotifications(int userId) async =>
      _affected(await _api.delete('notifications', query: {'user_id': userId}));

  // ============================================================
  // STATISTICS
  // ============================================================

  Future<List<Map<String, dynamic>>> getRatingsSummary() async =>
      _dataList(await _api.get('statistics/ratings-summary'));

  Future<List<Map<String, dynamic>>> getDailySales({
    int days = 7,
    String? tenantName,
  }) async {
    final body = await _api.get(
      'statistics/daily-sales',
      query: {'days': days, 'tenant_name': tenantName},
    );
    return _dataList(body);
  }

  Future<List<Map<String, dynamic>>> getMonthlySales({
    int months = 6,
    String? tenantName,
  }) async {
    final body = await _api.get(
      'statistics/monthly-sales',
      query: {'months': months, 'tenant_name': tenantName},
    );
    return _dataList(body);
  }

  Future<List<Map<String, dynamic>>> getMenuCategorySales({
    String? tenantName,
  }) async {
    final body = await _api.get(
      'statistics/menu-category-sales',
      query: {'tenant_name': tenantName},
    );
    return _dataList(body);
  }

  // ============================================================
  // TOPUP & RATING
  // ============================================================

  Future<int> createTopup(int userId, double amount) async {
    final body = await _api.post(
      'topups',
      body: {'userId': userId, 'amount': amount, 'status': 'success'},
    );
    return _createdId(body);
  }

  /// Rating untuk kombinasi (user, menu, order) yang sama akan ditimpa.
  Future<int> createRating({
    required int userId,
    required int menuId,
    required int orderId,
    required int rating,
    String? review,
  }) async {
    final body = await _api.post(
      'ratings',
      body: {
        'userId': userId,
        'menuId': menuId,
        'orderId': orderId,
        'rating': rating,
        'review': review,
      },
    );
    return _createdId(body);
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  Future<List<int>> getFavoriteMenuIds(int userId) async {
    final body = await _api.get('favorites', query: {'user_id': userId});
    return _dataList(body)
        .map((row) => (row['menuId'] as num).toInt())
        .toList();
  }

  Future<void> addFavorite(int userId, int menuId) async {
    await _api.post('favorites', body: {'userId': userId, 'menuId': menuId});
  }

  Future<void> removeFavorite(int userId, int menuId) async {
    await _api.delete(
      'favorites',
      query: {'user_id': userId, 'menu_id': menuId},
    );
  }
}
