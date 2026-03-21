import 'package:flutter_test/flutter_test.dart';
import 'package:mflow/main.dart';

void main() {
  testWidgets('MFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MFlowApp());
    expect(find.text('MFlow'), findsOneWidget);
  });
}
