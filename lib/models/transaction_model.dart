enum TransactionType {
  adReward,
  deposit,
  bonusCashback,
  matchEntryFee,
  matchWinningCash,
  matchWinningRewardCoins,
  voucherRedeem,
  withdrawalRequest,
  withdrawalRefund,
  adminAdjustment,
}

enum WalletType {
  adCoins,       // 🟡 Free entry
  rewardCoins,   // 🎟️ Free match winnings (Redeem only)
  bonusCash,     // 🎁 10% Extra Cashback / Referral Bonus (Non-withdrawable, used first)
  depositCash,   // 💵 Real money deposit (Non-withdrawable, match entry only)
  winningCash,   // 🏆 Real money winnings (100% UPI withdrawable)
}

class TransactionModel {
  String id;
  String userId;
  String userName;
  TransactionType type;
  WalletType walletAffected;
  double amount;
  String currency; // 'AD_COINS' | 'REWARD_COINS' | 'INR'
  double balanceBefore;
  double balanceAfter;
  String status; // 'SUCCESS' | 'PENDING' | 'FAILED'
  String description;
  DateTime createdAt;
  Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.walletAffected,
    required this.amount,
    required this.currency,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.description,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'type': type.name,
    'walletAffected': walletAffected.name,
    'amount': amount,
    'currency': currency,
    'balanceBefore': balanceBefore,
    'balanceAfter': balanceAfter,
    'status': status,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: (json['id'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}') as String,
    userId: (json['userId'] ?? 'anonymous') as String,
    userName: (json['userName'] ?? 'Player') as String,
    type: TransactionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TransactionType.deposit,
    ),
    walletAffected: WalletType.values.firstWhere(
      (e) => e.name == json['walletAffected'],
      orElse: () => WalletType.depositCash,
    ),
    amount: ((json['amount'] ?? json['credited_amount'] ?? 0) as num).toDouble(),
    currency: (json['currency'] ?? 'INR') as String,
    balanceBefore: ((json['balanceBefore'] ?? 0) as num).toDouble(),
    balanceAfter: ((json['balanceAfter'] ?? 0) as num).toDouble(),
    status: (json['status'] ?? 'SUCCESS') as String,
    description: (json['description'] ?? '') as String,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
  );
}
