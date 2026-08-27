import 'package:flutter_test/flutter_test.dart';

import 'package:hohaya/main.dart';

void main() {
  testWidgets('displays onboarding content and next action', (tester) async {
    await tester.pumpWidget(const HohayaApp());

    expect(find.text('Trouvez votre bien idéal'), findsOneWidget);
    expect(find.text('Découvrir les biens qui correspondent à votre style de vie'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}