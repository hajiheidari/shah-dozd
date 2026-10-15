import 'package:flutter/widgets.dart';

import '../engine/engine.dart';

/// Supported languages. Persian is the original text; English and Hindi are
/// full translations (no machine text). Add a language by adding a column to
/// every table in this folder.
enum Lang {
  fa('فارسی', TextDirection.rtl),
  en('English', TextDirection.ltr),
  hi('हिन्दी', TextDirection.ltr);

  const Lang(this.label, this.direction);
  final String label;
  final TextDirection direction;

  Locale get locale => Locale(name);

  static Lang? tryParse(String? code) => code == null ? null : values.asNameMap()[code.toLowerCase().split(RegExp('[-_]')).first];
}

/// All visible text. `S.of(context)` gives the current language.
class S {
  const S(this.lang);
  final Lang lang;

  static S of(BuildContext context) => _Scope.of(context);

  bool get rtl => lang.direction == TextDirection.rtl;

  /// Digits in the language's style (Persian digits for Persian).
  String n(num value) {
    var s = value is int ? value.toString() : value.toStringAsFixed(0);
    if (value is int && value.abs() >= 10000) {
      s = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    }
    if (lang != Lang.fa) return s;
    const d = '۰۱۲۳۴۵۶۷۸۹';
    return s.replaceAllMapped(RegExp(r'[0-9,]'), (m) => m[0] == ',' ? '٬' : d[int.parse(m[0]!)]);
  }

  /// Signed points, e.g. "+800".
  String pts(int v) => v > 0 ? '${rtl ? '\u200E' : ''}+${n(v)}' : n(v);

  String t(String key, [Map<String, Object> vars = const {}]) {
    final row = _text[key];
    assert(row != null, 'missing text: $key');
    var s = row?[lang.index] ?? key;
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v is num ? n(v) : '$v'));
    return s;
  }

  String mode(ModeId m) => t('mode.${m.name}');
  String modeLine(ModeId m) => t('mode.${m.name}.roles');

  /// The role's name in this mode (Shah in the Persian game, Raja in the Indian one).
  String role(Role r, ModeId m) {
    final indian = m == ModeId.indian;
    final persian = m == ModeId.persian;
    final key = switch (r) {
      Role.king => indian ? 'role.raja' : 'role.king',
      Role.minister => indian ? 'role.mantri' : 'role.minister',
      Role.thief => indian ? 'role.chor' : (m == ModeId.twoThieves ? 'role.thief1' : 'role.thief'),
      Role.thief2 => 'role.thief2',
      Role.executioner => 'role.executioner',
      Role.sipahi => 'role.sipahi',
      Role.joker => 'role.joker',
    };
    if (persian && lang == Lang.hi && r == Role.king) return 'बादशाह';
    if (persian && lang == Lang.hi && r == Role.minister) return 'वज़ीर';
    return t(key);
  }

  /// The private hint shown only while the player holds their card.
  String roleHint(Role r, Scenario s) {
    if (r == s.guesser) return t(s.picks == 2 ? 'hint.guesser2' : 'hint.guesser', {'thief': role(Role.thief, s.mode)});
    return switch (r) {
      Role.king => t('hint.king'),
      Role.thief || Role.thief2 => t(s.thiefCount == 2 ? 'hint.thief2' : 'hint.thief'),
      Role.joker => t('hint.joker'),
      Role.minister => t('hint.bystander'),
      _ => t('hint.guard'),
    };
  }

  /// Concise rule summary shown at the top of the guess screen.
  String ruleSummary(Scenario s) {
    final g = role(s.guesser, s.mode);
    return switch (s.mode) {
      ModeId.twoThieves => t('rule.short.two', {'g': g}),
      ModeId.joker => t('rule.short.joker', {'g': g}),
      _ => t('rule.short.classic', {'g': g, 'thief': role(Role.thief, s.mode)}),
    };
  }

  /// The full rules of one mode, as bullet points.
  List<String> fullRules(Scenario s) {
    final m = s.mode;
    final g = role(s.guesser, m);
    final k = role(Role.king, m);
    final th = role(Role.thief, m);
    final guard = s.guard == null ? '' : role(s.guard!, m);
    return switch (m) {
      ModeId.persian || ModeId.indian => [
          t('rule.deal', {'n': s.playerCount}),
          t('rule.reveal', {'k': k, 'g': g}),
          t('rule.classic.guess', {'g': g, 'thief': th}),
          t('rule.classic.right', {'thief': th}),
          t('rule.classic.wrong', {'g': g, 'thief': th}),
          if (m == ModeId.persian) t('rule.challenge', {'guard': guard}),
          if (m == ModeId.indian) t(s.guesser == Role.sipahi ? 'rule.indian.sipahi' : 'rule.indian.mantri'),
        ],
      ModeId.joker => [
          t('rule.deal', {'n': s.playerCount}),
          t('rule.reveal', {'k': k, 'g': g}),
          t('rule.joker.guess', {'g': g}),
          t('rule.joker.bluff'),
          t('rule.joker.right', {'g': g}),
          t('rule.joker.joker', {'g': g}),
          t('rule.joker.guard', {'g': g, 'guard': guard}),
        ],
      ModeId.twoThieves => [
          t('rule.deal', {'n': s.playerCount}),
          t('rule.reveal', {'k': k, 'g': g}),
          t('rule.two.guess', {'g': g}),
          t('rule.two.one', {'g': g}),
          t('rule.two.perfect'),
          t('rule.two.none', {'g': g}),
          t('rule.two.joker', {'g': g}),
        ],
    };
  }

  List<String> get challenges => _challenges[lang.index];
}

