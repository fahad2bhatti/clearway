import 'package:clearway/data/progress_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressCodec', () {
    test('round trips sparse star data', () {
      final source = {1: 3, 4: 1, 9: 2};
      final encoded = ProgressCodec.encode(source);

      expect(encoded, '300100002');
      expect(ProgressCodec.decode(encoded), source);
    });

    test('encodes and decodes levels beyond the original catalog size', () {
      final encoded = ProgressCodec.encode({101: 3}, throughLevel: 101);

      expect(encoded, hasLength(101));
      expect(encoded[100], '3');
      expect(ProgressCodec.decode(encoded), {101: 3});
    });

    test('skips unknown characters without shifting following levels', () {
      expect(ProgressCodec.decode('3x02?1'), {1: 3, 4: 2, 6: 1});
    });

    test('supports an empty progress string', () {
      expect(ProgressCodec.encode({}), isEmpty);
      expect(ProgressCodec.decode(''), isEmpty);
    });
  });
}
