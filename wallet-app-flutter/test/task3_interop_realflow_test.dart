import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/state/security_interop_demo_store.dart';
import 'package:wallet_app_flutter/state/transaction_demo_store.dart';

void main() {
  test('bip21 扫码会回填交易草稿', () {
    final interopStore = DappInteropStore.instance;
    final draftBridge = TransferFormDraftBridge.instance;
    draftBridge.value = null;

    interopStore.parseBip21(
      'soulon:soulon1v9jxgu33ps6en2mu7k9l0y4xt6t7e8q8nk?amount=3.6&memo=coffee',
    );

    expect(interopStore.value.scanResult, isNotNull);
    expect(draftBridge.value, isNotNull);
    expect(draftBridge.value!.recipientAddress, 'soulon1v9jxgu33ps6en2mu7k9l0y4xt6t7e8q8nk');
    expect(draftBridge.value!.amountText, '3.6');
    expect(draftBridge.value!.memo, 'coffee');
  });

  test('reorg 刷新会保持已绑定交易哈希', () async {
    final interopStore = DappInteropStore.instance;
    const txHash = 'A0B1C2D3E4F500112233445566778899AABBCCDDEEFF00112233445566778899';
    interopStore.bindTrackedTx(txHash);

    await interopStore.refreshReorgStatus();

    expect(interopStore.value.reorgNotice.txHash, txHash);
    expect(interopStore.value.reorgNotice.currentHeight, greaterThanOrEqualTo(0));
  });
}
