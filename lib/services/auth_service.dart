import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/token_storage.dart';
import '../models/user_profile.dart';
import '../screens/register_screen.dart' show UserRole;
import 'local_auth_store.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  AuthResult({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _dio = ApiClient.instance.dio;
  final _googleSignIn = GoogleSignIn.instance;
  var _googleInitialized = false;

  Future<AuthResult> login({required String identifier, required String password}) async {
    if (ApiConfig.useLocalAuth) {
      final result = await LocalAuthStore.instance.login(identifier: identifier, password: password);
      return _persistResult(result);
    }
    try {
      final response = await _dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      return _persistTokens(response.data);
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Identifiants incorrects'));
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    if (ApiConfig.useLocalAuth) {
      final result = await LocalAuthStore.instance.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      return _persistResult(result);
    }
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.name,
      });
      return _persistTokens(response.data);
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: "L'inscription a échoué"));
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    if (ApiConfig.useLocalAuth) {
      final result = await LocalAuthStore.instance.signInWithGoogle();
      return _persistResult(result);
    }
    try {
      if (!_googleInitialized) {
        await _googleSignIn.initialize(
          serverClientId: ApiConfig.googleServerClientId.isEmpty
              ? null
              : ApiConfig.googleServerClientId,
        );
        _googleInitialized = true;
      }

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthException('Impossible de récupérer le compte Google');
      }

      final response = await _dio.post('/auth/google', data: {'idToken': idToken});
      return _persistTokens(response.data);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Connexion Google annulée');
      }
      throw AuthException('Connexion Google indisponible sur cet appareil');
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Connexion Google échouée'));
    }
  }

  Future<void> forgotPassword(String email) async {
    if (ApiConfig.useLocalAuth) {
      return LocalAuthStore.instance.forgotPassword(email);
    }
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: "Impossible d'envoyer le code"));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (ApiConfig.useLocalAuth) {
      return LocalAuthStore.instance.resetPassword(email: email, code: code, newPassword: newPassword);
    }
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Code invalide ou expiré'));
    }
  }

  Future<UserProfile> getCurrentUser() async {
    if (ApiConfig.useLocalAuth) {
      final userId = await _currentUserId();
      return LocalAuthStore.instance.findById(userId);
    }
    try {
      final response = await _dio.get('/users/me');
      return _profileFromJson(response.data);
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Impossible de charger le profil'));
    }
  }

  Future<UserProfile> getPublicProfile(String userId) async {
    if (ApiConfig.useLocalAuth) {
      final profile = LocalAuthStore.instance.findById(userId);
      return UserProfile(id: profile.id, name: profile.name, email: '', phone: '', role: profile.role);
    }
    try {
      final response = await _dio.get('/users/$userId/public');
      return _profileFromJson(response.data);
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Impossible de charger ce profil'));
    }
  }

  Future<UserProfile> updateProfile({required String name, required String phone}) async {
    if (ApiConfig.useLocalAuth) {
      final userId = await _currentUserId();
      return LocalAuthStore.instance.updateProfile(userId: userId, name: name, phone: phone);
    }
    try {
      final response = await _dio.patch('/users/me', data: {'name': name, 'phone': phone});
      return _profileFromJson(response.data);
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Impossible de mettre à jour le profil'));
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (ApiConfig.useLocalAuth) {
      final userId = await _currentUserId();
      return LocalAuthStore.instance.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    }
    try {
      await _dio.post('/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, fallback: 'Impossible de changer le mot de passe'));
    }
  }

  Future<String> _currentUserId() async {
    final token = await TokenStorage.instance.accessToken;
    if (token == null) throw AuthException('Aucune session active');
    final userId = LocalAuthStore.parseUserId(token);
    if (userId == null) throw AuthException('Session invalide');
    return userId;
  }

  UserProfile _profileFromJson(dynamic data) {
    return UserProfile(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      role: (data['role'] as String) == 'proprietaire' ? UserRole.proprietaire : UserRole.locataire,
    );
  }

  Future<AuthResult> _persistTokens(dynamic data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw AuthException('Réponse du serveur invalide');
    }
    return _persistResult(AuthResult(accessToken: accessToken, refreshToken: refreshToken));
  }

  Future<AuthResult> _persistResult(AuthResult result) async {
    await TokenStorage.instance.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    return result;
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Impossible de contacter le serveur';
    }
    return fallback;
  }
}
