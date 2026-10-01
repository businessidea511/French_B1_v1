import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Slowly moving glowing colours and drifting particles behind every page.
class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _AuroraPainter(reduceMotion ? const AlwaysStoppedAnimation(0.2) : _controller)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> t;
  _AuroraPainter(this.t) : super(repaint: t);

  // A getter, so the colours follow the light/dark mode.
  static List<(Color, double, double)> get _blobs => [
        (AppTheme.primary, 0.0, 0.55),
        (AppTheme.sun, 2.1, 0.45),
        (AppTheme.success, 4.2, 0.5),
        (AppTheme.accent, 1.0, 0.4),
      ];

  static final _particles = List.generate(36, (i) {
    final r = Random(i * 7919);
    return (r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 1.8, r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.background);
    final phase = t.value * 2 * pi;
    final span = max(size.width, size.height);
    for (final (color, offset, radius) in _blobs) {
      final center = Offset(
        size.width * (0.5 + 0.38 * sin(phase + offset)),
        size.height * (0.5 + 0.36 * cos(phase * 0.8 + offset * 1.3)),
      );
      final r = span * radius;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: AppTheme.isDark ? 0.16 : 0.20), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
    final dot = Paint();
    for (final (x, y, s, speed) in _particles) {
      final dy = (y - t.value * (0.3 + speed)) % 1.0;
      final twinkle = 0.25 + 0.35 * (0.5 + 0.5 * sin(phase * 3 + x * 20));
      dot.color = (AppTheme.isDark ? AppTheme.fg : AppTheme.sun).withValues(alpha: twinkle * (AppTheme.isDark ? 0.8 : 0.9));
      canvas.drawCircle(Offset(x * size.width, dy * size.height), s, dot);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => false;
}

/// Tilts its child in 3D towards the mouse or finger, with a light reflection,
/// and presses in when tapped.
class Tilt3D extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double maxTilt;
  final BorderRadius borderRadius;

  const Tilt3D({
    super.key,
    required this.child,
    this.onTap,
    this.maxTilt = 0.22,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _pointer = Offset.zero; // -1..1 in both axes
  bool _active = false;
  bool _pressed = false;

  void _update(Offset local, Size size) {
    setState(() {
      _active = true;
      _pointer = Offset(
        ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
        ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  void _release() => setState(() {
        _active = false;
        _pressed = false;
        _pointer = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 200);
      return MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onHover: (e) => _update(e.localPosition, size),
        onExit: (_) => _release(),
        child: Listener(
          onPointerDown: (e) {
            _update(e.localPosition, size);
            setState(() => _pressed = true);
          },
          onPointerMove: (e) => _update(e.localPosition, size),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => _release(),
          child: GestureDetector(
            onTap: widget.onTap,
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(end: _active ? _pointer : Offset.zero),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, p, child) {
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateX(-p.dy * widget.maxTilt)
                  ..rotateY(p.dx * widget.maxTilt);
                return AnimatedScale(
                  scale: _pressed ? 0.96 : (_active ? 1.03 : 1),
                  duration: const Duration(milliseconds: 150),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        child!,
                        if (_active)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: widget.borderRadius,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(p.dx, p.dy),
                                      radius: 1.1,
                                      colors: [Colors.white.withValues(alpha: AppTheme.isDark ? 0.14 : 0.45), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        ),
      );
    });
  }
}

/// Fades and swings its child up into place, [index] × [step] after it appears.
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration step;

  const Entrance({super.key, required this.child, this.index = 0, this.step = const Duration(milliseconds: 60)});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.step * min(widget.index, 12), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_c.value);
        final fade = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: fade,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..translate(0.0, (1 - t) * 40)
              ..rotateX((1 - t) * 0.6),
            child: child,
          ),
        );
      },
    );
  }
}

/// Moves its child gently up and down.
class Floating extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration period;

  const Floating({super.key, required this.child, this.distance = 6, this.period = const Duration(seconds: 3)});

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, sin(_c.value * 2 * pi) * widget.distance), child: child),
      );
}

/// A card that turns over in 3D when [flipped] changes.
class Flip3D extends StatelessWidget {
  final bool flipped;
  final Widget front;
  final Widget back;
  final Duration duration;

  const Flip3D({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? pi : 0),
      duration: duration,
      curve: Curves.easeInOutBack,
      builder: (context, angle, _) {
        final showBack = angle > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(pi), child: back)
              : front,
        );
      },
    );
  }
}

/// Frosted card used across the new interface.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;
  final double radius;

  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.glow, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark;
    final tint = glow ?? AppTheme.fg;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [tint.withValues(alpha: glow == null ? 0.07 : 0.16), AppTheme.surface.withValues(alpha: 0.7)]
              : [
                  Color.alphaBlend(tint.withValues(alpha: glow == null ? 0.0 : 0.14), AppTheme.surface),
                  AppTheme.surface,
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tint.withValues(alpha: dark ? 0.16 : (glow == null ? 0.07 : 0.28))),
        boxShadow: [
          BoxShadow(
            color: (glow ?? (dark ? Colors.black : const Color(0xFF8A6A4A)))
                .withValues(alpha: dark ? (glow == null ? 0.25 : 0.2) : (glow == null ? 0.10 : 0.16)),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Circular progress with a glowing gradient arc.
class GoalRing extends StatelessWidget {
  final double progress;
  final double size;
  final Widget? center;

  const GoalRing({super.key, required this.progress, this.size = 120, this.center});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, 2 * pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppTheme.fg.withValues(alpha: 0.08));
    if (value <= 0) return;
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: [AppTheme.primary, AppTheme.sun, AppTheme.success, AppTheme.primary],
      transform: const GradientRotation(-pi / 2),
    );
    canvas.drawArc(rect, -pi / 2, 2 * pi * value, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3)
          ..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// Celebration: a burst of confetti over the whole screen.
class Confetti {
  static void burst(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _ConfettiLayer(onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiLayer({required this.onDone});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward().whenComplete(widget.onDone);
  final _random = Random();
  late final _pieces = List.generate(90, (_) {
    final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 2.2;
    final speed = 0.9 + _random.nextDouble() * 1.1;
    return (angle, speed, _random.nextDouble() * 2 * pi, Colors.primaries[_random.nextInt(Colors.primaries.length)]);
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(size: MediaQuery.sizeOf(context), painter: _ConfettiPainter(_c.value, _pieces)),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<(double, double, double, Color)> pieces;
  _ConfettiPainter(this.t, this.pieces);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.75);
    final paint = Paint();
    for (final (angle, speed, spin, color) in pieces) {
      final d = speed * size.height * 0.75 * t;
      final pos = origin + Offset(cos(angle) * d, sin(angle) * d + 0.9 * size.height * t * t);
      paint.color = color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(spin + t * 12);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 9, height: 5 + 4 * sin(t * 20 + spin).abs()), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

/// Page transition: the new page swings up from below in 3D while the old one
/// sinks back.
class Swing3DPageTransitionsBuilder extends PageTransitionsBuilder {
  const Swing3DPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final back = Curves.easeInOut.transform(secondaryAnimation.value);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translate(0.0, (1 - t) * 80)
          ..rotateX((1 - t) * 0.45)
          ..scale(0.92 + 0.08 * t - 0.06 * back);
        return FadeTransition(
          opacity: AlwaysStoppedAnimation((t * (1 - back)).clamp(0.0, 1.0)),
          child: Transform(alignment: Alignment.topCenter, transform: transform, child: child),
        );
      },
    );
  }
}
