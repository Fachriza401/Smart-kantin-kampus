class OrderItem {
  final int? id;
  final int orderId;
  final String menuName;
  final double price;
  final int quantity;

  OrderItem({
    this.id,
    required this.orderId,
    required this.menuName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'menuName': menuName,
        'price': price,
        'quantity': quantity,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        id: map['id'] as int?,
        orderId: map['orderId'] as int,
        menuName: map['menuName'] as String,
        price: (map['price'] as num).toDouble(),
        quantity: (map['quantity'] as num).toInt(),
      );
}

class CampusOrder {
  final int? id;
  /// 0 berarti pesanan Guest; akun staf/mahasiswa memakai userId > 0.
  final int userId;
  final String orderCode;
  final String tenantName;
  final double total;
  final String paymentMethod;
  final String paymentRecipient;
  final String paymentStatus;
  final String status;
  final String pickupTime;
  final String note;
  final String createdAt;
  final String? guestName;
  final String? guestEmail;
  final String queueNumber;
  final String? paymentLink;
  final String? paymentQrPayload;
  final List<OrderItem> items;

  CampusOrder({
    this.id,
    required this.userId,
    required this.orderCode,
    required this.tenantName,
    required this.total,
    required this.paymentMethod,
    this.paymentRecipient = 'Admin Smart Kantin',
    this.paymentStatus = 'Menunggu Pembayaran',
    required this.status,
    required this.pickupTime,
    this.note = '',
    required this.createdAt,
    this.guestName,
    this.guestEmail,
    required this.queueNumber,
    this.paymentLink,
    this.paymentQrPayload,
    this.items = const [],
  });

  bool get isGuest => userId == 0;
  String get buyerName => guestName?.trim().isNotEmpty == true ? guestName! : 'Pengguna Terdaftar';
  String get buyerEmail => guestEmail?.trim().isNotEmpty == true ? guestEmail! : '-';

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'orderCode': orderCode,
        'tenantName': tenantName,
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentRecipient': paymentRecipient,
        'paymentStatus': paymentStatus,
        'status': status,
        'pickupTime': pickupTime,
        'note': note,
        'createdAt': createdAt,
        'guestName': guestName,
        'guestEmail': guestEmail,
        'queueNumber': queueNumber,
        'paymentLink': paymentLink,
        'paymentQrPayload': paymentQrPayload,
      };

  factory CampusOrder.fromMap(
    Map<String, dynamic> map, {
    List<OrderItem> items = const [],
  }) => CampusOrder(
        id: map['id'] as int?,
        userId: (map['userId'] as num?)?.toInt() ?? 0,
        orderCode: map['orderCode'] as String,
        tenantName: map['tenantName'] as String,
        total: (map['total'] as num).toDouble(),
        paymentMethod: map['paymentMethod'] as String,
        paymentRecipient: map['paymentRecipient'] as String? ?? 'Admin Smart Kantin',
        paymentStatus: map['paymentStatus'] as String? ?? 'Menunggu Pembayaran',
        status: map['status'] as String,
        pickupTime: map['pickupTime'] as String,
        note: map['note'] as String? ?? '',
        createdAt: map['createdAt'] as String,
        guestName: map['guestName'] as String?,
        guestEmail: map['guestEmail'] as String?,
        queueNumber: map['queueNumber'] as String? ?? 'A01',
        paymentLink: map['paymentLink'] as String?,
        paymentQrPayload: map['paymentQrPayload'] as String?,
        items: items,
      );

  CampusOrder copyWith({
    String? status,
    String? paymentStatus,
  }) => CampusOrder(
        id: id,
        userId: userId,
        orderCode: orderCode,
        tenantName: tenantName,
        total: total,
        paymentMethod: paymentMethod,
        paymentRecipient: paymentRecipient,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        status: status ?? this.status,
        pickupTime: pickupTime,
        note: note,
        createdAt: createdAt,
        guestName: guestName,
        guestEmail: guestEmail,
        queueNumber: queueNumber,
        paymentLink: paymentLink,
        paymentQrPayload: paymentQrPayload,
        items: items,
      );
}
