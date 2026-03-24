import 'package:flutter/material.dart';

import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/dialogs/wallet_alert_dialog.dart';
import '../widgets/inputs/wallet_text_field.dart';

class ComponentShowcasePage extends StatefulWidget {
  const ComponentShowcasePage({super.key});

  @override
  State<ComponentShowcasePage> createState() => _ComponentShowcasePageState();
}

class _ComponentShowcasePageState extends State<ComponentShowcasePage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('基础组件')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WalletCard(
            title: '输入组件',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalletTextField(
                  label: '收款地址',
                  hintText: 'cosmos1...',
                  controller: _addressController,
                ),
                const SizedBox(height: 12),
                WalletTextField(
                  label: '金额',
                  hintText: '1.25',
                  keyboardType: TextInputType.number,
                  controller: _amountController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WalletCard(
            title: '按钮与弹窗',
            child: WalletPrimaryButton(
              label: '打开确认弹窗',
              onPressed: () {
                WalletAlertDialog.show(
                  context,
                  title: '确认交易',
                  message: '基础弹窗已接入统一按钮组件。',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
