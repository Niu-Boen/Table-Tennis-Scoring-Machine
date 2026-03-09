import 'package:flutter_test/flutter_test.dart';
import 'package:table_tennis_scoring_machine/main.dart'; // 使用 package 导入

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Table Tennis Scorekeeper'), findsOneWidget);
  });
}