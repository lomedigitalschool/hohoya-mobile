class ApiConfig {
  ApiConfig._();

  // Simulates the auth API entirely in memory (no server, no network) so the
  // app is usable before a backend is available. Flip to false with
  // --dart-define=USE_LOCAL_AUTH=false once pointing at a real/mock backend.
  static const useLocalAuth = bool.fromEnvironment('USE_LOCAL_AUTH', defaultValue: true);

  // No backend is deployed yet (see issue #9) — point this at your dev server.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // OAuth "Web client" ID from Google Cloud Console, required on Android so
  // google_sign_in can exchange for a backend-verifiable ID token.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