class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.strings, required super.child});
  final S strings;

  @override
  bool updateShouldNotify(LangScope old) => old.strings.lang != strings.lang;
}

class _Scope {
  static S of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.strings ?? const S(Lang.fa);
}

// Columns: fa, en, hi.
const Map<String, List<String>> _text = {
  'app.title': ['شاه، دزد، وزیر', 'Shah, Thief & Minister', 'राजा, मंत्री, चोर, सिपाही'],
  'app.tagline': ['بازی دورهمی با یک گوشی', 'The party game for one phone', 'एक फ़ोन पर पार्टी गेम'],
  'home.pick': ['یک حالت را انتخاب کنید', 'Choose a mode', 'एक मोड चुनें'],
  'home.badges': ['بدون اینترنت · بدون تبلیغ', 'Offline · No ads', 'ऑफ़लाइन · कोई विज्ञापन नहीं'],
  'home.continue': ['ادامه‌ی بازی قبلی', 'Continue last game', 'पिछला खेल जारी रखें'],
  'home.continue.sub': ['{mode} · دور {r} · {n} بازیکن', '{mode} · round {r} · {n} players', '{mode} · राउंड {r} · {n} खिलाड़ी'],
  'home.rules': ['قوانین', 'Rules', 'नियम'],
  'home.players': ['بازیکن‌ها', 'Players', 'खिलाड़ी'],
  'home.settings': ['تنظیمات', 'Settings', 'सेटिंग्स'],
  'players.count': ['{n} نفر', '{n} players', '{n} खिलाड़ी'],

  'mode.persian': ['کلاسیک ایرانی', 'Persian Classic', 'फ़ारसी क्लासिक'],
  'mode.indian': ['کلاسیک هندی', 'Indian Classic', 'भारतीय क्लासिक'],
  'mode.joker': ['نسخه‌ی دلقک', 'Joker Edition', 'जोकर संस्करण'],
  'mode.twoThieves': ['دو دزد', 'Two Thieves', 'दो चोर'],
  'mode.persian.roles': ['شاه · وزیر · دزد · جلاد', 'King · Minister · Thief · Executioner', 'बादशाह · वज़ीर · चोर · जल्लाद'],
  'mode.indian.roles': ['راجا · منتری · چور · سپاهی', 'Raja · Mantri · Chor · Sipahi', 'राजा · मंत्री · चोर · सिपाही'],
  'mode.joker.roles': ['شاه، وزیر، دزد، نگهبان و دلقک', 'King, Minister, Thief, Guard and Joker', 'राजा, मंत्री, चोर, पहरेदार और जोकर'],
  'mode.twoThieves.roles': ['دو دزد، دلقک، نگهبان، شاه و وزیر', 'Two thieves, Joker, Guard, King, Minister', 'दो चोर, जोकर, पहरेदार, राजा, मंत्री'],
  'mode.new': ['جدید', 'New', 'नया'],

  'role.king': ['شاه', 'King', 'राजा'],
  'role.minister': ['وزیر', 'Minister', 'मंत्री'],
  'role.thief': ['دزد', 'Thief', 'चोर'],
  'role.thief1': ['دزد اول', 'First Thief', 'पहला चोर'],
  'role.thief2': ['دزد دوم', 'Second Thief', 'दूसरा चोर'],
  'role.executioner': ['جلاد', 'Executioner', 'जल्लाद'],
  'role.sipahi': ['سپاهی', 'Sipahi', 'सिपाही'],
  'role.joker': ['دلقک', 'Joker', 'जोकर'],
  'role.raja': ['راجا', 'Raja', 'राजा'],
  'role.mantri': ['منتری', 'Mantri', 'मंत्री'],
  'role.chor': ['چور', 'Chor', 'चोर'],

  'hint.king': ['شما شاه هستید! نقش‌تان برای همه رو می‌شود؛ فقط لذت ببرید.', 'You are the King! Everyone will see it. Just enjoy.', 'आप राजा हैं! सबको पता चलेगा, बस मज़े लीजिए।'],
  'hint.guesser': ['شما باید {thief} را پیدا کنید!', 'You must find the {thief}!', 'आपको {thief} ढूँढना है!'],
  'hint.guesser2': ['دو نفر را انتخاب می‌کنید؛ اگر حتی یکی‌شان دزد باشد برنده‌اید.', 'You pick two players. If even one is a thief, you win.', 'आप दो लोग चुनेंगे। एक भी चोर निकला तो आप जीते।'],
  'hint.thief': ['لو نروید! خونسرد باشید.', 'Don’t get caught! Keep a straight face.', 'पकड़े मत जाना! चेहरा शांत रखें।'],
  'hint.thief2': ['شما یکی از دو دزد هستید. لو نروید!', 'You are one of two thieves. Don’t get caught!', 'आप दो चोरों में से एक हैं। पकड़े मत जाना!'],
  'hint.guard': ['شما بی‌گناهید. آرام باشید؛ اگر شما را انتخاب کنند، دزد فرار می‌کند.', 'You are innocent. Stay calm: if you are picked, the thief escapes.', 'आप निर्दोष हैं। शांत रहें: आपको चुना गया तो चोर बच निकलेगा।'],
  'hint.bystander': ['شما بی‌گناهید و امتیازتان محفوظ است.', 'You are innocent and your points are safe.', 'आप निर्दोष हैं और आपके अंक सुरक्षित हैं।'],
  'hint.joker': ['خودتان را مشکوک نشان دهید! اگر شما را به‌جای دزد انتخاب کنند، جایزه‌ی ویژه می‌گیرید.', 'Look suspicious! If you are picked instead of a thief, you win a special bonus.', 'संदिग्ध दिखिए! चोर की जगह आपको चुना गया तो ख़ास इनाम मिलेगा।'],

  'rule.title': ['قانون این حالت', 'This mode’s rule', 'इस मोड का नियम'],
  'rule.more': ['قوانین کامل', 'Full rules', 'पूरे नियम'],
  'rule.less': ['بستن قوانین', 'Hide rules', 'नियम छिपाएँ'],
  'rule.short.classic': ['{g} یک نفر را به‌عنوان {thief} انتخاب می‌کند. درست باشد، {thief} می‌بازد؛ اشتباه باشد، {g} می‌بازد.', 'The {g} picks one player as the {thief}. Right: the {thief} loses. Wrong: the {g} loses.', '{g} एक खिलाड़ी को {thief} चुनता है। सही तो {thief} हारा, ग़लत तो {g} हारा।'],
  'rule.short.joker': ['{g} یک نفر را به‌عنوان دزد انتخاب می‌کند. دلقک انتخاب شود = برد ویژه‌ی دلقک.', 'The {g} picks one player as the thief. Picking the Joker = a special Joker win.', '{g} एक को चोर चुनता है। जोकर चुना गया = जोकर की ख़ास जीत।'],
  'rule.short.two': ['{g} دو نفر را انتخاب می‌کند. اگر حتی یکی از آن‌ها دزد باشد، {g} برنده است. هر دو دزد = «شکار کامل».', 'The {g} picks two players. If even one of them is a thief, the {g} wins. Both thieves = Perfect Catch.', '{g} दो खिलाड़ी चुनता है। एक भी चोर हो तो {g} जीता। दोनों चोर = परफ़ेक्ट कैच।'],
  'rule.deal': ['نقش‌ها مخفیانه بین {n} نفر پخش می‌شود؛ هر کس فقط نقش خودش را می‌بیند.', 'Roles are dealt in secret to {n} players; each sees only their own.', '{n} खिलाड़ियों में भूमिकाएँ गुप्त रूप से बँटती हैं; हर कोई सिर्फ़ अपनी देखता है।'],
  'rule.reveal': ['{k} و {g} خودشان را معرفی می‌کنند.', 'The {k} and the {g} reveal themselves.', '{k} और {g} अपनी पहचान बताते हैं।'],
  'rule.classic.guess': ['{g} از بین دو نفر باقی‌مانده، {thief} را حدس می‌زند.', 'The {g} guesses the {thief} between the two others.', '{g} बाक़ी दो में से {thief} का अंदाज़ा लगाता है।'],
  'rule.classic.right': ['حدس درست: {thief} این دور را می‌بازد.', 'Right guess: the {thief} loses the round.', 'सही अंदाज़ा: {thief} राउंड हारता है।'],
  'rule.classic.wrong': ['حدس اشتباه: {g} می‌بازد و امتیازش به {thief} می‌رسد.', 'Wrong guess: the {g} loses and the {thief} takes their points.', 'ग़लत अंदाज़ा: {g} हारता है और उसके अंक {thief} को मिलते हैं।'],
  'rule.challenge': ['در پایان دور، {guard} می‌تواند یک چالش بامزه و بی‌خطر برای بازنده انتخاب کند (اختیاری).', 'After the round the {guard} may give the loser a funny, harmless challenge (optional).', 'राउंड के बाद {guard} हारने वाले को एक मज़ेदार, सुरक्षित चुनौती दे सकता है (वैकल्पिक)।'],
  'rule.indian.mantri': ['قاعده‌ی محلی: منتری چور را پیدا می‌کند (در تنظیمات قابل تغییر است).', 'Local rule: the Mantri finds the Chor (change it in Settings).', 'स्थानीय नियम: मंत्री चोर ढूँढता है (सेटिंग्स में बदलें)।'],
  'rule.indian.sipahi': ['قاعده‌ی محلی: سپاهی چور را پیدا می‌کند (در تنظیمات قابل تغییر است).', 'Local rule: the Sipahi finds the Chor (change it in Settings).', 'स्थानीय नियम: सिपाही चोर ढूँढता है (सेटिंग्स में बदलें)।'],
  'rule.joker.guess': ['{g} از بین سه نفر باقی‌مانده، دزد را انتخاب می‌کند.', 'The {g} picks the thief among the three others.', '{g} बाक़ी तीन में से चोर चुनता है।'],
  'rule.joker.bluff': ['دلقک می‌تواند وانمود کند که دزد است؛ نه قدرت مخفی دارد، نه کار اضافه.', 'The Joker may pretend to be the thief. No secret powers, no extra steps.', 'जोकर चोर होने का नाटक कर सकता है। कोई गुप्त शक्ति या अतिरिक्त चरण नहीं।'],
  'rule.joker.right': ['دزد واقعی انتخاب شود: {g} برنده است.', 'The real thief is picked: the {g} wins.', 'असली चोर चुना गया: {g} जीता।'],
  'rule.joker.joker': ['دلقک انتخاب شود: {g} می‌بازد و دلقک برد ویژه می‌گیرد.', 'The Joker is picked: the {g} loses and the Joker gets a special win.', 'जोकर चुना गया: {g} हारा और जोकर को ख़ास जीत मिली।'],
  'rule.joker.guard': ['{guard} انتخاب شود: {g} می‌بازد.', 'The {guard} is picked: the {g} loses.', '{guard} चुना गया: {g} हारा।'],
  'rule.two.guess': ['{g} دقیقاً دو نفر را با هم از بین چهار نفر باقی‌مانده انتخاب می‌کند.', 'The {g} picks exactly two of the four others, at once.', '{g} बाक़ी चार में से ठीक दो को एक साथ चुनता है।'],
  'rule.two.one': ['اگر حتی یکی از دو نفر دزد باشد، {g} برنده است. پیدا کردن هر دو لازم نیست.', 'If even one of the two is a thief, the {g} wins. Finding both is not required.', 'दोनों में से एक भी चोर हो तो {g} जीता। दोनों को ढूँढना ज़रूरी नहीं।'],
  'rule.two.perfect': ['هر دو دزد انتخاب شوند: «شکار کامل» و امتیاز اضافه.', 'Both thieves picked: Perfect Catch and bonus points.', 'दोनों चोर चुने गए: परफ़ेक्ट कैच और बोनस अंक।'],
  'rule.two.none': ['هیچ‌کدام دزد نباشند: {g} می‌بازد.', 'Neither is a thief: the {g} loses.', 'कोई भी चोर नहीं: {g} हारा।'],
  'rule.two.joker': ['اگر دلقک انتخاب شود جایزه‌ی ویژه می‌گیرد، ولی برد {g} را عوض نمی‌کند.', 'If the Joker is picked they get a bonus, but it never changes the {g}’s win.', 'जोकर चुना गया तो उसे बोनस मिलता है, पर {g} की जीत नहीं बदलती।'],

  'setup.title': ['بازیکن‌ها', 'Players', 'खिलाड़ी'],
  'setup.name': ['نام بازیکن {n}', 'Player {n} name', 'खिलाड़ी {n} का नाम'],
  'setup.default': ['بازیکن {n}', 'Player {n}', 'खिलाड़ी {n}'],
  'setup.saved': ['بازیکن‌های ذخیره‌شده', 'Saved players', 'सहेजे गए खिलाड़ी'],
  'setup.rounds': ['تعداد دور', 'Rounds', 'राउंड'],
  'setup.unlimited': ['بی‌پایان', 'Unlimited', 'असीमित'],
  'setup.start': ['شروع بازی', 'Start game', 'खेल शुरू करें'],
  'setup.duplicate': ['نام‌ها نباید تکراری باشند.', 'Names must be different.', 'नाम अलग-अलग होने चाहिए।'],
  'setup.avatar': ['نشان', 'Badge', 'बैज'],

  'deal.title': ['پخش نقش‌ها', 'Dealing roles', 'भूमिकाएँ बँट रही हैं'],
  'deal.progress': ['بازیکن {i} از {n}', 'Player {i} of {n}', 'खिलाड़ी {i} / {n}'],
  'deal.shuffling': ['بُر زدن کارت‌ها…', 'Shuffling…', 'पत्ते फेंटे जा रहे हैं…'],
  'deal.give': ['گوشی را به {name} بدهید', 'Hand the phone to {name}', 'फ़ोन {name} को दें'],
  'deal.give.sub': ['بقیه نگاه نکنند!', 'Everyone else, look away!', 'बाक़ी सब, नज़र हटाइए!'],
  'deal.iam': ['من {name} هستم', 'I am {name}', 'मैं {name} हूँ'],
  'deal.turn': ['نوبت', 'Your turn', 'आपकी बारी'],
  'deal.hold': ['کارت را نگه دارید تا نقش‌تان را ببینید؛ با برداشتن انگشت، کارت بسته می‌شود.', 'Press and hold the card to see your role. Let go and it hides again.', 'अपनी भूमिका देखने के लिए कार्ड दबाए रखें। छोड़ते ही वह छिप जाएगा।'],
  'deal.holdLabel': ['نگه دارید', 'Hold', 'दबाए रखें'],
  'deal.cardA11y': ['کارت نقش؛ برای دیدن نگه دارید', 'Role card; press and hold to see it', 'भूमिका कार्ड; देखने के लिए दबाए रखें'],
  'deal.private': ['نقش فقط وقتی دیده می‌شود که انگشت‌تان روی کارت است.', 'Your role shows only while your finger is on the card.', 'भूमिका तभी दिखती है जब उँगली कार्ड पर हो।'],
  'deal.done': ['دیدم، گوشی را به نفر بعد بدهید', 'Got it, pass the phone on', 'देख लिया, फ़ोन आगे दें'],
  'deal.doneLast': ['دیدم، برویم سراغ بازی', 'Got it, let’s play', 'देख लिया, खेलते हैं'],
  'deal.seeFirst': ['اول کارت را نگه دارید', 'Hold the card first', 'पहले कार्ड दबाएँ'],
  'deal.hidden': ['بازی پنهان شد', 'Game hidden', 'खेल छिपाया गया'],
  'deal.hidden.sub': ['برای ادامه بزنید', 'Tap to continue', 'जारी रखने के लिए टैप करें'],

  'announce.title': ['خودتان را معرفی کنید!', 'Reveal yourselves!', 'अपनी पहचान बताइए!'],
  'announce.is': ['{role}: {name}', '{role}: {name}', '{role}: {name}'],
  'announce.go': ['{name}، آماده‌ی حدس زدن؟', '{name}, ready to guess?', '{name}, अंदाज़ा लगाने को तैयार?'],
  'announce.ready': ['آماده‌ام', 'Ready', 'तैयार'],

  'guess.title': ['{name}، {thief} کجاست؟', '{name}, where is the {thief}?', '{name}, {thief} कहाँ है?'],
  'guess.title2': ['{name}، دزدها کجا هستند؟', '{name}, where are the thieves?', '{name}, चोर कहाँ हैं?'],
  'guess.count': ['{k} از {n} انتخاب شده', '{k} of {n} picked', '{n} में से {k} चुने'],
  'guess.reveal': ['رو کن!', 'Reveal!', 'खोलो!'],

  'result.round': ['{mode} · دور {r}', '{mode} · round {r}', '{mode} · राउंड {r}'],
  'result.win': ['{g} برنده شد!', 'The {g} wins!', '{g} जीता!'],
  'result.lose': ['{g} باخت!', 'The {g} loses!', '{g} हारा!'],
  'result.win.sub': ['{thief} گیر افتاد.', 'The {thief} was caught.', '{thief} पकड़ा गया।'],
  'result.win.one': ['یکی از دزدها پیدا شد؛ همین کافی است.', 'One thief was found, and that is enough.', 'एक चोर मिला, और इतना काफ़ी है।'],
  'result.perfect': ['شکار کامل! هر دو دزد گیر افتادند.', 'Perfect Catch! Both thieves caught.', 'परफ़ेक्ट कैच! दोनों चोर पकड़े गए।'],
  'result.lose.sub': ['{thief} فرار کرد.', 'The {thief} got away.', '{thief} बच निकला।'],
  'result.lose.two': ['هر دو دزد فرار کردند.', 'Both thieves got away.', 'दोनों चोर बच निकले।'],
  'result.joker': ['دلقک {g} را فریب داد و {p} گرفت!', 'The Joker fooled the {g} and got {p}!', 'जोकर ने {g} को बेवक़ूफ़ बनाया और {p} पाए!'],
  'result.caught': ['گیر افتاد', 'Caught', 'पकड़ा गया'],
  'result.fooled': ['گولش زد!', 'Fooled!', 'चकमा!'],
  'result.innocent': ['بی‌گناه', 'Innocent', 'निर्दोष'],
  'result.escaped': ['فرار کرد', 'Escaped', 'बच निकला'],
  'result.table': ['امتیازها', 'Scores', 'अंक'],
  'result.thisRound': ['این دور', 'Round', 'राउंड'],
  'result.total': ['مجموع', 'Total', 'कुल'],
  'result.next': ['دور بعد', 'Next round', 'अगला राउंड'],
  'result.finish': ['پایان', 'Finish', 'समाप्त'],
  'result.champion': ['قهرمان را ببین', 'See the champion', 'विजेता देखें'],
  'result.challenge': ['چالش {guard}', '{guard}’s challenge', '{guard} की चुनौती'],
  'result.challenge.for': ['چالش برای {name}', 'Challenge for {name}', '{name} के लिए चुनौती'],
  'result.challenge.another': ['یکی دیگر', 'Another one', 'दूसरी'],
  'result.challenge.done': ['انجام شد', 'Done', 'हो गया'],
  'result.history': ['تاریخچه', 'History', 'इतिहास'],

  'champ.title': ['قهرمان تورنمنت', 'Tournament champion', 'टूर्नामेंट विजेता'],
  'champ.tie': ['تساوی در صدر!', 'A tie at the top!', 'शीर्ष पर बराबरी!'],
  'champ.points': ['{p} امتیاز', '{p} points', '{p} अंक'],
  'champ.again': ['دوباره با همین بازیکن‌ها', 'Play again, same table', 'इन्हीं खिलाड़ियों से फिर'],
  'champ.home': ['صفحه‌ی اصلی', 'Home', 'होम'],

  'board.title': ['جدول امتیاز', 'Scoreboard', 'स्कोरबोर्ड'],
  'board.round': ['دور {r}', 'Round {r}', 'राउंड {r}'],
  'board.empty': ['هنوز دوری بازی نشده.', 'No rounds played yet.', 'अभी कोई राउंड नहीं खेला गया।'],
  'board.restart': ['شروع دوباره‌ی تورنمنت', 'Restart tournament', 'टूर्नामेंट फिर शुरू करें'],
  'board.restart.q': ['همه‌ی امتیازها صفر شوند؟', 'Reset all scores to zero?', 'सभी अंक शून्य कर दें?'],
  'board.end': ['پایان تورنمنت', 'End tournament', 'टूर्नामेंट समाप्त करें'],

  'exit.q': ['از بازی خارج شوید؟', 'Leave the game?', 'खेल छोड़ें?'],
  'exit.sub': ['امتیازها ذخیره می‌ماند؛ این دور از اول پخش می‌شود.', 'Scores are kept; this round will be dealt again.', 'अंक सुरक्षित रहेंगे; यह राउंड फिर से बँटेगा।'],
  'yes': ['بله', 'Yes', 'हाँ'],
  'no': ['خیر', 'No', 'नहीं'],
  'cancel': ['انصراف', 'Cancel', 'रद्द करें'],
  'save': ['ذخیره', 'Save', 'सहेजें'],
  'delete': ['حذف', 'Delete', 'हटाएँ'],
  'add': ['افزودن', 'Add', 'जोड़ें'],
  'back': ['بازگشت', 'Back', 'वापस'],
  'close': ['بستن', 'Close', 'बंद करें'],
  'restartRound': ['پخش دوباره‌ی این دور', 'Re-deal this round', 'यह राउंड फिर से बाँटें'],

  'settings.title': ['تنظیمات', 'Settings', 'सेटिंग्स'],
  'settings.language': ['زبان', 'Language', 'भाषा'],
  'settings.sound': ['صدای بازی', 'Sound effects', 'ध्वनि प्रभाव'],
  'settings.haptics': ['لرزش', 'Vibration', 'कंपन'],
  'settings.motion': ['کاهش حرکت و انیمیشن', 'Reduce motion', 'कम एनिमेशन'],
  'settings.rules': ['قوانین', 'Rules', 'नियम'],
  'settings.indian': ['در کلاسیک هندی، چه کسی چور را پیدا می‌کند؟', 'Indian Classic: who finds the Chor?', 'भारतीय क्लासिक: चोर कौन ढूँढे?'],
  'settings.guard': ['نگهبان در حالت‌های ۵ و ۶ نفره', 'Guard in the 5- and 6-player modes', '5 और 6 खिलाड़ी मोड में पहरेदार'],
  'settings.scoring': ['امتیازدهی', 'Scoring', 'अंक प्रणाली'],
  'settings.scoring.traditional': ['سنتی (۱۰۰۰ / ۸۰۰ / ۵۰۰)', 'Traditional (1000 / 800 / 500)', 'पारंपरिक (1000 / 800 / 500)'],
  'settings.scoring.party': ['ساده‌ی دورهمی (هر برد یک امتیاز)', 'Simple party (one point per win)', 'सरल पार्टी (हर जीत एक अंक)'],
  'settings.scoring.note': ['تغییر امتیازدهی از تورنمنت بعدی اعمال می‌شود.', 'Scoring changes apply from the next tournament.', 'अंक प्रणाली अगले टूर्नामेंट से लागू होगी।'],
  'settings.challenges': ['چالش جلاد بعد از هر دور', 'Executioner’s challenge after rounds', 'हर राउंड के बाद जल्लाद की चुनौती'],
  'settings.premium': ['نسخه‌ی ویژه', 'Premium', 'प्रीमियम'],
  'settings.premium.sub': ['هر چهار حالت، با دورهای نامحدود، برای همیشه رایگان است. نسخه‌ی ویژه فقط ظاهر و چالش‌های بیشتر اضافه می‌کند و هنوز فعال نیست.', 'All four modes are free forever, with unlimited rounds. Premium will only add looks and extra challenges, and is not available yet.', 'चारों मोड हमेशा मुफ़्त हैं, असीमित राउंड के साथ। प्रीमियम सिर्फ़ रूप और अतिरिक्त चुनौतियाँ जोड़ेगा, अभी उपलब्ध नहीं है।'],
  'settings.about': ['درباره', 'About', 'परिचय'],
  'settings.about.sub': ['ساخت اسپادنا · بدون حساب کاربری، بدون اینترنت، بدون تبلیغ. هیچ داده‌ای از گوشی شما خارج نمی‌شود.', 'Made by Espadna · No account, no internet, no ads. No data leaves your device.', 'Espadna द्वारा · कोई खाता नहीं, इंटरनेट नहीं, विज्ञापन नहीं। कोई डेटा आपके डिवाइस से बाहर नहीं जाता।'],
  'settings.privacy': ['حریم خصوصی', 'Privacy policy', 'गोपनीयता नीति'],

  'saved.title': ['بازیکن‌های ذخیره‌شده', 'Saved players', 'सहेजे गए खिलाड़ी'],
  'saved.empty': ['هنوز بازیکنی ذخیره نشده. نام‌هایی که در بازی می‌نویسید خودکار اینجا می‌آیند.', 'No saved players yet. Names you use in games appear here automatically.', 'अभी कोई खिलाड़ी नहीं। खेल में लिखे नाम यहाँ अपने-आप आ जाते हैं।'],
  'saved.new': ['نام بازیکن جدید', 'New player name', 'नए खिलाड़ी का नाम'],

  'rules.title': ['قوانین بازی', 'How to play', 'कैसे खेलें'],
  'rules.intro': ['یک گوشی بین همه می‌چرخد. هر کس مخفیانه نقشش را می‌بیند، شاه و وزیر خودشان را معرفی می‌کنند و وزیر باید دزد را پیدا کند. سریع، بامزه و بدون حذف شدن کسی.', 'One phone goes around the table. Everyone secretly sees their role, the King and the Minister reveal themselves, and the Minister has to find the thief. Quick, funny, and nobody is eliminated.', 'एक फ़ोन सबके बीच घूमता है। हर कोई चुपके से अपनी भूमिका देखता है, राजा और मंत्री अपनी पहचान बताते हैं, और मंत्री को चोर ढूँढना होता है। तेज़, मज़ेदार, और कोई बाहर नहीं होता।'],
  'rules.scoring': ['امتیازها', 'Points', 'अंक'],
  'rules.scoring.traditional': ['سنتی: شاه ۱۰۰۰، وزیر ۸۰۰ اگر درست حدس بزند، نگهبان ۵۰۰، دزدِ گیرافتاده ۰. حدس اشتباه: امتیاز وزیر به دزد می‌رسد. دلقک ۲۰۰ و اگر انتخاب شود ۶۰۰ اضافه. در حالت دو دزد: شکار کامل ۴۰۰ اضافه و هر دزد فراری ۴۰۰.', 'Traditional: King 1000, Minister 800 for a right guess, Guard 500, caught thief 0. Wrong guess: the thief takes the Minister’s points. Joker 200, plus 600 when picked. Two Thieves: Perfect Catch +400, each escaped thief 400.', 'पारंपरिक: राजा 1000, सही अंदाज़े पर मंत्री 800, पहरेदार 500, पकड़ा गया चोर 0। ग़लत अंदाज़ा: मंत्री के अंक चोर को। जोकर 200, चुना जाए तो +600। दो चोर: परफ़ेक्ट कैच +400, हर बचा चोर 400।'],
  'rules.scoring.party': ['ساده: برنده‌ی رقابت (وزیر یا هر دزد فراری) ۱ امتیاز، دلقکِ انتخاب‌شده ۱ و شکار کامل ۱ امتیاز اضافه.', 'Simple: the duel winner (the Minister, or each escaped thief) 1 point, a picked Joker 1, Perfect Catch +1.', 'सरल: मुक़ाबले का विजेता (मंत्री, या हर बचा चोर) 1 अंक, चुना गया जोकर 1, परफ़ेक्ट कैच +1।'],
};

