import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_config.dart';

class PaymentOrderResponse {
  final bool success;
  final String orderId;
  final int amountInPaise;
  final String currency;
  final String keyId;
  final String name;
  final String description;
  final double bonusCoins;
  final double realAmount;
  final String? errorMessage;

  PaymentOrderResponse({
    required this.success,
    required this.orderId,
    required this.amountInPaise,
    required this.currency,
    required this.keyId,
    required this.name,
    required this.description,
    required this.bonusCoins,
    required this.realAmount,
    this.errorMessage,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'] ?? json['order_id'] ?? json['id'] ?? '';
    return PaymentOrderResponse(
      success: (json['success'] == true || orderId.toString().isNotEmpty),
      orderId: orderId.toString(),
      amountInPaise: (json['amount'] ?? 0) as int,
      currency: json['currency'] ?? 'INR',
      keyId: json['keyId'] ?? json['key'] ?? FirebaseConfig.defaultRazorpayKeyId,
      name: json['name'] ?? 'SW Tech Solution',
      description: json['description'] ?? 'Wallet Recharge',
      bonusCoins: ((json['bonusCoins'] ?? json['bonus'] ?? 0) as num).toDouble(),
      realAmount: ((json['realAmount'] ?? 0) as num).toDouble(),
      errorMessage: json['error'] ?? json['message'],
    );
  }
}

class PaymentVerificationResponse {
  final bool success;
  final String message;
  final double addedReal;
  final double addedBonus;
  final double totalAdded;

  PaymentVerificationResponse({
    required this.success,
    required this.message,
    required this.addedReal,
    required this.addedBonus,
    required this.totalAdded,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      success: json['success'] == true,
      message: json['message'] ?? 'Payment verified successfully',
      addedReal: ((json['addedReal'] ?? json['realAmount'] ?? 0) as num).toDouble(),
      addedBonus: ((json['addedBonus'] ?? json['bonusCoins'] ?? 0) as num).toDouble(),
      totalAdded: ((json['totalAdded'] ?? 0) as num).toDouble(),
    );
  }
}

class PaymentService {
  /// 1. Create Live Razorpay Order via SW Tech Backend
  static Future<PaymentOrderResponse> createOrder({
    required String userId,
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(FirebaseConfig.orderEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'uid': userId.isNotEmpty ? userId : 'USER_123',
          'userId': userId.isNotEmpty ? userId : 'USER_123',
          'amount': amount.toInt(),
          'name': name.isNotEmpty ? name : 'Gamer',
          'phone': phone,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PaymentOrderResponse.fromJson(data);
      } else {
        debugPrint('[PaymentService] Order HTTP error: ${response.statusCode} - ${response.body}');
        return PaymentOrderResponse(
          success: false,
          orderId: '',
          amountInPaise: (amount * 100).toInt(),
          currency: 'INR',
          keyId: FirebaseConfig.defaultRazorpayKeyId,
          name: 'SW Tech Solution',
          description: 'Wallet Recharge',
          bonusCoins: amount * 0.5,
          realAmount: amount,
          errorMessage: 'Server returned HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[PaymentService] Order network exception: $e');
      return PaymentOrderResponse(
        success: false,
        orderId: '',
        amountInPaise: (amount * 100).toInt(),
        currency: 'INR',
        keyId: FirebaseConfig.defaultRazorpayKeyId,
        name: 'SW Tech Solution',
        description: 'Wallet Recharge',
        bonusCoins: amount * 0.5,
        realAmount: amount,
        errorMessage: 'Network error connecting to payment gateway: $e',
      );
    }
  }

  /// 2. Verify Payment & Auto-Credit Wallet in Firebase
  static Future<PaymentVerificationResponse> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String userId,
    required double amount,
    required double bonusCoins,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(FirebaseConfig.verifyEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'uid': userId.isNotEmpty ? userId : 'USER_123',
          'userId': userId.isNotEmpty ? userId : 'USER_123',
          'orderId': orderId,
          'razorpay_order_id': orderId,
          'paymentId': paymentId,
          'razorpay_payment_id': paymentId,
          'signature': signature,
          'razorpay_signature': signature,
          'amount': amount.toInt(),
          'bonusCoins': bonusCoins.toInt(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentVerificationResponse.fromJson(data);
      } else {
        debugPrint('[PaymentService] Verify HTTP error: ${response.statusCode} - ${response.body}');
        return PaymentVerificationResponse(
          success: false,
          message: 'Payment verification failed on server: ${response.body}',
          addedReal: 0,
          addedBonus: 0,
          totalAdded: 0,
        );
      }
    } catch (e) {
      debugPrint('[PaymentService] Verify network exception: $e');
      return PaymentVerificationResponse(
        success: false,
        message: 'Network error verifying payment: $e',
        addedReal: 0,
        addedBonus: 0,
        totalAdded: 0,
      );
    }
  }
}
