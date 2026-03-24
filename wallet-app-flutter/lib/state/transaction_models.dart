import 'package:flutter/foundation.dart';

enum AssetProtocol { native, cw20, ibc }

enum ExportFormat { csv, pdf, json }

class TransferFormDraft {
  const TransferFormDraft({
    required this.recipientAddress,
    required this.amountText,
    required this.memo,
    required this.source,
    required this.appliedAt,
  });

  final String recipientAddress;
  final String amountText;
  final String memo;
  final String source;
  final DateTime appliedAt;
}

class TransferFormDraftBridge extends ValueNotifier<TransferFormDraft?> {
  TransferFormDraftBridge._() : super(null);

  static final TransferFormDraftBridge instance = TransferFormDraftBridge._();

  void publishFromScan({
    required String recipientAddress,
    required String amountText,
    required String memo,
  }) {
    value = TransferFormDraft(
      recipientAddress: recipientAddress,
      amountText: amountText,
      memo: memo,
      source: 'BIP-21 扫码',
      appliedAt: DateTime.now(),
    );
  }
}

class AssetBalanceItem {
  const AssetBalanceItem({
    required this.symbol,
    required this.protocol,
    required this.amount,
    required this.usdPrice,
  });

  final String symbol;
  final AssetProtocol protocol;
  final String amount;
  final double usdPrice;

  double get normalizedAmount => double.tryParse(amount) ?? 0;

  AssetBalanceItem copyWith({
    String? symbol,
    AssetProtocol? protocol,
    String? amount,
    double? usdPrice,
  }) {
    return AssetBalanceItem(
      symbol: symbol ?? this.symbol,
      protocol: protocol ?? this.protocol,
      amount: amount ?? this.amount,
      usdPrice: usdPrice ?? this.usdPrice,
    );
  }
}

class FeeTierSuggestion {
  const FeeTierSuggestion({
    required this.label,
    required this.gasPrice,
    required this.estimatedFee,
  });

  final String label;
  final String gasPrice;
  final String estimatedFee;
}

class BuildResult {
  const BuildResult({
    required this.accountNumber,
    required this.sequence,
    required this.memo,
  });

  final int accountNumber;
  final int sequence;
  final String memo;
}

class SimulationResult {
  const SimulationResult({
    required this.gasUsed,
    required this.feeSuggestions,
  });

  final int gasUsed;
  final List<FeeTierSuggestion> feeSuggestions;
}

class SignResult {
  const SignResult({
    required this.signerAddress,
    required this.signatureDigest,
  });

  final String signerAddress;
  final String signatureDigest;
}

class BroadcastResult {
  const BroadcastResult({
    required this.txHash,
    required this.height,
    required this.status,
  });

  final String txHash;
  final int height;
  final String status;
}

class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.type,
    required this.toAddress,
    required this.amount,
    required this.txHash,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String type;
  final String toAddress;
  final String amount;
  final String txHash;
  final String status;
  final DateTime timestamp;
}

class ExportResult {
  const ExportResult({
    required this.format,
    required this.fileName,
    required this.recordCount,
    required this.bytes,
  });

  final ExportFormat format;
  final String fileName;
  final int recordCount;
  final int bytes;
}

class TransferExecutionSnapshot {
  const TransferExecutionSnapshot({
    required this.buildResult,
    required this.simulationResult,
    required this.signResult,
    required this.broadcastResult,
    required this.historyRecord,
  });

  final BuildResult buildResult;
  final SimulationResult simulationResult;
  final SignResult signResult;
  final BroadcastResult broadcastResult;
  final HistoryRecord historyRecord;
}

abstract class TransactionRepository {
  Future<List<AssetBalanceItem>> fetchAssets();
  Future<List<HistoryRecord>> fetchHistory({int limit});
  Future<TransferExecutionSnapshot> submitTransfer({
    required String recipientAddress,
    required double amount,
    required String memo,
  });
}

class TransactionUseCase {
  const TransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<List<AssetBalanceItem>> loadAssets() {
    return _repository.fetchAssets();
  }

  Future<List<HistoryRecord>> loadHistory({int limit = 20}) {
    return _repository.fetchHistory(limit: limit);
  }

  Future<TransferExecutionSnapshot> runTransfer({
    required String recipientAddress,
    required double amount,
    required String memo,
  }) {
    return _repository.submitTransfer(
      recipientAddress: recipientAddress,
      amount: amount,
      memo: memo,
    );
  }
}
