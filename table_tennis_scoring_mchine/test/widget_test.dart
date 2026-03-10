import 'package:flutter_test/flutter_test.dart';
import 'package:table_tennis_scoring_machine/main.dart';
import 'package:table_tennis_scoring_machine/models/match.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    final matchProvider = MatchProvider();
    await tester.pumpWidget(MyApp(matchProvider: matchProvider));
    expect(find.text('Table Tennis Scorekeeper'), findsOneWidget);
  });
}