import '../razorpay_checkout_service.dart';

Future<Map<String, dynamic>?> createOrderViaJsImpl({
  required String userId,
  required double amount,
  required String name,
  required String phone,
  required String email,
}) async {
  return null;
}

Future<RazorpayPaymentResult> openCheckoutImpl({
  required String keyId,
  required String orderId,
  required double amount,
  required String name,
  required String description,
  required String userEmail,
  required String userPhone,
  required String userName,
}) async {
  return RazorpayPaymentResult(
    success: true,
    paymentId: 'pay_native_${DateTime.now().millisecondsSinceEpoch}',
    orderId: orderId,
    signature: 'sig_native_${DateTime.now().millisecondsSinceEpoch}',
  );
}
