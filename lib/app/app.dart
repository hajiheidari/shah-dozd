import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/strings.dart';
import '../ui/screens/home.dart';
import '../ui/theme.dart';
import 'sfx.dart';
import 'state.dart';

class ShahDozdApp extends StatelessWidget {
  const ShahDozdApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            final lang = state.lang;
            Sounds.enabled = state.settings.sound;
            Sounds.haptics = state.settings.haptics;
            return LangScope(
              strings: S(lang),
              child: MaterialApp(
                title: S(lang).t('app.title'),
                debugShowCheckedModeBanner: false,
                theme: buildTheme(lang),
                locale: lang.locale,
                supportedLocales: [for (final l in Lang.values) l.locale],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (context, child) => Directionality(textDirection: lang.direction, child: child!),
                home: const HomeScreen(),
              ),
            );
          },
        ),
      );
}
