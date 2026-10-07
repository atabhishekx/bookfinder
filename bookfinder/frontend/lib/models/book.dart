import '../utils/constants.dart';

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final int? firstPublishYear;
  final int? coverId;
  final String? description;
  final List<String> subjects;
  final int? editionCount;
  final List<EditionDetail>? editionDetails;
  final double? ratingsAverage;
  final int? ratingsCount;
  final int? wantToReadCount;
  final String? reason;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.firstPublishYear,
    this.coverId,
    this.description,
    required this.subjects,
    this.editionCount,
    this.editionDetails,
    this.ratingsAverage,
    this.ratingsCount,
    this.wantToReadCount,
    this.reason,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      authors: (json['authors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      firstPublishYear: json['first_publish_year'] as int?,
      coverId: json['cover_id'] as int?,
      description: json['description']?.toString(),
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      editionCount: json['edition_count'] as int?,
      editionDetails: (json['edition_details'] as List<dynamic>?)
          ?.map((e) => EditionDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      ratingsAverage: (json['ratings_average'] as num?)?.toDouble(),
      ratingsCount: json['ratings_count'] as int?,
      wantToReadCount: json['want_to_read_count'] as int?,
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'first_publish_year': firstPublishYear,
      'cover_id': coverId,
      'description': description,
      'subjects': subjects,
      'edition_count': editionCount,
      'edition_details': editionDetails?.map((e) => e.toJson()).toList(),
      'ratings_average': ratingsAverage,
      'ratings_count': ratingsCount,
      'want_to_read_count': wantToReadCount,
      'reason': reason,
    };
  }

  String get authorString => authors.isEmpty ? 'Unknown Author' : authors.join(', ');

  String get coverUrlS => coverId != null ? '$coverBaseUrl/$coverId-S.jpg' : '';
  String get coverUrlM => coverId != null ? '$coverBaseUrl/$coverId-M.jpg' : '';
  String get coverUrlL => coverId != null ? '$coverBaseUrl/$coverId-L.jpg' : '';

  String get displayId => id.replaceAll('/works/', '');

  String get formattedRating =>
      ratingsAverage != null ? ratingsAverage!.toStringAsFixed(1) : '--';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class EditionDetail {
  final String key;
  final String? title;
  final int? coverId;
  final String? isbn;
  final String? publishDate;
  final int? numberOfPages;
  final String? publisher;

  EditionDetail({
    required this.key,
    this.title,
    this.coverId,
    this.isbn,
    this.publishDate,
    this.numberOfPages,
    this.publisher,
  });

  factory EditionDetail.fromJson(Map<String, dynamic> json) {
    return EditionDetail(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString(),
      coverId: json['cover_id'] as int?,
      isbn: json['isbn']?.toString(),
      publishDate: json['publish_date']?.toString(),
      numberOfPages: json['number_of_pages'] as int?,
      publisher: json['publisher']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'cover_id': coverId,
      'isbn': isbn,
      'publish_date': publishDate,
      'number_of_pages': numberOfPages,
      'publisher': publisher,
    };
  }
}

class SearchResponse {
  final String query;
  final int page;
  final int total;
  final List<Book> results;

  SearchResponse({
    required this.query,
    required this.page,
    required this.total,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query']?.toString() ?? '',
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}