import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'motion.dart';
import 'translated_text.dart';

/// A big 3D tile opening a feature: floating emoji, title, subtitle, badge.
class FeatureTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle; // English, translated on screen
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const FeatureTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Tilt3D(
      onTap: onTap,
      child: GlassCard(
        glow: color,
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Floating(
                  distance: 4,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.12)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 23))),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: TranslatedText(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppTheme.fg.withValues(alpha: 0.6), height: 1.3)),
                ),
              ],
            ),
            if (badge != null)
              PositionedDirectional(
                top: -4,
                end: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                  child: Text(badge!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Responsive grid of [FeatureTile]s with a staggered 3D entrance.
class FeatureGrid extends StatelessWidget {
  final List<Widget> tiles;
  const FeatureGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth > 1000 ? 4 : (c.maxWidth > 640 ? 3 : 2);
      const gap = 14.0;
      final width = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < tiles.length; i++)
            SizedBox(width: width, height: 168, child: Entrance(index: i, child: tiles[i])),
        ],
      );
    });
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Buttons that type French accented letters into [controller], for keyboards
/// without them.
class AccentBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  const AccentBar({super.key, required this.controller, this.focusNode});

  static const _letters = ['é', 'è', 'ê', 'à', 'â', 'ç', 'î', 'ï', 'ô', 'û', 'ù', 'ë', 'œ', "'"];

  void _insert(String letter) {
    final value = controller.value;
    final start = value.selection.isValid ? value.selection.start : value.text.length;
    final end = value.selection.isValid ? value.selection.end : value.text.length;
    final text = value.text.replaceRange(start, end, letter);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + letter.length),
    );
    focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (final l in _letters)
            InkWell(
              onTap: () => _insert(l),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.fg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.fg.withValues(alpha: 0.12)),
                ),
                child: Text(l, style: TextStyle(fontSize: 17, color: AppTheme.textPrimary)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Big gradient button with a soft glow.
class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color>? colors;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = this.colors ?? [AppTheme.primary, AppTheme.sun];
    return Tilt3D(
      maxTilt: 0.08,
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: AppTheme.onColor), const SizedBox(width: 10)],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.onColor, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page body limited to a readable width and centred.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets padding;
  const PageBody({super.key, required this.children, this.controller, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 120)});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: padding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
  }
}
