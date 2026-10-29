import 'package:flutter/material.dart';

import '../dados/repositorio.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import 'cuidador/login_cuidador_tela.dart';
import 'cuidador/painel_tela.dart';
import 'cuidador/primeiro_acesso_tela.dart';
import 'idoso/entrar_codigo_tela.dart';
import 'idoso/home_idoso_tela.dart';

/// Decide para onde ir ao abrir o app:
/// - idoso já conectado  -> Caixinha (home do idoso)
/// - cuidador logado     -> Painel (ou primeiro acesso)
/// - ninguém             -> escolher "Sou eu que tomo" / "Sou cuidador"
class InicioTela extends StatefulWidget {
  final String? codigoInicial;
  const InicioTela({super.key, this.codigoInicial});

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decidir());
  }

  Future<void> _decidir() async {
    // Abriu pelo link do WhatsApp: entra direto com o código.
    if (widget.codigoInicial != null) {
      _irPara(EntrarCodigoTela(codigoInicial: widget.codigoInicial));
      return;
    }
    try {
      final r = await Repo.meuPapel();
      if (!mounted) return;
      if (r.papel == 'idoso') {
        _irPara(HomeIdosoTela(idosoId: r.idosoId!));
      } else if (r.papel == 'cuidador') {
        _irPara(r.idosoId == null
            ? const PrimeiroAcessoTela()
            : PainelTela(idosoId: r.idosoId!));
      } else {
        setState(() => _mostrarEscolha = true);
      }
    } catch (_) {
      if (mounted) setState(() => _mostrarEscolha = true);
    }
  }

  bool _mostrarEscolha = false;

  void _irPara(Widget tela) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrarEscolha) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
            const Icon(Icons.inventory_2, size: 72, color: Cores.acao),
            const SizedBox(height: 12),
            Text('Caixinha Digital',
                textAlign: TextAlign.center, style: Estilos.idosoTitulo.copyWith(fontSize: 30)),
            const SizedBox(height: 8),
            Text('Seus remédios organizados, sem complicação.',
                textAlign: TextAlign.center, style: Estilos.idosoCorpo),
            const SizedBox(height: 40),
            Botao('TENHO UM CÓDIGO',
                estilo: Estilos.idosoBotao,
                icone: Icons.medication,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const EntrarCodigoTela()))),
            const SizedBox(height: 8),
            Text('Para quem toma os remédios',
                textAlign: TextAlign.center, style: Estilos.cuidadorCorpo),
            const SizedBox(height: 28),
            Botao('Sou cuidador / familiar',
                tipo: TipoBotao.secundario,
                icone: Icons.family_restroom,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const LoginCuidadorTela()))),
          ]),
        ),
      ),
    );
  }
}
