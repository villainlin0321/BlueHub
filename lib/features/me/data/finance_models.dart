import 'package:europepass/shared/network/api_decoders.dart';

class ProviderFinanceOverviewVO {
  const ProviderFinanceOverviewVO({
    required this.availableAmount,
    required this.pendingAmount,
    required this.totalEarned,
    required this.currency,
  });

  final double availableAmount;
  final double pendingAmount;
  final double totalEarned;
  final String currency;

  factory ProviderFinanceOverviewVO.fromJson(JsonMap json) {
    return ProviderFinanceOverviewVO(
      availableAmount: readDouble(json, 'availableAmount'),
      pendingAmount: readDouble(json, 'pendingAmount'),
      totalEarned: readDouble(json, 'totalEarned'),
      currency: readString(json, 'currency', fallback: 'CNY'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'availableAmount': availableAmount,
      'pendingAmount': pendingAmount,
      'totalEarned': totalEarned,
      'currency': currency,
    };
  }
}

class ProviderTransactionVO {
  const ProviderTransactionVO({
    required this.txId,
    required this.orderNo,
    required this.clientNameMasked,
    required this.netAmount,
    required this.currency,
    required this.txType,
    required this.settledAt,
  });

  final int txId;
  final String orderNo;
  final String clientNameMasked;
  final double netAmount;
  final String currency;
  final String txType;
  final String settledAt;

  factory ProviderTransactionVO.fromJson(JsonMap json) {
    return ProviderTransactionVO(
      txId: readInt(json, 'txId'),
      orderNo: readString(json, 'orderNo'),
      clientNameMasked: readString(json, 'clientNameMasked'),
      netAmount: readDouble(json, 'netAmount'),
      currency: readString(json, 'currency', fallback: 'CNY'),
      txType: readString(json, 'txType'),
      settledAt: readString(json, 'settledAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'txId': txId,
      'orderNo': orderNo,
      'clientNameMasked': clientNameMasked,
      'netAmount': netAmount,
      'currency': currency,
      'txType': txType,
      'settledAt': settledAt,
    };
  }
}

class ProviderWithdrawalVO {
  const ProviderWithdrawalVO({
    required this.withdrawalId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.cardNoMask,
    required this.bankName,
    required this.appliedAt,
    required this.processedAt,
    required this.remark,
  });

  final int withdrawalId;
  final double amount;
  final String currency;
  final String status;
  final String cardNoMask;
  final String bankName;
  final String appliedAt;
  final String processedAt;
  final String remark;

  factory ProviderWithdrawalVO.fromJson(JsonMap json) {
    return ProviderWithdrawalVO(
      withdrawalId: readInt(json, 'withdrawalId'),
      amount: readDouble(json, 'amount'),
      currency: readString(json, 'currency', fallback: 'CNY'),
      status: readString(json, 'status'),
      cardNoMask: readString(json, 'cardNoMask'),
      bankName: readString(json, 'bankName'),
      appliedAt: readString(json, 'appliedAt'),
      processedAt: readString(json, 'processedAt'),
      remark: readString(json, 'remark'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'withdrawalId': withdrawalId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'cardNoMask': cardNoMask,
      'bankName': bankName,
      'appliedAt': appliedAt,
      'processedAt': processedAt,
      'remark': remark,
    };
  }
}

class ProviderBankCardVO {
  const ProviderBankCardVO({
    required this.cardId,
    required this.bankName,
    required this.cardNoMask,
    required this.cardHolder,
    required this.isDefault,
    required this.createdAt,
  });

  final int cardId;
  final String bankName;
  final String cardNoMask;
  final String cardHolder;
  final bool isDefault;
  final String createdAt;

  factory ProviderBankCardVO.fromJson(JsonMap json) {
    return ProviderBankCardVO(
      cardId: readInt(json, 'cardId'),
      bankName: readString(json, 'bankName'),
      cardNoMask: readString(json, 'cardNoMask'),
      cardHolder: readString(json, 'cardHolder'),
      isDefault: readBool(json, 'isDefault'),
      createdAt: readString(json, 'createdAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'cardId': cardId,
      'bankName': bankName,
      'cardNoMask': cardNoMask,
      'cardHolder': cardHolder,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }
}

class AddBankCardBO {
  const AddBankCardBO({
    required this.bankName,
    required this.cardNoMask,
    required this.cardHolder,
    this.isDefault = false,
  });

  final String bankName;
  final String cardNoMask;
  final String cardHolder;
  final bool isDefault;

  JsonMap toJson() {
    return <String, dynamic>{
      'bankName': bankName,
      'cardNoMask': cardNoMask,
      'cardHolder': cardHolder,
      'isDefault': isDefault,
    };
  }
}

class WithdrawBO {
  const WithdrawBO({required this.amount, required this.cardId});

  final double amount;
  final int cardId;

  JsonMap toJson() {
    return <String, dynamic>{'amount': amount, 'cardId': cardId};
  }
}
