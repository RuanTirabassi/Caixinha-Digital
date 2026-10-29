import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorio.dart';
import '../../widgets/comuns.dart';

Future<void> _abrir(BuildContext context, Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication) && context.mounted) {
    mostrarAviso(context, 'Não foi possível abrir o WhatsApp.');
  }
}

String _numero(String? n) => (n ?? '').replaceAll(RegExp(r'\D'), '');

/// "Enviar link pelo WhatsApp". O código vale 10 minutos e só entra uma vez:
/// se já venceu, gera um novo antes de enviar. Devolve o código enviado.
Future<String?> enviarLinkIdoso(BuildContext context, Idoso idoso) async {
  try {
    final codigo = idoso.codigoValido ? idoso.codigoAcesso : await Repo.novoCodigoIdoso(idoso.id);
    final msg = 'Oi, cadastrei seus remédios na Caixinha. É só tocar no link abaixo, '
        'não precisa de senha. O link vale por 10 minutos.\n\n${Config.linkBase}/#/entrar/$codigo';
    if (!context.mounted) return codigo;
    await _abrir(context,
        Uri.parse('https://wa.me/${_numero(idoso.whatsapp)}?text=${Uri.encodeComponent(msg)}'));
    return codigo;
  } catch (e) {
    if (context.mounted) mostrarErro(context, e);
    return null;
  }
}

/// "+ Adicionar cuidador": manda o código para outro familiar entrar.
Future<void> convidarCuidador(BuildContext context, Idoso idoso) => _abrir(
      context,
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Estou usando a Caixinha Digital para acompanhar '
          'os remédios ${idoso.daDo} ${idoso.nomeTratamento}. Para me ajudar, crie sua conta de '
          'cuidador em ${Config.linkBase} e use o código para cuidadores: ${idoso.codigoCuidador}')}'),
    );

/// "Ligar pelo WhatsApp" (aviso de remédio sem confirmação).
Future<void> conversarWhatsApp(BuildContext context, String? numero) =>
    _abrir(context, Uri.parse('https://wa.me/${_numero(numero)}'));
