import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _favoritesKey = 'bookfinder_favorites';
  final List<Book> _favorites = [];

  List<Book> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String bookId) => _favorites.any((b) => b.id == bookId);

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _favorites.clear();
        _favorites.addAll(decoded.map((e) => Book.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_favorites.map((b) => b.toJson()).toList());
      await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> toggleFavorite(Book book) async {
    final index = _favorites.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, book);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String bookId) async {
    _favorites.removeWhere((b) => b.id == bookId);
    await _saveFavorites();
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    _saveFavorites();
    notifyListeners();
  }
}