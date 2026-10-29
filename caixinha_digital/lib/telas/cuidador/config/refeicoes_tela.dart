import 'package:flutter/material.dart';

import '../../../dados/modelos.dart';
import '../../../dados/repositorio.dart';
import '../../../tema.dart';
import '../../../widgets/comuns.dart';

/// Config / 01 Horários das refeições.
class RefeicoesTela extends StatefulWidget {
  final Idoso idoso;
  const RefeicoesTela({super.key, required this.idoso});

  @override
  State<RefeicoesTela> createState() => _RefeicoesTelaState();
}

class _RefeicoesTelaState extends State<RefeicoesTela> {
  late final Map<Turno, TimeOfDay> _horas = {
    for (final t in Turno.values) t: widget.idoso.horaDoTurno(t),
  };
  bool _salvando = false;

  Future<void> _escolher(Turno t) async {
    final n = await showTimePicker(context: context, initialTime: _horas[t]!);
    if (n != null) setState(() => _horas[t] = n);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await Repo.atualizarRefeicoes(
          widget.idoso.id, _horas[Turno.manha]!, _horas[Turno.almoco]!, _horas[Turno.noite]!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.idoso;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 22),
          Text('Horários das refeições', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 14),
          Text(
              'Os lembretes ${i.daDo} ${i.nomeTratamento} seguem estes horários. Ao cadastrar um '
              'remédio, o horário escolhido marca o turno sozinho.',
              style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
          const SizedBox(height: 16),
          for (final t in Turno.values)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                IconeTurno(t, tamanho: 24, titulo: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.nome, style: Estilos.cuidadorRotulo),
                    Text('${t.refeicao} • ${t.faixa}', style: Estilos.cuidadorLegenda.copyWith(fontSize: 10)),
                  ]),
                ),
                Semantics(
                  button: true,
                  label: 'Horário ${t.nome}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _escolher(t),
                    child: Container(
                      width: 78,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Cores.borda),
                      ),
                      child: Text(horaTexto(_horas[t]!), style: Estilos.cuidadorTitulo),
                    ),
                  ),
                ),
              ]),
            ),
          Text(
              'Remédios que estavam no horário da refeição passam a ser lembrados no novo horário.',
              style: Estilos.cuidadorLegenda.copyWith(fontSize: 10, color: Cores.texto)),
          const SizedBox(height: 14),
          Botao('Salvar horários', altura: 46, carregando: _salvando, onPressed: _salvar),
        ]),
      ),
    );
  }
}
