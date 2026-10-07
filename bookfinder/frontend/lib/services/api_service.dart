import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Future<SearchResponse> searchBooks({
    required String query,
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final uri = Uri.parse('$baseUrl/books/search').replace(
      queryParameters: {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(uri).timeout(apiTimeout);

    if (response.statusCode == 200) {
      return SearchResponse.fromJson(jsonDecode(response.body));
    }

    throw ApiException(_extractErrorMessage(response.body, response.statusCode));
  }

  Future<Book> getBookDetails(String workId) async {
    final uri = Uri.parse('$baseUrl/books/$workId');
    final response = await _client.get(uri).timeout(apiTimeout);

    if (response.statusCode == 200) {
      return Book.fromJson(jsonDecode(response.body));
    }

    throw ApiException(_extractErrorMessage(response.body, response.statusCode));
  }

  Future<List<Book>> getRecommendations({int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/books/recommendations').replace(
      queryParameters: {'limit': limit.toString()},
    );

    final response = await _client.get(uri).timeout(apiTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = (data['results'] as List<dynamic>?) ?? [];
      return results
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Failed to load recommendations');
  }

  Future<List<BookCategory>> getCategories() async {
    final uri = Uri.parse('$baseUrl/books/categories');
    final response = await _client.get(uri).timeout(apiTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final categories = (data['categories'] as List<dynamic>?) ?? [];
      return categories
          .map((e) => BookCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Failed to load categories');
  }

  Future<SearchResponse> getBooksBySubject({
    required String subject,
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final uri = Uri.parse('$baseUrl/books/subject/$subject').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    // Subject queries can be slow (the backend retries upstream), so allow
    // extra time before giving up.
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return SearchResponse.fromJson(jsonDecode(response.body));
    }

    throw ApiException(_extractErrorMessage(response.body, response.statusCode));
  }

  /// Pulls a human-readable message out of an error response body,
  /// falling back to a generic status message.
  String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Body was not JSON — fall through to the generic message.
    }
    if (statusCode == 404) return 'Book not found';
    return 'Server error: $statusCode';
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}