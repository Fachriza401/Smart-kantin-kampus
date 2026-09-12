class MenuItem {
  final int id;
  final int tenantId;
  final String tenantName;
  final String name;
  final double price;
  final String category; // Makanan, Minuman, Snacks, Aneka
  final String description;
  final double rating;
  final int reviewCount;
  final String estimasi;
  final bool tersedia;
  final String icon;
  final String imageUrl;

  const MenuItem({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.estimasi,
    this.tersedia = true,
    required this.icon,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'estimasi': estimasi,
      'tersedia': tersedia ? 1 : 0,
      'icon': icon,
      'imageUrl': imageUrl,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int,
      tenantId: map['tenantId'] as int,
      tenantName: map['tenantName'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      estimasi: map['estimasi'] as String? ?? '10-15 menit',
      tersedia: (map['tersedia'] as int?) == 1,
      icon: map['icon'] as String? ?? 'fastfood',
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  MenuItem copyWith({
    int? id,
    int? tenantId,
    String? tenantName,
    String? name,
    double? price,
    String? category,
    String? description,
    double? rating,
    int? reviewCount,
    String? estimasi,
    bool? tersedia,
    String? icon,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      estimasi: estimasi ?? this.estimasi,
      tersedia: tersedia ?? this.tersedia,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
