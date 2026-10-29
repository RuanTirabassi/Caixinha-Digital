import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import 'painel_tela.dart';
import 'whatsapp.dart';

/// Cuidador / 04 Cadastro efetuado — mostra os códigos e envia o link ao idoso.
class CadastroEfetuadoTela extends StatefulWidget {
  final String idosoId;
  const CadastroEfetuadoTela({super.key, required this.idosoId});

  @override
  State<CadastroEfetuadoTela> createState() => _CadastroEfetuadoTelaState();
}

class _CadastroEfetuadoTelaState extends State<CadastroEfetuadoTela> {
  Idoso? _idoso;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final i = await Repo.buscarIdoso(widget.idosoId);
      if (mounted) setState(() => _idoso = i);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _idoso;
    if (i == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final legenda = Estilos.cuidadorCorpo.copyWith(fontSize: 14);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 32, 22, 24), children: [
          Center(child: SvgPicture.asset('assets/figma/icone_ok.svg', width: 76, height: 76)),
          const SizedBox(height: 22),
          Text('Cadastro efetuado!', textAlign: TextAlign.center, style: Estilos.cuidadorTitulo.copyWith(fontSize: 24)),
          const SizedBox(height: 18),
          Text('Agora é só adicionar o usuário (receptor do cuidado).',
              textAlign: TextAlign.center, style: Estilos.cuidadorCorpo),
          const SizedBox(height: 20),
          Text('Código do cuidador', textAlign: TextAlign.center, style: Estilos.cuidadorSecao.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          SelectableText(i.codigoCuidador, textAlign: TextAlign.center, style: Estilos.codigo),
          const SizedBox(height: 12),
          Text('Passe este código para outros familiares que também cuidam ${i.daDo == 'do' ? 'dele' : 'dela'}.',
              textAlign: TextAlign.center, style: legenda),
          const SizedBox(height: 24),
          Text('Código do Usuário', textAlign: TextAlign.center, style: Estilos.cuidadorSecao.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          SelectableText(i.codigoAcesso, textAlign: TextAlign.center, style: Estilos.codigo),
          const SizedBox(height: 6),
          Text('Vale por 10 minutos e só pode ser usado uma vez.', textAlign: TextAlign.center, style: legenda),
          const SizedBox(height: 12),
          Text('ou', textAlign: TextAlign.center, style: Estilos.cuidadorCorpo.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Botao('Enviar link pelo WhatsApp',
              tipo: TipoBotao.whatsapp,
              icone: Icons.send_outlined,
              onPressed: () async {
                await enviarLinkIdoso(context, i);
                _carregar();
              }),
          const SizedBox(height: 44),
          Botao('Continuar',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => PainelTela(idosoId: i.id)), (_) => false)),
        ]),
      ),
    );
  }
}
