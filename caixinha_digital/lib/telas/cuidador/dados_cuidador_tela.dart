import 'package:flutter/material.dart';

import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Cuidador / 03 Dados do cuidador ("Adicionar Cuidador").
/// O nome e o WhatsApp aparecem em "Quem recebe" e "Celulares conectados".
class DadosCuidadorTela extends StatefulWidget {
  /// Para onde ir depois de salvar (cadastro efetuado ou painel).
  final void Function(BuildContext context) aoConcluir;
  const DadosCuidadorTela({super.key, required this.aoConcluir});

  @override
  State<DadosCuidadorTela> createState() => _DadosCuidadorTelaState();
}

class _DadosCuidadorTelaState extends State<DadosCuidadorTela> {
  final _nome = TextEditingController();
  final _sobrenome = TextEditingController();
  final _whats = TextEditingController();
  bool _salvando = false;

  Future<void> _continuar() async {
    if (_nome.text.trim().isEmpty) {
      mostrarAviso(context, 'Informe o seu nome.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final whats = _whats.text.replaceAll(RegExp(r'\D'), '');
      await Repo.salvarPerfil(
        nome: _nome.text,
        sobrenome: _sobrenome.text,
        whatsapp: whats.isEmpty ? null : '55$whats',
      );
      if (mounted) widget.aoConcluir(context);
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
          Text('Adicionar Cuidador',
              textAlign: TextAlign.center, style: Estilos.cuidadorTitulo.copyWith(fontSize: 24)),
          const SizedBox(height: 24),
          Text('Adicione as informações do cuidador:', style: Estilos.cuidadorCorpo),
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
          const Rotulo('Contato/WhatsApp'),
          CampoWhatsApp(controller: _whats),
          const SizedBox(height: 200),
          Botao('Continuar', carregando: _salvando, onPressed: _continuar),
        ]),
      ),
    );
  }
}
