import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favorites_provider.dart';
import '../screens/home_screen.dart';
import '../widgets/app_logo.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final favorites = favoritesProvider.favorites;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 30),
                const SizedBox(width: 10),
                Text('Favorites (${favorites.length})'),
              ],
            ),
            actions: favorites.isEmpty
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showClearDialog(context, favoritesProvider),
                      tooltip: 'Clear all favorites',
                    ),
                  ],
          ),
          body: favorites.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_outline,
                  title: 'No favorites yet',
                  message: 'Search for books and tap the heart icon to save them here.',
                )
              : RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final book = favorites[index];
                      return BookCard(
                        book: book,
                        isFavorite: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailsScreen(book: book),
                          ),
                        ),
                        onFavoriteToggle: () => favoritesProvider.removeFavorite(book.id),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, FavoritesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all favorites?'),
        content: const Text('This will remove all saved books from your favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearFavorites();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}