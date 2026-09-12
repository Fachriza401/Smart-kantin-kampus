class AppUser {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String role; // mahasiswa, tenant, kasir, admin
  final String? nirm;
  final String? photoPath;
  final double saldo;
  final String? tenantName;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'mahasiswa',
    this.nirm,
    this.photoPath,
    this.saldo = 0,
    this.tenantName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'nirm': nirm,
        'photoPath': photoPath,
        'saldo': saldo,
        'tenantName': tenantName,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
        role: map['role'] as String? ?? 'mahasiswa',
        nirm: map['nirm'] as String?,
        photoPath: map['photoPath'] as String?,
        saldo: (map['saldo'] as num?)?.toDouble() ?? 0,
        tenantName: map['tenantName'] as String?,
      );

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? nirm,
    String? photoPath,
    double? saldo,
    String? tenantName,
  }) => AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
        nirm: nirm ?? this.nirm,
        photoPath: photoPath ?? this.photoPath,
        saldo: saldo ?? this.saldo,
        tenantName: tenantName ?? this.tenantName,
      );
}
