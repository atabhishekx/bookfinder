import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/favorites_provider.dart';
import '../services/api_service.dart';
import '../widgets/book_card.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'home_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _apiService.getRecommendations(limit: 20);
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load recommendations. Please try again.';
      });
    }
  }

  void _onBookTap(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended for You'),
      ),
      body: _buildBody(favoritesProvider),
    );
  }

  Widget _buildBody(FavoritesProvider favoritesProvider) {
    if (_errorMessage != null && _books.isEmpty) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadRecommendations,
      );
    }

    if (_isLoading && _books.isEmpty) {
      return const LoadingState(message: 'Loading recommendations...');
    }

    if (_books.isEmpty) {
      return const Center(child: Text('No recommendations available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          final isFavorite = favoritesProvider.isFavorite(book.id);

          return BookCard(
            book: book,
            isFavorite: isFavorite,
            onTap: () => _onBookTap(book),
            onFavoriteToggle: () => favoritesProvider.toggleFavorite(book),
          );
        },
      ),
    );
  }
}
