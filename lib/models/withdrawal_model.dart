enum WithdrawalStatus { pending, completed, rejected }

class WithdrawalModel {
  String id;
  String userId;
  String userName;
  String? userPhone;
  double amount; // INR Payout Amount (e.g. ₹50.0)
  double coinAmount; // Winning Coins Redeemed (e.g. 500 Coins)
  String upiId;
  WithdrawalStatus status;
  DateTime requestedAt;
  DateTime? processedAt;
  String? adminNotes;
  String? payoutTxnRef;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.amount,
    double? coinAmount,
    required this.upiId,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.adminNotes,
    this.payoutTxnRef,
  }) : coinAmount = coinAmount ?? amount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userPhone': userPhone,
    'amount': amount,
    'coinAmount': coinAmount,
    'upiId': upiId,
    'status': status.name,
    'requestedAt': requestedAt.toIso8601String(),
    'processedAt': processedAt?.toIso8601String(),
    'adminNotes': adminNotes,
    'payoutTxnRef': payoutTxnRef,
  };

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    final amt = ((json['amount'] ?? 0) as num).toDouble();
    return WithdrawalModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'],
      amount: amt,
      coinAmount: json['coinAmount'] != null ? ((json['coinAmount']) as num).toDouble() : amt,
      upiId: json['upiId'] ?? '',
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      requestedAt: json['requestedAt'] != null ? DateTime.parse(json['requestedAt']) : DateTime.now(),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
      adminNotes: json['adminNotes'],
      payoutTxnRef: json['payoutTxnRef'],
    );
  }
}
