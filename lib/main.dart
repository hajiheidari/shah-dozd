import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/native.dart';
import 'app/state.dart';
import 'l10n/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0C0F2A),
    ));
  }
  // ?lang=fa|en|hi in the link wins over the saved choice (web).
  final forced = kIsWeb ? Lang.tryParse(Uri.base.queryParameters['lang']) : null;
  final state = await AppState.load(forcedLang: forced);
  // iOS: a reinstall brings back coins and items from iCloud.
  await state.restoreFromICloud(onlyIfFresh: true).timeout(const Duration(seconds: 4), onTimeout: () => false);
  Native.gameCenterSignIn(); // fire and forget; never blocks play
  runApp(ShahDozdApp(state: state));
}
