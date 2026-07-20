import 'package:flutter_test/flutter_test.dart';

import 'package:hohaya/main.dart';

void main() {
  testWidgets('onboarding screen shows its first slide', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Trouvez votre bien idéal'), findsOneWidget);
    expect(find.text('Découvrir les biens qui correspondent à votre style de vie'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
