class LegalConfig {
  static const supportEmail = 'kevinklecio96@gmail.com';
  static const _baseUrlFromEnvironment = String.fromEnvironment(
    'LEGAL_BASE_URL',
    defaultValue: 'https://solarpro.app',
  );

  static String get baseUrl => normalizeLegalBaseUrl(_baseUrlFromEnvironment);
  static String get privacyUrl => '$baseUrl/privacy.html';
  static String get termsUrl => '$baseUrl/terms.html';
  static String get dataDeletionUrl => '$baseUrl/data-deletion.html';
  static String get faqUrl => '$baseUrl/support.html';
  static String get supportUrl => '$baseUrl/support.html';
}

String normalizeLegalBaseUrl(String value) {
  final trimmed = value.trim();
  final normalized = trimmed.isEmpty ? 'https://solarpro.app' : trimmed;
  return normalized.endsWith('/')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}
