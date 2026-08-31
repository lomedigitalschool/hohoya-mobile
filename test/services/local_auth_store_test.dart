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
