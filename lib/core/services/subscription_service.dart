import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../config/api_endpoints.dart';

class SubscriptionStatus {
  final String tier;
  final String status;
  final String? currentPeriodEnd;
  final String? stripeSubscriptionId;

  SubscriptionStatus({
    required this.tier,
    required this.status,
    this.currentPeriodEnd,
    this.stripeSubscriptionId,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: json['tier'] ?? 'free',
      status: json['status'] ?? 'none',
      currentPeriodEnd: json['current_period_end'],
      stripeSubscriptionId: json['stripe_subscription_id'],
    );
  }

  bool get isFree => tier == 'free';
  bool get isBasic => tier == 'basic';
  bool get isPremium => tier == 'premium';
  bool get isActive => status == 'active';
}

class SubscriptionService {
  static SubscriptionService? _instance;
  final ApiClient _api;

  static SubscriptionService get instance {
    _instance ??= SubscriptionService._(ApiClient.instance);
    return _instance!;
  }

  SubscriptionService._(this._api);

  /// Create a Stripe Checkout session for a subscription tier
  Future<Map<String, dynamic>> createCheckout(String tier) async {
    try {
      final response = await _api.post(
        ApiEndpoints.subscriptionCheckout,
        data: {'tier': tier},
      );

      if (response.data['success'] == true) {
        return {
          'checkout_url': response.data['checkout_url'] as String,
          'session_id': response.data['session_id'] as String,
        };
      }
      throw SubscriptionException(
        response.data['error']?['message'] ?? 'Failed to create checkout',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create checkout session');
    }
  }

  /// Open Stripe billing portal
  Future<String> openPortal() async {
    try {
      final response = await _api.post(ApiEndpoints.subscriptionPortal);

      if (response.data['success'] == true) {
        return response.data['portal_url'] as String;
      }
      throw SubscriptionException(
        response.data['error']?['message'] ?? 'Failed to open portal',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to open billing portal');
    }
  }

  /// Get current subscription status
  Future<SubscriptionStatus> getStatus() async {
    try {
      final response = await _api.get(ApiEndpoints.subscriptionStatus);

      if (response.data['success'] == true) {
        return SubscriptionStatus.fromJson(
          response.data['subscription'] as Map<String, dynamic>,
        );
      }
      throw SubscriptionException('Failed to get subscription status');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to get subscription status');
    }
  }

  SubscriptionException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] is Map) {
        return SubscriptionException(
          data['error']['message'] ?? fallback,
          code: data['error']['code'],
        );
      }
      return SubscriptionException(data['message'] ?? fallback);
    }
    return SubscriptionException(fallback);
  }
}

class SubscriptionException implements Exception {
  final String message;
  final String? code;

  SubscriptionException(this.message, {this.code});

  @override
  String toString() => message;
}
