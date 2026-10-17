import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Símbolo da Nesaro: raiz (根) que sobe pelo caminho (路) e floresce (咲).
/// Desenhado em código, igual ao logotipo — não precisa de arquivo de imagem.
class NesaroLogo extends StatelessWidget {
  const NesaroLogo({
    super.key,
    this.size = 96,
    this.inkColor = NesaroColors.ink,
    this.petalColor = NesaroColors.sakura,
    this.centerColor = NesaroColors.paper,
  });

  final double size;
  final Color inkColor;
  final Color petalColor;
  final Color centerColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logotipo Nesaro',
      child: CustomPaint(
        size: Size.square(size),
        painter: _NesaroLogoPainter(inkColor, petalColor, centerColor),
      ),
    );
  }
}

class _NesaroLogoPainter extends CustomPainter {
  _NesaroLogoPainter(this.ink, this.petal, this.center);

  final Color ink;
  final Color petal;
  final Color center;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    Paint stroke(double width, {double opacity = 1}) => Paint()
      ..color = ink.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // Chão
    canvas.drawLine(const Offset(56, 168), const Offset(144, 168), stroke(3, opacity: 0.3));

    // Raízes
    final roots = [
      [100.0, 168.0, 92.0, 176.0, 80.0, 180.0, 66.0, 188.0, 4.5],
      [100.0, 168.0, 103.0, 177.0, 98.0, 186.0, 101.0, 196.0, 4.5],
      [100.0, 168.0, 110.0, 176.0, 122.0, 180.0, 136.0, 186.0, 4.5],
      [82.0, 180.0, 78.0, 186.0, 74.0, 189.0, 68.0, 192.0, 2.5],
      [120.0, 179.0, 124.0, 185.0, 128.0, 188.0, 132.0, 194.0, 2.5],
    ];
    for (final r in roots) {
      final path = Path()
        ..moveTo(r[0], r[1])
        ..cubicTo(r[2], r[3], r[4], r[5], r[6], r[7]);
      canvas.drawPath(path, stroke(r[8]));
    }

    // Caminho (caule)
    final stem = Path()
      ..moveTo(100, 168)
      ..cubicTo(70, 145, 128, 118, 100, 92);
    canvas.drawPath(stem, stroke(7));

    // Folha
    final leaf = Path()
      ..moveTo(108, 130)
      ..cubicTo(120, 117, 136, 118, 142, 124)
      ..cubicTo(132, 135, 118, 138, 108, 130)
      ..close();
    canvas.drawPath(leaf, Paint()..color = ink);

    // Flor de sakura
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
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 72 * math.pi / 180);
      canvas.drawPath(petalPath, petalPaint);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 6, Paint()..color = center);
    canvas.drawCircle(Offset.zero, 2.5, Paint()..color = ink);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NesaroLogoPainter old) =>
      old.ink != ink || old.petal != petal || old.center != center;
}

/// Logo + nome, usado no login.
class NesaroWordmark extends StatelessWidget {
  const NesaroWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NesaroLogo(size: 112),
        SizedBox(height: 8),
        Text(
          'NESARO',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: NesaroColors.ink,
          ),
        ),
        Text(
          'ネサロ · 根咲路',
          style: TextStyle(fontSize: 16, letterSpacing: 3, color: NesaroColors.muted),
        ),
        SizedBox(height: 8),
        Text(
          'Respostas automáticas no Direct',
          style: TextStyle(fontSize: 15, color: NesaroColors.muted),
        ),
      ],
    );
  }
}
