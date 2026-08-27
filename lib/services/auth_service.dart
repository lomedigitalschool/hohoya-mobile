import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthException implements Exception {
  final String message;
  const GoogleAuthException(this.message);
}

class AuthService {
  static String? jwt;
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  final GoogleSignIn _googleSignIn;

  AuthService({GoogleSignIn? googleSignIn}) : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  Future<String> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const GoogleAuthException('Connexion Google annulée.');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleAuthException('Impossible de récupérer le token Google.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': idToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GoogleAuthException('Le serveur a refusé la connexion Google.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final jwt = body['token'] ?? body['accessToken'] ?? body['jwt'];
    if (jwt is! String || jwt.isEmpty) {
      throw const GoogleAuthException('Réponse serveur invalide : JWT manquant.');
    }
    AuthService.jwt = jwt;
    return jwt;
  }

  Future<String> uploadProfilePicture(File image) async {
    final token = jwt;
    if (token == null || token.isEmpty) {
      throw const GoogleAuthException('Connectez-vous avant de modifier votre photo.');
    }
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/users/me/picture'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('picture', image.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GoogleAuthException('Échec de l’envoi de la photo (${response.statusCode}).');
    }
    final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
    return (data['pictureUrl'] ?? data['avatarUrl'] ?? data['url'] ?? '') as String;
  }
}