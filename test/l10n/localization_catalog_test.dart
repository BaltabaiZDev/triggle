import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English, Kazakh, and Russian catalogs expose the same messages', () {
    final catalogs = {
      for (final locale in ['en', 'kk', 'ru'])
        locale:
            jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, Object?>,
    };
    final englishKeys = _messageKeys(catalogs['en']!);

    expect(_messageKeys(catalogs['kk']!), englishKeys);
    expect(_messageKeys(catalogs['ru']!), englishKeys);
  });

  test('Kazakh catalog includes the required player-facing terminology', () {
    final values =
        (jsonDecode(File('lib/l10n/app_kk.arb').readAsStringSync())
                as Map<String, Object?>)
            .values
            .whereType<String>()
            .join('\n');

    for (final phrase in [
      'Ойын құру',
      'Ойынға қосылу',
      'Жергілікті желі',
      'Ойыншы',
      'Бот деңгейі',
      'Ойын алаңы',
      'Кезек',
      'Жеңімпаз',
      'Байланыс үзілді',
      'Қайта қосылу',
    ]) {
      expect(values, contains(phrase), reason: phrase);
    }
  });
}

Set<String> _messageKeys(Map<String, Object?> catalog) {
  return catalog.keys
      .where((key) => !key.startsWith('@') && key != '@@locale')
      .toSet();
}
