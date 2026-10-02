import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

/// Fixed interface text (buttons, titles, messages) in every app language.
/// Built in, so it shows instantly and offline. Placeholders like {n} are filled by [tr].
class UiStrings {
  static const languages = ['fr', 'ar', 'uk', 'it', 'ti', 'tr', 'id'];

  /// English → [fr, ar, uk, it, ti, tr, id]
  static const Map<String, List<String>> table = {
    // General
    'Listen': ['Écouter', 'استمع', 'Слухати', 'Ascolta', 'ስማዕ', 'Dinle', 'Dengarkan'],
    'Delete': ['Supprimer', 'حذف', 'Видалити', 'Elimina', 'ደምስስ', 'Sil', 'Hapus'],
    'Camera': ['Caméra', 'الكاميرا', 'Камера', 'Fotocamera', 'ካሜራ', 'Kamera', 'Kamera'],
    'Gallery': ['Galerie', 'المعرض', 'Галерея', 'Galleria', 'ጋለሪ', 'Galeri', 'Galeri'],
    'Check': ['Vérifier', 'تحقّق', 'Перевірити', 'Verifica', 'ኣረጋግጽ', 'Kontrol et', 'Periksa'],
    'Next': ['Suivant', 'التالي', 'Далі', 'Avanti', 'ቀጻሊ', 'İleri', 'Lanjut'],
    'Results': ['Résultats', 'النتائج', 'Результати', 'Risultati', 'ውጽኢት', 'Sonuçlar', 'Hasil'],
    'Start': ['Commencer', 'ابدأ', 'Почати', 'Inizia', 'ጀምር', 'Başla', 'Mulai'],
    'Start again': ['Recommencer', 'ابدأ من جديد', 'Почати знову', 'Ricomincia', 'እንደገና ጀምር', 'Yeniden başla', 'Mulai lagi'],
    'Level': ['Niveau', 'المستوى', 'Рівень', 'Livello', 'ደረጃ', 'Seviye', 'Tingkat'],
    'Level {n}': ['Niveau {n}', 'المستوى {n}', 'Рівень {n}', 'Livello {n}', 'ደረጃ {n}', 'Seviye {n}', 'Tingkat {n}'],
    'Easy': ['Facile', 'سهل', 'Легкий', 'Facile', 'ቀሊል', 'Kolay', 'Mudah'],
    'Medium': ['Moyen', 'متوسط', 'Середній', 'Medio', 'ማእከላይ', 'Orta', 'Sedang'],
    'Hard': ['Difficile', 'صعب', 'Складний', 'Difficile', 'ከቢድ', 'Zor', 'Sulit'],
    'Change level': ['Changer de niveau', 'غيّر المستوى', 'Змінити рівень', 'Cambia livello', 'ደረጃ ቀይር', 'Seviyeyi değiştir', 'Ganti tingkat'],
    'To review': ['À revoir', 'للمراجعة', 'Повторити', 'Da ripassare', 'ዝድገም', 'Tekrar edilecek', 'Perlu diulang'],
    'Play again': ['Rejouer', 'العب مجددًا', 'Грати знову', 'Gioca ancora', 'እንደገና ተጻወት', 'Tekrar oyna', 'Main lagi'],
    'Light': ['Clair', 'فاتح', 'Світла', 'Chiaro', 'ብሩህ', 'Açık', 'Terang'],
    'Dark': ['Sombre', 'داكن', 'Темна', 'Scuro', 'ጸልማት', 'Koyu', 'Gelap'],
    'Relaxed': ['Détente', 'مريح', 'Спокійно', 'Rilassato', 'ብዝሕል', 'Rahat', 'Santai'],
    'Regular': ['Régulier', 'منتظم', 'Регулярно', 'Regolare', 'ስሩዕ', 'Düzenli', 'Rutin'],
    'Intensive': ['Intensif', 'مكثّف', 'Інтенсивно', 'Intensivo', 'ብትግሃት', 'Yoğun', 'Intensif'],
    'Your daily goal?': ['Ton objectif chaque jour ?', 'ما هدفك اليومي؟', 'Твоя щоденна мета?', 'Il tuo obiettivo giornaliero?', 'ዕላማኻ መዓልታዊ?', 'Günlük hedefin?', 'Target harianmu?'],
    'Chapter {n}': ['Chapitre {n}', 'الفصل {n}', 'Розділ {n}', 'Capitolo {n}', 'ምዕራፍ {n}', 'Bölüm {n}', 'Bab {n}'],
    'Tap to flip': ['Touche pour retourner', 'المس لقلب البطاقة', 'Торкнися, щоб перевернути', 'Tocca per girare', 'ንምግልባጥ ጠውቕ', 'Çevirmek için dokun', 'Ketuk untuk membalik'],
    'Nothing to review today. Study new cards!': [
      'Rien à réviser aujourd\'hui. Étudie de nouvelles cartes !',
      'لا شيء للمراجعة اليوم. ادرس بطاقات جديدة!',
      'Сьогодні нічого повторювати. Вивчай нові картки!',
      'Niente da ripassare oggi. Studia nuove carte!',
      'ሎሚ ዝድገም የለን። ሓደስቲ ካርድታት ተማሃር!',
      'Bugün tekrar edilecek bir şey yok. Yeni kartlar çalış!',
      'Tidak ada yang perlu diulang hari ini. Pelajari kartu baru!',
    ],
    'Install on iPhone': ['Installer sur iPhone', 'التثبيت على iPhone', 'Встановити на iPhone', 'Installa su iPhone', 'ኣብ iPhone ኣእቱ', 'iPhone\'a yükle', 'Pasang di iPhone'],
    'IPHONE_STEPS': [
      '1. Touche le bouton « Partager » dans Safari.\n2. Choisis « Sur l\'écran d\'accueil ».\n3. Touche « Ajouter ».',
      '1. اضغط زر «مشاركة» في Safari.\n2. اختر «إضافة إلى الشاشة الرئيسية».\n3. اضغط «إضافة».',
      '1. Натисни кнопку «Поділитися» в Safari.\n2. Обери «На екран «Додому»».\n3. Натисни «Додати».',
      '1. Tocca il pulsante «Condividi» in Safari.\n2. Scegli «Aggiungi alla schermata Home».\n3. Tocca «Aggiungi».',
      '1. ኣብ Safari «Share» ዝብል መጠወቒ ጠውቕ።\n2. «Add to Home Screen» ምረጽ።\n3. «Add» ጠውቕ።',
      '1. Safari\'de «Paylaş» düğmesine dokun.\n2. «Ana Ekrana Ekle»yi seç.\n3. «Ekle»ye dokun.',
      '1. Ketuk tombol «Bagikan» di Safari.\n2. Pilih «Tambah ke Layar Utama».\n3. Ketuk «Tambah».',
    ],

    'Share': ['Partager', 'مشاركة', 'Поділитися', 'Condividi', 'ኣካፍል', 'Paylaş', 'Bagikan'],
    'Back': ['Retour', 'رجوع', 'Назад', 'Indietro', 'ተመለስ', 'Geri', 'Kembali'],

    // Lesson parts
    'This lesson has {n} parts. Open one at a time.': [
      'Cette leçon a {n} parties. Ouvre-les une par une.',
      'هذا الدرس فيه {n} أجزاء. افتحها واحدًا تلو الآخر.',
      'Цей урок має {n} частин. Відкривай їх по одній.',
      'Questa lezione ha {n} parti. Aprile una alla volta.',
      'እዚ ትምህርቲ {n} ክፍልታት ኣለዎ። ሓደ ብሓደ ክፈቶም።',
      'Bu dersin {n} bölümü var. Birer birer aç.',
      'Pelajaran ini punya {n} bagian. Buka satu per satu.',
    ],
    '{done} / {total} parts done': ['{done} / {total} parties faites', '{done} / {total} أجزاء مكتملة', '{done} / {total} частин пройдено', '{done} / {total} parti fatte', '{done} / {total} ክፍልታት ተወዲኦም', '{done} / {total} bölüm bitti', '{done} / {total} bagian selesai'],
    'Part {n} of {total}': ['Partie {n} sur {total}', 'الجزء {n} من {total}', 'Частина {n} з {total}', 'Parte {n} di {total}', 'ክፍሊ {n} ካብ {total}', 'Bölüm {n} / {total}', 'Bagian {n} dari {total}'],
    'Next part': ['Partie suivante', 'الجزء التالي', 'Наступна частина', 'Parte successiva', 'ዝቕጽል ክፍሊ', 'Sonraki bölüm', 'Bagian berikutnya'],
    'Previous part': ['Partie précédente', 'الجزء السابق', 'Попередня частина', 'Parte precedente', 'ዝሓለፈ ክፍሊ', 'Önceki bölüm', 'Bagian sebelumnya'],

    // Exercises
    'Exercises': ['Exercices', 'التمارين', 'Вправи', 'Esercizi', 'ልምምዳት', 'Alıştırmalar', 'Latihan'],
    'Could not create exercises. Please try again.': [
      'Impossible de créer les exercices. Réessaie.',
      'تعذّر إنشاء التمارين. حاول مرة أخرى.',
      'Не вдалося створити вправи. Спробуй ще раз.',
      'Impossibile creare gli esercizi. Riprova.',
      'ልምምዳት ክፍጠሩ ኣይከኣሉን። እንደገና ፈትን።',
      'Alıştırmalar oluşturulamadı. Tekrar dene.',
      'Tidak bisa membuat latihan. Coba lagi.',
    ],
    'This may take a few seconds': ['Cela peut prendre quelques secondes', 'قد يستغرق ذلك بضع ثوانٍ', 'Це може зайняти кілька секунд', 'Potrebbe richiedere qualche secondo', 'ቁሩብ ካልኢታት ክወስድ ይኽእል', 'Bu birkaç saniye sürebilir', 'Ini mungkin perlu beberapa detik'],
    'No exercises found for this topic.': ['Aucun exercice pour ce sujet.', 'لا توجد تمارين لهذا الموضوع.', 'Для цієї теми немає вправ.', 'Nessun esercizio per questo argomento.', 'ነዚ ኣርእስቲ ልምምድ የለን።', 'Bu konu için alıştırma yok.', 'Tidak ada latihan untuk topik ini.'],
    'Back to topics': ['Retour aux sujets', 'العودة إلى المواضيع', 'Назад до тем', 'Torna agli argomenti', 'ናብ ኣርእስታት ተመለስ', 'Konulara dön', 'Kembali ke topik'],
    'New questions': ['Nouvelles questions', 'أسئلة جديدة', 'Нові питання', 'Nuove domande', 'ሓደስቲ ሕቶታት', 'Yeni sorular', 'Pertanyaan baru'],
    'Review your mistakes ({n})': ['Revoir tes erreurs ({n})', 'راجع أخطاءك ({n})', 'Переглянь свої помилки ({n})', 'Rivedi i tuoi errori ({n})', 'ጌጋታትካ ርአ ({n})', 'Hatalarını gözden geçir ({n})', 'Tinjau kesalahanmu ({n})'],
    'Your answer': ['Ta réponse', 'إجابتك', 'Твоя відповідь', 'La tua risposta', 'መልስኻ', 'Cevabın', 'Jawabanmu'],
    'See a model answer': ['Voir un modèle de réponse', 'اعرض إجابة نموذجية', 'Показати зразок відповіді', 'Vedi una risposta modello', 'ኣብነታዊ መልሲ ርአ', 'Örnek cevabı gör', 'Lihat contoh jawaban'],

    // Flashcards
    'Could not create flashcards. Please try again.': [
      'Impossible de créer les cartes. Réessaie.',
      'تعذّر إنشاء البطاقات. حاول مرة أخرى.',
      'Не вдалося створити картки. Спробуй ще раз.',
      'Impossibile creare le carte. Riprova.',
      'ካርድታት ክፍጠሩ ኣይከኣሉን። እንደገና ፈትን።',
      'Kartlar oluşturulamadı. Tekrar dene.',
      'Tidak bisa membuat kartu. Coba lagi.',
    ],
    '{decks} decks · {cards} cards': ['{decks} paquets · {cards} cartes', '{decks} مجموعات · {cards} بطاقة', '{decks} колод · {cards} карток', '{decks} mazzi · {cards} carte', '{decks} ጥቕላላት · {cards} ካርድታት', '{decks} deste · {cards} kart', '{decks} dek · {cards} kartu'],
    '{n} cards from this lesson': ['{n} cartes de cette leçon', '{n} بطاقة من هذا الدرس', '{n} карток з цього уроку', '{n} carte da questa lezione', '{n} ካርድታት ካብዚ ትምህርቲ', 'Bu dersten {n} kart', '{n} kartu dari pelajaran ini'],
    'Shuffle': ['Mélanger', 'خلط', 'Перемішати', 'Mescola', 'ሕወስ', 'Karıştır', 'Acak'],
    'I knew it': ['Je savais', 'كنت أعرفها', 'Я знав(-ла)', 'Lo sapevo', 'ፈሊጠዮ ነይረ', 'Biliyordum', 'Aku tahu'],
    'Show answer': ['Voir la réponse', 'أظهر الإجابة', 'Показати відповідь', 'Mostra la risposta', 'መልሲ ኣርኢ', 'Cevabı göster', 'Tampilkan jawaban'],
    '{known} of {total} known': ['{known} sur {total} connues', '{known} من {total} معروفة', '{known} з {total} відомо', '{known} su {total} conosciute', '{known} ካብ {total} ዝፍለጡ', '{total} karttan {known} biliniyor', '{known} dari {total} dikuasai'],
    '{n} to review': ['{n} à revoir', '{n} للمراجعة', '{n} повторити', '{n} da ripassare', '{n} ዝድገሙ', '{n} tekrar edilecek', '{n} perlu diulang'],
    'Review the {n} cards I missed': ['Revoir les {n} cartes ratées', 'راجع البطاقات الـ {n} التي أخطأت فيها', 'Повторити {n} пропущених карток', 'Ripassa le {n} carte sbagliate', 'ነተን {n} ዝሰሓትኩወን ካርድታት ድገም', 'Bilemediğim {n} kartı tekrar et', 'Ulangi {n} kartu yang salah'],
    'New cards for this topic': ['Nouvelles cartes pour ce sujet', 'بطاقات جديدة لهذا الموضوع', 'Нові картки для цієї теми', 'Nuove carte per questo argomento', 'ሓደስቲ ካርድታት ነዚ ኣርእስቲ', 'Bu konu için yeni kartlar', 'Kartu baru untuk topik ini'],
    'Next {n} cards ({left} left)': ['{n} cartes suivantes (encore {left})', 'البطاقات الـ {n} التالية (بقي {left})', 'Наступні {n} карток (залишилось {left})', 'Prossime {n} carte (ne restano {left})', 'ዝቕጽላ {n} ካርድታት ({left} ተሪፈን)', 'Sonraki {n} kart ({left} kaldı)', '{n} kartu berikutnya ({left} tersisa)'],
    'Start again with all {n} cards': ['Recommencer avec les {n} cartes', 'ابدأ من جديد بجميع البطاقات الـ {n}', 'Почати знову з усіма {n} картками', 'Ricomincia con tutte le {n} carte', 'ብኹለን {n} ካርድታት እንደገና ጀምር', 'Tüm {n} kartla yeniden başla', 'Mulai lagi dengan semua {n} kartu'],

    // Conjugation
    'Conjugation': ['Conjugaison', 'التصريف', 'Відмінювання', 'Coniugazione', 'ምርባሕ ግሲ', 'Fiil çekimi', 'Konjugasi'],
    'Conjugation game': ['Jeu de conjugaison', 'لعبة التصريف', 'Гра з дієвідмінювання', 'Gioco di coniugazione', 'ጸወታ ምርባሕ ግሲ', 'Fiil çekimi oyunu', 'Permainan konjugasi'],
    'Play!': ['Jouer !', 'العب!', 'Грати!', 'Gioca!', 'ተጻወት!', 'Oyna!', 'Main!'],
    'Almost! Watch the accents.': ['Presque ! Attention aux accents.', 'تقريبًا! انتبه إلى العلامات (accents).', 'Майже! Зверни увагу на акценти.', 'Quasi! Attenzione agli accenti.', 'ቀሪብካ! ንኣክሰንት ተጠንቀቕ።', 'Neredeyse! Aksanlara dikkat.', 'Hampir! Perhatikan aksennya.'],
    'New record!': ['Nouveau record !', 'رقم قياسي جديد!', 'Новий рекорд!', 'Nuovo record!', 'ሓድሽ ሪኮርድ!', 'Yeni rekor!', 'Rekor baru!'],
    'Record: {n}': ['Record : {n}', 'الرقم القياسي: {n}', 'Рекорд: {n}', 'Record: {n}', 'ሪኮርድ: {n}', 'Rekor: {n}', 'Rekor: {n}'],
    'Any French verb: prendre, se lever, envoyer…': ['N\'importe quel verbe : prendre, se lever, envoyer…', 'أي فعل فرنسي: prendre، se lever، envoyer…', 'Будь-яке французьке дієслово: prendre, se lever, envoyer…', 'Qualsiasi verbo francese: prendre, se lever, envoyer…', 'ዝኾነ ፈረንሳዊ ግሲ: prendre, se lever, envoyer…', 'Herhangi bir Fransızca fiil: prendre, se lever, envoyer…', 'Kata kerja Prancis apa saja: prendre, se lever, envoyer…'],
    'NOT_A_VERB': [
      '« {verb} » n\'est pas un verbe français que je connais. Écris l\'infinitif, par ex. « prendre » ou « se lever ».',
      '«{verb}» ليس فعلًا فرنسيًا أعرفه. اكتب المصدر، مثل «prendre» أو «se lever».',
      '«{verb}» — я не знаю такого французького дієслова. Напиши інфінітив, напр. «prendre» або «se lever».',
      '«{verb}» non è un verbo francese che conosco. Scrivi l\'infinito, ad es. «prendre» o «se lever».',
      '«{verb}» ዝፈልጦ ፈረንሳዊ ግሲ ኣይኮነን። ኢንፊኒቲቭ ጽሓፍ፡ ንኣብነት «prendre» ወይ «se lever»።',
      '«{verb}» bildiğim bir Fransızca fiil değil. Mastar hâlini yaz, ör. «prendre» veya «se lever».',
      '«{verb}» bukan kata kerja Prancis yang aku kenal. Tulis bentuk infinitif, mis. «prendre» atau «se lever».',
    ],

    // Dictée
    'Dictation': ['Dictée', 'الإملاء', 'Диктант', 'Dettato', 'ዲክተ (ጽሑፍ ብምስማዕ)', 'Dikte', 'Dikte'],
    'Slowly': ['Lentement', 'ببطء', 'Повільно', 'Lentamente', 'ቀስ ኢሉ', 'Yavaşça', 'Pelan-pelan'],
    'Average: {n} %': ['Moyenne : {n} %', 'المعدّل: {n} %', 'Середнє: {n} %', 'Media: {n} %', 'ማእከላይ: {n} %', 'Ortalama: %{n}', 'Rata-rata: {n} %'],
    'Write the sentence here…': ['Écris la phrase ici…', 'اكتب الجملة هنا…', 'Напиши речення тут…', 'Scrivi la frase qui…', 'ነቲ ምሉእ ሓረግ ኣብዚ ጽሓፍ…', 'Cümleyi buraya yaz…', 'Tulis kalimatnya di sini…'],
    'Correct it': ['Corriger', 'صحّح', 'Перевірити', 'Correggi', 'ኣርም', 'Düzelt', 'Koreksi'],
    'Next sentence': ['Phrase suivante', 'الجملة التالية', 'Наступне речення', 'Frase successiva', 'ዝቕጽል ሓረግ', 'Sonraki cümle', 'Kalimat berikutnya'],
    'DICTEE_KEY': [
      '🟢 juste   🟡 accent   🔴 faux ou oublié',
      '🟢 صحيح   🟡 علامة (accent)   🔴 خطأ أو ناقص',
      '🟢 правильно   🟡 акцент   🔴 помилка або пропуск',
      '🟢 giusto   🟡 accento   🔴 sbagliato o mancante',
      '🟢 ቅኑዕ   🟡 ኣክሰንት   🔴 ጌጋ ወይ ዝተረስዐ',
      '🟢 doğru   🟡 aksan   🔴 yanlış veya eksik',
      '🟢 benar   🟡 aksen   🔴 salah atau terlewat',
    ],
    'success': ['de réussite', 'نجاح', 'успіху', 'di successo', 'ዓወት', 'başarı', 'berhasil'],
    'Another dictation': ['Encore une dictée', 'إملاء آخر', 'Ще один диктант', 'Un altro dettato', 'ካልእ ዲክተ', 'Bir dikte daha', 'Dikte lagi'],
    'up to 5 words': ['≤ 5 mots', 'حتى 5 كلمات', 'до 5 слів', 'fino a 5 parole', 'ክሳብ 5 ቃላት', 'en fazla 5 kelime', 'maks. 5 kata'],
    '6 – 9 words': ['6 – 9 mots', '6 – 9 كلمات', '6 – 9 слів', '6 – 9 parole', '6 – 9 ቃላት', '6 – 9 kelime', '6 – 9 kata'],
    '10+ words': ['10 mots et +', '10 كلمات أو أكثر', '10+ слів', '10+ parole', '10+ ቃላት', '10+ kelime', '10+ kata'],

    // Duel
    'Duel with friends': ['Duel entre amis', 'مبارزة مع الأصدقاء', 'Дуель з друзями', 'Sfida tra amici', 'ውድድር ምስ ኣዕሩኽ', 'Arkadaşlarla düello', 'Duel dengan teman'],
    'Invitation copied ✓': ['Invitation copiée ✓', 'تم نسخ الدعوة ✓', 'Запрошення скопійовано ✓', 'Invito copiato ✓', 'ዕድመ ተቐዲሑ ✓', 'Davet kopyalandı ✓', 'Undangan disalin ✓'],
    'Write your first name first.': ['Écris ton prénom d\'abord.', 'اكتب اسمك الأول أولًا.', 'Спочатку напиши своє ім\'я.', 'Prima scrivi il tuo nome.', 'መጀመርታ ሽምካ ጽሓፍ።', 'Önce adını yaz.', 'Tulis nama depanmu dulu.'],
    'The code has 6 letters or numbers.': ['Le code a 6 lettres ou chiffres.', 'الرمز يتكوّن من 6 أحرف أو أرقام.', 'Код має 6 літер або цифр.', 'Il codice ha 6 lettere o cifre.', 'እቲ ኮድ 6 ፊደላት ወይ ቁጽርታት ኣለዎ።', 'Kod 6 harf veya rakamdan oluşur.', 'Kodenya 6 huruf atau angka.'],
    'The duel server is not ready. Your score: {n}.': ['Le serveur des duels n\'est pas prêt. Ton score : {n}.', 'خادم المبارزات غير جاهز. نتيجتك: {n}.', 'Сервер дуелей не готовий. Твій результат: {n}.', 'Il server delle sfide non è pronto. Il tuo punteggio: {n}.', 'ሰርቨር ውድድር ድሉው ኣይኮነን። ነጥብኻ: {n}።', 'Düello sunucusu hazır değil. Puanın: {n}.', 'Server duel belum siap. Skormu: {n}.'],
    'Your first name': ['Ton prénom', 'اسمك الأول', 'Твоє ім\'я', 'Il tuo nome', 'ሽምካ', 'Adın', 'Nama depanmu'],
    'Create a duel': ['Créer un duel', 'أنشئ مبارزة', 'Створити дуель', 'Crea una sfida', 'ውድድር ፍጠር', 'Düello oluştur', 'Buat duel'],
    'I received a code': ['J\'ai reçu un code', 'وصلني رمز', 'Я отримав(-ла) код', 'Ho ricevuto un codice', 'ኮድ ተቐቢለ', 'Bir kod aldım', 'Aku menerima kode'],
    'Join': ['Rejoindre', 'انضم', 'Приєднатися', 'Partecipa', 'ተሓወስ', 'Katıl', 'Gabung'],
    'Copy the invitation': ['Copier l\'invitation', 'انسخ الدعوة', 'Скопіювати запрошення', 'Copia l\'invito', 'ዕድመ ቕዳሕ', 'Daveti kopyala', 'Salin undangan'],
    'Ranking': ['Classement', 'الترتيب', 'Рейтинг', 'Classifica', 'ደረጃ ተወዳደርቲ', 'Sıralama', 'Peringkat'],
    'You are #{rank} of {total}': ['Tu es n° {rank} sur {total}', 'أنت في المركز {rank} من {total}', 'Ти №{rank} з {total}', 'Sei n° {rank} su {total}', 'ቁጽሪ {rank} ካብ {total} ኢኻ', '{total} kişi içinde {rank}. sıradasın', 'Kamu #{rank} dari {total}'],
    'What should the duel cover?': ['Sur quoi porte le duel ?', 'ما مواضيع المبارزة؟', 'Що буде в дуелі?', 'Su cosa sarà la sfida?', 'ውድድር ብዛዕባ እንታይ ይኸውን?', 'Düello hangi konularda olsun?', 'Duel ini tentang apa?'],
    'All topics': ['Tous les sujets', 'كل المواضيع', 'Усі теми', 'Tutti gli argomenti', 'ኩሎም ኣርእስታት', 'Tüm konular', 'Semua topik'],
    'Grammar': ['Grammaire', 'القواعد', 'Граматика', 'Grammatica', 'ሰዋሰው', 'Dil bilgisi', 'Tata bahasa'],
    'How many questions?': ['Combien de questions ?', 'كم عدد الأسئلة؟', 'Скільки питань?', 'Quante domande?', 'ክንደይ ሕቶታት?', 'Kaç soru?', 'Berapa pertanyaan?'],
    'From easy to hard.': ['Du plus facile au plus difficile.', 'من السهل إلى الصعب.', 'Від легкого до складного.', 'Dalla più facile alla più difficile.', 'ካብ ቀሊል ናብ ከቢድ።', 'Kolaydan zora.', 'Dari mudah ke sulit.'],
    'Choose at least one topic.': ['Choisis au moins un sujet.', 'اختر موضوعًا واحدًا على الأقل.', 'Обери хоча б одну тему.', 'Scegli almeno un argomento.', 'እንተወሓደ ሓደ ኣርእስቲ ምረጽ።', 'En az bir konu seç.', 'Pilih minimal satu topik.'],
    'Create the duel': ['Créer le duel', 'أنشئ المبارزة', 'Створити дуель', 'Crea la sfida', 'ውድድር ፍጠር', 'Düelloyu oluştur', 'Buat duelnya'],
    'Preparing the questions…': ['Préparation des questions…', 'جارٍ تحضير الأسئلة…', 'Готуємо питання…', 'Preparo le domande…', 'ሕቶታት ይዳለዉ ኣለዉ…', 'Sorular hazırlanıyor…', 'Menyiapkan pertanyaan…'],
    'Loading the duel…': ['Chargement du duel…', 'جارٍ تحميل المبارزة…', 'Завантаження дуелі…', 'Caricamento della sfida…', 'ውድድር ይጽዕን ኣሎ…', 'Düello yükleniyor…', 'Memuat duel…'],
    '{n} questions': ['{n} questions', '{n} أسئلة', '{n} питань', '{n} domande', '{n} ሕቶታት', '{n} soru', '{n} pertanyaan'],
    'Could not prepare the questions. Try again.': ['Impossible de préparer les questions. Réessaie.', 'تعذّر تحضير الأسئلة. حاول مرة أخرى.', 'Не вдалося підготувати питання. Спробуй ще раз.', 'Impossibile preparare le domande. Riprova.', 'ሕቶታት ክዳለዉ ኣይከኣሉን። እንደገና ፈትን።', 'Sorular hazırlanamadı. Tekrar dene.', 'Tidak bisa menyiapkan pertanyaan. Coba lagi.'],
    'The class duel server is not ready yet.': ['Le serveur des duels de classe n\'est pas encore prêt.', 'خادم مبارزات الصف غير جاهز بعد.', 'Сервер класних дуелей ще не готовий.', 'Il server delle sfide di classe non è ancora pronto.', 'ሰርቨር ውድድር ክፍሊ ገና ድሉው ኣይኮነን።', 'Sınıf düellosu sunucusu henüz hazır değil.', 'Server duel kelas belum siap.'],
    'New duel': ['Nouveau duel', 'مبارزة جديدة', 'Нова дуель', 'Nuova sfida', 'ሓድሽ ውድድር', 'Yeni düello', 'Duel baru'],

    // Missions, mistakes
    'Missions of the week': ['Missions de la semaine', 'مهام الأسبوع', 'Місії тижня', 'Missioni della settimana', 'ዕማማት ናይዚ ሰሙን', 'Haftanın görevleri', 'Misi minggu ini'],
    'My mistakes': ['Mes erreurs', 'أخطائي', 'Мої помилки', 'I miei errori', 'ጌጋታተይ', 'Hatalarım', 'Kesalahanku'],
    'No mistakes yet!': ['Aucune erreur pour le moment !', 'لا أخطاء حتى الآن!', 'Поки що немає помилок!', 'Ancora nessun errore!', 'ክሳብ ሕጂ ጌጋ የለን!', 'Henüz hata yok!', 'Belum ada kesalahan!'],
    'Fix my mistakes ({n})': ['Corriger mes erreurs ({n})', 'صحّح أخطائي ({n})', 'Виправити мої помилки ({n})', 'Correggi i miei errori ({n})', 'ጌጋታተይ ኣርም ({n})', 'Hatalarımı düzelt ({n})', 'Perbaiki kesalahanku ({n})'],
    'Fix my mistakes': ['Corriger mes erreurs', 'صحّح أخطائي', 'Виправити мої помилки', 'Correggi i miei errori', 'ጌጋታተይ ኣርም', 'Hatalarımı düzelt', 'Perbaiki kesalahanku'],
    'New exercises on my weak points': ['Nouveaux exercices sur mes points faibles', 'تمارين جديدة على نقاط ضعفي', 'Нові вправи на мої слабкі місця', 'Nuovi esercizi sui miei punti deboli', 'ሓደስቲ ልምምዳት ኣብ ድኹም ጎነይ', 'Zayıf noktalarım için yeni alıştırmalar', 'Latihan baru untuk titik lemahku'],
    'I know it now': ['Je le sais maintenant', 'أعرفها الآن', 'Тепер я це знаю', 'Ora lo so', 'ሕጂ ፈሊጠዮ', 'Artık biliyorum', 'Sekarang aku tahu'],
    'My weak points': ['Mes points faibles', 'نقاط ضعفي', 'Мої слабкі місця', 'I miei punti deboli', 'ድኹም ጎነይ', 'Zayıf noktalarım', 'Titik lemahku'],

    // Role-play
    'Role-play': ['Jeu de rôle', 'لعب الأدوار', 'Рольова гра', 'Gioco di ruolo', 'ጸወታ ተራ', 'Rol yapma', 'Bermain peran'],
    'Connection lost. Try again.': ['Connexion perdue. Réessaie.', 'انقطع الاتصال. حاول مرة أخرى.', 'Зв\'язок втрачено. Спробуй ще раз.', 'Connessione persa. Riprova.', 'ርክብ ተቋሪጹ። እንደገና ፈትን።', 'Bağlantı koptu. Tekrar dene.', 'Koneksi terputus. Coba lagi.'],
    'Finish': ['Terminer', 'إنهاء', 'Завершити', 'Termina', 'ዛዝም', 'Bitir', 'Selesai'],
    'See my evaluation': ['Voir mon évaluation', 'اعرض تقييمي', 'Переглянути мою оцінку', 'Vedi la mia valutazione', 'ገምጋመይ ርአ', 'Değerlendirmemi gör', 'Lihat penilaianku'],
    'Use': ['Utiliser', 'استخدم', 'Використати', 'Usa', 'ተጠቐም', 'Kullan', 'Pakai'],
    'An idea?': ['Une idée ?', 'فكرة؟', 'Ідея?', 'Un\'idea?', 'ሓሳብ?', 'Bir fikir?', 'Ada ide?'],
    'Stop': ['Arrêter', 'إيقاف', 'Зупинити', 'Ferma', 'ደው ኣብል', 'Durdur', 'Berhenti'],
    'Speak': ['Parler', 'تحدّث', 'Говорити', 'Parla', 'ተዛረብ', 'Konuş', 'Bicara'],
    'Answer in French…': ['Réponds en français…', 'أجب بالفرنسية…', 'Відповідай французькою…', 'Rispondi in francese…', 'ብፈረንሳይኛ መልስ…', 'Fransızca cevap ver…', 'Jawab dalam bahasa Prancis…'],
    "I'm listening… speak French": ['Je t\'écoute… parle en français', 'أنا أستمع… تحدّث بالفرنسية', 'Я слухаю… говори французькою', 'Ti ascolto… parla in francese', 'እሰምዓካ ኣለኹ… ብፈረንሳይኛ ተዛረብ', 'Dinliyorum… Fransızca konuş', 'Aku mendengarkan… bicaralah bahasa Prancis'],
    'Allow the microphone in your browser to speak.': ['Autorise le micro dans ton navigateur pour parler.', 'اسمح باستخدام الميكروفون في متصفحك لتتحدّث.', 'Дозволь мікрофон у браузері, щоб говорити.', 'Consenti il microfono nel browser per parlare.', 'ንምዝራብ ኣብ ብራውዘርካ ማይክሮፎን ፍቐድ።', 'Konuşmak için tarayıcında mikrofona izin ver.', 'Izinkan mikrofon di browser untuk bicara.'],
    'I did not hear anything. Tap the microphone and speak.': ['Je n\'ai rien entendu. Touche le micro et parle.', 'لم أسمع شيئًا. اضغط على الميكروفون وتحدّث.', 'Я нічого не почув. Натисни мікрофон і говори.', 'Non ho sentito niente. Tocca il microfono e parla.', 'ዋላ ሓንቲ ኣይሰማዕኩን። ማይክሮፎን ጠውቕ እሞ ተዛረብ።', 'Hiçbir şey duymadım. Mikrofona dokun ve konuş.', 'Aku tidak mendengar apa pun. Ketuk mikrofon lalu bicara.'],
    'The microphone did not work. Try again or type.': ['Le micro n\'a pas marché. Réessaie ou écris.', 'لم يعمل الميكروفون. حاول مرة أخرى أو اكتب.', 'Мікрофон не спрацював. Спробуй ще раз або напиши.', 'Il microfono non ha funzionato. Riprova o scrivi.', 'ማይክሮፎን ኣይሰርሐን። እንደገና ፈትን ወይ ጽሓፍ።', 'Mikrofon çalışmadı. Tekrar dene veya yaz.', 'Mikrofon tidak berfungsi. Coba lagi atau ketik.'],
    'Evaluation not possible right now.': ['Évaluation impossible pour le moment.', 'التقييم غير ممكن الآن.', 'Оцінювання зараз неможливе.', 'Valutazione non possibile al momento.', 'ሕጂ ገምጋም ኣይከኣልን።', 'Şu anda değerlendirme yapılamıyor.', 'Penilaian belum bisa dilakukan sekarang.'],

    // Words
    'Photo → words': ['Photo → mots', 'صورة ← كلمات', 'Фото → слова', 'Foto → parole', 'ስእሊ → ቃላት', 'Fotoğraf → kelimeler', 'Foto → kata'],
    'My words': ['Mes mots', 'كلماتي', 'Мої слова', 'Le mie parole', 'ቃላተይ', 'Kelimelerim', 'Kataku'],
    'Words found': ['Mots trouvés', 'الكلمات التي وُجدت', 'Знайдені слова', 'Parole trovate', 'ዝተረኽቡ ቃላት', 'Bulunan kelimeler', 'Kata yang ditemukan'],
    'Save {n} words': ['Enregistrer {n} mots', 'احفظ {n} كلمة', 'Зберегти {n} слів', 'Salva {n} parole', '{n} ቃላት ዓቕብ', '{n} kelimeyi kaydet', 'Simpan {n} kata'],
    'SAVED_WORDS': [
      '{n} mots ajoutés à « Mes mots » et à tes révisions ✓',
      'أُضيفت {n} كلمة إلى «كلماتي» وإلى مراجعاتك ✓',
      '{n} слів додано до «Мої слова» і до повторень ✓',
      '{n} parole aggiunte a «Le mie parole» e ai ripassi ✓',
      '{n} ቃላት ናብ «ቃላተይ» ከምኡ’ውን ናብ ድግግምካ ተወሲኾም ✓',
      '{n} kelime «Kelimelerim»e ve tekrarlarına eklendi ✓',
      '{n} kata ditambahkan ke «Kataku» dan ke ulanganmu ✓',
    ],
    '{c} themes · {w} words and expressions': ['{c} thèmes · {w} mots et expressions', '{c} مواضيع · {w} كلمة وتعبير', '{c} тем · {w} слів і виразів', '{c} temi · {w} parole ed espressioni', '{c} ኣርእስታት · {w} ቃላትን ኣገላልጻታትን', '{c} tema · {w} kelime ve ifade', '{c} tema · {w} kata dan ungkapan'],
    'Search in French or English…': ['Cherche en français ou en anglais…', 'ابحث بالفرنسية أو الإنجليزية…', 'Шукай французькою або англійською…', 'Cerca in francese o in inglese…', 'ብፈረንሳይኛ ወይ እንግሊዝኛ ድለ…', 'Fransızca veya İngilizce ara…', 'Cari dalam bahasa Prancis atau Inggris…'],
    'No word found.': ['Aucun mot trouvé.', 'لم يتم العثور على أي كلمة.', 'Слів не знайдено.', 'Nessuna parola trovata.', 'ቃል ኣይተረኽበን።', 'Kelime bulunamadı.', 'Kata tidak ditemukan.'],
    'Blue = masculine, pink = feminine': ['Bleu = masculin, rose = féminin', 'الأزرق = مذكّر، الوردي = مؤنّث', 'Синій = чоловічий рід, рожевий = жіночий', 'Blu = maschile, rosa = femminile', 'ሰማያዊ = ተባዕታይ፡ ሮዛ = ኣንስታይ', 'Mavi = eril, pembe = dişil', 'Biru = maskulin, merah muda = feminin'],
    'informal (street language)': ['familier (langue de la rue)', 'عامّي (لغة الشارع)', 'розмовне (вулична мова)', 'informale (lingua di strada)', 'ዘይስሩዕ (ቋንቋ ጎደና)', 'gündelik (sokak dili)', 'informal (bahasa jalanan)'],
    'standard': ['courant', 'شائع', 'загальновживане', 'comune', 'ልሙድ', 'standart', 'umum'],

    // Ask AI, photo sheet
    'Maximum 10 images allowed per lesson.': ['10 images maximum par leçon.', 'الحد الأقصى 10 صور لكل درس.', 'Максимум 10 зображень на урок.', 'Massimo 10 immagini per lezione.', 'ኣብ ሓደ ትምህርቲ ልዕሊ 10 ስእልታት ኣይፍቀድን።', 'Ders başına en fazla 10 resim.', 'Maksimal 10 gambar per pelajaran.'],
    'Take a photo': ['Prendre une photo', 'التقط صورة', 'Зробити фото', 'Scatta una foto', 'ስእሊ ልዓል', 'Fotoğraf çek', 'Ambil foto'],
    'Choose from gallery': ['Choisir dans la galerie', 'اختر من المعرض', 'Вибрати з галереї', 'Scegli dalla galleria', 'ካብ ጋለሪ ምረጽ', 'Galeriden seç', 'Pilih dari galeri'],
    'Ask me anything…': ['Pose-moi une question…', 'اسألني أي شيء…', 'Запитай мене про будь-що…', 'Chiedimi qualsiasi cosa…', 'ዝኾነ ሕተተኒ…', 'Bana her şeyi sor…', 'Tanya aku apa saja…'],
    'No pages yet': ['Pas encore de pages', 'لا توجد صفحات بعد', 'Ще немає сторінок', 'Ancora nessuna pagina', 'ክሳብ ሕጂ ገጽ የለን', 'Henüz sayfa yok', 'Belum ada halaman'],
    'Too large to send at once. Remove a page or split it into two imports.': [
      'Trop lourd pour un seul envoi. Retire une page ou fais deux imports.',
      'الحجم كبير جدًا للإرسال دفعة واحدة. احذف صفحة أو قسّمها إلى استيرادين.',
      'Завелико для одного надсилання. Видали сторінку або розділи на два імпорти.',
      'Troppo grande per un solo invio. Togli una pagina o dividi in due importazioni.',
      'ብሓንሳብ ንምልኣኽ ዓቢ እዩ። ሓደ ገጽ ኣውጽእ ወይ ኣብ ክልተ ምቕራብ ምቀሎ።',
      'Tek seferde göndermek için çok büyük. Bir sayfa çıkar veya iki parçaya böl.',
      'Terlalu besar untuk dikirim sekaligus. Hapus satu halaman atau bagi jadi dua impor.',
    ],
    'Optional instructions (e.g. "only exercise 3 and 4")': [
      'Consignes facultatives (ex. « seulement les exercices 3 et 4 »)',
      'تعليمات اختيارية (مثل: «التمرينان 3 و4 فقط»)',
      'Додаткові вказівки (напр. «лише вправи 3 і 4»)',
      'Istruzioni facoltative (es. «solo esercizi 3 e 4»)',
      'ኣማራጺ መምርሒ (ንኣብነት «ልምምድ 3ን 4ን ጥራይ»)',
      'İsteğe bağlı talimat (ör. «sadece 3. ve 4. alıştırma»)',
      'Instruksi opsional (mis. «hanya latihan 3 dan 4»)',
    ],
  };

