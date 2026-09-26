import 'package:flutter_test/flutter_test.dart';
import 'package:booyah_rewards/main.dart';

void main() {
  testWidgets('Booyah Rewards app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const BooyahRewardsApp());
    expect(find.textContaining('BOOYAH'), findsWidgets);
  });
}
