class Transaction {
  final String id;
  final String description;
  final double amount;
  final String category;
  final String mood;
  final String location;
  final DateTime date;
  final String type; // 'income' or 'expense'

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.mood,
    required this.location,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'mood': mood,
      'location': location,
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      mood: map['mood'],
      location: map['location'],
      date: DateTime.parse(map['date']),
      type: map['type'],
    );
  }
}
