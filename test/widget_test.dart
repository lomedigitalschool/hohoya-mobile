import 'package:flutter_test/flutter_test.dart';

import 'package:hohaya/main.dart';

void main() {
  testWidgets('Login screen shows sign-in form and links to register', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Content de vous revoir'), findsOneWidget);
    expect(find.text('Email ou téléphone'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    final createAccountLink = find.text('Créer un compte');
    await tester.ensureVisible(createAccountLink);
    await tester.pumpAndSettle();
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    expect(find.text('Rejoignez Hohaya'), findsOneWidget);
    expect(find.text('Locataire'), findsOneWidget);
    expect(find.text('Propriétaire'), findsOneWidget);
  });
}
