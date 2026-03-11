import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cicada/main.dart';

void main() {
  testWidgets('CicadaApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CicadaApp()));
    expect(find.text('CICADA'), findsOneWidget);
  });
}
