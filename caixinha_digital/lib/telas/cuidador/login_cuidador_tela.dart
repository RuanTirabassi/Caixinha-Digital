import 'package:flutter/material.dart';

import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import '../inicio_tela.dart';

/// Login do cuidador (e-mail e senha). A complexidade fica com ele, não com o idoso.
class LoginCuidadorTela extends StatefulWidget {
  const LoginCuidadorTela({super.key});

  @override
  State<LoginCuidadorTela> createState() => _LoginCuidadorTelaState();
}

class _LoginCuidadorTelaState extends State<LoginCuidadorTela> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _criarConta = false;
  bool _carregando = false;

  Future<void> _enviar() async {
    if (!_email.text.contains('@') || _senha.text.length < 6) {
      mostrarAviso(context, 'Informe um e-mail válido e senha com 6+ caracteres.');
      return;
    }
    setState(() => _carregando = true);
    try {
      if (_criarConta) {
        await Repo.cadastrarCuidador(_email.text, _senha.text);
      } else {
        await Repo.loginCuidador(_email.text, _senha.text);
      }
      if (!mounted) return;
      // InicioTela decide se vai para o painel ou para o primeiro acesso.
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InicioTela()), (_) => false);
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
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 32, 22, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 24),
          Text(_criarConta ? 'Criar conta de cuidador' : 'Entrar como cuidador',
              textAlign: TextAlign.center, style: Estilos.cuidadorTitulo.copyWith(fontSize: 24)),
          const SizedBox(height: 16),
          Text('Você cadastra os remédios e acompanha as doses.', style: Estilos.cuidadorCorpo),
          const Rotulo('E-mail'),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: Estilos.cuidadorCorpo,
            decoration: const InputDecoration(hintText: 'voce@email.com'),
          ),
          const Rotulo('Senha'),
          TextField(
            controller: _senha,
            obscureText: true,
            style: Estilos.cuidadorCorpo,
            decoration: const InputDecoration(hintText: 'Mínimo 6 caracteres'),
            onSubmitted: (_) => _enviar(),
          ),
          const SizedBox(height: 32),
          Botao(_criarConta ? 'Criar conta' : 'Entrar', carregando: _carregando, onPressed: _enviar),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _criarConta = !_criarConta),
            child: Text(_criarConta ? 'Já tenho conta' : 'Ainda não tenho conta',
                style: Estilos.cuidadorCorpo.copyWith(color: Cores.acao)),
          ),
        ]),
      ),
    );
  }
}
