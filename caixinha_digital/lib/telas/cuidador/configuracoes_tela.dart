import 'package:flutter/material.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import '../inicio_tela.dart';
import 'config/acesso_tela.dart';
import 'config/avisos_tela.dart';
import 'config/celular_tela.dart';
import 'config/privacidade_tela.dart';
import 'config/refeicoes_tela.dart';
import 'primeiro_acesso_tela.dart';

/// Config / 00 Configurações. Ao tocar em outra pessoa, devolve o id dela ao painel.
class ConfiguracoesTela extends StatefulWidget {
  final Idoso idoso;
  final List<Idoso> pessoas;
  const ConfiguracoesTela({super.key, required this.idoso, required this.pessoas});

  @override
  State<ConfiguracoesTela> createState() => _ConfiguracoesTelaState();
}

class _ConfiguracoesTelaState extends State<ConfiguracoesTela> {
  late Idoso _i = widget.idoso;

  Future<void> _recarregar() async {
    try {
      final novo = await Repo.buscarIdoso(_i.id);
      if (mounted) setState(() => _i = novo);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _atualizar(Map<String, dynamic> dados) async {
    try {
      await Repo.atualizarIdoso(_i.id, dados);
      await _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _abrir(Widget tela) async {
    final r = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    if (!mounted) return;
    // Privacidade > Apagar todos os dados: volta ao início
    if (r == 'apagado') {
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InicioTela()), (_) => false);
      return;
    }
    _recarregar();
  }

  Future<void> _sair() async {
    await Repo.sair();
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InicioTela()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final nome = _i.nomeTratamento;
    final daDo = _i.daDo;

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 22),
          Text('Configurações', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 14),
          Secao(titulo: 'Pessoas que você acompanha', filhos: [
            Linhas([
              for (final p in widget.pessoas)
                LinhaNavegacao(
                  titulo: p.nomeCompletoTratamento,
                  detalhe: 'Toque para ver o painel ${p.delaDele}',
                  onTap: () => Navigator.pop(context, p.id),
                ),
            ]),
            const SizedBox(height: 8),
            Botao('+ Adicionar pessoa',
                altura: 46,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const PrimeiroAcessoTela(adicionando: true)))),
          ]),
          Secao(titulo: 'Rotina $daDo $nome', filhos: [
            LinhaNavegacao(
              titulo: 'Horários das refeições',
              detalhe:
                  'Café ${horaTexto(_i.horaCafe)} • Almoço ${horaTexto(_i.horaAlmoco)} • Jantar ${horaTexto(_i.horaJantar)}',
              onTap: () => _abrir(RefeicoesTela(idoso: _i)),
            ),
          ]),
          Secao(titulo: 'Avisos para você', filhos: [
            Linhas([
              LinhaNavegacao(
                  titulo: 'Remédio não marcado', detalhe: _i.resumoAviso, onTap: () => _abrir(AvisosTela(idoso: _i))),
              LinhaComInterruptor(
                titulo: 'Resumo do dia',
                detalhe: 'Uma mensagem às 21:00',
                valor: _i.resumoDiario,
                onChanged: (v) => _atualizar({'resumo_diario': v}),
              ),
            ]),
          ]),
          Secao(titulo: 'Celular $daDo $nome', filhos: [
            Linhas([
              LinhaNavegacao(
                  titulo: 'Tamanho da letra',
                  detalhe: _i.tamanhoLetraTexto,
                  onTap: () => _abrir(CelularTela(idoso: _i))),
              LinhaComInterruptor(
                titulo: 'Som do lembrete',
                detalhe: 'Toca quando chega a hora',
                valor: _i.som,
                onChanged: (v) => _atualizar({'som': v}),
              ),
              LinhaComInterruptor(
                titulo: 'Vibração',
                detalhe: 'Vibra ao lembrar e ao confirmar',
                valor: _i.vibracao,
                onChanged: (v) => _atualizar({'vibracao': v}),
              ),
            ]),
          ]),
          Secao(titulo: 'Conta e segurança', filhos: [
            Linhas([
              LinhaNavegacao(
                  titulo: 'Acesso e aparelhos',
                  detalhe: 'Código, link e celulares conectados',
                  onTap: () => _abrir(AcessoTela(idoso: _i))),
              LinhaNavegacao(
                  titulo: 'Privacidade e dados',
                  detalhe: 'Consentimento, baixar ou apagar dados',
                  onTap: () => _abrir(PrivacidadeTela(idoso: _i))),
            ]),
          ]),
          Botao('Sair desta conta', tipo: TipoBotao.risco, altura: 46, onPressed: _sair),
          const SizedBox(height: 16),
          Center(child: Text('Caixinha Digital • versão 1.0', style: Estilos.cuidadorLegenda.copyWith(color: Cores.texto))),
        ]),
      ),
    );
  }
}
