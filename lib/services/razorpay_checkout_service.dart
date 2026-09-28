import 'dart:async';
import 'razorpay/razorpay_bridge.dart';

class RazorpayPaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;

  RazorpayPaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
  });
}

class RazorpayCheckoutService {
  /// Create Order via Web JS Bridge to bypass Flutter Web fetch restrictions
  static Future<Map<String, dynamic>?> createOrderViaJs({
    required String userId,
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) async {
    return createOrderViaJsImpl(
      userId: userId,
      amount: amount,
      name: name,
      phone: phone,
      email: email,
    );
  }

  static Future<RazorpayPaymentResult> openCheckout({
    required String keyId,
    required String orderId,
    required double amount, // in rupees
    required String name,
    required String description,
    required String userEmail,
    required String userPhone,
    required String userName,
  }) async {
    return openCheckoutImpl(
      keyId: keyId,
      orderId: orderId,
      amount: amount,
      name: name,
      description: description,
      userEmail: userEmail,
      userPhone: userPhone,
      userName: userName,
    );
  }
}

