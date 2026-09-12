class Promo {
  final int id;
  final String title;
  final String description;
  final double discount;
  final bool active;
  final String icon;
  final String imageUrl;
  final String? startDate;
  final String? endDate;

  const Promo({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.active,
    this.icon = 'local_offer',
    this.imageUrl = '',
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discount': discount,
      'active': active ? 1 : 0,
      'icon': icon,
      'imageUrl': imageUrl,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  factory Promo.fromMap(Map<String, dynamic> map) {
    return Promo(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      discount: (map['discount'] as num).toDouble(),
      active: (map['active'] as int) == 1,
      icon: map['icon'] as String? ?? 'local_offer',
      imageUrl: map['imageUrl'] as String? ?? '',
      startDate: map['startDate'] as String?,
      endDate: map['endDate'] as String?,
    );
  }

  Promo copyWith({
    int? id,
    String? title,
    String? description,
    double? discount,
    bool? active,
    String? icon,
    String? imageUrl,
    String? startDate,
    String? endDate,
  }) {
    return Promo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      active: active ?? this.active,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
