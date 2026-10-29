import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'tema.dart';
import 'telas/inicio_tela.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await Supabase.initialize(
    url: Config.supabaseUrl,
    publishableKey: Config.supabaseAnonKey,
  );
  runApp(const CaixinhaApp());
}

/// Lê o código de um link do tipo .../entrar/024587 (ou .../#/entrar/024587).
String? codigoDoLink() {
  final uri = Uri.base;
  final partes = [
    ...uri.pathSegments,
    ...Uri.parse(uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}')
        .pathSegments,
  ].where((p) => p.isNotEmpty).toList();
  final i = partes.indexOf('entrar');
  if (i >= 0 && i + 1 < partes.length) return partes[i + 1];
  return null;
}

Route<void> _rotaInicial() =>
    MaterialPageRoute(builder: (_) => InicioTela(codigoInicial: codigoDoLink()));

class CaixinhaApp extends StatelessWidget {
  const CaixinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caixinha Digital',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Ignora a rota da URL (ex.: /#/entrar/024587) e sempre começa no
      // InicioTela, que lê o código do link e decide para onde ir.
      onGenerateInitialRoutes: (_) => [_rotaInicial()],
      // Obrigatório: sem home/routes/onGenerateRoute o MaterialApp não cria
      // o Navigator e a tela fica em branco.
      onGenerateRoute: (_) => _rotaInicial(),
      // As telas do Figma são de celular (360 de largura): no computador
      // o app fica numa coluna central em vez de esticar.
      builder: (context, child) => ColoredBox(
        color: Cores.cartao,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child),
        ),
      ),
    );
  }
}
