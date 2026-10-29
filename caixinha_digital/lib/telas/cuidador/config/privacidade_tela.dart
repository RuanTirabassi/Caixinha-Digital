import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../dados/baixar_arquivo.dart';
import '../../../dados/modelos.dart';
import '../../../dados/repositorio.dart';
import '../../../tema.dart';
import '../../../widgets/comuns.dart';

/// Config / 05 Privacidade e dados (LGPD).
/// Devolve 'apagado' para as Configurações quando a pessoa é apagada.
class PrivacidadeTela extends StatefulWidget {
  final Idoso idoso;
  const PrivacidadeTela({super.key, required this.idoso});

  @override
  State<PrivacidadeTela> createState() => _PrivacidadeTelaState();
}

class _PrivacidadeTelaState extends State<PrivacidadeTela> {
  Cuidador? _perfil;
  bool _baixando = false;
  bool _apagando = false;

  static const _guardado = [
    'Remédios, doses e horários cadastrados',
    'Quando cada dose foi marcada como tomada',
    'Fotos de receitas, exames e caixas de remédio',
    'Nomes e WhatsApp de quem cuida',
  ];

  @override
  void initState() {
    super.initState();
    Repo.meuPerfil().then((p) {
      if (mounted) setState(() => _perfil = p);
    }).catchError((Object e) {
      if (mounted) mostrarErro(context, e);
    });
  }

  Future<void> _autorizarWhatsapp(bool v) async {
    try {
      await Repo.definirAutorizaWhatsapp(v);
      final p = await Repo.meuPerfil();
      if (mounted) setState(() => _perfil = p);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _baixar() async {
    setState(() => _baixando = true);
    try {
      final dados = await Repo.exportarDados(widget.idoso.id);
      final json = const JsonEncoder.withIndent('  ').convert(dados);
      final baixou = await baixarArquivo('caixinha-${widget.idoso.primeiroNome.toLowerCase()}.json', json);
      if (mounted) {
        mostrarAviso(context, baixou ? 'Cópia dos dados baixada.' : 'Cópia dos dados copiada. Cole onde quiser guardar.');
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  Future<void> _apagar() async {
    final i = widget.idoso;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar todos os dados?'),
        content: Text('Remédios, doses, receitas, exames e fotos ${i.daDo} ${i.nomeTratamento} serão '
            'apagados para todos os cuidadores. Isso não pode ser desfeito.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Apagar tudo', style: TextStyle(color: Cores.alerta)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _apagando = true);
    try {
      await Repo.apagarTudo(i.id);
      if (mounted) Navigator.pop(context, 'apagado');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _apagando = false);
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
          Text('Privacidade e dados', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 14),
          Text(
              'Remédios, receitas e exames são dados de saúde e, pela LGPD, só ficam guardados com a sua autorização.',
              style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
          const SizedBox(height: 16),
          Secao(titulo: 'O que fica guardado', filhos: [
            for (final g in _guardado)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $g', style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
              ),
          ]),
          Secao(titulo: 'Autorizações', filhos: [
            Linhas([
              LinhaComInterruptor(
                titulo: 'Guardar dados de saúde',
                detalhe: 'Necessário para o app funcionar',
                valor: true,
                onChanged: (_) => mostrarAviso(context,
                    'Sem esta autorização o app não funciona. Para não guardar mais nada, use “Apagar todos os dados”.'),
              ),
              LinhaComInterruptor(
                titulo: 'Avisos pelo WhatsApp',
                detalhe: 'Você pode desligar quando quiser',
                valor: _perfil?.autorizaWhatsapp ?? false,
                onChanged: _perfil == null ? null : _autorizarWhatsapp,
              ),
              LinhaNavegacao(
                titulo: 'Ler o termo de uso',
                detalhe: 'Versão de 20/10/2026',
                onTap: () => showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Termo de uso'),
                    content: SingleChildScrollView(
                      child: Text(
                          'A Caixinha Digital guarda só o necessário para organizar os remédios:\n\n'
                          '${_guardado.map((g) => '• $g').join('\n')}\n\n'
                          'A Caixinha só organiza o que o médico receitou. Ela não sugere e nem muda as doses.\n\n'
                          'Você pode baixar uma cópia ou apagar todos os dados quando quiser, nesta tela.'),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                  ),
                ),
              ),
            ]),
          ]),
          Secao(titulo: 'Seus dados', filhos: [
            Botao('Baixar uma cópia dos dados',
                tipo: TipoBotao.secundario, altura: 46, carregando: _baixando, onPressed: _baixar),
            const SizedBox(height: 14),
            Botao('Apagar todos os dados',
                tipo: TipoBotao.risco, altura: 46, carregando: _apagando, onPressed: _apagar),
            const SizedBox(height: 10),
            Text(
                'Apagar remove tudo ${i.daDo} ${i.nomeTratamento} para todos os cuidadores. Isso não pode ser desfeito.',
                style: Estilos.cuidadorLegenda.copyWith(fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}
