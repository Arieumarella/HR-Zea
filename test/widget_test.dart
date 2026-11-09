import 'package:flutter_test/flutter_test.dart';
import 'package:zea_hr/core/theme.dart';

void main() {
  test('tema Zea HR terbentuk dengan benar', () {
    final theme = buildZeaTheme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, ZeaColors.primary);
  });
}
