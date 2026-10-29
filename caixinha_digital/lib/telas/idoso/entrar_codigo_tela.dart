import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import 'home_idoso_tela.dart';

/// RF02 — Acesso sem senha: o código de 6 números (ou o link) que o cuidador enviou.
/// O código vale 10 minutos e só entra uma vez.
class EntrarCodigoTela extends StatefulWidget {
  final String? codigoInicial;
  const EntrarCodigoTela({super.key, this.codigoInicial});

  @override
  State<EntrarCodigoTela> createState() => _EntrarCodigoTelaState();
}

class _EntrarCodigoTelaState extends State<EntrarCodigoTela> {
  final _codigo = TextEditingController();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    if (widget.codigoInicial != null) {
      _codigo.text = widget.codigoInicial!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _entrar());
    }
  }

  Future<void> _entrar() async {
    final c = _codigo.text.replaceAll(RegExp(r'\D'), '');
    if (c.length != 6) {
      mostrarAviso(context, 'O código tem 6 números.');
      return;
    }
    setState(() => _carregando = true);
    try {
      final id = await Repo.entrarComoIdoso(c);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeIdosoTela(idosoId: id)),
        (_) => false,
      );
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), children: [
          if (Navigator.of(context).canPop()) const BotaoVoltar(),
          const SizedBox(height: 25),
          Text('Digite o seu código', style: Estilos.idosoTitulo),
          const SizedBox(height: 8),
          Text('São 6 números. Quem cuida de você mandou pelo WhatsApp.', style: Estilos.idosoCorpo),
          const SizedBox(height: 28),
          TextField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Estilos.idosoTitulo.copyWith(fontSize: 40, letterSpacing: 10),
            decoration: const InputDecoration(
                counterText: '', hintText: '000000', contentPadding: EdgeInsets.symmetric(vertical: 14)),
            onSubmitted: (_) => _entrar(),
          ),
          const SizedBox(height: 28),
          Botao('ENTRAR',
              tipo: TipoBotao.whatsapp,
              estilo: Estilos.idosoBotao,
              carregando: _carregando,
              onPressed: _entrar),
        ]),
      ),
    );
  }
}
