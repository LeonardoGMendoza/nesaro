import 'package:flutter/material.dart';

/// Pontos de quebra do layout. Celular < 600 ≤ tablet < 1000 ≤ computador.
class Breakpoints {
  const Breakpoints._();

  static const tablet = 600.0;
  static const desktop = 1000.0;

  static bool isPhone(BuildContext context) => MediaQuery.sizeOf(context).width < tablet;

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
}

/// Centraliza o conteúdo com largura máxima, para não esticar em telas grandes.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Grade que escolhe o número de colunas pela largura disponível.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.maxColumns = 6,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor().clamp(1, maxColumns);
        final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
        );
      },
    );
  }
}
