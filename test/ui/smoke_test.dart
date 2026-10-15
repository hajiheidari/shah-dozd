import 'package:flutter_test/flutter_test.dart';
import 'package:shah_dozd/app/app.dart';
import 'package:shah_dozd/app/state.dart';
import 'package:shah_dozd/l10n/strings.dart';

void main() {
  for (final lang in Lang.values) {
    testWidgets('home renders in ${lang.name}', (tester) async {
      final state = AppState.memory(settings: Settings(lang: lang));
      await tester.pumpWidget(ShahDozdApp(state: state));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(S(lang).t('mode.persian')), findsOneWidget);
    });
  }
}
