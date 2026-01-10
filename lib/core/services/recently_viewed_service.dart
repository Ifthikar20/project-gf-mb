import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A recently viewed content item
class RecentlyViewedItem {
  final String contentId;
  final String title;
  final String? thumbnailUrl;
  final String contentType; // 'video' or 'audio'
  final DateTime viewedAt;
  final int? durationSeconds;
  
  RecentlyViewedItem({
    required this.contentId,
    required this.title,
    this.thumbnailUrl,
    required this.contentType,
    required this.viewedAt,
    this.durationSeconds,
  });
  
  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'contentType': contentType,
    'viewedAt': viewedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };
  
  factory RecentlyViewedItem.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedItem(
      contentId: json['contentId'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      contentType: json['contentType'] ?? 'video',
      viewedAt: DateTime.tryParse(json['viewedAt'] ?? '') ?? DateTime.now(),
      durationSeconds: json['durationSeconds'],
    );
  }
}

/// Service to track and persist recently viewed content
class RecentlyViewedService extends ChangeNotifier {
  static final RecentlyViewedService _instance = RecentlyViewedService._internal();
  static RecentlyViewedService get instance => _instance;
  
  static const String _storageKey = 'recently_viewed';
  static const int _maxItems = 20; // Keep last 20 items
  
  RecentlyViewedService._internal();
  
  final List<RecentlyViewedItem> _items = [];
  bool _isInitialized = false;
  
  List<RecentlyViewedItem> get items => List.unmodifiable(_items);
  
  int get count => _items.length;
  
  bool get isEmpty => _items.isEmpty;
  
  /// Initialize service - load from storage
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _items.clear();
        _items.addAll(
          jsonList.map((json) => RecentlyViewedItem.fromJson(json)).toList()
        );
        debugPrint('📚 Loaded ${_items.length} recently viewed items');
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Failed to load recently viewed: $e');
    }
  }
  
  /// Add content to recently viewed
  Future<void> addItem({
    required String contentId,
    required String title,
    String? thumbnailUrl,
    String contentType = 'video',
    int? durationSeconds,
  }) async {
    // Remove existing entry for this content if present
    _items.removeWhere((item) => item.contentId == contentId);
    
    // Add to the beginning (most recent first)
    _items.insert(0, RecentlyViewedItem(
      contentId: contentId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      contentType: contentType,
      viewedAt: DateTime.now(),
      durationSeconds: durationSeconds,
    ));
    
    // Limit to max items
    if (_items.length > _maxItems) {
      _items.removeRange(_maxItems, _items.length);
    }
    
    await _save();
    notifyListeners();
    
    debugPrint('📚 Added to recently viewed: $title');
  }
  
  /// Remove item from history
  Future<void> removeItem(String contentId) async {
    _items.removeWhere((item) => item.contentId == contentId);
    await _save();
    notifyListeners();
  }
  
  /// Clear all history
  Future<void> clearAll() async {
    _items.clear();
    await _save();
    notifyListeners();
    debugPrint('📚 Cleared recently viewed history');
  }
  
  /// Get videos only
  List<RecentlyViewedItem> get recentVideos =>
      _items.where((item) => item.contentType == 'video').toList();
  
  /// Get audio only
  List<RecentlyViewedItem> get recentAudio =>
      _items.where((item) => item.contentType == 'audio').toList();
  
  /// Persist to storage
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('❌ Failed to save recently viewed: $e');
    }
  }
}
