import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { customer, driver }

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Best-effort parser for the role returned by the backend.
/// Accepts common shapes: "CUSTOMER" / "DRIVER", "ROLE_CUSTOMER", "customer", etc.
UserRole? userRoleFromValue(dynamic value) {
  if (value == null) return null;
  final s = value.toString().toUpperCase();
  if (s.contains('DRIVER') || s.contains('DELIVERY')) return UserRole.driver;
  if (s.contains('CUSTOMER') || s.contains('USER')) return UserRole.customer;
  return null;
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? userId;
  final UserRole? role;
  final String? name;

  const AuthState({
    required this.status,
    this.token,
    this.userId,
    this.role,
    this.name,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState(status: AuthStatus.unknown));

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';
  static const _nameKey = 'user_name';

  static const String jwtTokenKey = _tokenKey;

  /// Loads any persisted session (e.g. after a cold app start).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    final roleValue = userRoleFromValue(prefs.getString(_roleKey));
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        token: token,
        userId: prefs.getString(_userIdKey),
        role: roleValue,
        name: prefs.getString(_nameKey),
      ),
    );
  }

  /// Persists a fresh session and switches to the matching portal.
  Future<void> signIn({
    required String token,
    String? userId,
    UserRole? role,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
    if (role != null) {
      await prefs.setString(_roleKey, role.name);
    } else {
      await prefs.remove(_roleKey);
    }
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_nameKey, name);
    }
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        token: token,
        userId: userId,
        role: role,
        name: name,
      ),
    );
  }

  /// Persists a chosen role without touching the token (fallback picker).
  Future<void> setRole(UserRole role) async {
    final current = state;
    if (current.token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        token: current.token,
        userId: current.userId,
        role: role,
        name: current.name,
      ),
    );
  }

  /// Clears every persisted session field so the next account starts clean.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}