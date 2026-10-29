import 'package:flutter/material.dart';

import '../../../dados/modelos.dart';
import '../../../dados/repositorio.dart';
import '../../../tema.dart';
import '../../../widgets/comuns.dart';
import '../whatsapp.dart';

/// Config / 02 Avisos — quando e para quem avisar de remédio não marcado.
/// (O envio pelo WhatsApp é da versão 2; por enquanto o aviso aparece no painel.)
class AvisosTela extends StatefulWidget {
  final Idoso idoso;
  const AvisosTela({super.key, required this.idoso});

  @override
  State<AvisosTela> createState() => _AvisosTelaState();
}

class _AvisosTelaState extends State<AvisosTela> {
  late int _minutos = widget.idoso.avisoMinutos;
  late String _canal = widget.idoso.avisoCanal;
  late bool _resumo = widget.idoso.resumoDiario;
  List<Pessoa>? _cuidadores;
  final Map<String, bool> _recebe = {};
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final l = (await Repo.pessoas(widget.idoso.id)).where((p) => p.papel == 'cuidador').toList();
      if (!mounted) return;
      setState(() {
        _cuidadores = l;
        for (final p in l) {
          _recebe[p.userId] = p.recebeAvisos;
        }
      });
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await Repo.atualizarIdoso(widget.idoso.id, {
        'aviso_minutos': _minutos,
        'aviso_canal': _canal,
        'resumo_diario': _resumo,
        'aviso_atraso': true,
      });
      for (final p in _cuidadores ?? <Pessoa>[]) {
        if (_recebe[p.userId] != p.recebeAvisos) {
          await Repo.definirRecebeAvisos(widget.idoso.id, p.userId, _recebe[p.userId]!);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
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
          Text('Avisos', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 14),
          Secao(titulo: 'Avisar se um remédio não for marcado depois de', filhos: [
            GrupoOpcoes<int>(
              opcoes: const {30: '30 min', 60: '1 hora', 120: '2 horas'},
              valor: _minutos,
              onChanged: (v) => setState(() => _minutos = v),
            ),
            const SizedBox(height: 12),
            Text('${i.nomeTratamento} não recebe esse aviso; ele vai só para quem cuida.',
                style: Estilos.cuidadorLegenda.copyWith(fontSize: 10)),
          ]),
          Secao(titulo: 'Como avisar', filhos: [
            GrupoOpcoes<String>(
              opcoes: const {'whatsapp': 'WhatsApp', 'app': 'No app', 'ambos': 'Os dois'},
              valor: _canal,
              onChanged: (v) => setState(() => _canal = v),
            ),
          ]),
          Secao(titulo: 'Quem recebe', filhos: [
            if (_cuidadores == null)
              const Center(child: CircularProgressIndicator())
            else
              Linhas([
                for (final p in _cuidadores!)
                  LinhaComInterruptor(
                    titulo: p.souEu ? '${p.nome ?? 'Você'} (você)' : (p.nome ?? 'Cuidador'),
                    detalhe: [
                      if (p.whatsapp != null) telefoneTexto(p.whatsapp),
                      p.autorizaWhatsapp ? 'autorizou o WhatsApp' : 'aguardando autorização',
                    ].join(' • '),
                    valor: _recebe[p.userId] ?? true,
                    onChanged: (v) => setState(() => _recebe[p.userId] = v),
                  ),
              ]),
            const SizedBox(height: 12),
            Botao('+ Adicionar cuidador',
                tipo: TipoBotao.secundario, altura: 46, onPressed: () => convidarCuidador(context, i)),
          ]),
          Secao(titulo: 'Resumo do dia', filhos: [
            LinhaComInterruptor(
              titulo: 'Enviar resumo às 21:00',
              detalhe: 'Ex.: “Hoje ${i.daDo} ${i.nomeTratamento} tomou 3 de 3 remédios.”',
              valor: _resumo,
              onChanged: (v) => setState(() => _resumo = v),
            ),
          ]),
          Botao('Salvar avisos', altura: 46, carregando: _salvando, onPressed: _salvar),
        ]),
      ),
    );
  }
}
