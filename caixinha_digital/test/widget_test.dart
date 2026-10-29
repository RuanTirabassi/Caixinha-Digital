import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:caixinha_digital/dados/modelos.dart';
import 'package:caixinha_digital/main.dart';

void main() {
  testWidgets('app abre na tela de escolha (não fica em branco)', (tester) async {
    // Sem Supabase inicializado o InicioTela cai na tela de escolha.
    await tester.pumpWidget(const CaixinhaApp());
    await tester.pumpAndSettle();
    expect(find.text('TENHO UM CÓDIGO'), findsOneWidget);
    expect(find.text('Sou cuidador / familiar'), findsOneWidget);
  });

  test('turno sugerido pela hora', () {
    expect(turnoPelaHora(const TimeOfDay(hour: 8, minute: 0)), Turno.manha);
    expect(turnoPelaHora(const TimeOfDay(hour: 12, minute: 0)), Turno.almoco);
    expect(turnoPelaHora(const TimeOfDay(hour: 20, minute: 0)), Turno.noite);
  });

  test('conversão de hora do banco', () {
    final h = horaDoBanco('12:30:00');
    expect(h.hour, 12);
    expect(h.minute, 30);
    expect(horaParaBanco(h), '12:30');
  });
}
