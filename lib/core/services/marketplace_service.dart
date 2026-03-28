import 'package:dio/dio.dart';
import 'api_client.dart';
import '../config/api_endpoints.dart';

class MarketplaceProgram {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? coverImageUrl;
  final String price;
  final MarketplaceCreator creator;
  final MarketplaceCategory? category;
  final int contentCount;
  final int purchaseCount;
  final bool isPurchased;

  MarketplaceProgram({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.coverImageUrl,
    required this.price,
    required this.creator,
    this.category,
    required this.contentCount,
    required this.purchaseCount,
    required this.isPurchased,
  });

  factory MarketplaceProgram.fromJson(Map<String, dynamic> json) {
    return MarketplaceProgram(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['cover_image_url'],
      price: json['price'] ?? '0.00',
      creator: MarketplaceCreator.fromJson(json['creator'] ?? {}),
      category: json['category'] != null
          ? MarketplaceCategory.fromJson(json['category'])
          : null,
      contentCount: json['content_count'] ?? 0,
      purchaseCount: json['purchase_count'] ?? 0,
      isPurchased: json['is_purchased'] ?? false,
    );
  }
}

class MarketplaceCreator {
  final String id;
  final String displayName;
  final String? avatarUrl;

  MarketplaceCreator({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory MarketplaceCreator.fromJson(Map<String, dynamic> json) {
    return MarketplaceCreator(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
    );
  }
}

class MarketplaceCategory {
  final String id;
  final String name;

  MarketplaceCategory({required this.id, required this.name});

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) {
    return MarketplaceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class ProgramContentItem {
  final String id;
  final String title;
  final String contentType;
  final String? thumbnailUrl;
  final int? durationSeconds;

  ProgramContentItem({
    required this.id,
    required this.title,
    required this.contentType,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  factory ProgramContentItem.fromJson(Map<String, dynamic> json) {
    return ProgramContentItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      contentType: json['content_type'] ?? 'video',
      thumbnailUrl: json['thumbnail_url'],
      durationSeconds: json['duration_seconds'],
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final minutes = durationSeconds! ~/ 60;
    return '$minutes min';
  }
}

class Purchase {
  final String id;
  final MarketplaceProgram? program;
  final String amount;
  final String status;
  final String? purchasedAt;

  Purchase({
    required this.id,
    this.program,
    required this.amount,
    required this.status,
    this.purchasedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] ?? '',
      program: json['program'] != null
          ? MarketplaceProgram.fromJson(json['program'])
          : null,
      amount: json['amount'] ?? '0.00',
      status: json['status'] ?? 'unknown',
      purchasedAt: json['purchased_at'],
    );
  }
}

class MarketplaceService {
  static MarketplaceService? _instance;
  final ApiClient _api;

  static MarketplaceService get instance {
    _instance ??= MarketplaceService._(ApiClient.instance);
    return _instance!;
  }

  MarketplaceService._(this._api);

  /// Browse marketplace programs
  Future<List<MarketplaceProgram>> getPrograms({
    String? categoryId,
    String? creatorId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category'] = categoryId;
      if (creatorId != null) queryParams['creator'] = creatorId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _api.get(
        ApiEndpoints.marketplacePrograms,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        final programs = (response.data['programs'] as List? ?? [])
            .map((p) => MarketplaceProgram.fromJson(p))
            .toList();
        return programs;
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load programs');
    }
  }

  /// Get program detail
  Future<MarketplaceProgram> getProgramDetail(String programId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.marketplaceProgramDetail(programId),
      );

      if (response.data['success'] == true) {
        final data = response.data['program'] ?? response.data;
        return MarketplaceProgram.fromJson(data);
      }
      throw MarketplaceException('Program not found');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load program');
    }
  }

  /// Purchase a program — returns Stripe client_secret
  Future<Map<String, dynamic>> purchaseProgram(String programId) async {
    try {
      final response = await _api.post(
        ApiEndpoints.marketplaceProgramPurchase(programId),
      );

      if (response.data['success'] == true) {
        return {
          'client_secret': response.data['client_secret'],
          'payment_intent_id': response.data['payment_intent_id'],
          'amount': response.data['amount'],
          'currency': response.data['currency'],
        };
      }
      throw MarketplaceException(
        response.data['error']?['message'] ?? 'Purchase failed',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Purchase failed');
    }
  }

  /// Get content for a purchased program
  Future<List<ProgramContentItem>> getProgramContent(String programId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.marketplaceProgramContent(programId),
      );

      if (response.data['success'] == true) {
        return (response.data['content_items'] as List? ?? [])
            .map((c) => ProgramContentItem.fromJson(c))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load program content');
    }
  }

  /// Get user's purchase history
  Future<List<Purchase>> getMyPurchases() async {
    try {
      final response = await _api.get(ApiEndpoints.marketplacePurchases);

      if (response.data['success'] == true) {
        return (response.data['purchases'] as List? ?? [])
            .map((p) => Purchase.fromJson(p))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load purchases');
    }
  }

  MarketplaceException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] is Map) {
        return MarketplaceException(
          data['error']['message'] ?? fallback,
          code: data['error']['code'],
        );
      }
      return MarketplaceException(data['message'] ?? fallback);
    }
    return MarketplaceException(fallback);
  }
}

class MarketplaceException implements Exception {
  final String message;
  final String? code;

  MarketplaceException(this.message, {this.code});

  @override
  String toString() => message;
}
