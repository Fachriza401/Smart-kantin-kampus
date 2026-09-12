class Tenant {
  final int id;
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final String etaText;
  final String icon;
  final String imageUrl;
  final bool isOpen;

  const Tenant({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.etaText,
    required this.icon,
    required this.imageUrl,
    this.isOpen = true,
  });
}
