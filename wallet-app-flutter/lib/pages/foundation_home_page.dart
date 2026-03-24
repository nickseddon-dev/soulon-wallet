import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class FoundationHomePage extends StatelessWidget {
  const FoundationHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Flutter Foundation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WalletCard(
            title: 'Task 1 基线',
            child: Text('已建立路由、主题令牌、基础组件与动效封装。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 2 身份与密钥管理',
            child: Text('新增助记词、HD 账户、观察者钱包与备份校验流程。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 3 资产与交易模块',
            child: Text('新增资产看板与法币折算、交易构建仿真签名广播、交易历史导出页面。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 4 Cosmos 生态互操作',
            child: Text('新增质押全流程、治理提案投票、IBC 传输与包状态追踪页面。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 5 安全认证与 DApp 交互',
            child: Text('新增 PIN/生物识别确认、WalletConnect 会话、SuggestChain 扫码与 Reorg 刷新提示。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 6 通知中心与多签工作台',
            child: Text('新增实时通知流与消息详情、多签审批流程、离线签名导入与进度展示页面。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 7 契约接入与验收归档',
            child: Text('已接入 v1.4.0 链端契约路径、统一错误映射，并补充页面与交互测试。'),
          ),
          const SizedBox(height: 16),
          const WalletCard(
            title: 'Task 8 P0 创建钱包与兑换',
            child: Text('新增创建钱包页与兑换页，打通首页入口并补充空态、错误态、成功态。'),
          ),
          const SizedBox(height: 16),
          WalletPrimaryButton(
            label: '查看基础组件',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.components),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '查看动效演示',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.motion),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '助记词生成与恢复',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.identityMnemonic),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '创建钱包（P0）',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.createWallet),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: 'HD账户与观察者钱包',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.identityHd),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '助记词备份校验',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.identityBackupVerify),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '资产看板与法币折算',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.assetDashboard),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '交易构建仿真签名广播',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.transactionFlow),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '交易历史导出CSV/PDF/JSON',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.transactionHistoryExport),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '兑换（P0）',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.swapExchange),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: 'Task3 复刻：主导航与资产收藏活动+发送接收设置安全',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.replicaMobileHome),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '质押操作全流程',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.stakingFlow),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '治理提案浏览与投票',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.governanceVote),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: 'IBC 传输与状态追踪',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.ibcTransferTracking),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: 'PIN/生物识别二次确认',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.pinBiometricConfirm),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: 'WalletConnect 授权与会话',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.walletConnectSession),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: 'SuggestChain/扫码/Reorg 提示',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.suggestChainScanReorg),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '实时通知流与消息详情',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.notificationCenter),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '多签任务审批流程',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.multisigApproval),
          ),
          const SizedBox(height: 12),
          WalletPrimaryButton(
            label: '离线签名导入与进度展示',
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.offlineSignatureImport),
          ),
        ],
      ),
    );
  }
}
