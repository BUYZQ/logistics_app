enum UserRole { operator, expeditor }

class AppUser {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final UserRole role;
  final int? warehouseId;
  final int? operatorNumber;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    this.warehouseId,
    this.operatorNumber,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] == 'operator' ? UserRole.operator : UserRole.expeditor,
      warehouseId: json['warehouse_id'] as int?,
      operatorNumber: json['operator_number'] as int?,
    );
  }

  String get displayContact => phone ?? email ?? '—';

  String get roleLabel =>
      role == UserRole.operator ? 'Оператор' : 'Экспедитор';
}

// Auth state — хранит текущего пользователя после входа
class AuthState {
  static AppUser? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static void clear() {
    currentUser = null;
  }

  /// Для совместимости с существующим мок-кодом
  static final List<AppUser> mockUsers = [
    AppUser(
      id: 'op1',
      name: 'Алексей Иванов',
      phone: '+7 (914) 001-00-01',
      role: UserRole.operator,
    ),
    AppUser(
      id: 'ex1',
      name: 'Дмитрий Петров',
      phone: '+7 (914) 765-43-21',
      role: UserRole.expeditor,
    ),
  ];
}
