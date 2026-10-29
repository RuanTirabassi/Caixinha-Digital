import 'package:flutter/material.dart';

import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import '../inicio_tela.dart';
import 'criar_idoso_tela.dart';
import 'dados_cuidador_tela.dart';
import 'painel_tela.dart';

/// Cuidador / 01 Sem usuário — primeiro cadastro feito pelo cuidador.
class PrimeiroAcessoTela extends StatelessWidget {
  /// true quando aberta pelas Configurações ("+ Adicionar pessoa").
  final bool adicionando;
  const PrimeiroAcessoTela({super.key, this.adicionando = false});

  Future<void> _codigoExistente(BuildContext context) async {
    final ctrl = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Adicionar usuário existente'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Peça o "código para cuidadores" a quem já acompanha a pessoa.'),
          const SizedBox(height: 12),
          TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 8),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Adicionar')),
        ],
      ),
    );
    if (codigo == null || codigo.trim().isEmpty || !context.mounted) return;
    try {
      final id = await Repo.vincularCuidador(codigo);
      final perfil = await Repo.meuPerfil();
      if (!context.mounted) return;
      void painel(BuildContext ctx) => Navigator.of(ctx)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => PainelTela(idosoId: id)), (_) => false);
      if (perfil == null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DadosCuidadorTela(aoConcluir: painel)));
      } else {
        painel(context);
      }
    } catch (e) {
      if (context.mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget botao(String texto, double fonte, VoidCallback onTap) => Material(
          color: Cores.cartao,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 58,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add, size: 28, color: Cores.texto),
                const SizedBox(width: 14),
                Text(texto, style: Estilos.cuidadorCorpo.copyWith(fontSize: fonte)),
              ]),
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(children: [
            if (adicionando)
              const BotaoVoltar()
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await Repo.sair();
                    if (!context.mounted) return;
                    Navigator.of(context)
                        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InicioTela()), (_) => false);
                  },
                  child: const Text('Sair'),
                ),
              ),
            const Spacer(),
            Text(adicionando ? 'Adicionar pessoa' : 'Sem usuário cadastrado',
                style: Estilos.cuidadorTitulo.copyWith(fontSize: 24)),
            Text('Primeiro cadastro pelo cuidador', style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
            const SizedBox(height: 20),
            botao('Criar usuário', 20, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CriarIdosoTela()));
            }),
            const SizedBox(height: 20),
            botao('Adicionar usuário existente', 16, () => _codigoExistente(context)),
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }
}
