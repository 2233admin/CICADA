import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cicada/main.dart';

void main() {
  testWidgets('CicadaApp exposes the expected app shell metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CicadaApp(home: SizedBox.shrink()),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, '知了猴');
  });
}
