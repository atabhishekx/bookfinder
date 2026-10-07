import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/favorites_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/book_card.dart';
import '../widgets/category_distribution.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/recommended_books_section.dart';
import '../widgets/wishlist_section.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final FocusNode _focusNode = FocusNode();

  SearchResponse? _searchResponse;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;

  final ScrollController _scrollController = ScrollController();

  List<BookCategory> _categories = [];
  List<Book> _recommendations = [];
  bool _isLoadingHome = true;
  String? _homeError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
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

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoadingHome = true;
      _homeError = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getRecommendations(limit: 12),
      ]);

      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<BookCategory>;
        _recommendations = results[1] as List<Book>;
        _isLoadingHome = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingHome = false;
        _homeError = 'Could not load recommendations. Pull down to retry.';
      });
    }
  }

  Future<void> _search({bool isNewSearch = true}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResponse = null;
        _errorMessage = null;
      });
      return;
    }

    if (isNewSearch) {
      _currentPage = 1;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _searchResponse = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _apiService.searchBooks(
        query: query,
        page: _currentPage,
      );

      if (isNewSearch) {
        setState(() {
          _searchResponse = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _searchResponse = SearchResponse(
            query: response.query,
            page: response.page,
            total: response.total,
            results: [..._searchResponse!.results, ...response.results],
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
        _errorMessage = 'Network error. Please check your connection and try again.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore ||
        _searchResponse == null ||
        _searchResponse!.results.length >= _searchResponse!.total) {
      return;
    }
    await _search(isNewSearch: false);
  }

  void _onBookTap(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
    );
  }

  bool get _isSearching =>
      _searchController.text.trim().isNotEmpty || _searchResponse != null;

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 34),
            SizedBox(width: 10),
            Text(appName),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, or keyword...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResponse = null;
                                _errorMessage = null;
                              });
                            },
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  onChanged: (value) {
                    if (value.isEmpty && _searchController.text.isNotEmpty) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  appTagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isSearching
          ? _buildSearchResults(favoritesProvider)
          : _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoadingHome) {
      return const LoadingState(message: 'Loading your library...');
    }

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 24),
            if (_homeError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _homeError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            if (_homeError != null) const SizedBox(height: 12),
            CategoryDistribution(categories: _categories),
            const SizedBox(height: 24),
            RecommendedBooksSection(
              books: _recommendations,
              isLoading: false,
              onSeeAll: () {},
            ),
            const SizedBox(height: 24),
            const WishlistSection(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Your Next',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha:0.9),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Favorite Book',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore trending books across categories',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha:0.85),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const AppLogo(size: 72),
        ],
      ),
    );
  }

  Widget _buildSearchResults(FavoritesProvider favoritesProvider) {
    if (_errorMessage != null &&
        (_searchResponse == null || _searchResponse!.results.isEmpty)) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _search,
      );
    }

    if (_isLoading && (_searchResponse == null || _searchResponse!.results.isEmpty)) {
      return const LoadingState(message: 'Searching for books...');
    }

    if (_searchResponse == null) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Start your search',
        message: 'Enter a book title, author name, or keyword to discover books.',
      );
    }

    if (_searchResponse!.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No books found',
        message:
            'No results for "${_searchResponse!.query}". Try a different search term.',
      );
    }

    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _searchResponse!.results.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResponse!.results.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final book = _searchResponse!.results[index];
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

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final ApiService _apiService = ApiService();
  Book? _detailedBook;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      final book = await _apiService.getBookDetails(widget.book.displayId);
      setState(() {
        _detailedBook = book;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load book details. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final book = _detailedBook ?? widget.book;
    final isFavorite = favoritesProvider.isFavorite(book.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
            onPressed: () => favoritesProvider.toggleFavorite(book),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading book details...')
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _loadDetails)
              : _buildDetails(book, isFavorite),
    );
  }

  Widget _buildDetails(Book book, bool isFavorite) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Hero(
              tag: 'book_${book.id}',
              child: _buildCover(book.coverUrlL, width: 200),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            book.authorString,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoChips(book),
          if (book.ratingsAverage != null) ...[
            const SizedBox(height: 12),
            _buildRatingBar(book),
          ],
          if (book.description != null && book.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              book.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (book.subjects.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Subjects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.subjects
                  .map((subject) => Chip(
                        label: Text(subject),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          if (book.editionDetails != null && book.editionDetails!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Editions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...book.editionDetails!.map((edition) => _buildEditionCard(edition)),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBar(Book book) {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber.shade700,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(
          book.formattedRating,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (book.ratingsCount != null) ...[
          const SizedBox(width: 6),
          Text(
            '(${book.ratingsCount} ratings)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        if (book.wantToReadCount != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.bookmark_border,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${book.wantToReadCount} want to read',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChips(Book book) {
    final chips = <Widget>[];

    if (book.firstPublishYear != null) {
      chips.add(_InfoChip(
        icon: Icons.calendar_today_outlined,
        label: 'First published: ${book.firstPublishYear}',
      ));
    }

    if (book.editionCount != null && book.editionCount! > 0) {
      chips.add(_InfoChip(
        icon: Icons.book_outlined,
        label: '${book.editionCount} edition${book.editionCount == 1 ? '' : 's'}',
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildEditionCard(EditionDetail edition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (edition.title != null)
              Text(
                edition.title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (edition.publishDate != null)
                  _DetailRow(icon: Icons.date_range_outlined, text: edition.publishDate!),
                if (edition.publisher != null)
                  _DetailRow(icon: Icons.business_outlined, text: edition.publisher!),
                if (edition.numberOfPages != null)
                  _DetailRow(icon: Icons.description_outlined, text: '${edition.numberOfPages} pages'),
                if (edition.isbn != null)
                  _DetailRow(icon: Icons.numbers_outlined, text: 'ISBN: ${edition.isbn}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(String url, {double width = 120}) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: width * 1.5,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(
          Icons.menu_book_outlined,
          size: width * 0.4,
          color: Colors.grey[400],
        ),
      );
    }

    return Image.network(
      url,
      width: width,
      height: width * 1.5,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: width * 1.5,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: width * 1.5,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(
          Icons.menu_book_outlined,
          size: width * 0.4,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
