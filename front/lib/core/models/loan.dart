// loan.dart — modèle Loan sans code generation
import 'book.dart';
import 'user.dart';

enum LoanDirection { out, in_ }

class Loan {
  final String id;
  final Book book;
  final User partner;
  final LoanDirection direction;
  final DateTime since;
  final DateTime? dueDate;
  final bool returned;
  final DateTime? returnedAt;

  const Loan({
    required this.id,
    required this.book,
    required this.partner,
    required this.direction,
    required this.since,
    this.dueDate,
    this.returned = false,
    this.returnedAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      partner: User.fromJson(json['partner'] as Map<String, dynamic>),
      direction: (json['direction'] as String?) == 'out'
          ? LoanDirection.out
          : LoanDirection.in_,
      since: DateTime.parse(json['since'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      returned: json['returned'] as bool? ?? false,
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'] as String)
          : null,
    );
  }

  int? get daysRemaining {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue {
    final r = daysRemaining;
    return r != null && r < 0;
  }

  bool get isUrgent {
    final r = daysRemaining;
    return r != null && r >= 0 && r <= 7;
  }

  double get progressRatio {
    if (dueDate == null) return 0;
    final total = dueDate!.difference(since).inDays;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(since).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
