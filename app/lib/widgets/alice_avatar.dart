import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'motion.dart';

/// Foto da Alice, a personagem da marca (mesma das artes de divulgação).
const aliceImage = AssetImage('assets/brand/alice.jpg');

/// Alice em um círculo, para o cartão do painel e outros pontos pequenos.
class AliceAvatar extends StatelessWidget {
  const AliceAvatar({super.key, this.size = 120, this.ring = true});

  final double size;

  /// Anel com o gradiente da marca em volta da foto.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final photo = ClipOval(
      child: Image(
        image: aliceImage,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.35),
        semanticLabel: 'Alice, assistente da AliceFlow',
      ),
    );
    if (!ring) return photo;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: NesaroColors.brandGradient),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: photo,
      ),
    );
  }
}

/// Alice com a conversa das artes: a pessoa pede informação no comentário
/// e a AliceFlow responde no Direct na hora.
class AliceShowcase extends StatelessWidget {
  const AliceShowcase({super.key, this.photoWidth = 240, this.height = 320});

  final double photoWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: photoWidth,
            child: FadeSlideIn(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: const Image(
                  image: aliceImage,
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.4),
                  semanticLabel: 'Alice, assistente da AliceFlow',
                ),
              ),
            ),
          ),
          Positioned(
            left: photoWidth - 40,
            right: 0,
            top: height * 0.18,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  delay: Duration(milliseconds: 500),
                  child: _Bubble(
                    icon: Icons.person,
                    text: 'Gostaria de mais informações!',
                    fromBot: false,
                  ),
                ),
                SizedBox(height: 12),
                FadeSlideIn(
                  delay: Duration(milliseconds: 1100),
                  child: _Bubble(
                    icon: Icons.smart_toy_outlined,
                    text: 'Oi! Claro! Vou te enviar todas as informações no seu Direct 😊',
                    fromBot: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, required this.text, required this.fromBot});

  final IconData icon;
  final String text;
  final bool fromBot;

  @override
  Widget build(BuildContext context) {
    final bg = fromBot ? const Color(0xFF221A6E) : Colors.white;
    final fg = fromBot ? Colors.white : NesaroColors.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(fromBot ? 18 : 4),
          bottomRight: const Radius.circular(18),
        ),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: fromBot ? Colors.white.withValues(alpha: 0.15) : NesaroColors.sakuraMist,
            child: Icon(icon, size: 16, color: fromBot ? Colors.white : NesaroColors.violet),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: fg, fontSize: 14, height: 1.35, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
