import 'package:flutter/material.dart';
import '../services/translation_store.dart';
import '../theme/app_theme.dart';

/// Small banner at the top of the app while a new lesson or grammar topic is
/// being translated into every language in the background.
class TranslationBanner extends StatelessWidget {
  final Widget child;
  const TranslationBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + 8,
          child: ValueListenableBuilder<String?>(
            valueListenable: TranslationStore.status,
            builder: (context, status, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: status == null
                  ? const SizedBox.shrink()
                  : Center(
                      key: ValueKey(status),
                      child: Material(
                        color: AppTheme.surface,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(status,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
