#!/usr/bin/env python3
"""Writes the landing pages of espadna.com/shahdozd-app/ into a folder.

    python3 tools/landing.py build/landing/shahdozd-app

English at the root, Persian in fa/, Hindi in hi/, privacy policy in
privacy/ (all three languages on one page). Same layout rules as the other
Espadna apps: absolute paths, canonical + hreflang, the game's own style.
Called by tools/web_build.mjs.
"""
import html
import json
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'build' / 'landing' / 'shahdozd-app'
BASE = '/shahdozd-app'
SITE = 'https://espadna.com' + BASE
GAME = 'https://shahdozd.espadna.com'

T = {
    'en': {
        'dir': 'ltr', 'path': '/', 'lang_name': 'English',
        'title': 'Shah, Thief & Minister — the party game for one phone',
        'desc': 'Play Shah-Dozd-Vazir and Raja-Mantri-Chor-Sipahi with one phone: secret roles, four modes for 4 to 6 players, works offline, no forced ads, free.',
        'name': 'Shah, Thief & Minister',
        'tagline': 'The classic party game of Iran and India, for one phone.',
        'play': 'Play now in your browser',
        'play_sub': 'Free · no sign-up · works offline after the first visit',
        'modes_h': 'Four modes',
        'modes': [
            ('Persian Classic', '4 players', 'King, Minister, Thief and Executioner. The Minister has one guess.'),
            ('Indian Classic', '4 players', 'Raja, Mantri, Chor and Sipahi, with both local rules for who finds the Chor.'),
            ('Joker Edition', '5 players', 'The Joker pretends to be the thief and wins big if the Minister falls for it.'),
            ('Two Thieves', '6 players', 'Two thieves are hiding. The Minister picks two players: one thief is enough to win.'),
        ],
        'feat_h': 'Made for the table',
        'feats': [
            ('One phone, secret roles', 'Each player presses and holds the card to see their role. Let go and it hides.'),
            ('Rules always on screen', 'A short rule for the current mode stays at the top while you play.'),
            ('Scores and tournaments', 'Traditional 1000/800/500 points or simple party scoring, with round history.'),
            ('No internet, no forced ads', 'Names and scores stay on your device. No account. Ads only if you choose to watch one for coins.'),
        ],
        'how_h': 'How a round goes',
        'how': ['The phone goes around; everyone secretly sees their role.', 'The King and the Minister reveal themselves.',
                'The Minister points at the thief.', 'Cards flip, points are added — next round in seconds.'],
        'privacy': 'Privacy', 'studio': 'An Espadna game',
    },
    'fa': {
        'dir': 'rtl', 'path': '/fa/', 'lang_name': 'فارسی',
        'title': 'شاه، دزد، وزیر | بازی دورهمی با یک گوشی',
        'desc': 'بازی شاه دزد وزیر با یک گوشی: پخش مخفی نقش‌ها، چهار حالت برای ۴ تا ۶ نفر، بدون اینترنت، بدون تبلیغ اجباری و رایگان.',
        'name': 'شاه، دزد، وزیر',
        'tagline': 'همان بازی نوستالژیک دورهمی، با یک گوشی برای همه.',
        'play': 'همین حالا بازی کنید',
        'play_sub': 'رایگان · بدون ثبت‌نام · بعد از اولین بار بدون اینترنت هم کار می‌کند',
        'modes_h': 'چهار حالت بازی',
        'modes': [
            ('کلاسیک ایرانی', '۴ نفر', 'شاه، وزیر، دزد و جلاد. وزیر یک بار حق حدس دارد.'),
            ('کلاسیک هندی', '۴ نفر', 'راجا، منتری، چور و سپاهی؛ با هر دو قاعده‌ی محلی برای اینکه چه کسی چور را پیدا کند.'),
            ('نسخه‌ی دلقک', '۵ نفر', 'دلقک خودش را دزد جا می‌زند و اگر وزیر گول بخورد، جایزه‌ی بزرگ می‌برد.'),
            ('دو دزد', '۶ نفر', 'دو دزد پنهان شده‌اند. وزیر دو نفر را انتخاب می‌کند و پیدا کردن یکی برای برد کافی است.'),
        ],
        'feat_h': 'ساخته‌شده برای دورهمی',
        'feats': [
            ('یک گوشی، نقش‌های مخفی', 'هر کس کارت را نگه می‌دارد تا نقشش را ببیند؛ با برداشتن انگشت، کارت بسته می‌شود.'),
            ('قانون همیشه جلوی چشم', 'خلاصه‌ی قانون همان حالت در طول بازی بالای صفحه می‌ماند.'),
            ('امتیاز و تورنمنت', 'امتیازدهی سنتی ۱۰۰۰/۸۰۰/۵۰۰ یا امتیاز ساده‌ی دورهمی، با تاریخچه‌ی دورها.'),
            ('بدون اینترنت، بدون تبلیغ اجباری', 'نام‌ها و امتیازها روی گوشی خودتان می‌ماند. بدون حساب کاربری. تبلیغ فقط اگر خودتان برای سکه بخواهید.'),
        ],
        'how_h': 'یک دور بازی',
        'how': ['گوشی دست‌به‌دست می‌چرخد و هر کس مخفیانه نقشش را می‌بیند.', 'شاه و وزیر خودشان را معرفی می‌کنند.',
                'وزیر دزد را نشان می‌دهد.', 'کارت‌ها رو می‌شوند و امتیازها اضافه می‌شود؛ دور بعد در چند ثانیه.'],
        'privacy': 'حریم خصوصی', 'studio': 'یک بازی از اسپادنا',
    },
    'hi': {
        'dir': 'ltr', 'path': '/hi/', 'lang_name': 'हिन्दी',
        'title': 'राजा मंत्री चोर सिपाही — एक फ़ोन पर पार्टी गेम',
        'desc': 'राजा-मंत्री-चोर-सिपाही एक फ़ोन पर खेलें: गुप्त भूमिकाएँ, 4 से 6 खिलाड़ियों के चार मोड, ऑफ़लाइन, कोई ज़बरदस्ती विज्ञापन नहीं, मुफ़्त।',
        'name': 'राजा, मंत्री, चोर, सिपाही',
        'tagline': 'ईरान और भारत का पुराना पार्टी गेम, अब एक फ़ोन पर।',
        'play': 'अभी ब्राउज़र में खेलें',
        'play_sub': 'मुफ़्त · बिना साइन-अप · पहली बार के बाद ऑफ़लाइन भी',
        'modes_h': 'चार मोड',
        'modes': [
            ('फ़ारसी क्लासिक', '4 खिलाड़ी', 'बादशाह, वज़ीर, चोर और जल्लाद। वज़ीर को एक अंदाज़ा मिलता है।'),
            ('भारतीय क्लासिक', '4 खिलाड़ी', 'राजा, मंत्री, चोर और सिपाही, चोर कौन ढूँढे इसके दोनों स्थानीय नियमों के साथ।'),
            ('जोकर संस्करण', '5 खिलाड़ी', 'जोकर चोर होने का नाटक करता है, और मंत्री फँस जाए तो बड़ा इनाम जीतता है।'),
            ('दो चोर', '6 खिलाड़ी', 'दो चोर छिपे हैं। मंत्री दो लोगों को चुनता है: जीत के लिए एक चोर काफ़ी है।'),
        ],
        'feat_h': 'महफ़िल के लिए बना',
        'feats': [
            ('एक फ़ोन, गुप्त भूमिकाएँ', 'हर खिलाड़ी अपनी भूमिका देखने के लिए कार्ड दबाए रखता है; छोड़ते ही वह छिप जाता है।'),
            ('नियम हमेशा सामने', 'खेलते समय मौजूदा मोड का छोटा नियम ऊपर दिखता रहता है।'),
            ('अंक और टूर्नामेंट', 'पारंपरिक 1000/800/500 अंक या सरल पार्टी अंक, राउंड के इतिहास के साथ।'),
            ('बिना इंटरनेट, ज़बरदस्ती विज्ञापन नहीं', 'नाम और अंक आपके डिवाइस पर रहते हैं। कोई खाता नहीं। विज्ञापन सिर्फ़ तब, जब आप सिक्कों के लिए ख़ुद देखें।'),
        ],
        'how_h': 'एक राउंड कैसे चलता है',
        'how': ['फ़ोन घूमता है; हर कोई चुपके से अपनी भूमिका देखता है।', 'राजा और मंत्री अपनी पहचान बताते हैं।',
                'मंत्री चोर की ओर इशारा करता है।', 'कार्ड पलटते हैं, अंक जुड़ते हैं — अगला राउंड कुछ ही पलों में।'],
        'privacy': 'गोपनीयता', 'studio': 'Espadna का एक गेम',
    },
}

