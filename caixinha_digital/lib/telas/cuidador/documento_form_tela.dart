import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Cuidador / 21 Cadastro de receita e 22 Cadastro de exame (também edita).
/// O que for salvo aparece na pasta "Consulta de hoje" do idoso.
class DocumentoFormTela extends StatefulWidget {
  final String idosoId;
  final Documento? documento; // null = novo
  const DocumentoFormTela({super.key, required this.idosoId, this.documento});

  @override
  State<DocumentoFormTela> createState() => _DocumentoFormTelaState();
}

class _DocumentoFormTelaState extends State<DocumentoFormTela> {
  late String _tipo = widget.documento?.tipo ?? 'receita';
  late final _especialidade = TextEditingController(text: widget.documento?.especialidade);
  late final _descricao = TextEditingController(text: widget.documento?.descricao);
  late DateTime _data = widget.documento?.data ?? DateTime.now();
  late final String? _arquivo = widget.documento?.arquivoPath;
  Uint8List? _foto;
  String _ext = 'jpg';
  bool _salvando = false;

  Future<void> _adicionarFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Fotografar'),
              onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
    if (origem == null) return;
    final arq = await ImagePicker().pickImage(source: origem, maxWidth: 2000, imageQuality: 85);
    if (arq == null) return;
    final bytes = await arq.readAsBytes();
    setState(() {
      _foto = bytes;
      _ext = arq.name.contains('.') ? arq.name.split('.').last : 'jpg';
    });
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _salvar() async {
    final esp = _especialidade.text.trim();
    if (esp.isEmpty) {
      mostrarAviso(context, _tipo == 'receita' ? 'Informe a especialidade.' : 'Informe qual é o exame.');
      return;
    }
    setState(() => _salvando = true);
    try {
      var caminho = _arquivo;
      if (_foto != null) caminho = await Repo.enviarFoto(widget.idosoId, _foto!, _ext);
      await Repo.salvarDocumento(
        id: widget.documento?.id,
        idosoId: widget.idosoId,
        tipo: _tipo,
        titulo: tituloDocumento(_tipo, esp),
        origem: _tipo == 'receita' ? esp : 'Laboratório',
        data: _data,
        descricao: _descricao.text,
        arquivoPath: caminho,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover() async {
    final d = widget.documento!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover documento?'),
        content: Text(d.titulo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Repo.removerDocumento(d);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receita = _tipo == 'receita';
    final dataTexto =
        '${_data.day.toString().padLeft(2, '0')}  /  ${_data.month.toString().padLeft(2, '0')}  /  ${(_data.year % 100).toString().padLeft(2, '0')}';
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
          const BotaoVoltar(),
          const SizedBox(height: 22),
          Text('Cadastro Documentos', style: Estilos.cuidadorTitulo),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 190,
              child: GrupoOpcoes<String>(
                opcoes: const {'receita': 'Receita', 'exame': 'Exame'},
                valor: _tipo,
                altura: 32,
                onChanged: (v) => setState(() => _tipo = v),
              ),
            ),
          ),
          const Rotulo('Especialidade'),
          TextField(
            controller: _especialidade,
            textCapitalization: TextCapitalization.words,
            style: Estilos.cuidadorCorpo,
            decoration: InputDecoration(
                hintText: receita ? 'Ex.: Clínico Geral, Cardiologista...' : 'Ex.: Exame de sangue, Radiografia...'),
          ),
          const Rotulo('Data do Documento'),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _escolherData,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(dataTexto, textAlign: TextAlign.center, style: Estilos.codigo),
            ),
          ),
          const Rotulo('Descrição', extra: '(opcional)'),
          TextField(
            controller: _descricao,
            minLines: 4,
            maxLines: 8,
            style: Estilos.cuidadorCorpo.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: receita
                  ? 'Ex.: Manter Losartana 50mg pela manhã.\nRetorno em 3 meses.'
                  : 'Ex.: Glicemia de jejum: 128 mg/dL\nHemoglobina glicada: 6,9%\nColesterol total: 186 mg/dL',
            ),
          ),
          const SizedBox(height: 16),
          if (_foto != null || _arquivo != null)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: _foto != null
                  ? Image.memory(_foto!, fit: BoxFit.cover, width: double.infinity)
                  : FotoDoStorage(caminho: _arquivo!, fit: BoxFit.cover),
            ),
          Botao(_foto != null || _arquivo != null ? 'Trocar foto' : 'Adicionar foto',
              tipo: TipoBotao.secundario,
              altura: 48,
              icone: Icons.photo_camera_outlined,
              onPressed: _adicionarFoto),
          const SizedBox(height: 36),
          Botao('Salvar', altura: 46, carregando: _salvando, onPressed: _salvar),
          if (widget.documento != null) ...[
            const SizedBox(height: 14),
            Botao('Remover documento', tipo: TipoBotao.risco, altura: 46, onPressed: _remover),
          ],
        ]),
      ),
    );
  }
}
