import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/config/legal_config.dart';

void main() {
  test('normalizes legal base URL without trailing slash', () {
    expect(
      normalizeLegalBaseUrl('https://example.com/legal/'),
      'https://example.com/legal',
    );
  });

  test('uses production legal URL when value is empty', () {
    expect(normalizeLegalBaseUrl(''), 'https://solarpro.app');
  });

  test('builds default legal document URLs', () {
    expect(LegalConfig.privacyUrl, 'https://solarpro.app/privacy.html');
    expect(LegalConfig.termsUrl, 'https://solarpro.app/terms.html');
    expect(
      LegalConfig.dataDeletionUrl,
      'https://solarpro.app/data-deletion.html',
    );
    expect(LegalConfig.supportUrl, 'https://solarpro.app/support.html');
  });
}