MODE_ART = [('king', 'thief', 'minister'), ('king', 'minister', 'sipahi'), ('joker', 'minister', 'thief'), ('thief', 'joker', 'thief2')]

CSS = """
@font-face{font-family:Vazirmatn;src:url(/shahdozd-app/fonts/Vazirmatn-Regular.ttf) format('truetype');font-weight:400;font-display:swap}
@font-face{font-family:Vazirmatn;src:url(/shahdozd-app/fonts/Vazirmatn-Black.ttf) format('truetype');font-weight:900;font-display:swap}
:root{--night:#0C0F2A;--surface:#151942;--gold:#D4AE55;--gold-l:#F6E3A6;--gold-t:#E9CD86;--ivory:#F6EEDC;--muted:#CFC6B4;--line:rgba(212,174,85,.35)}
*{box-sizing:border-box}
body{margin:0;background:var(--night);color:var(--ivory);font-family:Vazirmatn,'Noto Sans Devanagari',system-ui,sans-serif;line-height:1.7}
a{color:var(--gold-t)}
.wrap{max-width:1040px;margin:0 auto;padding:0 16px}
header{display:flex;justify-content:space-between;align-items:center;padding:14px 0}
header .brand{display:flex;align-items:center;gap:10px;color:var(--ivory);text-decoration:none;font-weight:900}
header img{width:36px;height:36px;border-radius:9px}
nav.langs a{margin-inline-start:12px;font-size:14px;color:var(--muted)}
nav.langs a[aria-current]{color:var(--gold-t);text-decoration:none}
.hero{display:grid;grid-template-columns:1.1fr 1fr;gap:32px;align-items:center;padding:24px 0 40px}
.hero h1{font-weight:900;font-size:clamp(34px,6vw,58px);line-height:1.2;margin:0;color:var(--gold-t)}
.hero p.tag{font-size:19px;color:var(--muted);margin:10px 0 24px}
.cta{display:inline-flex;flex-direction:column;background:var(--gold);color:#1A1530;text-decoration:none;border-radius:16px;padding:14px 26px;font-weight:900;font-size:19px;min-height:54px}
.cta small{font-weight:400;font-size:13px}
.fan{position:relative;height:340px}
.fan img{position:absolute;width:190px;top:20px;left:50%;filter:drop-shadow(0 18px 30px rgba(0,0,0,.5))}
.fan img:nth-child(1){transform:translateX(-120%) rotate(-12deg)}
.fan img:nth-child(2){transform:translateX(20%) rotate(12deg)}
.fan img:nth-child(3){transform:translateX(-50%);top:0;width:210px}
h2{font-weight:900;font-size:28px;color:var(--gold-t);margin:36px 0 16px}
.modes{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}
.mode{background:var(--surface);border:1px solid var(--line);border-radius:20px;overflow:hidden}
.mode .art{height:150px;display:flex;justify-content:center;align-items:flex-end;padding-top:12px}
.mode .art img{width:86px;margin:0 -14px;filter:drop-shadow(0 8px 12px rgba(0,0,0,.5))}
.mode .art img:nth-child(2){width:100px;position:relative;z-index:1}
.mode div.t{padding:12px 14px 16px}
.mode b{display:block;font-size:17px}
.mode span.n{display:inline-block;background:var(--gold);color:#1A1530;border-radius:99px;padding:0 10px;font-size:12px;font-weight:900}
.mode p{margin:6px 0 0;font-size:14px;color:var(--muted)}
.feats{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}
.feat{background:var(--surface);border-radius:16px;padding:16px 18px}
.feat b{color:var(--gold-l)}
.feat p{margin:4px 0 0;color:var(--muted);font-size:15px}
ol.how{padding-inline-start:22px;font-size:16px;color:var(--muted)}
footer{margin:48px 0 28px;padding-top:18px;border-top:1px solid var(--line);font-size:14px;color:var(--muted);display:flex;gap:16px;flex-wrap:wrap;justify-content:space-between}
@media (max-width:820px){.hero{grid-template-columns:1fr;text-align:center}.fan{height:300px}.modes{grid-template-columns:repeat(2,minmax(0,1fr))}.feats{grid-template-columns:1fr}}
@media (max-width:420px){.fan img{width:150px}.fan img:nth-child(3){width:170px}.mode .art img{width:66px}.mode .art img:nth-child(2){width:78px}}
"""


