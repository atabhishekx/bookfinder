// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to read child widgets and verify
// the values of widget properties.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bookfinder/main.dart';
import 'package:bookfinder/models/favorites_provider.dart';

void main() {
  testWidgets('App renders splash screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FavoritesProvider()..loadFavorites(),
        child: const BookFinderApp(),
      ),
    );

    expect(find.text('BookFinder'), findsOneWidget);
  });
}
