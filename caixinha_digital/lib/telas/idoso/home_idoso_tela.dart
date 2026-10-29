import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import '../inicio_tela.dart';
import 'consulta_tela.dart';
import 'tomar_remedio_tela.dart';

/// Idoso / 02 Tela inicial — a "caixinha" de remédios (RF01, RF06).
class HomeIdosoTela extends StatefulWidget {
  final String idosoId;
  const HomeIdosoTela({super.key, required this.idosoId});

  @override
  State<HomeIdosoTela> createState() => _HomeIdosoTelaState();
}

class _HomeIdosoTelaState extends State<HomeIdosoTela> {
  Idoso? _idoso;
  List<DoseHoje> _doses = [];
  Object? _erro;
  Timer? _relogio;
  DateTime _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregar();
    Repo.registrarUso(widget.idosoId);
    // Atualiza a cada minuto (troca de turno, zera à meia-noite).
    _relogio = Timer.periodic(const Duration(minutes: 1), (_) => _carregar());
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final idoso = await Repo.buscarIdoso(widget.idosoId);
      final doses = await Repo.dosesDeHoje(widget.idosoId);
      if (!mounted) return;
      setState(() {
        _idoso = idoso;
        _doses = doses;
        _agora = DateTime.now();
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  String _saudacao() {
    final h = _agora.hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _abrirTurno(Turno t) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TomarRemedioTela(idoso: _idoso!, turno: t),
    ));
    _carregar();
  }

