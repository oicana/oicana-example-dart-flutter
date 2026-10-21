import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oicana_example_dart_flutter/main.dart';

void main() {
  late Templates templates;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    templates = await Templates.load();
  });

  /// Oicana works on other isolates, which fake async test time does not wait for.
  Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(done(), isTrue);
  }

  Future<void> openPreview(
    WidgetTester tester,
    String document, {
    required Size size,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      OicanaExampleApp(templates: Future.value(templates)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(document));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  final preview = find.byWidgetPredicate(
    (widget) => widget is Image && widget.semanticLabel == 'Document preview',
  );
  final vatIdError = find.textContaining('vat-id');

  testWidgets('previews the invoice and reports schema violations', (
    tester,
  ) async {
    await openPreview(tester, 'Invoice', size: const Size(1400, 1000));
    await pumpUntil(tester, () => preview.evaluate().isNotEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'VAT ID'), 'DE1');
    await pumpUntil(tester, () => vatIdError.evaluate().isNotEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'VAT ID'),
      'DE765432100',
    );
    await pumpUntil(tester, () => vatIdError.evaluate().isEmpty);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('adds and removes invoice items', (tester) async {
    await openPreview(tester, 'Invoice', size: const Size(1400, 1000));

    expect(find.widgetWithText(TextField, 'Description'), findsNWidgets(3));
    await tester.tap(find.text('Add item'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Description'), findsNWidgets(4));
    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Description'), findsNWidgets(3));
  });

  testWidgets('shows edit and preview tabs on narrow screens', (tester) async {
    await openPreview(tester, 'Certificate', size: const Size(400, 800));

    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Preview'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pumpUntil(tester, () => preview.evaluate().isNotEmpty);
  });
}