def page(lang: str) -> str:
    t = T[lang]
    e = html.escape
    alts = ''.join(f'<link rel="alternate" hreflang="{l}" href="{SITE}{T[l]["path"]}">' for l in T)
    langs = ''.join(
        f'<a href="{BASE}{T[l]["path"]}" lang="{l}"{" aria-current=page" if l == lang else ""}>{T[l]["lang_name"]}</a>' for l in T)
    def imgs(arts):
        return ''.join(f'<img src="{BASE}/cards/{a}.webp" alt="" loading="lazy">' for a in (arts[1], arts[0], arts[2]))

    modes = ''.join(
        f'<div class="mode"><div class="art">{imgs(arts)}</div>'
        f'<div class="t"><b>{e(name)}</b><span class="n">{e(n)}</span><p>{e(d)}</p></div></div>'
        for (name, n, d), arts in zip(t['modes'], MODE_ART))
    feats = ''.join(f'<div class="feat"><b>{e(a)}</b><p>{e(b)}</p></div>' for a, b in t['feats'])
    how = ''.join(f'<li>{e(x)}</li>' for x in t['how'])
    ld = json.dumps({'@context': 'https://schema.org', '@type': 'VideoGame', 'name': t['name'], 'description': t['desc'],
                     'url': SITE + t['path'], 'inLanguage': lang, 'genre': 'Party game', 'numberOfPlayers': '4-6',
                     'gamePlatform': ['Web browser', 'Android', 'iOS'], 'isAccessibleForFree': True,
                     'publisher': {'@type': 'Organization', 'name': 'Espadna', 'url': 'https://espadna.com'}}, ensure_ascii=False)
    return f'''<!DOCTYPE html>
<html lang="{lang}" dir="{t['dir']}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{e(t['title'])}</title>
<meta name="description" content="{e(t['desc'])}">
<meta name="theme-color" content="#0C0F2A">
<link rel="canonical" href="{SITE}{t['path']}">
{alts}<link rel="alternate" hreflang="x-default" href="{SITE}/">
<link rel="icon" type="image/png" href="{BASE}/favicon.png">
<link rel="apple-touch-icon" href="{BASE}/icon.png">
<meta property="og:type" content="website">
<meta property="og:title" content="{e(t['title'])}">
<meta property="og:description" content="{e(t['desc'])}">
<meta property="og:url" content="{SITE}{t['path']}">
<meta property="og:image" content="{SITE}/og.png">
<meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">{ld}</script>
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
<header><a class="brand" href="{BASE}{t['path']}"><img src="{BASE}/icon.png" alt="">{e(t['name'])}</a><nav class="langs">{langs}</nav></header>
<section class="hero">
<div><h1>{e(t['name'])}</h1><p class="tag">{e(t['tagline'])}</p>
<a class="cta" href="{GAME}/?lang={lang}">{e(t['play'])}<small>{e(t['play_sub'])}</small></a></div>
<div class="fan" aria-hidden="true"><img src="{BASE}/cards/minister.webp" alt=""><img src="{BASE}/cards/thief.webp" alt=""><img src="{BASE}/cards/king.webp" alt=""></div>
</section>
<h2>{e(t['modes_h'])}</h2><div class="modes">{modes}</div>
<h2>{e(t['feat_h'])}</h2><div class="feats">{feats}</div>
<h2>{e(t['how_h'])}</h2><ol class="how">{how}</ol>
<footer><span>{e(t['studio'])} · <a href="https://espadna.com{'/fa/' if lang == 'fa' else '/'}">espadna.com</a></span><a href="{BASE}/privacy/">{e(t['privacy'])}</a></footer>
</div>
</body>
</html>
'''


