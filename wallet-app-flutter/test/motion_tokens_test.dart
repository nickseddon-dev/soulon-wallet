import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/theme/tokens/app_motion_tokens.dart';

void main() {
  test('motion tokens are ordered by duration', () {
    expect(AppMotionTokens.fast < AppMotionTokens.normal, isTrue);
    expect(AppMotionTokens.normal < AppMotionTokens.slow, isTrue);
  });
}
