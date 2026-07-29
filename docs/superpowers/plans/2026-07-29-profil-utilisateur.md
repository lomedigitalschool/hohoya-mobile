# Profil Utilisateur (#28, #29, #30, #31) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add view/edit profile, change password, profile photo, and public profile screens to the Hohaya Flutter app, backed by the existing local-mock auth system.

**Architecture:** Extend the existing `LocalAuthStore`/`AuthService` pair (same pattern as login/register/forgot-password) with a `UserProfile` model and four new operations (`currentUser`/`getCurrentUser`, `publicProfile`/`getPublicProfile`, `updateProfile`, `changePassword`). Three new screens (`ProfileScreen`, `ChangePasswordScreen`, `PublicProfileScreen`) consume `AuthService`. Navigation wiring connects the bottom nav's profile icon and the Home property cards to these screens.

**Tech Stack:** Flutter/Dart, `dio` (HTTP client, already a dependency), `flutter_secure_storage` (already a dependency, via `TokenStorage`), `image_picker` (new dependency, added in Task 5).

**Spec:** `docs/superpowers/specs/2026-07-29-profil-utilisateur-design.md`

## Global Constraints

- Follow the existing `AuthService` pattern: every public method branches on `ApiConfig.useLocalAuth`; the local branch calls `LocalAuthStore`, the remote branch calls `_dio` inside a `try { } on DioException catch (e) { throw AuthException(...) }`.
- New authenticated backend routes (`updateProfile`, `changePassword`) MUST NOT be placed under `/auth/...` — `ApiClient`'s interceptor (`lib/core/api_client.dart:11-18`) only attaches the Bearer token to paths that do **not** start with `/auth/`. Use `/users/me` and `/users/me/password`.
- Profile photo is session-only (in-memory `File?`), never persisted to disk or secure storage.
- Email is never editable in this batch of work.
- `#8` (Google Sign-In) and `#9` (Mot de passe oublié) are already implemented — do not modify `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`, or `lib/screens/forgot_password_screen.dart` beyond what's explicitly listed below.
- All UI strings are in French, matching the rest of the app.

---

### Task 1: `UserProfile` model + `LocalAuthStore` profile operations

**Files:**
- Create: `lib/models/user_profile.dart`
- Modify: `lib/services/local_auth_store.dart`
- Test: `test/services/local_auth_store_test.dart`

