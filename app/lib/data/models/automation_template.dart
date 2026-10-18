import 'package:flutter/material.dart';

import 'automation.dart';

/// Modelos prontos para o cliente começar em um clique (como os concorrentes oferecem).
class AutomationTemplate {
  const AutomationTemplate({
    required this.title,
    required this.description,
    required this.icon,
    required this.name,
    required this.keyword,
    required this.dmMessage,
    this.publicReply,
  });

  final String title;
  final String description;
  final IconData icon;
  final String name;
  final String keyword;
  final String dmMessage;
  final String? publicReply;

  Automation toAutomation() => Automation(
        name: name,
        keyword: keyword,
        dmMessage: dmMessage,
        publicReply: publicReply,
      );

  static const all = <AutomationTemplate>[
    AutomationTemplate(
      title: 'Loja / produto',
      description: 'Quem comentar QUERO recebe o link do produto.',
      icon: Icons.shopping_bag_outlined,
      name: 'Link do produto',
      keyword: 'QUERO',
      dmMessage: 'Oi! Que bom que gostou 😍 Aqui está o link para comprar: {link}\nQualquer dúvida é só responder aqui.',
      publicReply: 'Te mandei o link no Direct! 💌',
    ),
    AutomationTemplate(
      title: 'Curso / infoproduto',
      description: 'Entrega a página de vendas ou a aula grátis.',
      icon: Icons.school_outlined,
      name: 'Aula grátis',
      keyword: 'AULA',
      dmMessage: 'Oi! Aqui está o acesso à aula gratuita que você pediu 🎓 {link}',
      publicReply: 'Enviado no seu Direct! 📩',
    ),
    AutomationTemplate(
      title: 'Afiliado / cupom',
      description: 'Manda o cupom e o link de afiliado.',
      icon: Icons.local_offer_outlined,
      name: 'Cupom de desconto',
      keyword: 'CUPOM',
      dmMessage: 'Seu cupom chegou! 🎁 Use o código NESARO10 neste link: {link}',
      publicReply: 'Cupom enviado no Direct 🎁',
    ),
    AutomationTemplate(
      title: 'Agendamento / serviço',
      description: 'Para salões, clínicas e prestadores de serviço.',
      icon: Icons.event_available_outlined,
      name: 'Agendar horário',
      keyword: 'AGENDAR',
      dmMessage: 'Oi! Para escolher seu horário é só tocar aqui: {link} 📅',
      publicReply: 'Te chamei no Direct para agendar 😉',
    ),
    AutomationTemplate(
      title: 'Material gratuito',
      description: 'E-book, planilha ou PDF para captar contatos.',
      icon: Icons.menu_book_outlined,
      name: 'Material gratuito',
      keyword: 'MATERIAL',
      dmMessage: 'Aqui está o material que você pediu 📘 {link}\nAproveite!',
    ),
    AutomationTemplate(
      title: 'Grupo do WhatsApp',
      description: 'Convida para o grupo VIP ou de promoções.',
      icon: Icons.groups_outlined,
      name: 'Grupo VIP',
      keyword: 'GRUPO',
      dmMessage: 'Bem-vindo(a)! Entre no nosso grupo VIP por aqui: {link} 🚀',
    ),
  ];
}
