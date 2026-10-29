import 'package:flutter/material.dart';

import '../../../dados/modelos.dart';
import '../../../dados/repositorio.dart';
import '../../../tema.dart';
import '../../../widgets/comuns.dart';

/// Config / 03 Celular da Sra. Maria — ajustes que mudam só a tela dela.
class CelularTela extends StatefulWidget {
  final Idoso idoso;
  const CelularTela({super.key, required this.idoso});

  @override
  State<CelularTela> createState() => _CelularTelaState();
}

class _CelularTelaState extends State<CelularTela> {
  late Idoso _i = widget.idoso;

  Future<void> _atualizar(Map<String, dynamic> dados) async {
    try {
      await Repo.atualizarIdoso(_i.id, dados);
      final novo = await Repo.buscarIdoso(_i.id);
      if (mounted) setState(() => _i = novo);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tamanhos = {'normal': ('Normal', 16.0), 'grande': ('Grande', 18.0), 'muito_grande': ('Maior', 20.0)};
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 22),
          Text('Celular ${_i.daDo} ${_i.nomeTratamento}', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 14),
          Text('Estes ajustes mudam só a tela ${_i.delaDele}. ${_i.pronome} não precisa mexer em nada.',
              style: Estilos.cuidadorCorpo.copyWith(fontSize: 14)),
          const SizedBox(height: 16),
          Secao(titulo: 'Tamanho da letra', filhos: [
            Row(children: [
              for (final t in tamanhos.entries) ...[
                if (t.key != 'normal') const SizedBox(width: 8),
                Expanded(
                  child: Opcao(
                    t.value.$1,
                    selecionado: _i.tamanhoLetra == t.key,
                    altura: 64,
                    topo: Text('Aa',
                        style: Estilos.cuidadorSecao.copyWith(
                            fontSize: t.value.$2,
                            color: _i.tamanhoLetra == t.key ? Cores.textoSobreAcao : Cores.texto)),
                    onTap: () => _atualizar({'tamanho_letra': t.key}),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            Text('Prévia', style: Estilos.cuidadorLegenda.copyWith(fontSize: 10)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_i.escalaLetra)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Losartana', style: Estilos.idosoTitulo.copyWith(fontSize: 22)),
                  Text('1 comprimido de 50mg', style: Estilos.idosoCorpo),
                ]),
              ),
            ),
          ]),
          Secao(titulo: 'Lembrete', filhos: [
            Linhas([
              LinhaComInterruptor(
                titulo: 'Som do lembrete',
                detalhe: 'Toca quando chega a hora',
                valor: _i.som,
                onChanged: (v) => _atualizar({'som': v}),
              ),
              LinhaComInterruptor(
                titulo: 'Vibração',
                detalhe: 'Vibra ao lembrar e ao confirmar',
                valor: _i.vibracao,
                onChanged: (v) => _atualizar({'vibracao': v}),
              ),
              LinhaComInterruptor(
                titulo: 'Repetir lembrete',
                detalhe: 'Se não marcar, lembra de novo em 15 min',
                valor: _i.repetirLembrete,
                onChanged: (v) => _atualizar({'repetir_lembrete': v}),
              ),
            ]),
          ]),
          Botao('Voltar ao padrão',
              tipo: TipoBotao.secundario,
              altura: 46,
              onPressed: () => _atualizar(
                  {'tamanho_letra': 'grande', 'som': true, 'vibracao': true, 'repetir_lembrete': false})),
        ]),
      ),
    );
  }
}
