import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uas_mobile/db/db_helper.dart';
import 'package:uas_mobile/models/order.dart';
import 'package:uas_mobile/services/api_client.dart';
import 'package:uas_mobile/utils/password_hasher.dart';

const _base = 'https://api.test/api';

http.Response _json(Object? body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

/// Membuat DBHelper dengan server palsu; setiap request dicatat di [log].
DBHelper _helper(
  List<http.Request> log,
  http.Response Function(http.Request req) handler,
) {
  final client = MockClient((req) async {
    log.add(req);
    return handler(req);
  });
  return DBHelper.withClient(ApiClient(client: client, baseUrl: _base));
}

final _orderJson = {
  'id': 7,
  'userId': 0,
  'orderCode': '#ORD-260930-123',
  'tenantName': 'Kantin Kampus',
  'total': 30000.0,
  'paymentMethod': 'Bayar Langsung',
  'paymentRecipient': 'Admin Smart Kantin',
  'paymentStatus': 'Menunggu Pembayaran',
  'status': 'Menunggu Persetujuan Tenant',
  'pickupTime': '12:00',
  'note': null,
  'createdAt': '2026-09-30T05:00:00+00:00',
  'guestName': 'Budi',
  'guestEmail': 'budi@kampus.ac.id',
  'phoneNumber': '',
  'queueNumber': 'A07',
  'paymentLink': null,
  'paymentQrPayload': null,
  'items': [
    {
      'id': 1,
      'orderId': 7,
      'menuName': 'Es Teh Manis',
      'price': 5000.0,
      'quantity': 2,
    },
  ],
};

void main() {
  group('ApiClient', () {
    test('melempar ApiException berisi pesan server saat status 4xx', () async {
      final api = ApiClient(
        client: MockClient((_) async => _json({'message': 'Tidak valid'}, 422)),
        baseUrl: _base,
      );

      expect(
        () => api.get('menus'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'Tidak valid'),
        ),
      );
    });

    test('mengubah gangguan jaringan menjadi ApiException tanpa status',
        () async {
      final api = ApiClient(
        client: MockClient((_) async => throw http.ClientException('offline')),
        baseUrl: _base,
      );

      expect(
        () => api.get('menus'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', null),
        ),
      );
    });

    test('tidak mengirim query parameter yang bernilai null', () async {
      final log = <http.Request>[];
      final api = ApiClient(
        client: MockClient((req) async {
          log.add(req);
          return _json({'data': []});
        }),
        baseUrl: _base,
      );

      await api.get('statistics/daily-sales', query: {
        'days': 7,
        'tenant_name': null,
      });

      expect(log.single.url.toString(),
          '$_base/statistics/daily-sales?days=7');
    });
  });

  group('DBHelper (REST)', () {
    test('login mengembalikan null saat kredensial salah (401)', () async {
      final db = _helper([], (_) => _json({'message': 'Salah'}, 401));

      expect(await db.login('admin@kantin.app', 'keliru'), isNull);
    });

    test('login mengirim identifier & password lalu memetakan user', () async {
      final log = <http.Request>[];
      final db = _helper(log, (_) => _json({
            'data': {
              'id': 1,
              'name': 'Administrator',
              'email': 'admin@kantin.app',
              'password': 'hash',
              'role': 'admin',
              'nirm': null,
              'photoPath': null,
              'saldo': 0.0,
              'tenantName': null,
            },
            'token': 'x',
          }));

      final user = await db.login(' admin@kantin.app ', 'admin123');

      expect(user?.role, 'admin');
      expect(log.single.method, 'POST');
      expect(log.single.url.path, '/api/auth/login');
      expect(jsonDecode(log.single.body), {
        'identifier': 'admin@kantin.app',
        'password': 'admin123',
      });
    });

    test('getOrderById memetakan order beserta item-nya', () async {
      final db = _helper([], (_) => _json({'data': _orderJson}));

      final order = await db.getOrderById(7);

      expect(order?.queueNumber, 'A07');
      expect(order?.note, '');
      expect(order?.items.single.menuName, 'Es Teh Manis');
      expect(order?.items.single.subtotal, 10000);
    });

    test('getOrderByCode mengembalikan null bila tidak ditemukan', () async {
      final log = <http.Request>[];
      final db = _helper(log, (_) => _json({'data': null}));

      expect(await db.getOrderByCode(' #ORD-1 '), isNull);
      expect(log.single.url.queryParameters, {'order_code': '#ORD-1'});
    });

    test('createOrder mengirim item pesanan dan mengembalikan id baru',
        () async {
      final log = <http.Request>[];
      final db = _helper(log, (_) => _json({'data': {'id': 42}}, 201));

      final id = await db.createOrder(CampusOrder(
        userId: 0,
        orderCode: '#ORD-X',
        tenantName: 'Kantin Kampus',
        total: 10000,
        paymentMethod: 'Bayar Langsung',
        status: 'Menunggu Persetujuan Tenant',
        pickupTime: '12:00',
        createdAt: '2026-09-30T12:00:00.000',
        queueNumber: 'A01',
        items: [
          OrderItem(
            orderId: 0,
            menuName: 'Es Teh Manis',
            price: 5000,
            quantity: 2,
          ),
        ],
      ));

      final body = jsonDecode(log.single.body) as Map<String, dynamic>;
      expect(id, 42);
      expect(body.containsKey('id'), isFalse);
      expect(body['items'], [
        {'menuName': 'Es Teh Manis', 'price': 5000.0, 'quantity': 2},
      ]);
    });

    test('resetPassword mengirim password yang sudah di-hash', () async {
      final log = <http.Request>[];
      final db = _helper(log, (_) => _json({'affected': 1}));

      final ok = await db.resetPassword(userId: 3, newPassword: 'rahasia123');

      expect(ok, isTrue);
      expect(log.single.url.path, '/api/users/3/password');
      expect(jsonDecode(log.single.body),
          {'password': hashPassword('rahasia123')});
    });

    test('getUserStatistics selalu berisi keenam key', () async {
      final db = _helper([], (_) => _json({'total': 4, 'admin': 1}));

      final stats = await db.getUserStatistics();

      expect(stats, {
        'total': 4,
        'mahasiswa': 0,
        'dosen': 0,
        'tenant': 0,
        'kasir': 0,
        'admin': 1,
      });
    });

    test('updateOrderStatus mengembalikan 0 bila pesanan tidak ada', () async {
      final db = _helper([], (_) => _json({'message': 'Tidak ada'}, 404));

      expect(await db.updateOrderStatus(99, 'Selesai'), 0);
    });

    test('getFavoriteMenuIds membaca menuId dari daftar favorit', () async {
      final db = _helper([], (_) => _json({
            'data': [
              {'userId': 1, 'menuId': 3, 'createdAt': '2026-09-30'},
              {'userId': 1, 'menuId': 8, 'createdAt': '2026-09-30'},
            ],
          }));

      expect(await db.getFavoriteMenuIds(1), [3, 8]);
    });
  });
}
