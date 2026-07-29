import 'dart:math';

import '../models/user_profile.dart';
import '../screens/register_screen.dart' show UserRole;
import 'auth_service.dart';

class _LocalUser {
  _LocalUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  final String id;
  String name;
  final String email;
  String phone;
  String password;
  final UserRole role;
}

/// Simulates a backend entirely in memory, so the app works with no server
/// running. Mirrors the contract of mock-auth-backend/server.js — swap
/// [ApiConfig.useLocalAuth] to false once a real/mock backend is reachable.
class LocalAuthStore {
  LocalAuthStore._();
  static final instance = LocalAuthStore._();

  final _random = Random();
  var _nextId = 3;

  final List<_LocalUser> _users = [
    _LocalUser(
      id: '1',
      name: 'Locataire Test',
      email: 'locataire@test.com',
      phone: '+22890000001',
      password: 'password123',
      role: UserRole.locataire,
    ),
    _LocalUser(
      id: '2',
      name: 'Proprietaire Test',
      email: 'proprietaire@test.com',
      phone: '+22890000002',
      password: 'password123',
      role: UserRole.proprietaire,
    ),
  ];

  final Map<String, String> _resetCodes = {};

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 500));

  AuthResult _tokensFor(_LocalUser user) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return AuthResult(
      accessToken: 'local-access-${user.id}-$stamp',
      refreshToken: 'local-refresh-${user.id}-$stamp',
    );
  }

  Future<AuthResult> login({required String identifier, required String password}) async {
    await _simulateLatency();
    final user = _users.where((u) => u.email == identifier || u.phone == identifier).firstOrNull;
    if (user == null) throw AuthException('Utilisateur introuvable');
    if (user.password != password) throw AuthException('Identifiants incorrects');
    return _tokensFor(user);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    await _simulateLatency();
    if (_users.any((u) => u.email == email)) {
      throw AuthException('Email déjà utilisé');
    }
    if (password.length < 6) {
      throw AuthException('Mot de passe trop court');
    }
    final user = _LocalUser(
      id: '${_nextId++}',
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    _users.add(user);
    return _tokensFor(user);
  }

  Future<AuthResult> signInWithGoogle() async {
    await _simulateLatency();
    var user = _users.where((u) => u.email == 'google-user@test.com').firstOrNull;
    user ??= _LocalUser(
      id: '${_nextId++}',
      name: 'Google Test User',
      email: 'google-user@test.com',
      phone: '',
      password: '',
      role: UserRole.locataire,
    );
    if (!_users.contains(user)) _users.add(user);
    return _tokensFor(user);
  }

  Future<void> forgotPassword(String email) async {
    await _simulateLatency();
    final user = _users.where((u) => u.email == email).firstOrNull;
    if (user == null) throw AuthException('Email inconnu');
    final code = (100000 + _random.nextInt(900000)).toString();
    _resetCodes[email] = code;
    // ignore: avoid_print
    print('[local-auth] Code de réinitialisation pour $email : $code');
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _simulateLatency();
    if (_resetCodes[email] != code) {
      throw AuthException('Code invalide ou expiré');
    }
    final user = _users.where((u) => u.email == email).firstOrNull;
    if (user == null) throw AuthException('Email inconnu');
    user.password = newPassword;
    _resetCodes.remove(email);
  }

  UserProfile _toProfile(_LocalUser user) => UserProfile(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      );

  UserProfile findById(String userId) {
    final user = _users.where((u) => u.id == userId).firstOrNull;
    if (user == null) throw AuthException('Utilisateur introuvable');
    return _toProfile(user);
  }

  Future<UserProfile> updateProfile({
    required String userId,
    required String name,
    required String phone,
  }) async {
    await _simulateLatency();
    final user = _users.where((u) => u.id == userId).firstOrNull;
    if (user == null) throw AuthException('Utilisateur introuvable');
    user.name = name;
    user.phone = phone;
    return _toProfile(user);
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _simulateLatency();
    final user = _users.where((u) => u.id == userId).firstOrNull;
    if (user == null) throw AuthException('Utilisateur introuvable');
    if (user.password != currentPassword) {
      throw AuthException('Mot de passe actuel incorrect');
    }
    if (newPassword.length < 6) {
      throw AuthException('Mot de passe trop court');
    }
    user.password = newPassword;
  }

  static String? parseUserId(String accessToken) {
    const prefix = 'local-access-';
    if (!accessToken.startsWith(prefix)) return null;
    final remainder = accessToken.substring(prefix.length);
    final separatorIndex = remainder.lastIndexOf('-');
    if (separatorIndex <= 0) return null;
    return remainder.substring(0, separatorIndex);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