**Interfaces:**
- Produces: `class UserProfile { final String id, name, email, phone; final UserRole role; UserProfile copyWith({String? name, String? phone}); }`
- Produces: `LocalAuthStore.findById(String userId) -> UserProfile` (throws `AuthException` if not found)
- Produces: `LocalAuthStore.updateProfile({required String userId, required String name, required String phone}) -> Future<UserProfile>`
- Produces: `LocalAuthStore.changePassword({required String userId, required String currentPassword, required String newPassword}) -> Future<void>` (throws `AuthException` on wrong current password or new password < 6 chars)
- Produces: `static LocalAuthStore.parseUserId(String accessToken) -> String?` (parses the `local-access-{id}-{stamp}` format from `local_auth_store.dart:57-63`; returns `null` if the token doesn't match)

- [ ] **Step 1: Create the `UserProfile` model**

```dart
// lib/models/user_profile.dart
import '../screens/register_screen.dart' show UserRole;

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  UserProfile copyWith({String? name, String? phone}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
    );
  }
}
```

- [ ] **Step 2: Write the failing tests for `LocalAuthStore`**

```dart
// test/services/local_auth_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hohaya/screens/register_screen.dart' show UserRole;
import 'package:hohaya/services/auth_service.dart';
import 'package:hohaya/services/local_auth_store.dart';

void main() {
  group('LocalAuthStore.parseUserId', () {
    test('extracts the id from a local access token', () {
      expect(LocalAuthStore.parseUserId('local-access-42-1700000000000'), '42');
    });

    test('returns null for a token with the wrong prefix', () {
      expect(LocalAuthStore.parseUserId('bearer-abc123'), isNull);
    });
  });

  group('LocalAuthStore profile operations', () {
    late String userId;

    setUp(() async {
      final email = 'profile-test-${DateTime.now().microsecondsSinceEpoch}@test.com';
      final result = await LocalAuthStore.instance.register(
        name: 'Profile Test',
        email: email,
        phone: '+22890000000',
        password: 'password123',
        role: UserRole.locataire,
      );
      userId = LocalAuthStore.parseUserId(result.accessToken)!;
    });

    test('findById returns the freshly registered user', () {
      final profile = LocalAuthStore.instance.findById(userId);
      expect(profile.name, 'Profile Test');
      expect(profile.role, UserRole.locataire);
    });

    test('findById throws for an unknown id', () {
      expect(
        () => LocalAuthStore.instance.findById('does-not-exist'),
        throwsA(isA<AuthException>()),
      );
    });

    test('updateProfile changes name and phone', () async {
      final updated = await LocalAuthStore.instance.updateProfile(
        userId: userId,
        name: 'Nouveau Nom',
        phone: '+22899999999',
      );
      expect(updated.name, 'Nouveau Nom');
      expect(updated.phone, '+22899999999');

      final refetched = LocalAuthStore.instance.findById(userId);
      expect(refetched.name, 'Nouveau Nom');
    });

    test('changePassword rejects an incorrect current password', () async {
      expect(
        () => LocalAuthStore.instance.changePassword(
          userId: userId,
          currentPassword: 'wrong-password',
          newPassword: 'newpassword123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('changePassword rejects a new password that is too short', () async {
      expect(
        () => LocalAuthStore.instance.changePassword(
          userId: userId,
          currentPassword: 'password123',
          newPassword: '123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('changePassword accepts a correct current password and allows login with the new one', () async {
      await LocalAuthStore.instance.changePassword(
        userId: userId,
        currentPassword: 'password123',
        newPassword: 'newpassword123',
      );

      final profile = LocalAuthStore.instance.findById(userId);
      final result = await LocalAuthStore.instance.login(
        identifier: profile.email,
        password: 'newpassword123',
      );
      expect(result.accessToken, isNotEmpty);
    });
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/services/local_auth_store_test.dart`
Expected: FAIL — `findById`, `updateProfile`, `changePassword`, `parseUserId` are not defined on `LocalAuthStore`.

- [ ] **Step 4: Implement the operations in `LocalAuthStore`**

In `lib/services/local_auth_store.dart`:

1. Add `import '../models/user_profile.dart';` at the top.
2. In `_LocalUser`, change `final String name;` and `final String phone;` to mutable (`String name;` and `String phone;`) — `password` is already mutable, `email`/`id`/`role` stay `final`.
3. Add these methods to the `LocalAuthStore` class (after `resetPassword`):

```dart
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
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/services/local_auth_store_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/models/user_profile.dart lib/services/local_auth_store.dart test/services/local_auth_store_test.dart
git commit -m "feat: add UserProfile model and profile operations to LocalAuthStore"
```

---

### Task 2: `AuthService` profile operations

**Files:**
- Modify: `lib/services/auth_service.dart`

**Interfaces:**
- Consumes: `UserProfile` (Task 1), `LocalAuthStore.findById/updateProfile/changePassword/parseUserId` (Task 1), `TokenStorage.instance.accessToken` (existing, `lib/core/token_storage.dart:17`)
- Produces: `AuthService.instance.getCurrentUser() -> Future<UserProfile>`
- Produces: `AuthService.instance.getPublicProfile(String userId) -> Future<UserProfile>` (email/phone blanked out)
- Produces: `AuthService.instance.updateProfile({required String name, required String phone}) -> Future<UserProfile>`
- Produces: `AuthService.instance.changePassword({required String currentPassword, required String newPassword}) -> Future<void>`

**Note:** These methods depend on `TokenStorage`, which uses `flutter_secure_storage` (a platform channel) — they cannot run in a plain `flutter test` unit test without platform-channel mocking, which is out of scope for this batch (see spec's Tests section). Verification for this task is `flutter analyze` plus the manual walkthrough in Task 7.

- [ ] **Step 1: Add the model import**

In `lib/services/auth_service.dart`, add near the other imports:

```dart
import '../models/user_profile.dart';
```

- [ ] **Step 2: Add the four methods**

Add to the `AuthService` class, after `resetPassword`:

```dart
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
```

- [ ] **Step 3: Verify static analysis passes**

Run: `flutter analyze`
Expected: No errors related to `auth_service.dart`.

- [ ] **Step 4: Commit**

```bash
git add lib/services/auth_service.dart
git commit -m "feat: add profile, password change, and public profile methods to AuthService"
```

---

### Task 3: Change password screen

**Files:**
- Create: `lib/screens/change_password_screen.dart`

**Interfaces:**
- Consumes: `AuthService.instance.changePassword({required String currentPassword, required String newPassword})` (Task 2), `AuthException` (existing), `AuthTextField` (`lib/widgets/auth_text_field.dart`), `PrimaryButton` (`lib/widgets/primary_button.dart`), `AppColors` (`lib/theme/app_colors.dart`)
- Produces: `class ChangePasswordScreen extends StatefulWidget` (no constructor params)

- [ ] **Step 1: Create the screen**

```dart
// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe changé avec succès')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Changer le mot de passe', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              AuthTextField(
                controller: _currentController,
                label: 'Mot de passe actuel',
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.isEmpty) ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _newController,
                label: 'Nouveau mot de passe',
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.length < 6) ? '6 caractères minimum' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirmer le nouveau mot de passe',
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    value != _newController.text ? 'Les mots de passe ne correspondent pas' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Changer le mot de passe',
                isLoading: _isLoading,
                onPressed: _handleChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify static analysis passes**

Run: `flutter analyze`
Expected: No errors related to `change_password_screen.dart`.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/change_password_screen.dart
git commit -m "feat: add change password screen"
```

---

### Task 4: Public profile screen

**Files:**
- Create: `lib/screens/public_profile_screen.dart`

**Interfaces:**
- Consumes: `AuthService.instance.getPublicProfile(String userId)` (Task 2), `UserProfile` (Task 1), `UserRole` (`lib/screens/register_screen.dart`)
- Produces: `class PublicProfileScreen extends StatefulWidget { const PublicProfileScreen({super.key, required this.userId}); final String userId; }`

- [ ] **Step 1: Create the screen**

```dart
// lib/screens/public_profile_screen.dart
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart' show UserRole;

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await AuthService.instance.getPublicProfile(widget.userId);
      if (!mounted) return;
      setState(() => _profile = profile);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Profil', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(child: Text(_errorMessage ?? 'Profil indisponible'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.surface,
                        child: Icon(Icons.person, size: 48, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _profile!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profile!.role == UserRole.proprietaire ? 'Propriétaire' : 'Locataire',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
    );
  }
}
```

- [ ] **Step 2: Verify static analysis passes**

Run: `flutter analyze`
Expected: No errors related to `public_profile_screen.dart`.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/public_profile_screen.dart
git commit -m "feat: add public profile screen"
```

---

### Task 5: Profile screen (view/edit + photo)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Create: `lib/screens/profile_screen.dart`

**Interfaces:**
- Consumes: `AuthService.instance.getCurrentUser()`, `.updateProfile(...)` (Task 2); `ChangePasswordScreen` (Task 3); `PublicProfileScreen` (Task 4); `AuthTextField`, `PrimaryButton`, `AppColors`
- Produces: `class ProfileScreen extends StatefulWidget` (no constructor params)

- [ ] **Step 1: Add the `image_picker` dependency**

Run: `flutter pub add image_picker`
Expected: `pubspec.yaml` gains an `image_picker: ^<version>` line under `dependencies`, and `flutter pub get` runs automatically.

- [ ] **Step 2: Add Android permissions**

In `android/app/src/main/AndroidManifest.xml`, add these two lines as direct children of `<manifest>`, before the `<application>` tag:

```xml
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

- [ ] **Step 3: Add iOS permission descriptions**

In `ios/Runner/Info.plist`, add these two key/string pairs inside the top-level `<dict>` (e.g. right after the `<key>CFBundleVersion</key>` block):

```xml
	<key>NSCameraUsageDescription</key>
	<string>Hohaya a besoin d'accéder à l'appareil photo pour changer votre photo de profil.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Hohaya a besoin d'accéder à vos photos pour changer votre photo de profil.</string>
```

- [ ] **Step 4: Create the profile screen**

```dart
// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import 'change_password_screen.dart';
import 'public_profile_screen.dart';
import 'register_screen.dart' show UserRole;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserProfile? _profile;
  File? _avatarFile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await AuthService.instance.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _phoneController.text = profile.phone;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final updated = await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = _profile?.name ?? '';
      _phoneController.text = _profile?.phone ?? '';
      _errorMessage = null;
    });
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _avatarFile = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Mon profil', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (!_isLoading && _profile != null)
            TextButton(
              onPressed: _isEditing ? _cancelEditing : () => setState(() => _isEditing = true),
              child: Text(_isEditing ? 'Annuler' : 'Modifier'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(child: Text(_errorMessage ?? 'Profil indisponible'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.surface,
                                backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                                child: _avatarFile == null
                                    ? const Icon(Icons.person, size: 48, color: AppColors.textSecondary)
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _pickAvatar,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        _isEditing
                            ? AuthTextField(
                                controller: _nameController,
                                label: 'Nom complet',
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) ? 'Ce champ est requis' : null,
                              )
                            : _ProfileField(label: 'Nom complet', value: _profile!.name),
                        const SizedBox(height: 16),
                        _ProfileField(label: 'Email', value: _profile!.email),
                        const SizedBox(height: 16),
                        _isEditing
                            ? AuthTextField(
                                controller: _phoneController,
                                label: 'Téléphone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                validator: (value) =>
                                    (value == null || value.trim().length < 8) ? 'Numéro invalide' : null,
                              )
                            : _ProfileField(label: 'Téléphone', value: _profile!.phone),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Rôle',
                          value: _profile!.role == UserRole.proprietaire ? 'Propriétaire' : 'Locataire',
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        if (_isEditing)
                          PrimaryButton(label: 'Enregistrer', isLoading: _isSaving, onPressed: _handleSave),
                        if (!_isEditing) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lock_outline, color: AppColors.textPrimary),
                            title: const Text('Changer le mot de passe'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.visibility_outlined, color: AppColors.textPrimary),
                            title: const Text('Aperçu public'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: _profile!.id)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
      ],
    );
  }
}
```

- [ ] **Step 5: Verify static analysis passes**

Run: `flutter analyze`
Expected: No errors related to `profile_screen.dart`.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist lib/screens/profile_screen.dart
git commit -m "feat: add profile screen with view/edit and avatar picking"
```

---

### Task 6: Wire navigation (bottom nav + Home cards)

**Files:**
- Modify: `lib/widgets/bottom_nav_bar.dart`
- Modify: `lib/widgets/featured_card.dart`
- Modify: `lib/widgets/property_card.dart`
- Modify: `lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `ProfileScreen` (Task 5), `PublicProfileScreen` (Task 4)
- Produces: `FeaturedCard` and `PropertyCard` gain an optional `final VoidCallback? onTap;` field, wired to the widget's root via `GestureDetector`.

- [ ] **Step 1: Wire the bottom nav profile icon**

In `lib/widgets/bottom_nav_bar.dart`, add the import and replace the person `IconButton`'s `onPressed`:

```dart
import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.explore_outlined), onPressed: () {}),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `onTap` to `FeaturedCard`**

In `lib/widgets/featured_card.dart`, add the field and wrap the root `Container` with a `GestureDetector`:

```dart
import 'package:flutter/material.dart';

class FeaturedCard extends StatelessWidget {
  final String title;
  final String address;
  final String price;
  final String rating;
  final String imageUrl;
  final VoidCallback? onTap;

  const FeaturedCard({
    super.key,
    required this.title,
    required this.address,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover),
              const Align(
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white70,
                  child: Icon(Icons.play_arrow, color: Colors.black),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          address,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add `onTap` to `PropertyCard`**

In `lib/widgets/property_card.dart`, add the field and wrap the root `Padding` with a `GestureDetector`:

```dart
import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String address;
  final String imageUrl;
  final int beds;
  final int baths;
  final int sqft;
  final VoidCallback? onTap;

  const PropertyCard({
    super.key,
    required this.title,
    required this.address,
    required this.imageUrl,
    required this.beds,
    required this.baths,
    required this.sqft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bed, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$beds Bed', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.bathtub, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$baths Bath', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.square_foot, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$sqft sq ft', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the Home cards to `PublicProfileScreen`**

In `lib/screens/home_screen.dart`, add the import, drop the `const` from the `ListView`'s children list, and pass `onTap` to both cards:

```dart
import 'package:flutter/material.dart';
import '../widgets/featured_card.dart';
import '../widgets/trending_filters.dart';
import '../widgets/property_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'public_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openOwnerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PublicProfileScreen(userId: '2')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Colors.teal),
            SizedBox(width: 6),
            Text('Rentity',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            FeaturedCard(
              title: 'Metro City Studio',
              address: '482 Ocean Dr, San Diego',
              price: '\$2,500/m',
              rating: '5.0 | 140 reviews',
              imageUrl: 'https://picsum.photos/400/220',
              onTap: () => _openOwnerProfile(context),
            ),
            const TrendingFilters(
              filters: ['All', 'House', 'Apartment', 'Villa'],
              selectedFilter: 'All',
            ),
            const SizedBox(height: 12),
            PropertyCard(
              title: 'Aqua Horizon Estate',
              address: '482 Ocean Dr, San Diego',
              imageUrl: 'https://picsum.photos/80/80',
              beds: 3,
              baths: 2,
              sqft: 1400,
              onTap: () => _openOwnerProfile(context),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {},
        shape: const CircleBorder(),
        child: const Icon(Icons.tune, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
```

- [ ] **Step 5: Verify static analysis passes**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/bottom_nav_bar.dart lib/widgets/featured_card.dart lib/widgets/property_card.dart lib/screens/home_screen.dart
git commit -m "feat: wire profile and public profile navigation from bottom nav and Home"
```

---

### Task 7: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Install dependencies**

Run: `flutter pub get`
Expected: Completes with no errors.

- [ ] **Step 2: Run the full analyzer**

Run: `flutter analyze`
Expected: No errors or warnings introduced by this feature.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All tests pass, including `test/services/local_auth_store_test.dart` (Task 1) and the existing `test/widget_test.dart`.

- [ ] **Step 4: Manual walkthrough (if a device/emulator is available)**

If a connected device or running emulator is available in this environment, run `flutter run` and walk through:
1. Log in with `locataire@test.com` / `password123`.
2. Tap the profile icon in the bottom nav → profile screen loads with seeded data.
3. Tap "Modifier" → change name/phone → "Enregistrer" → values persist after leaving and reopening the screen.
4. Tap the camera icon on the avatar → pick a photo from gallery → avatar updates.
5. Tap "Changer le mot de passe" → try the wrong current password (error shown) → then the correct one with a valid new password → succeeds, returns to profile.
6. Log out and back in with the new password to confirm it was actually changed.
7. Tap "Aperçu public" → read-only screen shows name + role only, no email/phone.
8. From Home, tap the featured card or the property card → opens the public profile of `proprietaire@test.com` ("Proprietaire Test", "Propriétaire").

If no device/emulator is available, explicitly state that the UI walkthrough could not be performed and that only `flutter analyze`/`flutter test` were used to verify correctness.

- [ ] **Step 5: Final commit (if any leftover changes)**

```bash
git status
```

If anything is unstaged (e.g. `pubspec.lock` changes from `pub get`), stage and commit it:

```bash
git add -A
git commit -m "chore: finalize profile feature (pubspec.lock refresh)"
```
