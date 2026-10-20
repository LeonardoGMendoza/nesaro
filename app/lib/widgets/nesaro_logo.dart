import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Símbolo da AliceFlow: balão de conversa com um raio no meio
/// (a resposta automática que sai na hora).
///
/// Com [animated] = true, o balão se desenha, o raio "acende" com um pulo
/// e depois pulsa de leve, sem parar. Desenhado em código: não precisa de imagem.
///
/// Por padrão usa o gradiente da marca (azul → roxo → magenta). Se [inkColor]
/// for diferente de [NesaroColors.ink], o símbolo fica de uma cor só, nessa cor
/// (ex.: branco em cima de um fundo colorido).
///
/// O nome da classe continua `NesaroLogo` para não mexer em todas as telas.
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

  /// Mantidos por compatibilidade com as telas; não são mais usados no desenho.
  final Color petalColor;
  final Color centerColor;

  @override
  State<NesaroLogo> createState() => _NesaroLogoState();
}

class _NesaroLogoState extends State<NesaroLogo> with TickerProviderStateMixin {
  AnimationController? _grow;
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _grow?.dispose();
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grow = _grow;
    final pulse = _pulse;
    final mono = widget.inkColor != NesaroColors.ink ? widget.inkColor : null;

    Widget paint(double progress, double glow) => CustomPaint(
          size: Size.square(widget.size),
          painter: _AliceFlowLogoPainter(mono: mono, progress: progress, glow: glow),
        );

    return Semantics(
      label: 'Logotipo AliceFlow',
      image: true,
      child: grow == null || pulse == null
          ? paint(1, 0)
          : AnimatedBuilder(
              animation: Listenable.merge([grow, pulse]),
              builder: (context, _) => paint(
                grow.value,
                Curves.easeInOutSine.transform(pulse.value),
              ),
            ),
    );
  }
}

class _AliceFlowLogoPainter extends CustomPainter {
  _AliceFlowLogoPainter({required this.mono, required this.progress, required this.glow});

  /// null = gradiente da marca; uma cor = símbolo de uma cor só.
  final Color? mono;

  /// 0 → nada desenhado; 1 → logo completo.
  final double progress;

  /// 0 a 1: pulso do raio.
  final double glow;

  double _phase(double start, double end) => ((progress - start) / (end - start)).clamp(0.0, 1.0);

  static const _box = Rect.fromLTWH(20, 20, 170, 170);

  Paint _brush({required PaintingStyle style, double width = 0, Gradient? gradient}) {
    final p = Paint()
      ..style = style
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    if (mono != null) {
      p.color = mono!;
    } else {
      p.shader = (gradient ?? NesaroColors.brandGradient).createShader(_box);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    // 1) Balão de conversa, com a ponta embaixo à esquerda.
    final bubble = Path()
      ..moveTo(70, 146)
      ..cubicTo(40, 128, 32, 96, 42, 70)
      ..cubicTo(56, 34, 104, 22, 142, 32)
      ..cubicTo(176, 42, 188, 80, 177, 110)
      ..cubicTo(165, 144, 124, 160, 92, 152)
      ..lineTo(60, 178)
      ..close();
    final bubbleT = Curves.easeInOutCubic.transform(_phase(0, 0.6));
    final stroke = _brush(style: PaintingStyle.stroke, width: 15);
    if (bubbleT > 0) {
      for (final m in bubble.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * bubbleT), stroke);
      }
    }

    // 2) Raio no centro: aparece com um pulo e depois pulsa.
    final boltT = Curves.easeOutBack.transform(_phase(0.5, 1));
    if (boltT > 0) {
      final bolt = Path()
        ..moveTo(124, 50)
        ..lineTo(84, 101)
        ..lineTo(107, 101)
        ..lineTo(95, 138)
        ..lineTo(135, 84)
        ..lineTo(112, 84)
        ..close();
      const c = Offset(110, 94);
      final scale = boltT * (1 + 0.05 * glow);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(scale);
      canvas.translate(-c.dx, -c.dy);

      if (mono == null && glow > 0) {
        canvas.drawPath(
          bolt,
          Paint()
            ..color = NesaroColors.magenta.withValues(alpha: 0.28 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      const boltGradient = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [NesaroColors.magenta, NesaroColors.violet],
      );
      canvas.drawPath(bolt, _brush(style: PaintingStyle.fill, gradient: boltGradient));
      canvas.drawPath(bolt, _brush(style: PaintingStyle.stroke, width: 5, gradient: boltGradient));
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AliceFlowLogoPainter old) =>
      old.progress != progress || old.glow != glow || old.mono != mono;
}

/// Logo + nome "AliceFlow" + slogan.
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
    final main = light ? Colors.white : NesaroColors.ink;
    final soft = light ? const Color(0xFFD9D6FF) : NesaroColors.muted;
    const nameStyle = TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NesaroLogo(size: logoSize, animated: animated),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Alice', style: nameStyle.copyWith(color: main)),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [NesaroColors.magenta, NesaroColors.violet, NesaroColors.blue],
              ).createShader(bounds),
              child: Text('Flow', style: nameStyle.copyWith(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Automação inteligente para Instagram',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, letterSpacing: 0.4, color: soft),
        ),
      ],
    );
  }
}

/// Nome "AliceFlow" em uma linha, para barras e menus.
class AliceFlowName extends StatelessWidget {
  const AliceFlowName({super.key, this.fontSize = 20, this.light = false});

  final double fontSize;

  /// true = "Alice" em branco, para fundos escuros.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Alice', style: style.copyWith(color: light ? Colors.white : NesaroColors.ink)),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [NesaroColors.magenta, NesaroColors.violet, NesaroColors.blue],
          ).createShader(bounds),
          child: Text('Flow', style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
