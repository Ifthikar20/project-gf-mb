import 'package:flutter/foundation.dart';

/// Singleton service to manage liked videos library
class LibraryService extends ChangeNotifier {
  static final LibraryService _instance = LibraryService._internal();
  static LibraryService get instance => _instance;
  
  LibraryService._internal();
  
  final Set<String> _likedVideoIds = {};
  
  Set<String> get likedVideoIds => Set.unmodifiable(_likedVideoIds);
  
  bool isLiked(String videoId) => _likedVideoIds.contains(videoId);
  
  void toggleLike(String videoId, bool isLiked) {
    if (isLiked) {
      _likedVideoIds.add(videoId);
    } else {
      _likedVideoIds.remove(videoId);
    }
    notifyListeners();
  }
  
  void addLike(String videoId) {
    _likedVideoIds.add(videoId);
    notifyListeners();
  }
  
  void removeLike(String videoId) {
    _likedVideoIds.remove(videoId);
    notifyListeners();
  }
  
  int get likedCount => _likedVideoIds.length;
}
