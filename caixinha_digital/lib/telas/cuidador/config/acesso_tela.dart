import 'package:flutter/material.dart';

import '../../../dados/modelos.dart';
import '../../../dados/repositorio.dart';
import '../../../tema.dart';
import '../../../widgets/comuns.dart';
import '../whatsapp.dart';

/// Config / 04 Acesso e aparelhos — código do idoso e celulares conectados.
class AcessoTela extends StatefulWidget {
  final Idoso idoso;
  const AcessoTela({super.key, required this.idoso});

  @override
  State<AcessoTela> createState() => _AcessoTelaState();
}

class _AcessoTelaState extends State<AcessoTela> {
  late Idoso _i = widget.idoso;
  List<Pessoa>? _pessoas;
  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await Future.wait([Repo.buscarIdoso(_i.id), Repo.pessoas(_i.id)]);
      if (!mounted) return;
      setState(() {
        _i = r[0] as Idoso;
        _pessoas = r[1] as List<Pessoa>;
      });
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _novoCodigo() async {
    setState(() => _gerando = true);
    try {
      await Repo.novoCodigoIdoso(_i.id);
      await _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  String _tituloAparelho(Pessoa p) {
    if (p.papel == 'idoso') return 'Celular ${_i.daDo} ${_i.nomeTratamento}';
    if (p.souEu) return 'Seu celular${p.nome == null ? '' : ' (${p.nome})'}';
    return 'Celular de ${p.nome ?? 'outro cuidador'}';
  }

  String _detalheAparelho(Pessoa p) {
    if (p.souEu) return 'Este aparelho';
    final uso = quandoUsado(p.ultimoUso, DateTime.now());
    return p.aparelho == null ? '${uso[0].toUpperCase()}${uso.substring(1)}' : '${p.aparelho} • $uso';
  }

  Future<void> _desconectar(Pessoa p) async {
    if (p.souEu) {
      mostrarAviso(context, 'Este é o seu aparelho. Para sair, use “Sair desta conta”.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Desconectar ${_tituloAparelho(p).toLowerCase()}?'),
        content: Text(p.papel == 'idoso'
            ? 'Para entrar de novo, ${_i.pronome.toLowerCase()} vai precisar de um código novo.'
            : '${p.nome ?? 'Essa pessoa'} deixa de ver o painel ${_i.daDo} ${_i.nomeTratamento}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Desconectar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Repo.desconectar(_i.id, p.userId);
      await _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _i.codigoAcesso;
    final codigoTexto = c.length == 6 ? '${c.substring(0, 3)} ${c.substring(3)}' : c;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 22),
          Text('Acesso e aparelhos', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 14),
          Secao(titulo: 'Código de acesso ${_i.daDo} ${_i.nomeTratamento}', filhos: [
            Center(child: SelectableText(codigoTexto, style: Estilos.codigo)),
            const SizedBox(height: 10),
            Text(
                _i.codigoValido
                    ? 'Vale por 10 minutos e só pode ser usado uma vez. Depois disso, gere outro.'
                    : 'Este código já foi usado ou venceu. Gere outro para entrar em um celular novo.',
                style: Estilos.cuidadorLegenda.copyWith(fontSize: 10)),
            const SizedBox(height: 10),
            Botao('Enviar link pelo WhatsApp', altura: 46, onPressed: () async {
              await enviarLinkIdoso(context, _i);
              _carregar();
            }),
            const SizedBox(height: 10),
            Botao('Gerar novo código',
                tipo: TipoBotao.secundario, altura: 46, carregando: _gerando, onPressed: _novoCodigo),
          ]),
          Secao(titulo: 'Celulares conectados', filhos: [
            if (_pessoas == null)
              const Center(child: CircularProgressIndicator())
            else if (_pessoas!.isEmpty)
              Text('Nenhum celular conectado.', style: Estilos.cuidadorCorpo)
            else
              Linhas([
                for (final p in _pessoas!)
                  LinhaNavegacao(
                    titulo: _tituloAparelho(p),
                    detalhe: _detalheAparelho(p),
                    onTap: () => _desconectar(p),
                  ),
              ]),
            const SizedBox(height: 8),
            Text('Toque em um celular para desconectá-lo.', style: Estilos.cuidadorLegenda.copyWith(fontSize: 10)),
          ]),
          Secao(titulo: 'Seu acesso', filhos: [
            LinhaNavegacao(
              titulo: 'Entrar em outro celular',
              detalhe: 'Use o mesmo e-mail e senha desta conta',
              onTap: () => showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Entrar em outro celular'),
                  content: Text('No outro celular, abra a Caixinha, toque em “Sou cuidador / familiar” e '
                      'entre com:\n\n${Repo.usuario?.email ?? ''}'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
