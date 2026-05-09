import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';
import '../../services/deepseek_service.dart';

class DailyPhrasesPage extends StatefulWidget {
  const DailyPhrasesPage({super.key});

  @override
  State<DailyPhrasesPage> createState() => _DailyPhrasesPageState();
}

class _DailyPhrasesPageState extends State<DailyPhrasesPage> {
  final TtsService _ttsService = TtsService();
  String? _currentlyPlayingId;
  final Set<String> _visibleTranslations = {};
  final Map<String, String> _dynamicTranslations = {};
  bool _isTranslating = false;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Salutations & Politesse',
      'arabicTitle': 'التحيات واللطافة',
      'icon': '👋',
      'phrases': [
        {'fr': 'Bonjour, comment allez-vous ?', 'ar': 'صباح الخير، كيف حالكم؟'},
        {
          'fr': 'Je vais bien, merci. Et vous ?',
          'ar': 'أنا بخير، شكراً. وأنت؟'
        },
        {'fr': 'Enchanté de vous rencontrer.', 'ar': 'سعدت بلقائك.'},
        {
          'fr': 'S\'il vous plaît / S\'il te plaît',
          'ar': 'من فضلك (للمحترم / للعادي)'
        },
        {'fr': 'Merci beaucoup / De rien', 'ar': 'شكراً جزيلاً / عفواً'},
        {'fr': 'Excusez-moi, je suis désolé.', 'ar': 'اعذرني، أنا آسف.'},
        {'fr': 'Bonne journée / Bonne soirée', 'ar': 'طاب يومك / طابت ليلتك'},
        {'fr': 'Comment ça va aujourd\'hui ?', 'ar': 'كيف تسير الأمور اليوم؟'},
        {
          'fr': 'Ça va très bien, merci de demander.',
          'ar': 'الأمور تسير بشكل جيد جداً، شكراً للسؤال.'
        },
        {
          'fr': 'Je vous souhaite une excellente journée.',
          'ar': 'أتمنى لكم يوماً ممتازاً.'
        },
        {'fr': 'Ravi(e) de vous revoir !', 'ar': 'سعيد برؤيتك مرة أخرى!'},
        {'fr': 'Comment se passe ta semaine ?', 'ar': 'كيف يسير أسبوعك؟'},
        {'fr': 'Passe le bonjour à ta famille.', 'ar': 'سلم على عائلتك.'},
        {'fr': 'Je vous en prie.', 'ar': 'على الرحب والسعة (للمحترم)'},
        {'fr': 'À plus tard !', 'ar': 'أراك لاحقاً.'},
        {'fr': 'À la prochaine !', 'ar': 'إلى المرة القادمة.'},
        {'fr': 'Félicitations pour ton succès !', 'ar': 'مبروك على نجاحك!'},
        {'fr': 'Bon courage pour ton examen.', 'ar': 'بالتوفيق في امتحانك.'},
        {'fr': 'Je m\'excuse pour le retard.', 'ar': 'أعتذر عن التأخير.'},
        {'fr': 'Avec plaisir !', 'ar': 'بكل سرور.'},
      ]
    },
    {
      'title': 'À la Boulangerie / Au Café',
      'arabicTitle': 'في المخبز / المقهى',
      'icon': '🥐',
      'phrases': [
        {
          'fr': 'Je voudrais une baguette, s\'il vous plaît.',
          'ar': 'أود خبز باجيت، من فضلك.'
        },
        {
          'fr': 'Est-ce que vous avez des croissants ?',
          'ar': 'هل لديكم كرواسان؟'
        },
        {
          'fr': 'Un café noir et un thé, s\'il vous plaît.',
          'ar': 'قهوة سوداء وشاي، من فضلك.'
        },
        {'fr': 'C\'est combien, s\'il vous plaît ?', 'ar': 'كم السعر من فضلك؟'},
        {'fr': 'Je vais prendre ça.', 'ar': 'سآخذ هذا.'},
        {'fr': 'Gardez la monnaie.', 'ar': 'احتفظ بالباقي.'},
        {
          'fr': 'Je voudrais aussi deux pains au chocolat.',
          'ar': 'أود أيضاً قطعتي "بان أو شوكولا".'
        },
        {'fr': 'Est-ce que le pain est frais ?', 'ar': 'هل الخبز طازج؟'},
        {
          'fr': 'Je vais prendre une part de tarte aux pommes.',
          'ar': 'سآخذ قطعة من فطيرة التفاح.'
        },
        {'fr': 'Chaud ou froid ?', 'ar': 'ساخن أم بارد؟'},
        {'fr': 'Sans sucre, s\'il vous plaît.', 'ar': 'بدون سكر، من فضلك.'},
        {
          'fr': 'Avec un peu de lait, s\'il vous plaît.',
          'ar': 'مع القليل من الحليب، من فضلك.'
        },
        {
          'fr': 'Est-ce que je peux avoir un verre d\'eau ?',
          'ar': 'هل يمكنني الحصول على كوب ماء؟'
        },
        {
          'fr': 'C\'est pour consommer sur place ou à emporter ?',
          'ar': 'هل للأكل هنا أم للطلبات الخارجية؟'
        },
        {'fr': 'C\'est à emporter, merci.', 'ar': 'للطلبات الخارجية، شكراً.'},
        {
          'fr': 'Est-ce que vous faites des sandwichs ?',
          'ar': 'هل تصنعون السندويشات؟'
        },
        {'fr': 'Quel est le plat du jour ?', 'ar': 'ما هو طبق اليوم؟'},
        {'fr': 'L\'addition, s\'il vous plaît.', 'ar': 'الحساب، من فضلك.'},
        {
          'fr': 'Je peux payer avec mon téléphone ?',
          'ar': 'هل يمكنني الدفع بهاتفي؟'
        },
        {'fr': 'C\'était délicieux, merci !', 'ar': 'كان لذيذاً، شكراً!'},
      ]
    },
    {
      'title': 'Au Supermarché',
      'arabicTitle': 'في السوبر ماركت',
      'icon': '🛒',
      'phrases': [
        {
          'fr': 'Où se trouve le rayon des boissons ?',
          'ar': 'أين يوجد قسم المشروبات؟'
        },
        {'fr': 'Je cherche du lait et des œufs.', 'ar': 'أبحث عن حليب وبيض.'},
        {
          'fr': 'Avez-vous un sac, s\'il vous plaît ?',
          'ar': 'هل لديكم حقيبة، من فضلك؟'
        },
        {'fr': 'Je peux payer par carte ?', 'ar': 'هل يمكنني الدفع بالبطاقة؟'},
        {'fr': 'Où est la caisse ?', 'ar': 'أين الخزينة (الكاشير)؟'},
        {
          'fr': 'Où puis-je trouver les produits frais ?',
          'ar': 'أين يمكنني العثور على المنتجات الطازجة؟'
        },
        {
          'fr': 'Est-ce que ce produit est en promotion ?',
          'ar': 'هل هذا المنتج في العرض/التخفيض؟'
        },
        {
          'fr': 'Je cherche le rayon de la boulangerie.',
          'ar': 'أبحث عن قسم المخبوزات.'
        },
        {
          'fr': 'Avez-vous du pain sans gluten ?',
          'ar': 'هل لديكم خبز خالي من الغلوتين؟'
        },
        {
          'fr': 'Il me faut un chariot, où sont-ils ?',
          'ar': 'أحتاج إلى عربة تسوق، أين هي؟'
        },
        {
          'fr': 'Avez-vous des sacs réutilisables ?',
          'ar': 'هل لديكم حقائب قابلة لإعادة الاستخدام؟'
        },
        {
          'fr': 'Quel est le prix de ce kilo de pommes ?',
          'ar': 'ما هو سعر كيلو التفاح هذا؟'
        },
        {
          'fr': 'Je voudrais 200 grammes de jambon.',
          'ar': 'أود 200 جرام من المرتديلا.'
        },
        {'fr': 'Où sont les bouteilles d\'eau ?', 'ar': 'أين زجاجات المياه؟'},
        {'fr': 'C\'est trop cher pour moi.', 'ar': 'هذا غالٍ جداً بالنسبة لي.'},
        {
          'fr': 'Pouvez-vous me montrer où est le riz ?',
          'ar': 'هل يمكنك إظهار مكان الأرز لي؟'
        },
        {
          'fr': 'Est-ce que le magasin est ouvert le dimanche ?',
          'ar': 'هل المتجر يفتح يوم الأحد؟'
        },
        {
          'fr': 'Je voudrais une facture, s\'il vous plaît.',
          'ar': 'أود الحصول على فاتورة، من فضلك.'
        },
        {
          'fr': 'Il y a une erreur sur mon ticket de caisse.',
          'ar': 'هناك خطأ في وصل الاستلام الخاص بي.'
        },
        {
          'fr': 'À quelle heure ferme le magasin ?',
          'ar': 'في أي ساعة يغلق المتجر؟'
        },
      ]
    },
    {
      'title': 'Demander son Chemin',
      'arabicTitle': 'السؤال عن الطريق',
      'icon': '📍',
      'phrases': [
        {'fr': 'Excusez-moi, où est la gare ?', 'ar': 'عذراً، أين المحطة؟'},
        {'fr': 'C\'est loin d\'ici ?', 'ar': 'هل هو بعيد من هنا؟'},
        {
          'fr': 'Allez tout droit et tournez à gauche.',
          'ar': 'اذهب مباشرة ثم اتجه يساراً.'
        },
        {'fr': 'C\'est à côté du musée.', 'ar': 'إنه بجانب المتحف.'},
        {'fr': 'Je suis perdu(e), aidez-moi.', 'ar': 'أنا تائه، ساعدني.'},
        {
          'fr': 'Pouvez-vous me montrer sur la carte ?',
          'ar': 'هل يمكنك إرشادي على الخريطة؟'
        },
        {
          'fr': 'Quel bus dois-je prendre pour aller au centre-ville ?',
          'ar': 'أي حافلة يجب أن أركب للذهاب إلى وسط المدينة؟'
        },
        {
          'fr': 'C\'est à environ dix minutes à pied.',
          'ar': 'إنه على بعد حوالي عشر دقائق مشياً.'
        },
        {
          'fr': 'Traversez la rue et continuez tout droit.',
          'ar': 'اعبر الشارع واستمر مباشرة.'
        },
        {
          'fr': 'C\'est juste après le feu rouge.',
          'ar': 'إنه مباشرة بعد الإشارة الضوئية.'
        },
        {
          'fr': 'Vous vous êtes trompé de direction.',
          'ar': 'لقد أخطأت في الاتجاه.'
        },
        {
          'fr': 'Est-ce qu\'il y a une banque près d\'ici ?',
          'ar': 'هل يوجد بنك بالقرب من هنا؟'
        },
        {
          'fr': 'Prenez la deuxième rue à droite.',
          'ar': 'خذ الشارع الثاني على اليمين.'
        },
        {
          'fr': 'Je cherche l\'office de tourisme.',
          'ar': 'أبحث عن مكتب السياحة.'
        },
        {'fr': 'C\'est en face de la poste.', 'ar': 'إنه مقابل مكتب البريد.'},
        {
          'fr': 'Est-ce que c\'est dangereux de marcher ici la nuit ?',
          'ar': 'هل المشي هنا في الليل خطر؟'
        },
        {'fr': 'Où est le métro le plus proche ?', 'ar': 'أين هو أقرب مترو؟'},
        {
          'fr': 'Est-ce que je peux y aller à pied ?',
          'ar': 'هل يمكنني الذهاب إلى هناك مشياً؟'
        },
        {'fr': 'Merci de m\'avoir aidé !', 'ar': 'شكراً لمساعدتي!'},
        {'fr': 'Bonne continuation !', 'ar': 'بالتوفيق في طريقك!'},
      ]
    },
    {
      'title': 'En Taxi / Transports',
      'arabicTitle': 'في التاكسي / المواصلات',
      'icon': '🚕',
      'phrases': [
        {
          'fr': 'À cette adresse, s\'il vous plaît.',
          'ar': 'إلى هذا العنوان، من فضلك.'
        },
        {
          'fr': 'Arrêtez-vous ici, c\'est parfait.',
          'ar': 'توقف هنا، هذا ممتاز.'
        },
        {
          'fr': 'Combien de temps ça va prendre ?',
          'ar': 'كم من الوقت سيستغرق ذلك؟'
        },
        {
          'fr': 'Où est l\'arrêt de bus le plus proche ?',
          'ar': 'أين أقرب محطة حافلات؟'
        },
        {
          'fr': 'Un billet pour Paris, s\'il vous plaît.',
          'ar': 'تذكرة إلى باريس، من فضلك.'
        },
        {
          'fr': 'Je voudrais aller à l\'aéroport, s\'il vous plaît.',
          'ar': 'أود الذهاب إلى المطار، من فضلك.'
        },
        {
          'fr': 'Pouvez-vous mettre mes valises dans le coffre ?',
          'ar': 'هل يمكنك وضع حقائبي في الصندوق؟'
        },
        {
          'fr': 'Gardez la monnaie, c\'est pour vous.',
          'ar': 'احتفظ بالباقي، هذا لك.'
        },
        {
          'fr': 'À quelle heure part le prochain train ?',
          'ar': 'متى يغادر القطار القادم؟'
        },
        {'fr': 'Est-ce que ce siège est libre ?', 'ar': 'هل هذا المقعد شاغل؟'},
        {
          'fr': 'Je voudrais un aller-simple pour Bruxelles.',
          'ar': 'أود تذكرة ذهاب فقط إلى بروكسل.'
        },
        {
          'fr': 'Je voudrais un aller-retour, s\'il vous plaît.',
          'ar': 'أود تذكرة ذهاب وإياب، من فضلك.'
        },
        {'fr': 'Y a-t-il un retard prévu ?', 'ar': 'هل هناك تأخير متوقع؟'},
        {
          'fr': 'Sur quel quai se trouve le train ?',
          'ar': 'على أي رصيف يوجد القطار؟'
        },
        {
          'fr': 'Est-ce que je dois composter mon billet ?',
          'ar': 'هل يجب علي ختم تذكرتي؟'
        },
        {
          'fr': 'Pouvez-vous rouler un peu plus vite, je suis pressé ?',
          'ar': 'هل يمكنك القيادة أسرع قليلاً، أنا مستعجل؟'
        },
        {
          'fr': 'Est-ce que vous acceptez la carte bancaire ?',
          'ar': 'هل تقبل البطاقة البنكية؟'
        },
        {
          'fr': 'Baissez la clim, s\'il vous plaît.',
          'ar': 'اخفض المكيف، من فضلك.'
        },
        {
          'fr': 'C\'est ma station, je descends ici.',
          'ar': 'هذه محطتي، سأنزل هنا.'
        },
        {'fr': 'Merci pour le trajet.', 'ar': 'شكراً على الرحلة.'},
      ]
    },
    {
      'title': 'Urgences',
      'arabicTitle': 'الطوارئ',
      'icon': '🆘',
      'phrases': [
        {'fr': 'J\'ai besoin d\'aide !', 'ar': 'أحتاج للمساعدة!'},
        {
          'fr': 'Appelez les secours / la police !',
          'ar': 'اتصل بالإسعاف / الشرطة!'
        },
        {
          'fr': 'J\'ai perdu mon sac / mon passeport.',
          'ar': 'فقدت حقيبتي / جواز سفري.'
        },
        {'fr': 'Je ne me sens pas bien.', 'ar': 'لا أشعر أنني بخير.'},
        {'fr': 'Où est l\'hôpital le plus proche ?', 'ar': 'أين أقرب مستشفى؟'},
        {
          'fr': 'Appelez une ambulance, vite !',
          'ar': 'اتصل بسيارة إسعاف، بسرعة!'
        },
        {'fr': 'J\'ai été victime d\'un vol.', 'ar': 'لقد كنت ضحية سرقة.'},
        {'fr': 'Quelqu\'un a pris mon téléphone !', 'ar': 'أحدهم أخذ هاتفي!'},
        {
          'fr': 'Je suis allergique à la pénicilline.',
          'ar': 'عندي حساسية من البنسلين.'
        },
        {
          'fr': 'Pouvez-vous appeler mon ambassade ?',
          'ar': 'هل يمكنك الاتصال بسفارتي؟'
        },
        {'fr': 'C\'est une urgence médicale !', 'ar': 'هذه حالة طبية طارئة!'},
        {'fr': 'Il y a le feu !', 'ar': 'هناك حريق!'},
        {'fr': 'J\'ai eu un accident de voiture.', 'ar': 'تعرضت لحادث سيارة.'},
        {
          'fr': 'Je ne trouve pas mes enfants.',
          'ar': 'لا أستطيع العثور على أطفالي.'
        },
        {'fr': 'Est-ce qu\'il y a un médecin ici ?', 'ar': 'هل يوجد طبيب هنا؟'},
        {'fr': 'Ne me touchez pas !', 'ar': 'لا تلمسني!'},
        {'fr': 'J\'ai très mal au ventre.', 'ar': 'عندي ألم شديد في بطني.'},
        {'fr': 'Je ne peux pas respirer.', 'ar': 'لا أستطيع التنفس.'},
        {'fr': 'Au secours ! Au voleur !', 'ar': 'النجدة! يا حرامي!'},
        {
          'fr': 'Restez avec moi, s\'il vous plaît.',
          'ar': 'ابقَ معي، من فضلك.'
        },
      ]
    },
    {
      'title': 'Romance & Flirt',
      'arabicTitle': 'الرومانسية والغزل',
      'icon': '❤️',
      'phrases': [
        {'fr': 'Tu viens souvent ici ?', 'ar': 'هل تأتي كثيراً إلى هنا؟'},
        {
          'fr': 'Est-ce que je peux t\'offrir un verre ?',
          'ar': 'هل يمكنني أن أقدم لكِ مشروباً؟'
        },
        {'fr': 'Tu as de très beaux yeux.', 'ar': 'لديكِ عينان جميلتان جداً.'},
        {'fr': 'J\'adore ton style.', 'ar': 'أحب أسلوبك/ستايلك.'},
        {
          'fr': 'Qu\'est-ce que tu fais dans la vie ?',
          'ar': 'ماذا تفعل في حياتك؟'
        },
        {'fr': 'Est-ce que tu es célibataire ?', 'ar': 'هل أنت عازب/عازبة؟'},
        {
          'fr': 'On peut s\'échanger nos numéros ?',
          'ar': 'هل يمكننا تبادل أرقام هواتفنا؟'
        },
        {
          'fr': 'Je t\'enverrai un message demain.',
          'ar': 'سأرسل لكِ رسالة غداً.'
        },
        {'fr': 'Tu me manques beaucoup.', 'ar': 'أفتقدكِ كثيراً.'},
        {
          'fr': 'Je pense à toi tout le temps.',
          'ar': 'أنا أفكر فيكِ طوال الوقت.'
        },
        {
          'fr': 'Tu es la personne la plus gentille que je connaisse.',
          'ar': 'أنتِ ألطف شخص أعرفه.'
        },
        {'fr': 'Je suis tombé amoureux de toi.', 'ar': 'لقد وقعت في حبكِ.'},
        {
          'fr': 'Est-ce que tu veux sortir avec moi ?',
          'ar': 'هل تودين الخروج معي؟'
        },
        {'fr': 'Je t\'aime de tout mon cœur.', 'ar': 'أنا أحبك من كل قلبي.'},
        {'fr': 'Tu es mon grand amour.', 'ar': 'أنت حبي الكبير.'},
        {'fr': 'Veux-tu m\'épouser ?', 'ar': 'هل تقبلين الزواج بي؟'},
        {
          'fr': 'Tu me rends très heureux / heureuse.',
          'ar': 'أنت تجعلني سعيداً جداً.'
        },
        {
          'fr': 'J\'adore passer du temps avec toi.',
          'ar': 'أحب قضاء الوقت معكِ.'
        },
        {
          'fr': 'Tu es magnifique dans cette robe.',
          'ar': 'أنتِ رائعة في هذا الفستان.'
        },
        {'fr': 'Pour moi, tu es parfait(e).', 'ar': 'بالنسبة لي، أنتِ مثالية.'},
      ]
    },
    {
      'title': 'Vie Professionnelle',
      'arabicTitle': 'الحياة المهنية',
      'icon': '💼',
      'phrases': [
        {'fr': 'Je travaille comme développeur.', 'ar': 'أعمل كمطور.'},
        {'fr': 'Où se trouve ton bureau ?', 'ar': 'أين يقع مكتبك؟'},
        {
          'fr': 'J\'ai une réunion à dix heures.',
          'ar': 'عندي اجتماع في الساعة العاشرة.'
        },
        {
          'fr': 'Peux-tu m\'envoyer le rapport par email ?',
          'ar': 'هل يمكنك إرسال التقرير لي عبر البريد الإلكتروني؟'
        },
        {
          'fr': 'Je suis en télétravail aujourd\'hui.',
          'ar': 'أنا أعمل عن بعد اليوم.'
        },
        {
          'fr': 'Le manager est très satisfait de votre travail.',
          'ar': 'المدير راضٍ جداً عن عملكم.'
        },
        {
          'fr': 'Je voudrais postuler pour ce poste.',
          'ar': 'أود التقديم لهذه الوظيفة.'
        },
        {
          'fr': 'Voici mon CV et ma lettre de motivation.',
          'ar': 'إليك سيرتي الذاتية وخطاب التغطية.'
        },
        {
          'fr': 'Quels sont les avantages de ce travail ?',
          'ar': 'ما هي مميزات هذا العمل؟'
        },
        {'fr': 'Je cherche un nouvel emploi.', 'ar': 'أبحث عن وظيفة جديدة.'},
        {'fr': 'On va faire une pause café.', 'ar': 'سنأخذ استراحة قهوة.'},
        {'fr': 'Le projet avance bien.', 'ar': 'المشروع يتقدم بشكل جيد.'},
        {
          'fr': 'J\'ai beaucoup de travail en ce moment.',
          'ar': 'عندي الكثير من العمل في الوقت الحالي.'
        },
        {
          'fr': 'Pouvons-nous fixer un rendez-vous ?',
          'ar': 'هل يمكننا تحديد موعد؟'
        },
        {
          'fr': 'Je vais envoyer l\'invitation pour la réunion.',
          'ar': 'سأرسل دعوة للاجتماع.'
        },
        {'fr': 'Quel est ton salaire ?', 'ar': 'ما هو راتبك؟'},
        {
          'fr': 'Je finis ma journée à dix-huit heures.',
          'ar': 'أنهي يوم عملي في الساعة السادسة مساءً.'
        },
        {
          'fr': 'Je suis en congé la semaine prochaine.',
          'ar': 'أنا في إجازة الأسبوع القادم.'
        },
        {
          'fr': 'C\'est un défi professionnel intéressant.',
          'ar': 'إنه تحدٍ مهني مثير للاهتمام.'
        },
        {
          'fr': 'Nous devons collaborer pour réussir.',
          'ar': 'يجب أن نتعاون لكي ننجح.'
        },
      ]
    },
    {
      'title': 'Vie Sociale & Amis',
      'arabicTitle': 'الحياة الاجتماعية والأصدقاء',
      'icon': '🍻',
      'phrases': [
        {'fr': 'Qu\'est-ce que tu fais ce soir ?', 'ar': 'ماذا ستفعل الليلة؟'},
        {'fr': 'On va au cinéma ?', 'ar': 'هل نذهب إلى السينما؟'},
        {'fr': 'Je t\'invite à mon anniversaire.', 'ar': 'أدعوك لعيد ميلادي.'},
        {'fr': 'On se retrouve où ?', 'ar': 'أين سنلتقي؟'},
        {'fr': 'C\'était une super fête !', 'ar': 'كانت حفلة رائعة!'},
        {'fr': 'Tu veux venir avec nous ?', 'ar': 'هل تود المجيء معنا؟'},
        {
          'fr': 'Je suis désolé, je ne peux pas venir.',
          'ar': 'أنا آسف، لا أستطيع المجيء.'
        },
        {'fr': 'C\'est dommage !', 'ar': 'يا للأسف!'},
        {'fr': 'Qu\'est-ce que tu proposes ?', 'ar': 'ماذا تقترح؟'},
        {
          'fr': 'On pourrait aller au parc.',
          'ar': 'يمكننا الذهاب إلى الحديقة.'
        },
        {'fr': 'Je vais appeler mes amis.', 'ar': 'سأتصل بأصدقائي.'},
        {
          'fr': 'Tu connais ce groupe de musique ?',
          'ar': 'هل تعرف فرقة الموسيقى هذه؟'
        },
        {
          'fr': 'C\'est mon meilleur ami / ma meilleure amie.',
          'ar': 'هذا هو أعز أصدقائي / أعز صديقاتي.'
        },
        {'fr': 'On s\'amuse beaucoup ici.', 'ar': 'نحن نستمتع كثيراً هنا.'},
        {
          'fr': 'Je me sens très bien avec vous.',
          'ar': 'أشعر براحة كبيرة معكم.'
        },
        {
          'fr': 'Est-ce que tu as des projets pour le week-end ?',
          'ar': 'هل عندك خطط لنهاية الأسبوع؟'
        },
        {'fr': 'On va manger ensemble demain ?', 'ar': 'هل سنأكل معاً غداً؟'},
        {'fr': 'Joyeux anniversaire !', 'ar': 'عيد ميلاد سعيد!'},
        {'fr': 'Je te souhaite le meilleur.', 'ar': 'أتمنى لك الأفضل.'},
        {'fr': 'Reste en contact !', 'ar': 'ابقَ على تواصل!'},
      ]
    },
    {
      'title': 'Dans le cours de français',
      'arabicTitle': 'في حصة اللغة الفرنسية',
      'icon': '🎓',
      'phrases': [
        {
          'fr': 'Comment dit-on ... en français ?',
          'ar': 'كيف نقول ... بالفرنسية؟'
        },
        {'fr': 'Que signifie ce mot ?', 'ar': 'ماذا تعني هذه الكلمة؟'},
        {
          'fr': 'Pouvez-vous répéter, s\'il vous plaît ?',
          'ar': 'هل يمكنك التكرار، من فضلك؟'
        },
        {'fr': 'Je n\'ai pas compris.', 'ar': 'لم أفهم.'},
        {
          'fr': 'Est-ce qu\'on peut faire une pause ?',
          'ar': 'هل يمكننا أخذ استراحة؟'
        },
        {'fr': 'J\'ai une question.', 'ar': 'عندي سؤال.'},
        {'fr': 'Comment ça s\'écrit ?', 'ar': 'كيف تُكتب هذه؟'},
        {
          'fr': 'Pouvez-vous parler plus lentement ?',
          'ar': 'هل يمكنك التحدث ببطء أكثر؟'
        },
        {'fr': 'À quelle page sommes-nous ?', 'ar': 'في أي صفحة نحن؟'},
        {
          'fr': 'Est-ce qu\'il y a des devoirs pour demain ?',
          'ar': 'هل هناك واجبات للغد؟'
        },
        {
          'fr': 'Je suis désolé, j\'ai oublié mes livres.',
          'ar': 'أنا آسف، لقد نسيت كتبي.'
        },
        {'fr': 'Puis-je emprunter un stylo ?', 'ar': 'هل يمكنني استعارة قلم؟'},
        {'fr': 'Est-ce que c\'est correct ?', 'ar': 'هل هذا صحيح؟'},
        {'fr': 'Comment se prononce ce mot ?', 'ar': 'كيف تُنطق هذه الكلمة؟'},
        {
          'fr': 'Pouvez-vous expliquer encore une fois ?',
          'ar': 'هل يمكنك الشرح مرة أخرى؟'
        },
        {'fr': 'Est-ce que vous pouvez m\'aider ?', 'ar': 'هل يمكنك مساعدتي؟'},
        {'fr': 'J\'ai fini l\'exercice.', 'ar': 'لقد أنهيت التمرين.'},
        {
          'fr': 'Quel est le sujet d\'aujourd\'hui ?',
          'ar': 'ما هو موضوع اليوم؟'
        },
        {
          'fr': 'Puis-je aller aux toilettes, s\'il vous plaît ?',
          'ar': 'هل يمكنني الذهاب إلى الحمام، من فضلك؟'
        },
        {
          'fr': 'Merci pour votre aide, Monsieur/Madame.',
          'ar': 'شكراً لمساعدتك يا سيدي/سيدتي.'
        },
      ]
    },
    {
      'title': 'Au centre commercial',
      'arabicTitle': 'في المركز التجاري',
      'icon': '🏬',
      'phrases': [
        {'fr': 'Je cherche un centre commercial.', 'ar': 'أبحث عن مركز تجاري.'},
        {
          'fr': 'À quelle heure ouvre le magasin ?',
          'ar': 'في أي ساعة يفتح المتجر؟'
        },
        {'fr': 'Je regarde juste, merci.', 'ar': 'أنا أتفرج فقط، شكراً.'},
        {'fr': 'Combien ça coûte ?', 'ar': 'كم ثمن هذا؟'},
        {
          'fr': 'Est-ce qu\'il y a des soldes en ce moment ?',
          'ar': 'هل توجد تنزيلات في الوقت الحالي؟'
        },
        {
          'fr': 'Où sont les cabines d\'essayage ?',
          'ar': 'أين توجد غرف القياس؟'
        },
        {
          'fr': 'Je voudrais essayer ce pantalon.',
          'ar': 'أود قياس هذا البنطلون.'
        },
        {
          'fr': 'Avez-vous une taille plus grande / plus petite ?',
          'ar': 'هل لديكم مقاس أكبر / أصغر؟'
        },
        {
          'fr': 'C\'est trop serré / trop large.',
          'ar': 'هذا ضيق جداً / واسع جداً.'
        },
        {'fr': 'Quelle est votre pointure ?', 'ar': 'ما هو مقاس حذائك؟'},
        {
          'fr': 'Est-ce que vous avez cette chemise en bleu ?',
          'ar': 'هل لديكم هذا القميص باللون الأزرق؟'
        },
        {'fr': 'De quelle matière est-ce fait ?', 'ar': 'من أي مادة صنع هذا؟'},
        {'fr': 'Je vais le prendre.', 'ar': 'سآخذه.'},
        {
          'fr': 'Je ne suis pas sûr(e), je vais réfléchir.',
          'ar': 'لست متأكداً، سأفكر في الأمر.'
        },
        {
          'fr': 'Où est la caisse, s\'il vous plaît ?',
          'ar': 'أين الخزينة (الكاشير)، من فضلك؟'
        },
        {
          'fr': 'Est-ce que je peux retourner cet article ?',
          'ar': 'هل يمكنني إرجاع هذه السلعة؟'
        },
        {'fr': 'Avez-vous le ticket de caisse ?', 'ar': 'هل معك إيصال الدفع؟'},
        {'fr': 'Je voudrais un remboursement.', 'ar': 'أود استرداد المبلغ.'},
        {
          'fr': 'Acceptez-vous les cartes de crédit ?',
          'ar': 'هل تقبلون بطاقات الائتمان؟'
        },
        {
          'fr': 'Est-ce qu\'il y a un parking gratuit ?',
          'ar': 'هل توجد مواقف سيارات مجانية؟'
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _ttsService.flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _playAudio(String text, String id) async {
    if (_currentlyPlayingId == id) {
      await _ttsService.stop();
      setState(() {
        _currentlyPlayingId = null;
      });
    } else {
      setState(() {
        _currentlyPlayingId = id;
      });
      await _ttsService.flutterTts.setLanguage("fr-FR");
      await _ttsService.setRate(0.85);
      await _ttsService.speak(text);
    }
  }

  Future<void> _handleTranslation(
      String frText, String arText, String id, LanguageProvider lp) async {
    if (_visibleTranslations.contains(id)) {
      setState(() {
        _visibleTranslations.remove(id);
      });
      return;
    }

    if (lp.currentLanguage == AppLanguage.arabic) {
      setState(() {
        _visibleTranslations.add(id);
      });
      return;
    }

    // Check if we already have the translation
    if (_dynamicTranslations.containsKey(id)) {
      setState(() {
        _visibleTranslations.add(id);
      });
      return;
    }

    // Fetch translation
    try {
      setState(() {
        _isTranslating = true;
      });
      final translation =
          await DeepSeekService.translateText(frText, lp.currentLanguage.name);
      setState(() {
        _dynamicTranslations[id] = translation;
        _visibleTranslations.add(id);
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      // Fallback to English (not implemented in data yet, but we could try translating to English)
      try {
        final enTranslation =
            await DeepSeekService.translateText(frText, "English");
        setState(() {
          _dynamicTranslations[id] = enTranslation;
          _visibleTranslations.add(id);
        });
      } catch (e2) {
        // Absolute fallback to Arabic if everything fails
        setState(() {
          _dynamicTranslations[id] = arText;
          _visibleTranslations.add(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(languageProvider.currentLanguage == AppLanguage.french
            ? 'Phrases Quotidiennes'
            : 'Daily Phrases (${languageProvider.translate('daily_phrases')})'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          return _buildExpansionSection(section, languageProvider);
        },
      ),
    );
  }

  Widget _buildExpansionSection(
      Map<String, dynamic> section, LanguageProvider lp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(section['icon'], style: const TextStyle(fontSize: 24)),
          ),
          title: Text(
            section['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: FutureBuilder<String>(
            future: lp.currentLanguage == AppLanguage.arabic
                ? Future.value(section['arabicTitle'])
                : DeepSeekService.translateText(
                    section['title'], lp.currentLanguage.name),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? section['arabicTitle'],
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                  fontFamily: 'Arial',
                ),
              );
            },
          ),
          children: (section['phrases'] as List).map((phrase) {
            final id = "${section['title']}_${phrase['fr']}";
            final isPlaying = _currentlyPlayingId == id;
            final isTranslationVisible = _visibleTranslations.contains(id);

            return Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  phrase['fr'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: isTranslationVisible
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          lp.currentLanguage == AppLanguage.arabic
                              ? phrase['ar']
                              : (_dynamicTranslations[id] ?? phrase['ar']),
                          textDirection:
                              lp.isRTL ? TextDirection.rtl : TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Arial',
                          ),
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: _isTranslating &&
                              !_visibleTranslations.contains(id) &&
                              !_dynamicTranslations.containsKey(id)
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.warning),
                              ),
                            )
                          : Icon(
                              isTranslationVisible
                                  ? Icons.translate
                                  : Icons.translate_outlined,
                              color: isTranslationVisible
                                  ? AppTheme.warning
                                  : AppTheme.textTertiary,
                              size: 22,
                            ),
                      onPressed: () => _handleTranslation(
                          phrase['fr'], phrase['ar'], id, lp),
                      tooltip: 'Traduire',
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                        color: isPlaying ? AppTheme.warning : AppTheme.accent,
                        size: 28,
                      ),
                      onPressed: () => _playAudio(phrase['fr'], id),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
