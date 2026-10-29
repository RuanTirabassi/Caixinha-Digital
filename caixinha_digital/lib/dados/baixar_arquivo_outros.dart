import 'package:flutter/services.dart';

/// No celular/computador (sem navegador): copia o conteúdo para colar onde quiser.
/// Devolve false para a tela avisar que foi copiado, e não baixado.
Future<bool> baixarArquivo(String nome, String conteudo) async {
  await Clipboard.setData(ClipboardData(text: conteudo));
  return false;
}
