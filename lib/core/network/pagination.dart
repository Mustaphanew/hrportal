import 'package:equatable/equatable.dart';

/// Pagination model as returned by the API contract v1.0.0 (§10.6).
///
/// Example:
/// ```json
/// {
///   "current_page": 1,
///   "last_page": 3,
///   "per_page": 15,
///   "total": 45
/// }
/// ```
class Pagination extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      };

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
  bool get isFirstPage => currentPage <= 1;
  bool get isLastPage => currentPage >= lastPage;

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total];
}