  /// [en] in language [code], with {placeholders} filled from [args].
  static String get(String code, String en, [Map<String, Object?> args = const {}]) {
    final i = languages.indexOf(code);
    final row = table[en];
    var text = i >= 0 && row != null ? row[i] : (_english[en] ?? en);
    args.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
    return text;
  }

  /// English text for the entries whose key is an ID rather than the English sentence.
  static const _english = {
    'IPHONE_STEPS': '1. Tap the "Share" button in Safari.\n2. Choose "Add to Home Screen".\n3. Tap "Add".',
    'NOT_A_VERB': '« {verb} » is not a French verb I know. Type the infinitive, e.g. « prendre » or « se lever ».',
    'DICTEE_KEY': '🟢 right   🟡 accent   🔴 wrong or missing',
    'SAVED_WORDS': '{n} words added to « My words » and to your reviews ✓',
  };

  /// French level names used as data ('Facile', 'Moyen', 'Difficile') → interface text.
  static String level(BuildContext context, String frenchLevel) =>
      tr(context, switch (frenchLevel) { 'Facile' => 'Easy', 'Moyen' => 'Medium', _ => 'Hard' });
}

/// Interface text in the learner's language. Screens rebuild when the language changes.
String tr(BuildContext context, String en, [Map<String, Object?> args = const {}]) {
  var code = 'en';
  try {
    code = Provider.of<LanguageProvider>(context, listen: false).currentLanguage.code;
  } on ProviderNotFoundException {
    // Outside the app (tests, previews): English.
  }
  return UiStrings.get(code, en, args);
}
