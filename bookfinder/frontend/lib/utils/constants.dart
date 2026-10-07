const String baseUrl = 'http://localhost:3000/api';

const String coverBaseUrl = 'https://covers.openlibrary.org/b/id';

const Map<String, String> coverSizes = {
  'S': '-S.jpg',
  'M': '-M.jpg',
  'L': '-L.jpg',
};

const Duration apiTimeout = Duration(seconds: 15);

const int defaultPageSize = 20;
const int maxPageSize = 50;

const String appName = 'BookFinder';
const String appTagline = 'Discover your next favorite book';

class BookCategory {
  final String name;
  final String subject;
  final String emoji;
  final int bookCount;
  final double percentage;

  const BookCategory({
    required this.name,
    required this.subject,
    required this.emoji,
    this.bookCount = 0,
    this.percentage = 0.0,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      bookCount: json['bookCount'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

const List<BookCategory> bookCategories = [
  BookCategory(name: 'Fiction', subject: 'fiction', emoji: '\u{1F4D6}'),
  BookCategory(name: 'Science', subject: 'science', emoji: '\u{1F52C}'),
  BookCategory(name: 'History', subject: 'history', emoji: '\u{1F3DB}'),
  BookCategory(name: 'Romance', subject: 'romance', emoji: '\u{1F495}'),
  BookCategory(name: 'Mystery', subject: 'mystery', emoji: '\u{1F50D}'),
  BookCategory(name: 'Fantasy', subject: 'fantasy', emoji: '\u{1F409}'),
  BookCategory(name: 'Biography', subject: 'biography', emoji: '\u{1F464}'),
  BookCategory(name: 'Self-Help', subject: 'self-help', emoji: '\u{1F31F}'),
  BookCategory(name: 'Technology', subject: 'technology', emoji: '\u{1F4BB}'),
  BookCategory(name: 'Art', subject: 'art', emoji: '\u{1F3A8}'),
  BookCategory(name: 'Poetry', subject: 'poetry', emoji: '\u{270D}'),
  BookCategory(name: 'Thriller', subject: 'thriller', emoji: '\u{1F631}'),
  BookCategory(name: 'Philosophy', subject: 'philosophy', emoji: '\u{1F914}'),
  BookCategory(name: 'Travel', subject: 'travel', emoji: '\u{2708}'),
  BookCategory(name: 'Comics', subject: 'comics', emoji: '\u{1F4AC}'),
  BookCategory(name: 'Horror', subject: 'horror', emoji: '\u{1F47B}'),
];