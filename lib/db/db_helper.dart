import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/dummy_data.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/promo.dart';
import '../models/user.dart';
import '../utils/password_hasher.dart';

/// Helper database lokal (SQLite) menggunakan package `sqflite`.
///
/// Database menyimpan:
/// - users
/// - orders
/// - order_items
/// - menus
/// - promos
///
/// Database version saat ini: 21
class DBHelper {
  DBHelper._internal();

  static final DBHelper instance = DBHelper._internal();

  static Database? _database;

  // ============================================================
  // DATABASE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(
      dbPath,
      'smart_kantin_kampus.db',
    );

    return openDatabase(
      path,
      version: 23,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // DATABASE UPGRADE / MIGRATION
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // ----------------------------------------------------------
    // VERSION 1 -> VERSION 2
    // Tambahkan tenantName ke users
    // ----------------------------------------------------------

    if (oldVersion < 2) {
      final hasTenantName = await _columnExists(
        db,
        'users',
        'tenantName',
      );

      if (!hasTenantName) {
        await db.execute(
          'ALTER TABLE users ADD COLUMN tenantName TEXT',
        );
      }
    }

    // ----------------------------------------------------------
    // VERSION 2 -> VERSION 3
    //
    // Pada versi lama, menus dan promos dibuat ketika upgrade.
    // Kita pertahankan supaya database lama tetap kompatibel.
    // ----------------------------------------------------------

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS menus (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenantId INTEGER NOT NULL,
          tenantName TEXT NOT NULL,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          rating REAL NOT NULL DEFAULT 0,
          reviewCount INTEGER NOT NULL DEFAULT 0,
          estimasi TEXT,
          tersedia INTEGER NOT NULL DEFAULT 1,
          icon TEXT,
          imageUrl TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS promos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          discount REAL NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          icon TEXT
        )
      ''');
    }

    // ----------------------------------------------------------
    // VERSION 3 -> VERSION 4
    //
    // Ini bagian penting untuk memperbaiki error:
    //
    // table menus has no column named imageUrl
    //
    // Kita tidak membuat tabel menus lagi.
    // Kita hanya menambahkan kolom imageUrl jika belum ada.
    // ----------------------------------------------------------

    if (oldVersion < 4) {
      final menusExists = await _tableExists(
        db,
        'menus',
      );

      if (!menusExists) {
        await db.execute('''
          CREATE TABLE menus (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tenantId INTEGER NOT NULL,
            tenantName TEXT NOT NULL,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            rating REAL NOT NULL DEFAULT 0,
            reviewCount INTEGER NOT NULL DEFAULT 0,
            estimasi TEXT,
            tersedia INTEGER NOT NULL DEFAULT 1,
            icon TEXT,
            imageUrl TEXT
          )
        ''');
      } else {
        final hasImageUrl = await _columnExists(
          db,
          'menus',
          'imageUrl',
        );

        if (!hasImageUrl) {
          await db.execute(
            'ALTER TABLE menus ADD COLUMN imageUrl TEXT',
          );
        }
      }
    }

    // VERSION 5/6: promo banner, topup, notification, rating.
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL, title TEXT NOT NULL, message TEXT NOT NULL,
          type TEXT NOT NULL, isRead INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS topups (
          id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER NOT NULL, amount REAL NOT NULL,
          status TEXT NOT NULL, createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ratings (
          id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER NOT NULL, menuId INTEGER NOT NULL,
          orderId INTEGER NOT NULL, rating INTEGER NOT NULL, review TEXT, createdAt TEXT NOT NULL,
          UNIQUE(userId, menuId, orderId)
        )
      ''');
      if (!await _columnExists(db, 'promos', 'imageUrl'))
        await db.execute('ALTER TABLE promos ADD COLUMN imageUrl TEXT');
      if (!await _columnExists(db, 'promos', 'startDate'))
        await db.execute('ALTER TABLE promos ADD COLUMN startDate TEXT');
      if (!await _columnExists(db, 'promos', 'endDate'))
        await db.execute('ALTER TABLE promos ADD COLUMN endDate TEXT');
    }

    if (oldVersion < 6) {
      await _insertStudentIfAbsent(db);
      await _insertPromoImagesIfEmpty(db);
    }

    // VERSION 7: NIRM mahasiswa untuk pendaftaran unik.
    if (oldVersion < 7) {
      if (!await _columnExists(db, 'users', 'nirm')) {
        await db.execute('ALTER TABLE users ADD COLUMN nirm TEXT');
      }
      await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_nirm ON users(nirm)');
      await _insertStudentIfAbsent(db);
    }

    // VERSION 8: satu tenant resmi untuk seluruh aplikasi.
    if (oldVersion < 8) {
      await _normalizeCampusTenant(db);
    }

    if (oldVersion < 9) {
      await _ensureMenuImages(db);
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS password_reset_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          role TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          createdAt TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 11) {
      await _normalizeCampusTenant(db);
      await _ensureMenuImages(db);
    }

    // VERSION 12: reset akun Tenant/Kasir dan buat ulang akun resmi.
    if (oldVersion < 12) {
      await db.delete('users', where: "role IN ('tenant','kasir')");
      await _insertTenantsIfAbsent(db);
      await _normalizeCampusTenant(db);
    }

    // VERSION 13: simpan penerima pembayaran pada setiap order.
    if (oldVersion < 13) {
      if (!await _columnExists(db, 'orders', 'paymentRecipient')) {
        await db.execute(
            "ALTER TABLE orders ADD COLUMN paymentRecipient TEXT NOT NULL DEFAULT 'Admin Smart Kantin'");
      }
    }

    // VERSION 14: pastikan setiap kategori memiliki minimal 10 menu bergambar.
    if (oldVersion < 14) {
      await _ensureMinimumMenusPerCategory(db);
    }

    // VERSION 15: reset akun Tenant/Kasir dan buat ulang akun demo resmi.
    if (oldVersion < 15) {
      await db.delete('users', where: "role IN ('tenant','kasir')");
      await _insertTenantsIfAbsent(db, forceReset: true);
      await _normalizeCampusTenant(db);
    }

    // VERSION 16: paymentStatus untuk sinkronisasi pembayaran Admin/Kasir.
    if (oldVersion < 16) {
      if (!await _columnExists(db, 'orders', 'paymentStatus')) {
        await db.execute(
            "ALTER TABLE orders ADD COLUMN paymentStatus TEXT NOT NULL DEFAULT 'Lunas'");
      }
      await db.execute(
          "UPDATE orders SET paymentStatus = 'Lunas' WHERE paymentMethod != 'Bayar Langsung'");
      await db.execute(
          "UPDATE orders SET paymentStatus = 'Menunggu Pembayaran' WHERE paymentMethod = 'Bayar Langsung' AND (paymentStatus IS NULL OR paymentStatus = '')");
    }

    // VERSION 17-20: Guest Checkout & payment receipt fields.
    if (oldVersion < 17) {
      if (!await _columnExists(db, 'orders', 'guestName'))
        await db.execute('ALTER TABLE orders ADD COLUMN guestName TEXT');
      if (!await _columnExists(db, 'orders', 'guestEmail'))
        await db.execute('ALTER TABLE orders ADD COLUMN guestEmail TEXT');
      if (!await _columnExists(db, 'orders', 'queueNumber'))
        await db.execute(
            "ALTER TABLE orders ADD COLUMN queueNumber TEXT NOT NULL DEFAULT 'A01'");
    }
    if (oldVersion < 18) {
      if (!await _columnExists(db, 'orders', 'paymentLink'))
        await db.execute('ALTER TABLE orders ADD COLUMN paymentLink TEXT');
      if (!await _columnExists(db, 'orders', 'paymentQrPayload'))
        await db.execute('ALTER TABLE orders ADD COLUMN paymentQrPayload TEXT');
    }
    if (oldVersion < 19) {
      await db.execute(
          "UPDATE orders SET queueNumber = 'A' || printf('%02d', id) WHERE queueNumber IS NULL OR queueNumber = ''");
    }
    if (oldVersion < 20) {
      // Ensure staff demo accounts survive migration; student accounts remain stored but are no longer required to access the app.
      await _insertAdminIfAbsent(db);
      await _insertTenantsIfAbsent(db);
    }

    // VERSION 21: reset/normalize staff demo credentials to the public V21 credentials.
    if (oldVersion < 21) {
      await db.delete('users', where: "role IN ('tenant','kasir')");
      await db.delete('users',
          where: "role = 'admin' AND email != ?",
          whereArgs: ['admin@kantin.app']);
      await _insertAdminIfAbsent(db);
      await _insertTenantsIfAbsent(db, forceReset: true);
      await _normalizeCampusTenant(db);
    }

    // VERSION 22: fitur favorit/wishlist menu.
    if (oldVersion < 22) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites (
          userId INTEGER NOT NULL,
          menuId INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          PRIMARY KEY (userId, menuId)
        )
      ''');
    }

    // VERSION 23: perbaiki foto menu.
    // Menu dengan gambar kosong/placeholder (mis. loremflickr) diganti
    // dengan aset gambar lokal yang sesuai dengan nama produknya.
    if (oldVersion < 23) {
      await _ensureMenuImages(db);
    }
  }

  // ============================================================
  // CHECK TABLE
  // ============================================================

  Future<bool> _tableExists(
    Database db,
    String tableName,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name = ?
      LIMIT 1
      ''',
      [tableName],
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // CHECK COLUMN
  // ============================================================

  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final result = await db.rawQuery(
      'PRAGMA table_info($tableName)',
    );

    return result.any(
      (column) => column['name'] == columnName,
    );
  }

  // ============================================================
  // DATABASE CREATE
  // ============================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // ----------------------------------------------------------
    // USERS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'mahasiswa',
        nirm TEXT,
        photoPath TEXT,
        saldo REAL NOT NULL DEFAULT 0,
        tenantName TEXT
      )
    ''');

    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_nirm ON users(nirm)');

    // ----------------------------------------------------------
    // ORDERS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        orderCode TEXT NOT NULL,
        tenantName TEXT NOT NULL,
        total REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        paymentRecipient TEXT NOT NULL DEFAULT 'Admin Smart Kantin',
        paymentStatus TEXT NOT NULL DEFAULT 'Menunggu Pembayaran',
        status TEXT NOT NULL,
        pickupTime TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        guestName TEXT,
        guestEmail TEXT,
        queueNumber TEXT NOT NULL DEFAULT 'A01',
        paymentLink TEXT,
        paymentQrPayload TEXT
      )
    ''');

    // ----------------------------------------------------------
    // ORDER ITEMS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        menuName TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (orderId)
          REFERENCES orders (id)
          ON DELETE CASCADE
      )
    ''');

    // ----------------------------------------------------------
    // MENUS
    //
    // imageUrl SUDAH ADA DI SINI.
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE menus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenantId INTEGER NOT NULL,
        tenantName TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        rating REAL NOT NULL DEFAULT 0,
        reviewCount INTEGER NOT NULL DEFAULT 0,
        estimasi TEXT,
        tersedia INTEGER NOT NULL DEFAULT 1,
        icon TEXT,
        imageUrl TEXT
      )
    ''');

    // ----------------------------------------------------------
    // PROMOS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE promos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        discount REAL NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        icon TEXT,
        imageUrl TEXT,
        startDate TEXT,
        endDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE topups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        menuId INTEGER NOT NULL,
        orderId INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        review TEXT,
        createdAt TEXT NOT NULL,
        UNIQUE(userId, menuId, orderId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS password_reset_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        userId INTEGER NOT NULL,
        menuId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        PRIMARY KEY (userId, menuId)
      )
    ''');

    // ----------------------------------------------------------
    // SEED INITIAL DATA
    // ----------------------------------------------------------

    await _seedInitialData(db);
  }

  // ============================================================
  // SEED INITIAL DATA
  // ============================================================

  /// Mengisi data awal:
  /// - admin
  /// - tenant
  /// - menu
  /// - promo
  Future<void> _seedInitialData(
    Database db,
  ) async {
    await _insertAdminIfAbsent(db);
    await _insertMenusIfAbsent(db);
    await _ensureMinimumMenusPerCategory(db);
    await _insertPromosIfAbsent(db);
    await _insertTenantsIfAbsent(db);
    await _insertStudentIfAbsent(db);
    await _insertPromoImagesIfEmpty(db);
  }

  // ============================================================
  // USERS
  // ============================================================

  /// Statistik pengguna untuk dashboard admin.
  Future<Map<String, int>> getUserStatistics() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    final mahasiswa = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM users WHERE role = 'mahasiswa'",
          ),
        ) ??
        0;
    final tenant = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM users WHERE role = 'tenant'",
          ),
        ) ??
        0;
    final kasir = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM users WHERE role = 'kasir'",
          ),
        ) ??
        0;
    final admin = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM users WHERE role = 'admin'"),
        ) ??
        0;
    final dosenCount = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM users WHERE role = 'dosen'"),
        ) ??
        0;
    return {
      'total': total,
      'mahasiswa': mahasiswa,
      'dosen': dosenCount,
      'tenant': tenant,
      'kasir': kasir,
      'admin': admin,
    };
  }

  Future<AppUser?> getUserByEmail(
    String email,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserByNirm(String nirm) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'nirm = ?',
      whereArgs: [nirm.trim()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<int> createPasswordResetRequest(int userId, String role) async {
    final db = await database;
    return db.insert('password_reset_requests', {
      'userId': userId,
      'role': role,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingPasswordResetRequests() async {
    final db = await database;
    return db.rawQuery('''
      SELECT r.*, u.name, u.email, u.tenantName
      FROM password_reset_requests r
      JOIN users u ON u.id = r.userId
      WHERE r.status = 'pending'
      ORDER BY r.id DESC
    ''');
  }

  Future<void> resolvePasswordResetRequest(
    int requestId,
    int userId,
    String newPassword,
  ) async {
    final db = await database;
    await db.update(
      'users',
      {'password': hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
    await db.update(
      'password_reset_requests',
      {'status': 'resolved'},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  Future<AppUser?> findUserForPasswordReset(String identifier) async {
    final value = identifier.trim();
    if (value.isEmpty) return null;
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? OR nirm = ?',
      whereArgs: [value, value],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<bool> resetPassword(
      {required int userId, required String newPassword}) async {
    final db = await database;
    final rows = await db.update(
      'users',
      {'password': hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }

  Future<AppUser?> login(String email, String password) async {
    final db = await database;
    final result = await db.query('users',
        where: 'email = ? OR nirm = ?',
        whereArgs: [email.trim(), email.trim()],
        limit: 1);
    if (result.isEmpty) return null;
    final row = result.first;
    final stored = row['password']?.toString() ?? '';
    final valid = verifyPassword(password, stored) || stored == password;
    if (!valid) return null;
    if (stored == password) {
      final hashed = hashPassword(password);
      await db.update('users', {'password': hashed},
          where: 'id = ?', whereArgs: [row['id']]);
      row['password'] = hashed;
    }
    return AppUser.fromMap(row);
  }

  Future<int> registerUser(
    AppUser user,
  ) async {
    final db = await database;

    final data = user.toMap();

    data.remove('id');

    return db.insert(
      'users',
      data,
    );
  }

  Future<List<AppUser>> getAllUsersByRole(String role) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'id ASC',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> getUserById(
    int id,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  Future<int> updateUser(
    AppUser user,
  ) async {
    final db = await database;

    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ============================================================
  // ORDERS
  // ============================================================

  Future<int> createOrder(CampusOrder order) async {
    final db = await database;
    final orderData = order.toMap()..remove('id');
    orderData['paymentStatus'] = order.paymentMethod == 'Bayar Langsung'
        ? 'Menunggu Pembayaran'
        : 'Lunas';

    final newId = await db.transaction((txn) async {
      final id = await txn.insert('orders', orderData);
      for (final item in order.items) {
        await txn.insert('order_items', {
          'orderId': id,
          'menuName': item.menuName,
          'price': item.price,
          'quantity': item.quantity,
        });
      }
      return id;
    });

    if (order.userId > 0) {
      await createNotification(
        order.userId,
        'Pesanan berhasil dibuat',
        '${order.orderCode} tersimpan. Nomor antrean ${order.queueNumber}.',
        'order',
      );
    }

    final staff = await db.query(
      'users',
      where: 'tenantName = ? AND role IN (?, ?)',
      whereArgs: [order.tenantName, 'tenant', 'kasir'],
    );
    for (final row in staff) {
      await createNotification(
        row['id'] as int,
        'Pesanan Baru',
        '${order.orderCode} dari ${order.guestName ?? 'Guest'} menunggu proses.',
        'order',
      );
    }

    final admins =
        await db.query('users', where: 'role = ?', whereArgs: ['admin']);
    for (final row in admins) {
      await createNotification(
        row['id'] as int,
        'Transaksi Guest Masuk',
        '${order.orderCode} • ${order.guestName ?? 'Guest'} • ${order.paymentMethod}.',
        'payment',
      );
    }

    return newId;
  }

  Future<List<CampusOrder>> getOrdersByUser(
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    final orders = <CampusOrder>[];

    for (final map in result) {
      final itemsMap = await db.query(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [map['id']],
      );

      final items = itemsMap
          .map(
            (e) => OrderItem.fromMap(e),
          )
          .toList();

      orders.add(
        CampusOrder.fromMap(
          map,
          items: items,
        ),
      );
    }

    return orders;
  }

  Future<List<CampusOrder>> getOrdersByGuestEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'orders',
      where: 'guestEmail = ? AND userId = 0',
      whereArgs: [email.trim().toLowerCase()],
      orderBy: 'id DESC',
    );
    final orders = <CampusOrder>[];
    for (final map in result) {
      final itemsMap = await db
          .query('order_items', where: 'orderId = ?', whereArgs: [map['id']]);
      orders.add(CampusOrder.fromMap(map,
          items: itemsMap.map(OrderItem.fromMap).toList()));
    }
    return orders;
  }

  Future<List<CampusOrder>> getAllOrders() async {
    final db = await database;
    final result = await db.query('orders', orderBy: 'id DESC');
    final orders = <CampusOrder>[];
    for (final map in result) {
      final itemsMap = await db
          .query('order_items', where: 'orderId = ?', whereArgs: [map['id']]);
      orders.add(CampusOrder.fromMap(map,
          items: itemsMap.map((e) => OrderItem.fromMap(e)).toList()));
    }
    return orders;
  }

  Future<CampusOrder?> getOrderByCode(
    String orderCode,
  ) async {
    final db = await database;

    final result = await db.query(
      'orders',
      where: 'orderCode = ?',
      whereArgs: [orderCode.trim()],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final orderId = result.first['id'] as int;
    final itemsMap = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );

    return CampusOrder.fromMap(
      result.first,
      items: itemsMap.map((e) => OrderItem.fromMap(e)).toList(),
    );
  }

  Future<CampusOrder?> getOrderById(
    int orderId,
  ) async {
    final db = await database;

    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (result.isEmpty) {
      return null;
    }

    final itemsMap = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );

    final items = itemsMap
        .map(
          (e) => OrderItem.fromMap(e),
        )
        .toList();

    return CampusOrder.fromMap(
      result.first,
      items: items,
    );
  }

  Future<int> confirmCashPayment(int orderId) async {
    final db = await database;
    final rows = await db.query('orders',
        where: 'id = ?', whereArgs: [orderId], limit: 1);
    if (rows.isEmpty) return 0;
    final row = rows.first;
    final result = await db.update(
      'orders',
      {'paymentStatus': 'Lunas', 'status': 'Menunggu Persetujuan Tenant'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (result > 0) {
      final userId = row['userId'] as int;
      final code = row['orderCode'].toString();
      await createNotification(userId, 'Pembayaran Dikonfirmasi',
          'Pembayaran $code sudah dinyatakan Lunas oleh petugas.', 'payment');
      final admins =
          await db.query('users', where: 'role = ?', whereArgs: ['admin']);
      for (final admin in admins) {
        await createNotification(admin['id'] as int, 'Pembayaran Lunas',
            'Pembayaran langsung $code telah dikonfirmasi.', 'payment');
      }
      final staff = await db
          .query('users', where: "role IN ('tenant','kasir')", whereArgs: []);
      for (final member in staff) {
        final role = member['role']?.toString();
        final title = role == 'tenant'
            ? 'Pesanan Menunggu Persetujuan'
            : 'Pembayaran Lunas';
        final message = role == 'tenant'
            ? '$code sudah lunas dan menunggu persetujuan Tenant sebelum diproses.'
            : '$code sudah lunas dan akan diproses setelah disetujui Tenant.';
        await createNotification(
            member['id'] as int, title, message, 'payment');
      }
    }
    return result;
  }

  Future<int> markVirtualPaymentPaid(int orderId) async {
    final db = await database;
    final rows = await db.query('orders',
        where: 'id = ?', whereArgs: [orderId], limit: 1);
    if (rows.isEmpty) return 0;
    final row = rows.first;
    final result = await db.update(
      'orders',
      {'paymentStatus': 'Lunas', 'status': 'Menunggu Persetujuan Tenant'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (result > 0) {
      final userId = (row['userId'] as num?)?.toInt() ?? 0;
      final code = row['orderCode'].toString();
      if (userId > 0) {
        await createNotification(
            userId,
            'Pembayaran Berhasil',
            'Pembayaran $code sudah dinyatakan Lunas. Pesanan menunggu persetujuan Tenant.',
            'payment');
      }
      final admins =
          await db.query('users', where: 'role = ?', whereArgs: ['admin']);
      for (final admin in admins) {
        await createNotification(admin['id'] as int, 'Pembayaran Guest Lunas',
            'Pembayaran virtual $code sudah diverifikasi.', 'payment');
      }
      final staff = await db
          .query('users', where: "role IN ('tenant','kasir')", whereArgs: []);
      for (final member in staff) {
        await createNotification(member['id'] as int, 'Pembayaran Guest Lunas',
            '$code dapat diproses setelah pembayaran diterima.', 'payment');
      }
    }
    return result;
  }

  Future<int> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final db = await database;
    final rows = await db.query('orders',
        where: 'id = ?', whereArgs: [orderId], limit: 1);
    final result = await db.update('orders', {'status': status},
        where: 'id = ?', whereArgs: [orderId]);
    if (result > 0 && rows.isNotEmpty) {
      final row = rows.first;
      final userId = row['userId'] as int;
      final orderCode = row['orderCode'].toString();
      final tenantName = row['tenantName'].toString();
      await createNotification(
        userId,
        'Status Pesanan',
        'Pesanan $orderCode sekarang: $status.',
        'order',
      );

      final dbStaff = await db.query(
        'users',
        where: 'tenantName = ? AND role IN (?, ?)',
        whereArgs: [tenantName, 'tenant', 'kasir'],
      );
      for (final staff in dbStaff) {
        if (status == 'Siap Diambil') {
          await createNotification(
            staff['id'] as int,
            'Pesanan Siap Diambil',
            '$orderCode sudah selesai disiapkan dan siap diverifikasi kasir.',
            'order',
          );
        } else if (status == 'Diproses' || status == 'Dimasak') {
          await createNotification(
            staff['id'] as int,
            'Update Produksi Pesanan',
            '$orderCode sekarang berstatus $status.',
            'order',
          );
        }
      }

      final admins =
          await db.query('users', where: 'role = ?', whereArgs: ['admin']);
      for (final admin in admins) {
        await createNotification(
          admin['id'] as int,
          'Monitoring Pesanan',
          '$orderCode sekarang berstatus $status.',
          'order',
        );
      }
    }
    return result;
  }

  /// Ambil semua pesanan yang ditujukan
  /// untuk tenant tertentu.
  Future<List<CampusOrder>> getOrdersByTenant(
    String tenantName,
  ) async {
    final db = await database;

    final result = await db.query(
      'orders',
      where: 'tenantName = ?',
      whereArgs: [tenantName],
      orderBy: 'id DESC',
    );

    final orders = <CampusOrder>[];

    for (final map in result) {
      final itemsMap = await db.query(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [map['id']],
      );

      final items = itemsMap
          .map(
            (e) => OrderItem.fromMap(e),
          )
          .toList();

      orders.add(
        CampusOrder.fromMap(
          map,
          items: items,
        ),
      );
    }

    return orders;
  }

  // ============================================================
  // SEED ADMIN
  // ============================================================

  /// Membuat akun admin sekali jika belum ada.
  Future<void> _insertAdminIfAbsent(
    Database db,
  ) async {
    const email = 'admin@kantin.app';

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    await db.insert(
      'users',
      {
        'name': 'Administrator',
        'email': email,
        'password': hashPassword('admin123'),
        'role': 'admin',
        'nirm': null,
        'photoPath': null,
        'saldo': 0,
        'tenantName': null,
      },
    );
  }

  Future<void> _insertStudentIfAbsent(Database db) async {
    const email = 'fachriza@kantin.app';
    const nirm = 'FACHRIZA001';
    final hasNirm = await _columnExists(db, 'users', 'nirm');
    final existing = await db.query('users',
        where: 'email = ?', whereArgs: [email], limit: 1);
    if (existing.isEmpty) {
      final data = <String, dynamic>{
        'name': 'Fachriza',
        'email': email,
        'password': hashPassword('fachriza123'),
        'role': 'mahasiswa',
        'photoPath': null,
        'saldo': 100000,
        'tenantName': null,
      };
      if (hasNirm) data['nirm'] = nirm;
      await db.insert('users', data);
    } else if (hasNirm) {
      await db.update('users', {'name': 'Fachriza', 'nirm': nirm},
          where: 'email = ?', whereArgs: [email]);
    }
  }

  Future<void> _insertPromoImagesIfEmpty(Database db) async {
    final rows = await db.query('promos');
    const images = [
      'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80',
    ];
    for (var i = 0; i < rows.length && i < images.length; i++) {
      if ((rows[i]['imageUrl'] as String?)?.isEmpty ?? true)
        await db.update('promos', {'imageUrl': images[i]},
            where: 'id = ?', whereArgs: [rows[i]['id']]);
    }
  }

  // ============================================================
  // SEED TENANTS
  // ============================================================

  /// Membuat akun login untuk setiap tenant
  /// dari DummyData.tenants.
  ///
  /// Password default:
  /// tenant123
  Future<void> _insertTenantsIfAbsent(Database db,
      {bool forceReset = false}) async {
    const tenantEmail = 'tenant1@kantin.app';
    const tenantName = 'Kantin Kampus';

    // Hanya satu tenant resmi.
    await db.delete(
      'users',
      where: "role = 'tenant' AND email != ?",
      whereArgs: [tenantEmail],
    );

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [tenantEmail],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('users', {
        'name': tenantName,
        'email': tenantEmail,
        'password': hashPassword('tenant123'),
        'role': 'tenant',
        'nirm': null,
        'photoPath':
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=900&q=80',
        'saldo': 0,
        'tenantName': tenantName,
      });
    } else {
      await db.update(
        'users',
        {
          'name': tenantName,
          'tenantName': tenantName,
          'saldo': 0,
          'photoPath':
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=900&q=80',
        },
        where: 'email = ?',
        whereArgs: [tenantEmail],
      );
    }

    const kasirEmail = 'kasir@kantin.app';
    final kasir = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [kasirEmail],
      limit: 1,
    );
    if (kasir.isEmpty) {
      await db.insert('users', {
        'name': 'Kasir Kantin Kampus',
        'email': kasirEmail,
        'password': hashPassword('kasir123'),
        'role': 'kasir',
        'nirm': null,
        'photoPath':
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=900&q=80',
        'saldo': 0,
        'tenantName': tenantName,
      });
    } else {
      await db.update(
        'users',
        {
          'tenantName': tenantName,
          'saldo': 0,
          if (forceReset) 'password': hashPassword('kasir123'),
        },
        where: 'email = ?',
        whereArgs: [kasirEmail],
      );
    }
  }

  Future<void> _normalizeCampusTenant(Database db) async {
    const tenantName = 'Kantin Kampus';

    // Migrasi data menu lama ke tenant tunggal.
    await db.update(
      'menus',
      {'tenantId': 1, 'tenantName': tenantName},
    );

    // Pesanan lama juga dipusatkan ke tenant resmi.
    await db.update(
      'orders',
      {'tenantName': tenantName},
    );

    await _insertTenantsIfAbsent(db);
  }

  /// Memastikan setiap menu memiliki gambar yang valid dan sesuai dengan
  /// nama produknya.
  ///
  /// Gambar yang masih kosong, placeholder (loremflickr), atau URL yang tidak
  /// dikenali akan diganti dengan aset lokal berdasarkan nama menu.
  /// Gambar custom hasil upload tenant (base64) atau URL pilihan admin
  /// (http/https selain placeholder) tetap dipertahankan.
  Future<void> _ensureMenuImages(Database db) async {
    final rows = await db.query('menus');
    for (final row in rows) {
      final name = (row['name'] as String?)?.trim() ?? '';
      final image = (row['imageUrl'] as String?)?.trim() ?? '';

      final isEmpty = image.isEmpty;
      final isPlaceholder = image.contains('loremflickr') ||
          image.contains('via.placeholder') ||
          image.contains('placeholder.com');
      final isValid = image.startsWith('assets/') ||
          image.startsWith('data:image') ||
          image.startsWith('http://') ||
          image.startsWith('https://');

      if (!isEmpty && !isPlaceholder && isValid) {
        continue;
      }

      final replacement = DummyData.photoAssetFor(name);
      await db.update(
        'menus',
        {'imageUrl': replacement},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  // ============================================================
  // SEED MENUS
  // ============================================================

  Future<void> _ensureMinimumMenusPerCategory(Database db) async {
    for (final category in DummyData.categories) {
      final rows = await db.rawQuery(
          'SELECT COUNT(*) AS total FROM menus WHERE category = ?', [category]);
      final current = (rows.first['total'] as num?)?.toInt() ?? 0;
      final needed = 10 - current;
      if (needed <= 0) continue;
      var added = 0;
      for (final menu
          in DummyData.menuItems.where((m) => m.category == category)) {
        if (added >= needed) break;
        final exists = await db.query('menus',
            where: 'name = ?', whereArgs: [menu.name], limit: 1);
        if (exists.isNotEmpty) continue;
        final data = menu.toMap()..remove('id');
        await db.insert('menus', data);
        added++;
      }
    }
  }

  /// Mengisi menu dari DummyData jika tabel menus masih kosong.
  Future<void> _insertMenusIfAbsent(
    Database db,
  ) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM menus',
      ),
    );

    if (count != null && count > 0) {
      return;
    }

    for (final menu in DummyData.menuItems) {
      final data = menu.toMap();

      data.remove('id');

      await db.insert(
        'menus',
        data,
      );
    }
  }

  // ============================================================
  // SEED PROMOS
  // ============================================================

  /// Mengisi promo default jika tabel promos masih kosong.
  Future<void> _insertPromosIfAbsent(
    Database db,
  ) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM promos',
      ),
    );

    if (count != null && count > 0) {
      return;
    }

    final defaults = const [
      {
        'title': 'Diskon Spesial Hari Ini',
        'description': 'Diskon sampai 30% untuk menu pilihan.',
        'discount': 30.0,
        'active': 1,
        'icon': 'local_offer',
      },
      {
        'title': 'Promo Paket Hemat',
        'description': 'Paket makanan + minuman lebih murah.',
        'discount': 20.0,
        'active': 1,
        'icon': 'fastfood',
      },
      {
        'title': 'Cashback Saldo',
        'description': 'Cashback 10% untuk pembayaran saldo kampus.',
        'discount': 10.0,
        'active': 1,
        'icon': 'account_balance_wallet',
      },
    ];

    for (final promo in defaults) {
      await db.insert(
        'promos',
        promo,
      );
    }
  }

  // ============================================================
  // BOOTSTRAP DATA
  // ============================================================

  /// Publik:
  /// bootstrap akun admin, tenant,
  /// menu, dan promo.
  ///
  /// Method ini dipanggil ketika splash screen.
  Future<void> bootstrapData() async {
    final db = await database;

    await _insertAdminIfAbsent(db);

    await _insertTenantsIfAbsent(db);

    await _insertMenusIfAbsent(db);

    await _insertPromosIfAbsent(db);
    await _ensureMenuImages(db);
  }

  // ============================================================
  // MENUS
  // ============================================================

  Future<List<MenuItem>> getAllMenus() async {
    final db = await database;

    final result = await db.query(
      'menus',
      orderBy: 'id ASC',
    );

    return result
        .map(
          MenuItem.fromMap,
        )
        .toList();
  }

  /// Foto default saat menu dibuat tanpa URL gambar.
  Future<int> insertMenu(
    MenuItem menu,
  ) async {
    final db = await database;

    final data = menu.toMap();
    data.remove('id');
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    if (imageUrl.isEmpty) {
      data['imageUrl'] = DummyData.photoAssetFor(menu.name);
    }

    return db.insert('menus', data);
  }

  Future<int> updateMenu(
    MenuItem menu,
  ) async {
    final db = await database;

    final data = menu.toMap();
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    if (imageUrl.isEmpty) {
      data['imageUrl'] = DummyData.photoAssetFor(menu.name);
    }
    return db.update(
      'menus',
      data,
      where: 'id = ?',
      whereArgs: [menu.id],
    );
  }

  Future<int> deleteMenu(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'menus',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> setMenuAvailability(int id, bool tersedia) async {
    final db = await database;
    return db.update(
      'menus',
      {'tersedia': tersedia ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // PROMOS
  // ============================================================

  Future<List<Promo>> getAllPromos() async {
    final db = await database;

    final result = await db.query(
      'promos',
      orderBy: 'id ASC',
    );

    return result
        .map(
          Promo.fromMap,
        )
        .toList();
  }

  Future<int> insertPromo(
    Promo promo,
  ) async {
    final db = await database;

    final data = promo.toMap();

    data.remove('id');

    return db.insert(
      'promos',
      data,
    );
  }

  Future<int> updatePromo(
    Promo promo,
  ) async {
    final db = await database;

    return db.update(
      'promos',
      promo.toMap(),
      where: 'id = ?',
      whereArgs: [promo.id],
    );
  }

  Future<int> deletePromo(
    int id,
  ) async {
    final db = await database;

    return db.delete(
      'promos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMenuRating(int menuId) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT AVG(rating) AS avgRating, COUNT(*) AS total FROM ratings WHERE menuId = ?',
        [menuId]);
    if (rows.isEmpty) return;
    final avg = (rows.first['avgRating'] as num?)?.toDouble() ?? 0;
    final total = (rows.first['total'] as num?)?.toInt() ?? 0;
    await db.update('menus', {'rating': avg, 'reviewCount': total},
        where: 'id = ?', whereArgs: [menuId]);
  }

  Future<Promo?> getBestActivePromo() async {
    final db = await database;
    final rows = await db.query('promos',
        where: 'active = 1', orderBy: 'discount DESC', limit: 1);
    return rows.isEmpty ? null : Promo.fromMap(rows.first);
  }

  Future<int> createNotification(
      int userId, String title, String message, String type) async {
    final db = await database;
    return db.insert('notifications', {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': 0,
      'createdAt': DateTime.now().toIso8601String()
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final db = await database;
    return db.query('notifications',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
  }

  Future<void> markNotificationsRead(int userId) async {
    final db = await database;
    await db.update('notifications', {'isRead': 1},
        where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM notifications WHERE userId = ? AND isRead = 0',
      [userId],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllNotifications(int userId) async {
    final db = await database;
    return db.delete('notifications', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getRatingsSummary() async {
    final db = await database;
    return db.rawQuery(
        "SELECT rating, COUNT(*) AS total FROM ratings GROUP BY rating ORDER BY rating DESC");
  }

  Future<List<Map<String, dynamic>>> getDailySales(
      {int days = 7, String? tenantName}) async {
    final db = await database;
    final where = tenantName == null ? '' : 'AND tenantName = ?';
    final args = tenantName == null ? <Object>[] : <Object>[tenantName];
    return db.rawQuery(
        "SELECT substr(createdAt,1,10) AS day, COUNT(*) AS totalOrders, COALESCE(SUM(total),0) AS revenue FROM orders WHERE status != 'Dibatalkan' $where GROUP BY substr(createdAt,1,10) ORDER BY day DESC LIMIT $days",
        args);
  }

  Future<List<Map<String, dynamic>>> getMonthlySales(
      {int months = 6, String? tenantName}) async {
    final db = await database;
    final where = tenantName == null ? '' : 'AND tenantName = ?';
    final args = tenantName == null ? <Object>[] : <Object>[tenantName];
    return db.rawQuery(
        "SELECT substr(createdAt,1,7) AS month, COUNT(*) AS totalOrders, COALESCE(SUM(total),0) AS revenue FROM orders WHERE status != 'Dibatalkan' $where GROUP BY substr(createdAt,1,7) ORDER BY month DESC LIMIT $months",
        args);
  }

  Future<List<Map<String, dynamic>>> getMenuCategorySales(
      {String? tenantName}) async {
    final db = await database;
    final where = tenantName == null ? '' : 'AND o.tenantName = ?';
    final args = tenantName == null ? <Object>[] : <Object>[tenantName];
    return db.rawQuery(
        "SELECT COALESCE(m.category,'Lainnya') AS category, COALESCE(SUM(oi.quantity),0) AS total FROM order_items oi JOIN orders o ON o.id=oi.orderId LEFT JOIN menus m ON m.name=oi.menuName WHERE o.status != 'Dibatalkan' $where GROUP BY m.category",
        args);
  }

  Future<int> createTopup(int userId, double amount) async {
    final db = await database;
    return db.insert('topups', {
      'userId': userId,
      'amount': amount,
      'status': 'success',
      'createdAt': DateTime.now().toIso8601String()
    });
  }

  Future<int> createRating(
      {required int userId,
      required int menuId,
      required int orderId,
      required int rating,
      String? review}) async {
    final db = await database;
    return db.insert(
        'ratings',
        {
          'userId': userId,
          'menuId': menuId,
          'orderId': orderId,
          'rating': rating,
          'review': review,
          'createdAt': DateTime.now().toIso8601String()
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  Future<List<int>> getFavoriteMenuIds(int userId) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      columns: ['menuId'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.map((r) => r['menuId'] as int).toList();
  }

  Future<void> addFavorite(int userId, int menuId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'userId': userId,
        'menuId': menuId,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int userId, int menuId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'userId = ? AND menuId = ?',
      whereArgs: [userId, menuId],
    );
  }
}
