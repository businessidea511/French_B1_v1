import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'essay_detail_page.dart';

class EssayPage extends StatelessWidget {
  const EssayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Rédactions (Essays)'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildEssayCard(
            context,
            title: "Souvenir d'enfance",
            description: "A story about a childhood football accident.",
            tenses: "Passé Composé, Imparfait, Conditionnel, Si seulement",
            content:
                """Quand j'étais petit, je jouais tout le temps au football avec mes amis. C'était ma passion.

Un jour, alors que nous jouions dans le parc, je suis tombé violemment en essayant d'attraper le ballon. Je me suis fait très mal à la main. J'avais très peur.

Mes parents sont arrivés rapidement et je suis allé à l'hôpital. Le médecin m'a examiné et il a soigné ma blessure. Heureusement, ce n'était pas cassé.

C'était une mauvaise expérience pour moi. Si seulement j'avais fait plus attention, je ne me serais pas blessé ce jour-là. J'aurais aimé pouvoir continuer le match avec mes copains au lieu d'aller aux urgences !""",
            arabicContent:
                """عندما كنت طفلاً، كنت ألعب كرة القدم دائماً مع أصدقائي. كان ذلك شغفي.

ذات يوم، بينما كنا نلعب في الحديقة، سقطت بقوة وأنا أحاول الإمساك بالكرة. جرحت يدي بشدة. كنت خائفاً جداً.

وصل والداي بسرعة وذهبت إلى المستشفى. فحصني الطبيب وعالج جرحي. لحسن الحظ، لم يكن مكسوراً.

كانت تجربة سيئة لي. لو أنني فقط انتبهت أكثر، لما كنت جرحت نفسي في ذلك اليوم. كنت أتمنى لو استطعت إكمال المباراة مع أصدقائي بدلاً من الذهاب إلى الطوارئ!""",
          ),
          const SizedBox(height: 16),
          _buildEssayCard(
            context,
            title: "Mon logement à Liège",
            description: "Description of an apartment in the Citadel district.",
            tenses: "Présent, Passé Composé, Imparfait, Conditionnel",
            content:
                """J'habite actuellement dans un appartement au rez-de-chaussée, dans le quartier de la Citadelle à Liège. C'est un quartier très calme et verdoyant.

Le propriétaire de la maison habite juste au-dessus de chez moi, au premier étage. Il vit avec sa femme. C'est un monsieur âgé, mais ils sont tous les deux très gentils et toujours prêts à aider.

L'emplacement est idéal : il y a un petit magasin et un arrêt de bus juste en face de l'appartement. C'est très pratique pour faire des courses ou aller en ville.

Mon appartement se compose de deux pièces. Le salon est spacieux, avec un grand canapé confortable et une télévision. La chambre est un peu petite, mais elle contient un lit douillet et une grande armoire. La cuisine est toute équipée, ce qui est parfait car j'aime cuisiner. Enfin, il y a une salle de bain avec une douche et des toilettes.

J'adore mon appartement, je m'y sens bien. J'aimerais vraiment trouver un travail à Liège ou dans les environs. Comme ça, je pourrais rester vivre ici encore longtemps. Ce serait parfait pour moi.""",
            arabicContent:
                """أعيش حالياً في شقة في الطابق الأرضي، في حي القلعة في لييج. إنه حي هادئ جداً ومليء بالخضرة.

صاحب المنزل يسكن فوقي تماماً، في الطابق الأول. يعيش مع زوجته. إنه رجل مسن، لكنهما لطيفان جداً ومستعدان دائماً للمساعدة.

الموقع مثالي: يوجد متجر صغير ومحطة حافلات أمام الشقة مباشرة. هذا عملي جداً للتسوق أو الذهاب إلى المدينة.

تتكون شقتي من غرفتين. غرفة المعيشة واسعة، وفيها أريكة كبيرة مريحة وتلفزيون. غرفة النوم صغيرة قليلاً، لكن فيها سرير مريح وخزانة كبيرة. المطبخ مجهز بالكامل، وهذا ممتاز لأنني أحب الطبخ. أخيراً، هناك حمام مع دش ومرحاض.

أحب شقتي، وأشعر بالراحة فيها. أود حقاً أن أجد عملاً في لييج أو في الجوار. هكذا، سأتمكن من البقاء في هذا السكن لفترة طويلة. سيكون ذلك مثالياً لي.""",
          ),
          const SizedBox(height: 16),
          _buildEssayCard(
            context,
            title: "Mes projets d'avenir",
            description: "Plans for studying, working, and creating apps.",
            tenses:
                "Futur Simple, Futur Proche, Présent, Imparfait, Conditionnel",
            content:
                """Actuellement, j'apprends le français parce que je veux trouver un bon travail. J'ai déjà terminé mon application pour les CV.

Bientôt, je vais commencer une nouvelle application pour le service client qui utilise l'IA. Cette application travaillera sur les sentiments. Par exemple, si le client est fâché, l'outil essaiera de le calmer.

L'outil surveillera aussi la conversation en direct. Il suggérera des réponses pour le support. Si le support essayait de répondre de manière impolie, l'IA enverrait une alerte. Elle dirait qu'on ne doit pas parler comme ça et proposerait une réponse plus polie.

Enfin, je créerai mon entreprise en Belgique et je commencerai à promouvoir mes applications.""",
            arabicContent:
                """أنا أدرس الفرنسية حاليًا لأنني أريد العثور على وظيفة جيدة. لقد أنهيت بالفعل تطبيقي للسير الذاتية.

قريباً، سأبدأ تطبيقاً آخر لخدمة العملاء يستخدم الذكاء الاصطناعي. سيعمل هذا التطبيق على تحليل مشاعر العملاء. على سبيل المثال، إذا كان العميل غاضباً، سيحاول التطبيق تهدئته.

سيقوم هذا التطبيق أيضاً بمراقبة المحادثة المباشرة بين الدعم والعميل وسيقترح إجابات. إذا حاول موظف الدعم الرد بطريقة غير مهذبة، سيرسل الذكاء الاصطناعي تنبيهاً ويقترح رداً أفضل.

في النهاية، سأسجل شركتي في بلجيكا وسأبدأ في الترويج لتطبيقاتي.""",
          ),
          const SizedBox(height: 16),
          _buildEssayCard(
            context,
            title: "Mes projets d'avenir (Facile)",
            description: "A simpler version of my future plans.",
            tenses:
                "Futur Simple, Futur Proche, Présent, Imparfait, Conditionnel",
            content:
                """Aujourd'hui, j'étudie le français. Je veux travailler. J'ai fini mon application CV.

Bientôt, je vais créer une application pour les clients.

Si un client était fâché, l'IA l'aiderait.

Si je parlais mal, l'IA me corrigerait.

Un jour, j'aurai ma société en Belgique.""",
            arabicContent:
                """اليوم، أدرس الفرنسية. أريد العمل. لقد أنهيت تطبيق السيرة الذاتية.

قريباً، سأقوم بإنشاء تطبيق للعملاء.

لو كان العميل غاضباً، سيساعده الذكاء الاصطناعي.

لو تحدثت بشكل سيء، سيصحح لي الذكاء الاصطناعي.

يوماً ما، سيكون لدي شركتي في بلجيكا.""",
          ),
        ],
      ),
    );
  }

  Widget _buildEssayCard(
    BuildContext context, {
    required String title,
    required String description,
    required String tenses,
    required String content,
    required String arabicContent,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EssayDetailPage(
                title: title,
                content: content,
                arabicContent: arabicContent,
                description: description,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '📝',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppTheme.textTertiary),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Grammaire: $tenses',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
