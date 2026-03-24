import 'package:flutter/material.dart';

import '../api/api_error_mapper.dart';
import '../state/interop_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class GovernanceVotePage extends StatefulWidget {
  const GovernanceVotePage({super.key});

  @override
  State<GovernanceVotePage> createState() => _GovernanceVotePageState();
}

class _GovernanceVotePageState extends State<GovernanceVotePage> {
  final GovernanceDemoStore _store = GovernanceDemoStore.instance;
  final TextEditingController _reasonController = TextEditingController();
  int? _selectedProposalId;
  GovernanceVoteOption _selectedOption = GovernanceVoteOption.yes;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final votingProposal = _store.value.proposals.where((item) => item.status == 'VotingPeriod');
    if (votingProposal.isNotEmpty) {
      _selectedProposalId = votingProposal.first.id;
    }
    _reasonController.text = '支持提案方向，建议加强执行期监控。';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _vote() async {
    setState(() => _errorText = null);
    try {
      await _store.vote(
        proposalId: _selectedProposalId ?? -1,
        option: _selectedOption,
        reason: _reasonController.text,
      );
    } catch (error) {
      setState(() => _errorText = mapApiErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovernanceVoteState>(
      valueListenable: _store,
      builder: (context, state, _) {
        if (_selectedProposalId == null && state.proposals.isNotEmpty) {
          final voting = state.proposals.where((item) => item.status == 'VotingPeriod');
          _selectedProposalId = (voting.isNotEmpty ? voting.first : state.proposals.first).id;
        }
        GovernanceProposal? selected;
        for (final proposal in state.proposals) {
          if (proposal.id == _selectedProposalId) {
            selected = proposal;
            break;
          }
        }
        return Scaffold(
          appBar: AppBar(title: const Text('治理提案投票')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '提案列表',
                child: Column(
                  children: [
                    for (final proposal in state.proposals) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColorTokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedProposalId == proposal.id ? AppColorTokens.primary : AppColorTokens.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '#${proposal.id} ${proposal.title}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Chip(label: Text(proposal.status)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(proposal.summary),
                            const SizedBox(height: 8),
                            Text('截止时间：${proposal.endAt.toLocal()}'),
                            const SizedBox(height: 8),
                            WalletPrimaryButton(
                              label: _selectedProposalId == proposal.id ? '当前已选中' : '选择此提案',
                              onPressed: _selectedProposalId == proposal.id
                                  ? null
                                  : () => setState(() => _selectedProposalId = proposal.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '投票操作',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<GovernanceVoteOption>(
                      key: ValueKey(_selectedOption),
                      value: _selectedOption,
                      items: const [
                        DropdownMenuItem(value: GovernanceVoteOption.yes, child: Text('Yes')),
                        DropdownMenuItem(value: GovernanceVoteOption.no, child: Text('No')),
                        DropdownMenuItem(value: GovernanceVoteOption.abstain, child: Text('Abstain')),
                        DropdownMenuItem(value: GovernanceVoteOption.noWithVeto, child: Text('NoWithVeto')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedOption = value);
                      },
                      decoration: const InputDecoration(labelText: '投票选项'),
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '投票理由',
                      hintText: '可选，最长 140 字',
                      maxLines: 3,
                      controller: _reasonController,
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '签名并提交投票',
                      loading: state.loading,
                      onPressed: state.loading ? null : _vote,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                      ),
                    ],
                    if (_errorText == null && state.errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '投票进度',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _stageChip('提案选择', selected != null),
                    _stageChip('签名摘要', state.signatureDigest != null),
                    _stageChip('链上确认', state.result != null),
                  ],
                ),
              ),
              if (state.signatureDigest != null) ...[
                const SizedBox(height: 12),
                WalletCard(
                  title: '签名摘要',
                  child: Text(state.signatureDigest!),
                ),
              ],
              if (state.result != null) ...[
                const SizedBox(height: 12),
                WalletCard(
                  title: '投票结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('提案ID: ${state.result!.proposalId}'),
                      Text('投票选项: ${_optionLabel(state.result!.option)}'),
                      Text('状态: ${state.result!.status}'),
                      Text('区块高度: ${state.result!.height}'),
                      Text('TxHash: ${state.result!.txHash}'),
                      Text('契约端点: ${state.result!.contractPath}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _stageChip(String label, bool done) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        done ? Icons.check_circle_rounded : Icons.schedule_rounded,
        size: 18,
        color: done ? AppColorTokens.success : AppColorTokens.warning,
      ),
    );
  }

  String _optionLabel(GovernanceVoteOption option) {
    switch (option) {
      case GovernanceVoteOption.yes:
        return 'Yes';
      case GovernanceVoteOption.no:
        return 'No';
      case GovernanceVoteOption.abstain:
        return 'Abstain';
      case GovernanceVoteOption.noWithVeto:
        return 'NoWithVeto';
    }
  }
}