  Future<void> _sair() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sair deste celular?'),
        content: Text('Para entrar de novo você vai precisar de um código novo de quem cuida de você.',
            style: Estilos.idosoCorpo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ficar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok != true) return;
    await Repo.sair();
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InicioTela()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_idoso == null) {
      return Scaffold(
        body: Center(
          child: _erro == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(mensagemDeErro(_erro!), textAlign: TextAlign.center, style: Estilos.idosoCorpo),
                    const SizedBox(height: 16),
                    Botao('Tentar de novo', onPressed: _carregar),
                  ]),
                ),
        ),
      );
    }

    final idoso = _idoso!;
    final atual = idoso.turnoAgora(_agora);
    final data = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_agora);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(idoso.escalaLetra)),
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 24), children: [
              // ---------- Cabeçalho ----------
              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: 'Sair deste celular',
                  child: TextButton.icon(
                    onPressed: _sair,
                    icon: const Icon(Icons.logout, size: 26, color: Cores.texto),
                    label: Text('Sair', style: Estilos.idosoCorpo.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              Text('${_saudacao()}, ${idoso.nomeTratamento}!', style: Estilos.idosoTitulo),
              const SizedBox(height: 4),
              Text('${capitalizarPalavras(data)}.', style: Estilos.idosoCorpo),
              const SizedBox(height: 4),
              Row(children: [
                IconeTurno(atual, tamanho: 28, titulo: true),
                Expanded(
                  child: Text('  •  ${atual.nome} • ${DateFormat.Hm().format(_agora)}',
                      style: Estilos.idosoTitulo),
                ),
              ]),
              const SizedBox(height: 20),
              _cardProgresso(),
              const SizedBox(height: 16),
              _cardCaixinha(atual),
              const SizedBox(height: 16),
              _cardConsulta(idoso),
              const SizedBox(height: 16),
              _faixaStatus(atual),
            ]),
          ),
        ),
      ),
    );
  }

  // ---------- Progresso do dia (RF06) ----------
  Widget _cardProgresso() {
    final tomados = _doses.where((d) => d.tomado).length;
    final total = _doses.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text.rich(
          TextSpan(style: Estilos.idosoCorpo.copyWith(fontSize: 22), children: [
            const TextSpan(text: 'Hoje: '),
            TextSpan(text: '$tomados de $total', style: const TextStyle(fontWeight: FontWeight.w700)),
            const TextSpan(text: ' tomados'),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconeTurno(Turno.manha),
            IconeTurno(Turno.almoco),
            IconeTurno(Turno.noite),
          ]),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final fracao = total == 0 ? 0.0 : tomados / total;
          return Stack(children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                  color: total == 0 ? Cores.neutro : Cores.pendente,
                  borderRadius: BorderRadius.circular(23)),
            ),
            Container(
              height: 16,
              width: c.maxWidth * fracao,
              decoration: BoxDecoration(color: Cores.tomado, borderRadius: BorderRadius.circular(23)),
            ),
          ]);
        }),
      ]),
    );
  }

  // ---------- Caixinha + TOMAR REMÉDIO ----------
  Widget _cardCaixinha(Turno atual) {
    return Material(
      color: Cores.acao,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirTurno(atual),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 20, 22, 16),
          child: Column(children: [
            AspectRatio(
              aspectRatio: 267 / 116,
              child: Stack(children: [
                const Positioned.fill(child: _Caixinha()),
                // os três compartimentos também abrem o turno certo
                Row(children: [
                  for (final t in Turno.values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Remédios ${t.doTurno}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _abrirTurno(t),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Text('TOMAR REMÉDIO', style: Estilos.idosoBotao.copyWith(color: Cores.textoSobreAcao)),
          ]),
        ),
      ),
    );
  }

  // ---------- Consulta de hoje (RF05) ----------
  Widget _cardConsulta(Idoso idoso) {
    final branco = Cores.textoSobreAcao;
    return Material(
      color: Cores.acaoEscura,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ConsultaTela(idosoId: idoso.id))),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 89),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              SvgPicture.asset('assets/figma/estetoscopio.svg', width: 22, height: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(children: [
                  Text('CONSULTA DE HOJE',
                      textAlign: TextAlign.center, style: Estilos.idosoBotao.copyWith(color: branco)),
                  Text('Veja suas receitas e exames',
                      textAlign: TextAlign.center, style: Estilos.idosoCorpo.copyWith(color: branco)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ---------- Faixa de status ----------
  Widget _faixaStatus(Turno atual) {
    final pendentesAgora = _doses.where((d) => d.turno == atual && !d.tomado).isNotEmpty;
    final atrasados = _doses.where((d) => d.status == 'atrasado').toList();
    String texto;
    Color fundo;
    Color cor = Cores.texto;
    if (_doses.isEmpty) {
      texto = 'Nenhum remédio cadastrado';
      fundo = Cores.cartao;
    } else if (pendentesAgora) {
      texto = 'Falta tomar o remédio ${atual.doTurno}';
      fundo = Cores.faltaTomar;
    } else if (atrasados.isNotEmpty) {
      texto = 'Falta tomar: ${atrasados.map((d) => d.nome).join(', ')}';
      fundo = Cores.faltaTomar;
    } else {
      texto = 'Seus remédios estão em dia';
      fundo = Cores.emDia;
      cor = Cores.tomadoTexto;
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(16)),
      child: Text(texto, textAlign: TextAlign.center, style: Estilos.idosoDestaque.copyWith(color: cor)),
    );
  }
}

/// Ilustração da caixinha de remédios do Figma (5 camadas SVG, posições em %).
class _Caixinha extends StatelessWidget {
  const _Caixinha();

  // [arquivo, topo, direita, baixo, esquerda] — insets do Figma
  static const _camadas = [
    ['caixinha_1', 0.0, 12.93, 86.3, 12.64],
    ['caixinha_2', 0.0, 12.96, 86.3, 12.67],
    ['caixinha_3', 8.6, 0.0, 0.02, 0.0],
    ['caixinha_4', 14.37, 2.74, 8.0, 2.74],
    ['caixinha_5', 8.61, 0.0, 0.0, 0.0],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      return Stack(children: [
        for (final l in _camadas)
          Positioned(
            top: h * (l[1] as double) / 100,
            right: w * (l[2] as double) / 100,
            bottom: h * (l[3] as double) / 100,
            left: w * (l[4] as double) / 100,
            child: SvgPicture.asset('assets/figma/${l[0]}.svg', fit: BoxFit.fill),
          ),
      ]);
    });
  }
}
