// Test intl v0.20.3 PT-BR formatting compatibility
// Run with: flutter test test/intl_formatting_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // Initialize locale data before tests
    await initializeDateFormatting('pt_BR', null);
  });

  group('intl PT-BR Formatting', () {
    test('Date format DD/MM/YYYY', () {
      final date = DateTime(2026, 7, 2);
      final formatted = DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
      expect(formatted, equals('02/07/2026'));
    });

    test('Currency format R\$ (Brazilian Real)', () {
      final formatter = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$ ',
        decimalDigits: 2,
      );
      final formatted = formatter.format(25000.00);
      // intl v0.20.3 should output: "R\$ 25.000,00"
      expect(formatted, contains('R'));
      expect(formatted, contains(','));
    });

    test('Decimal format with comma', () {
      final formatter = NumberFormat.decimalPattern('pt_BR');
      final formatted = formatter.format(3.14159);
      // Should use comma as decimal separator
      expect(formatted, contains(','));
    });

    test('Percent format PT-BR', () {
      final formatter = NumberFormat.percentPattern('pt_BR');
      final formatted = formatter.format(0.75);
      expect(formatted, contains('75'));
    });

    test('Date range formatting', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 12, 31);
      final startStr = DateFormat('dd/MM/yyyy', 'pt_BR').format(start);
      final endStr = DateFormat('dd/MM/yyyy', 'pt_BR').format(end);
      
      expect(startStr, equals('01/01/2026'));
      expect(endStr, equals('31/12/2026'));
    });

    test('Weekday names PT-BR', () {
      final monday = DateTime(2026, 7, 6); // Next Monday from 2026-07-02
      final formatter = DateFormat('EEEE', 'pt_BR');
      final formatted = formatter.format(monday);
      // Should be Portuguese weekday name
      expect(formatted.toLowerCase(), contains('segunda'));
    });

    test('Month names PT-BR', () {
      final july = DateTime(2026, 7, 2);
      final formatter = DateFormat('MMMM', 'pt_BR');
      final formatted = formatter.format(july);
      // Should be Portuguese month name (julho)
      expect(formatted.toLowerCase(), contains('julho'));
    });
  });
}