const List<List<String>> _challenges = [
  [
    'با صدای یک پادشاه خسته، یک خبر هواشناسی بخوان.',
    'ده ثانیه مثل یک ربات راه برو.',
    'اسم سه میوه را با لهجه‌ی دلخواه بگو.',
    'یک بیت شعر یا ترانه را آهسته و با احساس بخوان.',
    'به نفر سمت راستت یک تعریف واقعی و بامزه بکن.',
    'سه بار پشت سر هم بگو: «شاه دزد وزیر، وزیر دزد شاه».',
    'ادای یک گربه را درآور که می‌خواهد غذا بگیرد.',
    'با چشم بسته، تعداد انگشت‌هایی که بقیه بالا می‌برند را حدس بزن.',
    'یک جمله‌ی کوتاه با فقط کلمه‌هایی بگو که با «م» شروع می‌شوند.',
    'تا نوبت بعد، به جای «بله» بگو «قربان».',
    'مثل گوینده‌ی فوتبال، ده ثانیه از همین بازی گزارش بده.',
    'یک لبخند بزرگ بزن و پنج ثانیه نگهش دار؛ بقیه سعی کنند تو را بخندانند.',
    'شعار تبلیغاتی یک محصول خیالی را بگو.',
    'سه حرکت ورزشی بامزه انجام بده.',
    'با دست، شکل یک حیوان را روی دیوار سایه بزن یا در هوا نشان بده.',
  ],
  [
    'Read a weather forecast in the voice of a very tired king.',
    'Walk like a robot for ten seconds.',
    'Name three fruits in any accent you like.',
    'Sing one line of a song, slowly and with feeling.',
    'Give the player on your right a true and funny compliment.',
    'Say “Shah, Thief, Minister, Minister, Thief, Shah” three times fast.',
    'Act like a cat asking for food.',
    'With eyes closed, guess how many fingers the others hold up.',
    'Say a short sentence where every word starts with the same letter.',
    'Until your next turn, answer “Your Majesty” instead of “yes”.',
    'Commentate this game like a football announcer for ten seconds.',
    'Hold a big smile for five seconds while the others try to make you laugh.',
    'Invent a slogan for an imaginary product.',
    'Do three silly exercise moves.',
    'Make an animal shape with your hands.',
  ],
  [
    'एक थके हुए राजा की आवाज़ में मौसम का हाल सुनाइए।',
    'दस सेकंड तक रोबोट की तरह चलिए।',
    'अपनी पसंद के लहजे में तीन फलों के नाम बोलिए।',
    'किसी गाने की एक पंक्ति धीरे और भाव से गाइए।',
    'अपने दाईं ओर वाले की एक सच्ची और मज़ेदार तारीफ़ कीजिए।',
    'तीन बार जल्दी बोलिए: “राजा मंत्री चोर सिपाही, सिपाही चोर मंत्री राजा”।',
    'खाना माँगती बिल्ली की नक़ल कीजिए।',
    'आँखें बंद करके अंदाज़ा लगाइए कि बाक़ी ने कितनी उँगलियाँ उठाई हैं।',
    'एक छोटा वाक्य बोलिए जिसका हर शब्द एक ही अक्षर से शुरू हो।',
    'अगली बारी तक “हाँ” की जगह “जी हुज़ूर” कहिए।',
    'दस सेकंड इस खेल की कमेंट्री क्रिकेट कमेंटेटर की तरह कीजिए।',
    'पाँच सेकंड बड़ी मुस्कान रखिए, बाक़ी आपको हँसाने की कोशिश करें।',
    'किसी काल्पनिक चीज़ का विज्ञापन नारा बनाइए।',
    'तीन मज़ेदार कसरत कीजिए।',
    'हाथों से किसी जानवर की आकृति बनाइए।',
  ],
];
