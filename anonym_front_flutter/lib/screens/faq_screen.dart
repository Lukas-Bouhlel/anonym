import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/chrome/moji_back_button.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<_FaqItem> _items = const [
    _FaqItem(
      question: 'Comment signaler un probleme ?',
      answer:
          'Pour signaler un probleme, que ce soit sur la plateforme Anonym '
          'ou avec un autre utilisateur lors d une discussion, ou pour tout '
          'autre souci lie a la plateforme, utilise le formulaire Feedback.\n\n'
          'Tout abus de signalement sera sanctionne par l equipe Anonym.',
    ),
    _FaqItem(
      question: 'Comment fonctionne le systeme de reputation ?',
      answer:
          'Le systeme de reputation se base sur le nombre de messages envoyes '
          'a d autres utilisateurs.\n\n'
          'Pour obtenir un multiplicateur de reputation, il faut acquerir un '
          'element de personnalisation depuis la boutique.',
    ),
    _FaqItem(
      question: 'Je n arrive plus a me connecter, comment faire ?',
      answer:
          'Si tu rencontres des problemes de connexion (aucun message, erreur '
          'silencieuse, etc.), envoie-nous un message via le formulaire Feedback.\n\n'
          'Tout abus de signalement sera sanctionne par l equipe Anonym.',
    ),
    _FaqItem(
      question: 'Quelles sont les informations recueillies par Anonym ?',
      answer:
          'Nous pouvons collecter les types de donnees suivants :\n'
          '- Donnees de connexion : nom d utilisateur, adresse e-mail, mot de passe.\n'
          '- Donnees de paiement : factures.\n'
          '- Donnees de navigation : pages visitees, clics, preferences.\n\n'
          'Pour plus d informations, consulte la politique de confidentialite.',
    ),
    _FaqItem(
      question: 'Comment soutenir l equipe Anonym ?',
      answer:
          'Pour soutenir l equipe Anonym, tu peux envoyer un don qui sera '
          'reverse a l equipe de developpement.\n\n'
          'Tu peux aussi soutenir le projet en achetant un element de '
          'personnalisation pour ton profil.',
    ),
  ];

  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MojiBackButton(),
                    const SizedBox(width: 14),
                    Text(
                      'FAQs',
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Retrouve ici les reponses aux questions les plus frequentes.',
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.whiteColor.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isOpen = _openIndex == index;
                      return _FaqAccordionTile(
                        title: item.question,
                        body: item.answer,
                        isOpen: isOpen,
                        onTap: () {
                          setState(() {
                            _openIndex = isOpen ? null : index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqAccordionTile extends StatelessWidget {
  const _FaqAccordionTile({
    required this.title,
    required this.body,
    required this.isOpen,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(1.1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppGradients.gB1BCFBTo393566,
          border: Border.all(
            color: isOpen
                ? AppColors.cFCFAFE.withValues(alpha: 0.52)
                : AppColors.cFCFAFE.withValues(alpha: 0.28),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.c393566.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.whiteColor.withValues(alpha: 0.96),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: isOpen ? 0.5 : 0.0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.whiteColor.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    body,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.whiteColor.withValues(alpha: 0.78),
                      height: 1.35,
                    ),
                  ),
                ),
                crossFadeState: isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
