import 'package:flutter/foundation.dart' show kIsWeb;

// Dados do projeto Supabase "caixinha-digital".
// A chave abaixo é a chave PÚBLICA (anon): pode ficar no app.
// A segurança dos dados vem das regras RLS do banco.
class Config {
  static const supabaseUrl = 'https://vmxlyeosgmrtjpvvgnje.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZteGx5ZW9zZ21ydGpwdnZnbmplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMjY3MDAsImV4cCI6MjEwODcwMjcwMH0.oLR1n-Ild9SiXnPxkV70vwbLW5ctFu5DfkOnZlHbmio';

  /// Endereço usado no link enviado pelo WhatsApp.
  /// Troque pelo endereço onde o app web for publicado (ex.: Vercel).
  static const urlApp = 'https://caixinha.app';

  /// No navegador usa o próprio endereço aberto (localhost, Vercel...),
  /// assim o link do WhatsApp funciona sem precisar editar este arquivo.
  static String get linkBase {
    if (!kIsWeb) return urlApp;
    final b = Uri.base;
    final caminho = b.path.endsWith('/') ? b.path.substring(0, b.path.length - 1) : b.path;
    return '${b.origin}$caminho';
  }
}
