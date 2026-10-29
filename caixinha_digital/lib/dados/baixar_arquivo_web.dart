import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Baixa o texto como arquivo. Devolve true quando o download começou.
Future<bool> baixarArquivo(String nome, String conteudo) async {
  final bytes = utf8.encode(conteudo);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = nome;
  a.click();
  web.URL.revokeObjectURL(url);
  return true;
}
