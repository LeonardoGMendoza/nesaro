import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Símbolo da Nesaro: raiz (根) que sobe pelo caminho (路) e floresce (咲).
///
/// Com [animated] = true, a raiz e o caule se desenham, as pétalas abrem uma a uma
/// e a flor balança de leve, sem parar. Desenhado em código: não precisa de imagem.
class NesaroLogo extends StatefulWidget {
  const NesaroLogo({
    super.key,
    this.size = 96,
    this.animated = false,
    this.inkColor = NesaroColors.ink,
    this.petalColor = NesaroColors.sakura,
    this.centerColor = NesaroColors.paper,
  });

  final double size;
  final bool animated;
  final Color inkColor;
  final Color petalColor;
  final Color centerColor;

  @override
  State<NesaroLogo> createState() => _NesaroLogoState();
}

class _NesaroLogoState extends State<NesaroLogo> with TickerProviderStateMixin {
  AnimationController? _grow;
  AnimationController? _sway;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
      _sway = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _grow?.dispose();
    _sway?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grow = _grow;
    final sway = _sway;

    Widget paint(double progress, double swing) => CustomPaint(
          size: Size.square(widget.size),
          painter: _NesaroLogoPainter(
            ink: widget.inkColor,
            petal: widget.petalColor,
            center: widget.centerColor,
            progress: progress,
            swing: swing,
          ),
        );

    return Semantics(
      label: 'Logotipo Nesaro',
      image: true,
      child: grow == null || sway == null
          ? paint(1, 0)
          : AnimatedBuilder(
              animation: Listenable.merge([grow, sway]),
              builder: (context, _) => paint(
                Curves.easeInOutCubic.transform(grow.value),
                Curves.easeInOutSine.transform(sway.value) * 2 - 1,
              ),
            ),
    );
  }
}

class _NesaroLogoPainter extends CustomPainter {
  _NesaroLogoPainter({
    required this.ink,
    required this.petal,
    required this.center,
    required this.progress,
    required this.swing,
  });

  final Color ink;
  final Color petal;
  final Color center;

  /// 0 → nada desenhado; 1 → logo completo.
  final double progress;

  /// -1 a 1: balanço da flor.
  final double swing;

  /// Fração [start, end] do progresso total mapeada para 0..1.
  double _phase(double start, double end) => ((progress - start) / (end - start)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    Paint stroke(double width, {double opacity = 1}) => Paint()
      ..color = ink.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    void drawPartial(Path path, Paint paint, double t) {
      if (t <= 0) return;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
      }
    }

    // 1) Chão
    drawPartial(Path()..moveTo(56, 168)..lineTo(144, 168), stroke(3, opacity: 0.3), _phase(0, 0.15));

    // 2) Raízes
    final roots = <List<double>>[
      [100, 168, 92, 176, 80, 180, 66, 188, 4.5],
      [100, 168, 103, 177, 98, 186, 101, 196, 4.5],
      [100, 168, 110, 176, 122, 180, 136, 186, 4.5],
      [82, 180, 78, 186, 74, 189, 68, 192, 2.5],
      [120, 179, 124, 185, 128, 188, 132, 194, 2.5],
    ];
    final rootT = _phase(0.05, 0.35);
    for (final r in roots) {
      final path = Path()
        ..moveTo(r[0], r[1])
        ..cubicTo(r[2], r[3], r[4], r[5], r[6], r[7]);
      drawPartial(path, stroke(r[8]), rootT);
    }

    // 3) Caminho (caule) — cresce para cima
    final stem = Path()
      ..moveTo(100, 168)
      ..cubicTo(70, 145, 128, 118, 100, 92);
    drawPartial(stem, stroke(7), _phase(0.3, 0.6));

    // 4) Folha
    final leafT = Curves.easeOutBack.transform(_phase(0.5, 0.7));
    if (leafT > 0) {
      canvas.save();
      canvas.translate(108, 130);
      canvas.scale(leafT);
      canvas.translate(-108, -130);
      final leaf = Path()
        ..moveTo(108, 130)
        ..cubicTo(120, 117, 136, 118, 142, 124)
        ..cubicTo(132, 135, 118, 138, 108, 130)
        ..close();
      canvas.drawPath(leaf, Paint()..color = ink);
      canvas.restore();
    }

    // 5) Flor de sakura — pétalas abrem uma a uma e a flor balança
    final petalPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(-13, -8, -14, -28, -6, -33)
      ..lineTo(0, -28)
      ..lineTo(6, -33)
      ..cubicTo(14, -28, 13, -8, 0, 0)
      ..close();
    final petalPaint = Paint()..color = petal;

    canvas.save();
    canvas.translate(100, 58);
    canvas.rotate(swing * 6 * math.pi / 180);
    for (var i = 0; i < 5; i++) {
      final t = Curves.easeOutBack.transform(_phase(0.6 + i * 0.06, 0.78 + i * 0.06));
      if (t <= 0) continue;
      canvas.save();
      canvas.rotate(i * 72 * math.pi / 180);
      canvas.scale(t);
      canvas.drawPath(petalPath, petalPaint);
      canvas.restore();
    }
    final coreT = _phase(0.9, 1);
    if (coreT > 0) {
      canvas.drawCircle(Offset.zero, 6 * coreT, Paint()..color = center);
      canvas.drawCircle(Offset.zero, 2.5 * coreT, Paint()..color = ink);
    }
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NesaroLogoPainter old) =>
      old.progress != progress ||
      old.swing != swing ||
      old.ink != ink ||
      old.petal != petal ||
      old.center != center;
}

/// Logo + nome + japonês + slogan.
class NesaroWordmark extends StatelessWidget {
  const NesaroWordmark({
    super.key,
    this.light = false,
    this.logoSize = 112,
    this.animated = true,
  });

  /// true = texto claro, para fundos escuros.
  final bool light;
  final double logoSize;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final main = light ? NesaroColors.paper : NesaroColors.ink;
    final soft = light ? const Color(0xFFE6DCCB) : NesaroColors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NesaroLogo(
          size: logoSize,
          animated: animated,
          inkColor: main,
          petalColor: light ? NesaroColors.sakuraLight : NesaroColors.sakura,
          centerColor: light ? NesaroColors.ink : NesaroColors.paper,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NESARO',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 5, color: main),
            ),
            const SizedBox(width: 10),
            const _Hanko(),
          ],
        ),
        Text('ネサロ · 根咲路', style: TextStyle(fontSize: 15, letterSpacing: 3, color: soft)),
        const SizedBox(height: 8),
        Text('Respostas automáticas no Direct', style: TextStyle(fontSize: 15, color: soft)),
      ],
    );
  }
}

/// Carimbo vermelho (hanko) com 根咲路 na vertical.
class _Hanko extends StatelessWidget {
  const _Hanko();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: NesaroColors.seal, borderRadius: BorderRadius.circular(5)),
      child: const Text(
        '咲',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1),
      ),
    );
  }
}
