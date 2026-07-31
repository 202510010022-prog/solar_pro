import 'dart:async';

const _networkMessage =
    'Sem conexão com a internet. Verifique sua rede e tente novamente.';

String friendlyNetworkError(
  Object error, {
  String fallback = 'Não foi possível concluir a ação agora.',
}) {
  if (error is TimeoutException) return _networkMessage;

  final text = error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '')
      .trim();
  final lower = text.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('connection timed out') ||
      lower.contains('network is unreachable') ||
      lower.contains('network unreachable') ||
      lower.contains('no address associated with hostname') ||
      lower.contains('clientexception') ||
      lower.contains('xmlhttprequest error') ||
      lower.contains('failed to fetch')) {
    return _networkMessage;
  }

  if (text.isEmpty) return fallback;
  return text;
}
