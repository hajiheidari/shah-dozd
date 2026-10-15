/// The Executioner's penalties for the loser of a round. Columns: fa, en, hi.
///
/// [Penalty.byExecutioner] = the Executioner carries it out on the loser;
/// otherwise the loser performs it. Everything stays light and playful:
/// nothing that hurts, and players can always skip ("Another one").
library;

enum PenaltyPack { base, fiery, party }

class Penalty {
  const Penalty(this.pack, this.byExecutioner, this.text);
  final PenaltyPack pack;
  final bool byExecutioner;
  final List<String> text; // fa, en, hi
}

const penalties = <Penalty>[
  // ---- Free: base pack ----
  Penalty(PenaltyPack.base, true, [
    'سیبیل آتشین! جلاد با انگشت اشاره چند بار تند و سریع بالای لب بازنده را می‌مالد.',
    'Fiery Moustache! The Executioner briskly rubs a finger above the loser’s upper lip a few times.',
    'जलती मूँछ! जल्लाद उँगली से हारने वाले के ऊपरी होंठ के ऊपर तेज़ी से कुछ बार रगड़ता है।',
  ]),
  Penalty(PenaltyPack.base, true, [
    'گوش‌کشی شاهانه: جلاد آرام گوش بازنده را می‌گیرد تا سه بار بگوید «غلط کردم قربان!»',
    'Royal ear pull: the Executioner gently holds the loser’s ear until they say “Forgive me, Your Majesty!” three times.',
    'शाही कान खिंचाई: जल्लाद हल्के से कान पकड़ता है जब तक हारने वाला तीन बार “माफ़ कीजिए हुज़ूर!” न कहे।',
  ]),
  Penalty(PenaltyPack.base, true, [
    'قلقلک ده‌ثانیه‌ای: جلاد ده ثانیه قلقلکش می‌دهد. اگر بخندد، ده ثانیه‌ی دیگر!',
    'Ten-second tickle: the Executioner tickles the loser for ten seconds. If they laugh, ten more!',
    'दस सेकंड गुदगुदी: जल्लाद दस सेकंड गुदगुदी करता है। हँसे तो दस सेकंड और!',
  ]),
  Penalty(PenaltyPack.base, true, [
    'لپ‌کشی: جلاد لپ‌های بازنده را آرام می‌کشد و او باید «اتل متل توتوله» را تا آخر بخواند.',
    'Cheek squeeze: the Executioner gently pulls the loser’s cheeks while they recite a nursery rhyme to the end.',
    'गाल खिंचाई: जल्लाद हल्के से गाल खींचता है और हारने वाले को पूरी कविता “मछली जल की रानी है” सुनानी है।',
  ]),
  Penalty(PenaltyPack.base, true, [
    'مجسمه‌ساز: جلاد بازنده را در یک ژست خنده‌دار قرار می‌دهد؛ سی ثانیه نباید تکان بخورد.',
    'Sculptor: the Executioner poses the loser in a silly pose; they must hold it for thirty seconds.',
    'मूर्तिकार: जल्लाद हारने वाले को मज़ेदार मुद्रा में खड़ा करता है; तीस सेकंड हिलना मना है।',
  ]),
  Penalty(PenaltyPack.base, true, [
    'آرایشگر سلطنتی: جلاد سی ثانیه موهای بازنده را هر جور دلش خواست درست می‌کند؛ تا دور بعد همان می‌ماند.',
    'Royal barber: the Executioner styles the loser’s hair however they like for thirty seconds; it stays until next round.',
    'शाही नाई: जल्लाद तीस सेकंड बालों को मनचाहा बनाता है; अगले राउंड तक वैसे ही रहेंगे।',
  ]),
  Penalty(PenaltyPack.base, true, [
    'شلاق کاغذی: جلاد با یک برگه‌ی لوله‌شده سه ضربه‌ی نمادین به کف دست بازنده می‌زند و هر بار می‌گوید «به حکم شاه!»',
    'Paper lash: with a rolled-up sheet the Executioner gives three symbolic taps on the loser’s palm, shouting “By order of the King!”',
    'काग़ज़ी कोड़ा: जल्लाद लिपटे काग़ज़ से हथेली पर तीन प्रतीकात्मक थपकी देता है और हर बार कहता है “राजा के हुक्म से!”',
  ]),
  Penalty(PenaltyPack.base, true, [
    'زل‌زدن: بازنده باید سی ثانیه بدون خندیدن به چشم‌های جلاد نگاه کند. جلاد هر کاری می‌تواند بکند جز دست زدن.',
    'Staring contest: the loser must look into the Executioner’s eyes for thirty seconds without laughing. The Executioner may do anything except touch.',
    'घूरना: हारने वाले को तीस सेकंड बिना हँसे जल्लाद की आँखों में देखना है। जल्लाद छूने के अलावा कुछ भी कर सकता है।',
  ]),
  Penalty(PenaltyPack.base, false, [
    'با صدای بلند و آهنگین بگو «من دزد بودم، ببخشید!» و یک دور کامل دور اتاق رژه برو.',
    'Sing out loud “I was the thief, I’m sorry!” while marching a full lap around the room.',
    'गाकर ज़ोर से कहो “मैं चोर था, माफ़ करो!” और कमरे का पूरा चक्कर मार्च करते हुए लगाओ।',
  ]),
  Penalty(PenaltyPack.base, false, [
    'ده بار اسکات بزن و همزمان الفبا را بلند بگو.',
    'Do ten squats while saying the alphabet out loud.',
    'दस बार उठक-बैठक करो और साथ में ज़ोर से वर्णमाला बोलो।',
  ]),
  Penalty(PenaltyPack.base, false, [
    'تا دور بعد فقط با صدای اردک حرف بزن.',
    'Until the next round, talk only in a duck voice.',
    'अगले राउंड तक सिर्फ़ बत्तख की आवाज़ में बोलो।',
  ]),
  Penalty(PenaltyPack.base, false, [
    'مثل گوینده‌ی اخبار، خبر فوری باختت را با جزئیات اعلام کن.',
    'Like a news anchor, announce the breaking news of your defeat, with details.',
    'न्यूज़ एंकर की तरह अपनी हार की ब्रेकिंग न्यूज़ पूरे ब्योरे के साथ सुनाओ।',
  ]),
  Penalty(PenaltyPack.base, false, [
    'بیست ثانیه روی یک پا بایست و یک آهنگ بخوان. اگر افتادی از اول!',
    'Stand on one leg for twenty seconds and sing. If you wobble off, start again!',
    'बीस सेकंड एक पैर पर खड़े होकर गाना गाओ। गिरे तो फिर से!',
  ]),
  Penalty(PenaltyPack.base, false, [
    'با دهان بسته یک آهنگ معروف را زمزمه کن تا بقیه حدس بزنند.',
    'Hum a famous song with your mouth closed until the others guess it.',
    'मुँह बंद करके एक मशहूर गाना गुनगुनाओ जब तक बाक़ी पहचान न लें।',
  ]),

  // ---- Coins: the Executioner's fiery pack ----
  Penalty(PenaltyPack.fiery, true, [
    'سیبیل آتشین دوبل! جلاد هر دو طرف بالای لب را می‌مالد، و بازنده باید وسطش بگوید «به‌به، چه سیبیلی!»',
    'Double Fiery Moustache! Both sides, and the loser must say “What a fine moustache!” in between.',
    'डबल जलती मूँछ! दोनों तरफ़, और बीच में हारने वाले को कहना है “वाह, क्या मूँछ है!”',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'قلقلک کف پا: جلاد پانزده ثانیه کف پای بازنده را قلقلک می‌دهد. جیغ زدن آزاد است!',
    'Foot tickle: fifteen seconds of tickling the loser’s soles. Screaming is allowed!',
    'तलवों की गुदगुदी: पंद्रह सेकंड। चीख़ने की इजाज़त है!',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'بالش‌کوبی: جلاد سه بار با بالش روی سر بازنده می‌زند و جمع شمارش می‌کند.',
    'Pillow strike: the Executioner bops the loser on the head three times with a pillow while everyone counts.',
    'तकिया वार: जल्लाद तकिये से सिर पर तीन बार मारता है और सब गिनते हैं।',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'خال شاهانه: جلاد با ماژیک پاک‌شدنی یا رژ، سیبیل یا خال روی صورت بازنده می‌کشد که تا آخر بازی می‌ماند.',
    'Royal beauty spot: with a washable marker or lipstick the Executioner draws a moustache or mole that stays until the end of the game.',
    'शाही तिल: धुलने वाले मार्कर या लिपस्टिक से जल्लाद मूँछ या तिल बनाता है जो खेल के अंत तक रहेगा।',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'یخ عدالت: جلاد یک تکه یخ را ده ثانیه پشت گردن بازنده نگه می‌دارد.',
    'Ice of justice: the Executioner holds an ice cube on the back of the loser’s neck for ten seconds.',
    'इंसाफ़ की बर्फ़: जल्लाद दस सेकंड बर्फ़ का टुकड़ा गर्दन के पीछे रखता है।',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'پای بسته: جلاد مچ پاهای بازنده را با یک شال می‌بندد و او باید تا آن سر اتاق لی‌لی کند و برگردد.',
    'Tied feet: the Executioner ties the loser’s ankles with a scarf; they must hop across the room and back.',
    'बँधे पैर: जल्लाद दुपट्टे से टखने बाँधता है; कमरे के उस पार कूदकर जाना और लौटना है।',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'چاشنی جلاد: جلاد یک قاشق کوچک چیز ترش انتخاب می‌کند (آبلیمو، آبغوره…) و بازنده بدون اخم می‌خورد. فقط اگر حساسیت ندارد.',
    'The Executioner’s seasoning: a small spoon of something sour (lemon juice, pickle juice…) chosen by the Executioner, eaten without a frown. Only if no allergies.',
    'जल्लाद का मसाला: जल्लाद की चुनी एक छोटी चम्मच खट्टी चीज़ (नींबू रस, अचार का पानी…) बिना मुँह बनाए खानी है। सिर्फ़ अगर एलर्जी न हो।',
  ]),
  Penalty(PenaltyPack.fiery, true, [
    'نوکر شاه: بازنده تا دور بعد نوکر شاه است؛ سی ثانیه شانه‌هایش را ماساژ می‌دهد و هر دستوری بگوید «بله قربان!»',
    'The King’s servant: until next round the loser serves the King, gives a thirty-second shoulder rub and answers every order with “Yes, Your Majesty!”',
    'राजा का सेवक: अगले राउंड तक हारने वाला राजा की सेवा करता है, तीस सेकंड कंधे दबाता है और हर हुक्म पर कहता है “जी हुज़ूर!”',
  ]),

  // ---- Coins: the party pack (the loser performs) ----
  Penalty(PenaltyPack.party, false, [
    'سی ثانیه بدون موسیقی، با تمام وجود برقص.',
    'Dance with all your heart for thirty seconds, without music.',
    'तीस सेकंड बिना संगीत के पूरे दिल से नाचो।',
  ]),
  Penalty(PenaltyPack.party, false, [
    'یک بیسکویت روی پیشانی‌ات بگذار و بدون دست آن را به دهانت برسان.',
    'Put a biscuit on your forehead and get it into your mouth without using your hands.',
    'माथे पर बिस्कुट रखकर बिना हाथ लगाए उसे मुँह तक पहुँचाओ।',
  ]),
  Penalty(PenaltyPack.party, false, [
    'مثل پنگوئن یک دور کامل دور اتاق راه برو و برای هر نفر تعظیم کن.',
    'Waddle a full lap around the room like a penguin and bow to everyone.',
    'पेंगुइन की तरह कमरे का पूरा चक्कर लगाओ और हर किसी को झुककर सलाम करो।',
  ]),
  Penalty(PenaltyPack.party, false, [
    'یک شعر کودکانه را با صدای خواننده‌ی اپرا اجرا کن.',
    'Perform a children’s song in an opera singer’s voice.',
    'एक बच्चों का गाना ओपेरा गायक की आवाज़ में गाओ।',
  ]),
  Penalty(PenaltyPack.party, false, [
    'ده تا شنا برو؛ برای هر کدام جمع اسمت را تشویق کند.',
    'Do ten push-ups while everyone cheers your name for each one.',
    'दस पुश-अप करो, और हर एक पर सब तुम्हारा नाम लेकर हौसला बढ़ाएँ।',
  ]),
  Penalty(PenaltyPack.party, false, [
    'تا دور بعد فقط با سؤال حرف بزن. اگر جمله‌ی خبری گفتی، یک جریمه‌ی دیگر!',
    'Until next round, speak only in questions. Say a statement and you get another penalty!',
    'अगले राउंड तक सिर्फ़ सवालों में बोलो। सीधा वाक्य बोला तो एक और सज़ा!',
  ]),
  Penalty(PenaltyPack.party, false, [
    'ادای یکی از جمع را درآور تا بقیه حدس بزنند کیست.',
    'Imitate someone at the table until the others guess who it is.',
    'मेज़ पर किसी की नक़ल करो जब तक बाक़ी पहचान न लें।',
  ]),
  Penalty(PenaltyPack.party, false, [
    'صدای پنج حیوان را پشت سر هم دربیاور، بدون اینکه بخندی.',
    'Make five animal sounds in a row without laughing.',
    'बिना हँसे लगातार पाँच जानवरों की आवाज़ निकालो।',
  ]),
];
