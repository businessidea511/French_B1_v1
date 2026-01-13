import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dialogue_detail_page.dart';

class DialoguePage extends StatelessWidget {
  const DialoguePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dialogues'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildDialogueCard(
            context,
            title: "Louer un appartement",
            description: "Conversation avec une agence immobilière à Liège.",
            dialogueLines: [
              {
                'role': 'Agent',
                'text':
                    "Bonjour Monsieur/Madame, bienvenue à l'agence Immobilière de Liège. Comment puis-je vous aider aujourd'hui ?"
              },
              {
                'role': 'Client',
                'text':
                    "Bonjour. Je cherche un appartement à louer à Liège, s'il vous plaît."
              },
              {
                'role': 'Agent',
                'text':
                    "Très bien. Avez-vous une préférence pour un quartier en particulier ?"
              },
              {
                'role': 'Client',
                'text':
                    "Oui, je voudrais habiter près de la gare des Guillemins, pour pouvoir prendre le train facilement."
              },
              {
                'role': 'Agent',
                'text':
                    "C'est noté. Quel type d'appartement recherchez-vous ? Un studio, un deux pièces ?"
              },
              {
                'role': 'Client',
                'text':
                    "Je cherche un petit appartement, mais pas trop petit. Un deux pièces serait parfait."
              },
              {
                'role': 'Agent',
                'text':
                    "D'accord. Et quel est votre budget mensuel pour le loyer ?"
              },
              {
                'role': 'Client',
                'text':
                    "Mon budget est entre 500 et 650 euros hors charges, ou alors 800 euros charges comprises maximum."
              },
              {
                'role': 'Agent',
                'text':
                    "C'est un budget raisonnable. Avez-vous d'autres critères importants ?"
              },
              {
                'role': 'Client',
                'text':
                    "Oui, j'aimerais qu'il y ait un parc ou un espace vert à proximité, et aussi des magasins pour faire mes courses."
              },
              {
                'role': 'Agent',
                'text':
                    "Entendu. Laissez-moi regarder ce que nous avons... Ah, j'ai justement un appartement qui pourrait vous convenir. Il est situé rue des Guillemins, à 5 minutes de la gare."
              },
              {
                'role': 'Client',
                'text':
                    "Ah, ça m'intéresse ! Est-ce qu'il y a des espaces verts autour ?"
              },
              {
                'role': 'Agent',
                'text':
                    "Oui, le Parc d'Avroy est juste à côté. Et il y a un supermarché et une boulangerie en bas de l'immeuble."
              },
              {'role': 'Client', 'text': "C'est parfait ! Et le loyer ?"},
              {
                'role': 'Agent',
                'text':
                    "Le loyer est de 600 euros, plus 150 euros de charges qui incluent le chauffage et l'eau. Donc on arrive à 750 euros au total."
              },
              {
                'role': 'Client',
                'text':
                    "C'est dans mon budget. Est-ce que je pourrais le visiter ?"
              },
              {
                'role': 'Agent',
                'text':
                    "Bien sûr. Est-ce que demain à 14 heures vous conviendrait ?"
              },
              {
                'role': 'Client',
                'text': "Oui, c'est parfait. Merci beaucoup !"
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<Map<String, String>> dialogueLines,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DialogueDetailPage(
                title: title,
                description: description,
                dialogueLines: dialogueLines,
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
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '💬',
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
            ],
          ),
        ),
      ),
    );
  }
}
