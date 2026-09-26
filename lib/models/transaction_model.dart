enum TransactionType {
  adReward,
  deposit,
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
  depositCash,   // 💵 Real money deposit (Paid entry only)
  winningCash,   // 🏆 Real money winnings (UPI withdrawable)
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
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    userName: json['userName'] ?? '',
    type: TransactionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TransactionType.deposit,
    ),
    walletAffected: WalletType.values.firstWhere(
      (e) => e.name == json['walletAffected'],
      orElse: () => WalletType.depositCash,
    ),
    amount: ((json['amount'] ?? 0) as num).toDouble(),
    currency: json['currency'] ?? 'INR',
    balanceBefore: ((json['balanceBefore'] ?? 0) as num).toDouble(),
    balanceAfter: ((json['balanceAfter'] ?? 0) as num).toDouble(),
    status: json['status'] ?? 'SUCCESS',
    description: json['description'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    metadata: json['metadata'],
  );
}
