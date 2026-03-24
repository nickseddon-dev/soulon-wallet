import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/api/api_error_mapper.dart';
import 'package:wallet_app_flutter/api/chain_api_contract.dart';

void main() {
  test('chain api contract endpoints are aligned and frozen', () {
    expect(ChainApiContract.version, 'v1.4.0');
    expect(ChainApiContract.frozen, isTrue);
    expect(ChainApiContract.endpoints.length, 16);
    expect(
      ChainApiContract.endpoints.any(
        (item) =>
            item.method == ChainApiMethod.get &&
            item.path == ChainApiContract.chainTxTemplate,
      ),
      isTrue,
    );
    expect(
      ChainApiContract.endpoints.any(
        (item) =>
            item.method == ChainApiMethod.post &&
            item.path == ChainApiContract.chainBroadcastTx,
      ),
      isTrue,
    );
  });

  test('error mapper returns unified user-facing text', () {
    expect(
      mapApiErrorMessage(
        const ApiClientException(kind: ApiErrorKind.timeout),
      ),
      '链端响应超时，请稍后重试。',
    );
    expect(
      mapApiErrorMessage(
        const ApiClientException(
          kind: ApiErrorKind.validation,
          message: '参数不合法',
        ),
      ),
      '参数不合法',
    );
    expect(
      mapApiErrorMessage(const FormatException('输入格式错误')),
      '输入格式错误',
    );
  });
}
