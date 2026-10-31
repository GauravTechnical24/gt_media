import 'package:flutter_test/flutter_test.dart';
import 'package:gt_media_example/main.dart';

void main() {
  testWidgets('MediaExampleScreen renders correctly smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify AppBar title is present
    expect(find.text('GT Media Example'), findsOneWidget);

    // Verify section headings are present
    expect(find.text('Image'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Document'), findsOneWidget);

    // Verify buttons are present
    expect(find.text('Pick Image (with crop & compress)'), findsOneWidget);
    expect(find.text('Pick Profile Picture (circular)'), findsOneWidget);
    expect(find.text('Pick Video (with trimmer)'), findsOneWidget);
    expect(find.text('Play Sample Network Video'), findsOneWidget);
    expect(find.text('Pick Document (PDF/DOC)'), findsOneWidget);
  });
}