PRIVACY = {
    'fa': ('حریم خصوصی', [
        'شاه، دزد، وزیر حساب کاربری ندارد و نام بازیکن‌ها، امتیازها، سکه‌ها و تنظیمات را فقط روی همین دستگاه نگه می‌دارد؛ این‌ها به هیچ سروری فرستاده نمی‌شوند و با پاک کردن داده‌ی اپ یا مرورگر پاک می‌شوند.',
        'خود بازی بدون اینترنت کار می‌کند و ابزار تحلیل یا ردیاب ندارد.',
        'تبلیغ فقط وقتی پخش می‌شود که خودتان در فروشگاه «دیدن تبلیغ» را بزنید تا سکه بگیرید. در نسخه‌های گوگل‌پلی و App Store این تبلیغ را Google AdMob و در نسخه‌های کافه‌بازار و دانلود مستقیم Adivery نمایش می‌دهد. این شبکه‌ها برای نمایش تبلیغ، اطلاعاتی مثل شناسه‌ی تبلیغاتی دستگاه، نوع دستگاه و نشانی IP را طبق سیاست حریم خصوصی خودشان پردازش می‌کنند. ما تبلیغ شخصی‌سازی‌شده درخواست نمی‌کنیم. نسخه‌ی وب تبلیغ ندارد.',
        'پشتیبان: در آیفون و آیپد اطلاعات ذخیره‌شده (سکه، خریدها، نام‌ها، تنظیمات و امتیازها) در iCloud خود شما هم نگه داشته می‌شود و در اندروید، اگر پشتیبان‌گیری گوشی روشن باشد، سیستم آن را در گوگل‌درایو خود شما ذخیره می‌کند؛ ما به هیچ‌کدام دسترسی نداریم. کد بازیابی در تنظیمات فقط سکه، خریدها و تعداد دورها را دارد و تا خودتان کپی نکنید از گوشی خارج نمی‌شود. گیم سنتر (iOS): اگر وارد شده باشید، تعداد دورهای بازی‌شده و دستاوردها طبق سیاست اپل به Game Center فرستاده می‌شود.',
        'با «معرفی به دوستان» فقط پیامی با لینک بازی در اپی که خودتان انتخاب می‌کنید فرستاده می‌شود؛ ما فهرست مخاطبان شما را نمی‌بینیم.',
        'سکه با پول خریده نمی‌شود. اگر روزی خرید درون‌برنامه‌ای اضافه شود، از طریق فروشگاه همان نسخه انجام می‌شود و این صفحه پیش از آن به‌روز خواهد شد.',
    ]),
    'en': ('Privacy policy', [
        'Shah, Thief & Minister has no accounts. Player names, scores, coins and settings are stored only on this device, are never sent to any server, and are deleted when you clear the app’s or browser’s data.',
        'The game itself works offline and contains no analytics or trackers.',
        'An ad plays only when you tap “Watch an ad” in the shop to earn coins. In the Google Play and App Store versions it is served by Google AdMob; in the Cafe Bazaar and direct-download versions by Adivery. To show it, these networks process data such as the device’s advertising identifier, device type and IP address under their own privacy policies. We request non-personalized ads. The web version has no ads.',
        'Backups: on iPhone and iPad the saved state (coins, items, names, settings, scores) is also kept in your own iCloud; on Android the system may back it up to your own Google Drive if device backup is on. We cannot read either. The recovery code in Settings holds only coins, items and rounds played, and leaves your device only if you copy it. Game Center (iOS): if you are signed in, rounds played and earned achievements are sent to Apple’s Game Center under Apple’s policy.',
        '“Share with friends” only sends a message with the game’s link through an app you choose; we never see your contacts.',
        'Coins cannot be bought with money. If an in-app purchase is ever added, it will go through that version’s store, and this page will be updated first.',
    ]),
    'hi': ('गोपनीयता नीति', [
        'इस गेम में कोई खाता नहीं है। खिलाड़ियों के नाम, अंक, सिक्के और सेटिंग्स सिर्फ़ इसी डिवाइस पर रहते हैं, किसी सर्वर पर नहीं भेजे जाते, और ऐप या ब्राउज़र का डेटा मिटाने पर मिट जाते हैं।',
        'गेम ख़ुद बिना इंटरनेट चलता है और इसमें कोई एनालिटिक्स या ट्रैकर नहीं है।',
        'विज्ञापन सिर्फ़ तब चलता है जब आप सिक्कों के लिए दुकान में “विज्ञापन देखें” दबाते हैं। Google Play और App Store संस्करणों में इसे Google AdMob दिखाता है, Cafe Bazaar और सीधे डाउनलोड वाले संस्करणों में Adivery। विज्ञापन दिखाने के लिए ये नेटवर्क अपनी गोपनीयता नीति के तहत डिवाइस की विज्ञापन पहचान, डिवाइस का प्रकार और IP पता जैसी जानकारी प्रोसेस करते हैं। हम ग़ैर-व्यक्तिगत विज्ञापन माँगते हैं। वेब संस्करण में विज्ञापन नहीं हैं।',
        'बैकअप: iPhone और iPad पर सहेजी जानकारी (सिक्के, चीज़ें, नाम, सेटिंग्स, अंक) आपके अपने iCloud में भी रहती है; Android पर, अगर डिवाइस बैकअप चालू है, तो सिस्टम इसे आपकी अपनी Google Drive में सहेज सकता है। हम इनमें से कुछ नहीं पढ़ सकते। सेटिंग्स का रिकवरी कोड सिर्फ़ सिक्के, चीज़ें और खेले गए राउंड रखता है और तभी बाहर जाता है जब आप उसे कॉपी करें। Game Center (iOS): साइन इन होने पर खेले गए राउंड और उपलब्धियाँ Apple की नीति के तहत Game Center को भेजी जाती हैं।',
        '“दोस्तों से शेयर करें” सिर्फ़ आपके चुने ऐप से गेम का लिंक भेजता है; हम आपके संपर्क नहीं देखते।',
        'सिक्के पैसे से नहीं ख़रीदे जाते। अगर कभी इन-ऐप ख़रीद जोड़ी गई तो वह उसी संस्करण के स्टोर से होगी और यह पेज पहले अपडेट होगा।',
    ]),
}


