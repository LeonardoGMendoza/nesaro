import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesaro/widgets/nesaro_logo.dart';

// O teste padrão do `flutter create` usava `MyApp`, que não existe aqui.
// Este teste não depende do Firebase: só confere que o logotipo renderiza.
void main() {
  testWidgets('Wordmark mostra o nome AliceFlow e o logotipo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: NesaroWordmark()))),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Flow'), findsOneWidget);
    expect(find.byType(NesaroLogo), findsOneWidget);
  });
}
