import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/reminder/autostart_guide.dart';

void main() {
  test('AutostartGuideType.fromStorage maps known vendors', () {
    expect(AutostartGuideType.fromStorage('xiaomi'), AutostartGuideType.xiaomi);
    expect(AutostartGuideType.fromStorage('huawei'), AutostartGuideType.huawei);
    expect(AutostartGuideType.fromStorage('oppo'), AutostartGuideType.oppo);
    expect(AutostartGuideType.fromStorage('vivo'), AutostartGuideType.vivo);
    expect(AutostartGuideType.fromStorage('samsung'), AutostartGuideType.samsung);
    expect(AutostartGuideType.fromStorage(null), AutostartGuideType.generic);
    expect(AutostartGuideType.fromStorage('unknown'), AutostartGuideType.generic);
  });

  test('AutostartOpenResult.fromMap parses native payload', () {
    final direct = AutostartOpenResult.fromMap({
      'opened': true,
      'destination': 'miui_autostart',
    });
    expect(direct.opened, isTrue);
    expect(direct.destination, 'miui_autostart');
    expect(direct.openedDirectSettings, isTrue);

    final failed = AutostartOpenResult.fromMap(null);
    expect(failed.opened, isFalse);
    expect(failed.destination, 'failed');
  });
}
