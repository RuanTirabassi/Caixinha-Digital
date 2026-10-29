import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Idoso / 10 Consulta de hoje — receitas e exames para mostrar ao médico (RF05).
class ConsultaTela extends StatelessWidget {
  final String idosoId;
  const ConsultaTela({super.key, required this.idosoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Documento>>(
          future: Repo.documentos(idosoId),
          builder: (context, snap) {
            return ListView(padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), children: [
              const BotaoVoltar(),
              const SizedBox(height: 25),
              Text('Consulta de hoje', style: Estilos.idosoTitulo),
              const SizedBox(height: 4),
              Text('Mostre esses papéis para o médico. Toque para ver grande.', style: Estilos.idosoCorpo),
              const SizedBox(height: 16),
              if (snap.hasError)
                Text(mensagemDeErro(snap.error!), style: Estilos.idosoCorpo)
              else if (!snap.hasData)
                const Center(child: CircularProgressIndicator())
              else if (snap.data!.isEmpty)
                Text('Nenhum papel guardado ainda.', style: Estilos.idosoCorpo)
              else
                for (final d in snap.data!) _CardDocumento(doc: d),
            ]);
          },
        ),
      ),
    );
  }
}

IconData iconeDocumento(String tipo) =>
    tipo == 'receita' ? Icons.description_outlined : Icons.biotech_outlined;

class _CardDocumento extends StatelessWidget {
  final Documento doc;
  const _CardDocumento({required this.doc});

  @override
  Widget build(BuildContext context) {
    final receita = doc.tipo == 'receita';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => DocumentoAbertoTela(doc: doc))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: receita ? Cores.receita : Cores.exame,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconeDocumento(doc.tipo), size: 30, color: Cores.texto),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc.titulo, style: Estilos.idosoTitulo.copyWith(fontSize: 22)),
                  if (doc.origem != null) Text(doc.origem!, style: Estilos.idosoCorpo),
                  if (doc.data != null)
                    Text(DateFormat('dd/MM/yyyy').format(doc.data!), style: Estilos.idosoCorpo),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Idoso / 11 Receita aberta e 12 Exame aberto.
class DocumentoAbertoTela extends StatelessWidget {
  final Documento doc;
  const DocumentoAbertoTela({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final cabecalho = [
      if (doc.origem != null) doc.origem!,
      if (doc.data != null) DateFormat('dd/MM/yyyy').format(doc.data!),
    ].join(' • ');
    final linhas = (doc.descricao ?? '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 25),
          Text(doc.titulo, style: Estilos.idosoTitulo.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: Cores.cartao,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Cores.textoSuave),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (cabecalho.isNotEmpty) ...[
                Text(cabecalho, textAlign: TextAlign.center, style: Estilos.idosoDestaque),
                const SizedBox(height: 14),
                const Divider(color: Cores.neutro),
              ],
              for (final l in linhas)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(l, style: Estilos.idosoCorpo),
                ),
              if (doc.arquivoPath != null) ...[
                const SizedBox(height: 18),
                Botao('Ver foto',
                    tipo: TipoBotao.secundario,
                    icone: Icons.photo_camera_outlined,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FotoTelaCheia(titulo: doc.titulo, caminho: doc.arquivoPath!)))),
              ],
              if (linhas.isEmpty && doc.arquivoPath == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Sem foto deste papel.', style: Estilos.idosoCorpo),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
