import 'package:flutter/material.dart';

import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import 'cadastro_efetuado_tela.dart';
import 'dados_cuidador_tela.dart';

/// Cuidador / 02 Adicionar usuário — dados de quem recebe o cuidado.
class CriarIdosoTela extends StatefulWidget {
  const CriarIdosoTela({super.key});

  @override
  State<CriarIdosoTela> createState() => _CriarIdosoTelaState();
}

class _CriarIdosoTelaState extends State<CriarIdosoTela> {
  final _nome = TextEditingController();
  final _sobrenome = TextEditingController();
  final _whats = TextEditingController();
  String _tratamento = 'nenhum';
  bool _salvando = false;

  Future<void> _continuar() async {
    if (_nome.text.trim().isEmpty) {
      mostrarAviso(context, 'Informe o nome.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final whats = _whats.text.replaceAll(RegExp(r'\D'), '');
      final idoso = await Repo.criarIdoso(
        nome: _nome.text,
        sobrenome: _sobrenome.text,
        tratamento: _tratamento,
        whatsapp: whats.isEmpty ? null : '55$whats',
      );
      final perfil = await Repo.meuPerfil();
      if (!mounted) return;
      void concluido(BuildContext ctx) => Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CadastroEfetuadoTela(idosoId: idoso.id)), (_) => false);
      if (perfil == null) {
        // primeiro cadastro: agora os dados de quem cuida (Cuidador / 03)
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DadosCuidadorTela(aoConcluir: concluido)));
      } else {
        concluido(context);
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 32, 22, 24), children: [
          Text('Adicionar Usuário',
              textAlign: TextAlign.center, style: Estilos.cuidadorTitulo.copyWith(fontSize: 24)),
          const SizedBox(height: 24),
          Text('Adicione as informações do receptor do cuidado:', style: Estilos.cuidadorCorpo),
          const Rotulo('Nome'),
          TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              style: Estilos.cuidadorCorpo,
              decoration: const InputDecoration(hintText: 'Ex.: Maria Antônia')),
          const Rotulo('Sobrenome'),
          TextField(
              controller: _sobrenome,
              textCapitalization: TextCapitalization.words,
              style: Estilos.cuidadorCorpo,
              decoration: const InputDecoration(hintText: 'Ex.: Ferreira da Silva')),
          const Rotulo('Referir-se como'),
          GrupoOpcoes<String>(
            opcoes: const {'nenhum': 'Nenhum', 'senhor': 'Senhor', 'senhora': 'Senhora'},
            valor: _tratamento,
            onChanged: (v) => setState(() => _tratamento = v),
          ),
          const Rotulo('Contato/WhatsApp'),
          CampoWhatsApp(controller: _whats),
          const SizedBox(height: 120),
          Botao('Continuar', carregando: _salvando, onPressed: _continuar),
        ]),
      ),
    );
  }
}
