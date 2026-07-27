import 'package:flutter_test/flutter_test.dart';

import 'package:hohaya/main.dart';

void main() {
<<<<<<< HEAD
  testWidgets('onboarding screen shows its first slide', (tester) async {
    await tester.pumpWidget(const MyApp());
=======
  testWidgets('displays onboarding content and next action', (tester) async {
    await tester.pumpWidget(const HohayaApp());
>>>>>>> 5d952171a042169ccba98fcd036f4b286b9a7568

    expect(find.text('Trouvez votre bien idéal'), findsOneWidget);
    expect(find.text('Découvrir les biens qui correspondent à votre style de vie'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