def privacy() -> str:
    def paras(ps):
        return ''.join(f'<p>{html.escape(p)}</p>' for p in ps)

    body = ''.join(
        f'<section lang="{l}" dir="{"rtl" if l == "fa" else "ltr"}"><h2>{html.escape(h)}</h2>{paras(ps)}</section>'
        for l, (h, ps) in PRIVACY.items())
    return f'''<!DOCTYPE html>
<html lang="fa">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>حریم خصوصی · Privacy — شاه، دزد، وزیر</title>
<link rel="canonical" href="{SITE}/privacy/"><link rel="icon" type="image/png" href="{BASE}/favicon.png">
<style>{CSS} section{{margin-bottom:28px}} p{{color:var(--muted)}}</style></head>
<body><div class="wrap"><header><a class="brand" href="{BASE}/fa/"><img src="{BASE}/icon.png" alt="">شاه، دزد، وزیر</a></header>
{body}<p style="color:var(--muted);font-size:14px">Espadna · <a href="https://espadna.com">espadna.com</a> · 2026-10</p></div></body></html>
'''


def main() -> None:
    shutil.rmtree(OUT, ignore_errors=True)
    for lang, t in T.items():
        d = OUT / t['path'].strip('/') if t['path'] != '/' else OUT
        d.mkdir(parents=True, exist_ok=True)
        (d / 'index.html').write_text(page(lang), encoding='utf-8')
    (OUT / 'privacy').mkdir(parents=True, exist_ok=True)
    (OUT / 'privacy' / 'index.html').write_text(privacy(), encoding='utf-8')
    shutil.copytree(ROOT / 'assets' / 'cards', OUT / 'cards')
    (OUT / 'fonts').mkdir()
    for f in ('Vazirmatn-Regular.ttf', 'Vazirmatn-Black.ttf'):
        shutil.copy(ROOT / 'assets' / 'fonts' / f, OUT / 'fonts' / f)
    shutil.copy(ROOT / 'web' / 'icons' / 'Icon-512.png', OUT / 'icon.png')
    shutil.copy(ROOT / 'web' / 'favicon.png', OUT / 'favicon.png')
    shutil.copy(ROOT / 'site' / 'og.png', OUT / 'og.png')
    print(f'landing pages → {OUT}')


if __name__ == '__main__':
    main()
