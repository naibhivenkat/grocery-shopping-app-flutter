class WalletTransaction {
  final String type;
  final double amount;
  final String date;
  final String? orderId;

  WalletTransaction({
    required this.type,
    required this.amount,
    required this.date,
    this.orderId,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      // Check 'type'
      type: json['type'] ?? "Unknown",
      
      // Check 'amount' (handle String or Number)
      amount: double.tryParse(json['amount']?.toString() ?? "0") ?? 0.0,
      
      // Check 'date_time' OR 'dateTime' OR 'created_at'
      date: json['date_time'] ?? json['dateTime'] ?? json['created_at'] ?? "",
      
      // Check 'order_id' OR 'orderId'
      orderId: json['order_id'] ?? json['orderId'],
    );
  }
}