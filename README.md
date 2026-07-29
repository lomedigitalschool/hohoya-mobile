# hohaya

A new Flutter project.

## Comptes de test (mode local, sans backend)

Par défaut l'app tourne en mode d'authentification 100% local (`ApiConfig.useLocalAuth = true`,
voir `lib/core/api_config.dart`) : aucun serveur n'est nécessaire pour se connecter et tester l'app.

| Rôle | Email | Mot de passe |
| --- | --- | --- |
| Locataire | `locataire@test.com` | `password123` |
| Propriétaire | `proprietaire@test.com` | `password123` |

Tu peux aussi créer un nouveau compte via l'écran d'inscription, ou utiliser "Continuer avec Google"
(en mode local, ça simule automatiquement la connexion d'un "Google Test User").

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
