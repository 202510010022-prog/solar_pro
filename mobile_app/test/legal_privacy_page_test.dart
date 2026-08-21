import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/screens/legal_privacy_page.dart';

void main() {
  testWidgets('renders legal and privacy hub actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalPrivacyPage(profile: null)),
    );

    expect(find.text('Legal, FAQ e Privacidade'), findsOneWidget);
    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.text('Excluir minha conta e dados'), findsOneWidget);
    expect(find.text('FAQ e suporte'), findsOneWidget);
  });

  test('deletion email body includes only safe profile fields', () {
    final body = deletionRequestEmailBody(null);

    expect(body, contains('Solar Pro'));
    expect(body, contains('Nome: Não informado'));
    expect(body, contains('E-mail: Não informado'));
    expect(body, contains('Empresa/Company ID: Não informado'));
    expect(body, isNot(contains('token')));
    expect(body, isNot(contains('senha')));
  });
}
