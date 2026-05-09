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
                    "Bonjour, bienvenue à l'agence immobilière de Liège. Comment puis-je vous aider ?"
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
                    "Oui, je voudrais habiter près de la gare. C'est pratique pour moi."
              },
              {
                'role': 'Agent',
                'text': "D'accord. Quel type d'appartement recherchez-vous ?"
              },
              {
                'role': 'Client',
                'text': "Je cherche un deux pièces, de préférence."
              },
              {
                'role': 'Agent',
                'text':
                    "Parfait. Et quel est votre budget mensuel pour le loyer ?"
              },
              {
                'role': 'Client',
                'text': "Mon budget est entre 500 et 650 euros par mois."
              },
              {
                'role': 'Agent',
                'text': "Entendu. Avez-vous d'autres critères importants ?"
              },
              {
                'role': 'Client',
                'text':
                    "Oui, j'aimerais qu'il y ait un parc à proximité de l'appartement."
              },
              {
                'role': 'Agent',
                'text':
                    "J'ai justement un appartement qui pourrait vous convenir. Il se trouve rue des Guillemins, à 5 minutes de la gare."
              },
              {
                'role': 'Client',
                'text':
                    "Très bien ! Est-ce qu'il y a un parc dans les environs ?"
              },
              {
                'role': 'Agent',
                'text':
                    "Oui, le Parc d'Avroy est juste à côté. Il y a également un supermarché à proximité."
              },
              {
                'role': 'Client',
                'text': "Excellent ! Pourriez-vous me dire le prix ?"
              },
              {
                'role': 'Agent',
                'text':
                    "Le loyer est de 600 euros, plus 100 euros de charges. Cela fait 700 euros au total."
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
                'text': "Oui, c'est parfait. Je vous remercie beaucoup !"
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
