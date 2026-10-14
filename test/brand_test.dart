import 'package:checkme/presentation/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all four brand variants load without asset errors', (
    tester,
  ) async {
    for (final layout in LogoLayout.values) {
      for (final inverted in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Logo(layout: layout, inverted: inverted),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        final asset = image.image as AssetImage;
        expect(
          asset.assetName,
          contains(layout == LogoLayout.icone ? 'short' : 'extended'),
        );
        expect(asset.assetName, contains(inverted ? 'dark-bg' : 'light-bg'));
        expect(image.semanticLabel, 'CheckMe');
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('brand header fits a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(24), child: BrandHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Logo>(find.byType(Logo)).inverted, isTrue);
    expect(tester.takeException(), isNull);
  });
}
