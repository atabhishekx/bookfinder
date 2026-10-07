import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/favorites_provider.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../utils/constants.dart';
import '../widgets/book_card.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';

class CategoryScreen extends StatefulWidget {
  final BookCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  SearchResponse? _response;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBooks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadBooks({bool isNewSearch = true}) async {
    if (isNewSearch) {
      _currentPage = 1;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _apiService.getBooksBySubject(
        subject: widget.category.subject,
        page: _currentPage,
      );

      if (isNewSearch) {
        setState(() {
          _response = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _response = SearchResponse(
            query: response.query,
            page: response.page,
            total: response.total,
            results: [...?_response?.results, ...response.results],
          );
          _isLoadingMore = false;
        });
      }
      _currentPage++;
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore ||
        _response == null ||
        _response!.results.length >= _response!.total) {
      return;
    }
    await _loadBooks(isNewSearch: false);
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
        title: Text(widget.category.name),
      ),
      body: _buildBody(favoritesProvider),
    );
  }

  Widget _buildBody(FavoritesProvider favoritesProvider) {
    if (_errorMessage != null && (_response == null || _response!.results.isEmpty)) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: () => _loadBooks(),
      );
    }

    if (_isLoading && (_response == null || _response!.results.isEmpty)) {
      return const LoadingState(message: 'Loading books...');
    }

    if (_response == null || _response!.results.isEmpty) {
      return const Center(child: Text('No books found in this category.'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadBooks(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _response!.results.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _response!.results.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final book = _response!.results[index];
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
