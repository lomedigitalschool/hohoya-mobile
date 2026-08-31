# Profil utilisateur (#28, #29, #30, #31) — Design

## Contexte

Tableau de projet GitHub avec 6 tâches liées à l'auth/profil :

- **Backlog** : Google Sign-In (#8), Changer mot de passe (#29), Photo de profil (#30), Profil public (#31)
- **In progress** : Voir/éditer profil (#28), Mot de passe oublié (#9)

Audit du code existant avant de commencer :

- **#8 Google Sign-In** — déjà implémenté (`AuthService.signInWithGoogle`, package `google_sign_in`, câblé dans login/register). Marqué "Backlog" sur le tableau mais le code existe et fonctionne en mode local.
- **#9 Mot de passe oublié** — déjà implémenté (`forgot_password_screen.dart`, `AuthService.forgotPassword/resetPassword`, `LocalAuthStore`). Complet en mode local.
- **#28, #29, #30, #31** — aucun code n'existe. C'est l'objet de ce design.

Ce spec couvre uniquement #28/#29/#30/#31. #8 et #9 ne sont pas retouchés (juste à vérifier manuellement plus tard, hors scope de ce plan).

## Décisions validées avec l'utilisateur

1. **Modèle utilisateur courant** : étendre `LocalAuthStore` + `AuthService` (pas de stockage séparé de l'objet `User` en clair après login). L'id utilisateur est extrait du token local existant (format `local-access-{id}-{stamp}`).
2. **Photo de profil** : `image_picker`, fichier gardé en mémoire pour la session uniquement — pas de persistance disque. Se perd au redémarrage de l'app, cohérent avec le reste du mock local.
3. **Entrée du profil public** : point d'entrée minimal avec utilisateur fictif — les `PropertyCard`/`FeaturedCard` de la Home deviennent cliquables et ouvrent le profil public du compte de test `proprietaire@test.com` (id `'2'`), simulant "voir le propriétaire de l'annonce".
4. **Champs du profil public** : nom, photo, rôle uniquement (pas d'email ni téléphone).

## Architecture

### Modèle de données

`lib/models/user_profile.dart` — nouvelle classe `UserProfile` :

```
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
}
```

Pas de champ avatar dans le modèle : la photo est un état d'écran (session-only), pas une donnée persistée, donc elle n'a pas besoin d'être dans le modèle partagé.

### LocalAuthStore

Ajouts :

- `UserProfile currentUser(String userId)` — retrouve l'utilisateur en mémoire par id, lève `AuthException` si introuvable.
- `UserProfile publicProfile(String userId)` — même recherche, mais l'appelant (AuthService) ne garde que name/role pour construire la vue publique.
- `Future<UserProfile> updateProfile({required String userId, required String name, required String phone})` — met à jour l'utilisateur en mémoire, retourne le profil à jour. Email non modifiable (pas de flux de vérification d'email prévu dans ce lot).
- `Future<void> changePassword({required String userId, required String currentPassword, required String newPassword})` — vérifie `currentPassword` contre l'utilisateur, lève `AuthException('Mot de passe actuel incorrect')` si ça ne correspond pas, sinon remplace.

Extraction de l'id depuis le token : petite fonction utilitaire dans `LocalAuthStore` (ou `AuthService`) qui parse `local-access-{id}-{stamp}` → `id`. Spécifique au mode local ; le mode backend réel utilisera un vrai payload de token ou un endpoint `/users/me`.

### AuthService

Nouvelles méthodes, même pattern que l'existant (branchement sur `ApiConfig.useLocalAuth`, `try/catch DioException` → `AuthException`) :

- `Future<UserProfile> getCurrentUser()`
- `Future<UserProfile> getPublicProfile(String userId)`
- `Future<UserProfile> updateProfile({required String name, required String phone})`
- `Future<void> changePassword({required String currentPassword, required String newPassword})`

**Endpoints backend réel** — `PATCH /users/me` et `POST /users/me/password` (pas `/auth/...`). C'est délibéré : l'intercepteur Dio dans `ApiClient` n'attache le Bearer token que si le chemin ne commence pas par `/auth/`. Mettre ces routes sous `/auth/` désactiverait silencieusement l'authentification une fois un vrai backend branché.

`getCurrentUser`/`getPublicProfile` doivent d'abord connaître l'id de l'utilisateur courant. En mode local, on le récupère en décodant l'access token stocké via `TokenStorage`. En mode réel, `getCurrentUser` tape `GET /users/me` (pas besoin d'id explicite, le backend l'infère du token).

### Écrans

- **`lib/screens/profile_screen.dart`** — vue + édition du profil courant. Avatar (avec bouton caméra), nom/email/téléphone/rôle. Toggle "Modifier" → champs name/phone éditables, email lecture seule. Bouton "Enregistrer" → `updateProfile`. Deux tuiles de navigation : "Changer le mot de passe" → `ChangePasswordScreen`, "Aperçu public" → `PublicProfileScreen(userId: <son propre id>)`.
- **`lib/screens/change_password_screen.dart`** — formulaire mot de passe actuel / nouveau / confirmation → `AuthService.changePassword`.
- **`lib/screens/public_profile_screen.dart`** — lecture seule : avatar, nom, rôle. Reçoit un `userId` en paramètre de constructeur.

### Navigation

- `lib/widgets/bottom_nav_bar.dart` : l'`IconButton` "person" (actuellement no-op) pousse `ProfileScreen`.
- `lib/screens/home_screen.dart` : `FeaturedCard`/`PropertyCard` devient cliquable (`onTap`) et pousse `PublicProfileScreen(userId: '2')`.

### Photo de profil (#30)

- Ajout de la dépendance `image_picker` dans `pubspec.yaml`.
- Sur `ProfileScreen`, un bouton caméra superposé à l'avatar ouvre un bottom sheet "Galerie / Appareil photo".
- Le fichier choisi est stocké dans une variable d'état `File? _avatarFile` du widget `ProfileScreen` — pas de persistance (ni disque, ni secure storage). Disparaît à la fermeture/redémarrage de l'app.
- Permissions natives à ajouter : `android/app/src/main/AndroidManifest.xml` (caméra + lecture stockage/médias) et `ios/Runner/Info.plist` (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`).

## Gestion des erreurs

Même convention que l'existant : les méthodes `AuthService` catchent `DioException` et relancent `AuthException` avec un message extrait via `_extractErrorMessage`, avec un message de repli pertinent par action (ex: "Impossible de mettre à jour le profil", "Mot de passe actuel incorrect"). Les écrans affichent l'erreur avec le même widget `Text` rouge que `login_screen.dart`/`forgot_password_screen.dart`.

## Tests

- `flutter analyze` doit passer sans nouvelle erreur/warning.
- Pas de test automatisé unitaire nouveau prévu pour ce lot (le projet n'a que le widget test par défaut) — validation manuelle des parcours : voir profil → éditer → enregistrer ; changer mot de passe (mauvais puis bon mot de passe actuel) ; prendre/choisir une photo ; ouvrir l'aperçu public depuis son profil ; ouvrir le profil public depuis la Home.
- Si un émulateur/device est disponible dans l'environnement d'exécution, faire un tour manuel de ces parcours avant de considérer le travail terminé. Sinon, documenter clairement que la vérification UI n'a pas pu être faite.

## Hors scope

- #8 (Google Sign-In) et #9 (Mot de passe oublié) : déjà implémentés, non retouchés par ce plan.
- Vérification d'email lors du changement d'email : pas de champ email éditable dans ce lot.
- Persistance de la photo de profil au-delà de la session (disque, upload backend) : explicitement exclu par décision utilisateur, à revoir plus tard si besoin.
- Modèle "annonce/logement avec propriétaire" réel : le point d'entrée du profil public reste un lien direct vers l'utilisateur de test `proprietaire@test.com`, pas un vrai lien annonce → propriétaire.
