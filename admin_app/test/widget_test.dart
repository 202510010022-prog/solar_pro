import 'package:flutter_test/flutter_test.dart';

import 'package:solarpro_admin/app/admin_theme.dart';

void main() {
  test('tema admin esta configurado', () {
    final theme = AdminTheme.theme;

    expect(theme.brightness, isNotNull);
    expect(AdminTheme.background.toARGB32(), isNot(0));
  });
}
