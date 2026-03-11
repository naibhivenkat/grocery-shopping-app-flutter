import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/wallet_transaction_model.dart';
import '../../../services/session_manager.dart';
import '../api/service_api.dart';

class ServiceWalletScreen extends StatefulWidget {
  const ServiceWalletScreen({super.key});

  @override
  State<ServiceWalletScreen> createState() => _ServiceWalletScreenState();
}

class _ServiceWalletScreenState extends State<ServiceWalletScreen> {

  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  Map<String, List<WalletTransaction>> _grouped = {};

  bool _isLoading = true;
  bool _hideBalance = false;

  String _selectedFilter = "All";
  String? _userId;
  String _lastUpdated = "";

  late Razorpay _razorpay;
  String? _pendingBackendOrderId;

  StreamSubscription<DocumentSnapshot>? _walletSub;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _startWalletListener();
    _fetchData();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _walletSub?.cancel();
    super.dispose();
  }

  // ───────────────── REALTIME BALANCE LISTENER ─────────────────

  void _startWalletListener() async {
    _userId = await SessionManager.getServiceUserId();
    if (_userId == null) return;

    _walletSub = FirebaseFirestore.instance
        .collection("service_wallets")
        .doc(_userId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;

      final data = snap.data();
      setState(() {
        _balance = (data?["balance"] ?? 0).toDouble();
        _lastUpdated = DateFormat("hh:mm a").format(DateTime.now());
      });
    });
  }

  // ───────────────── FETCH + SORT + GROUP ─────────────────

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    _userId ??= await SessionManager.getServiceUserId();
    if (_userId == null) return;

    final txs = await ServiceApi.getWalletTransactions(_userId!);
    final bal = await ServiceApi.getWalletBalance(_userId!);

    // 🔥 SORT latest → oldest
    txs.sort((a, b) =>
        DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    _transactions = txs;
    _applyFilterAndGroup();

    setState(() {
      _balance = bal;
      _isLoading = false;
      _lastUpdated = DateFormat("hh:mm a").format(DateTime.now());
    });
  }

  // ───────────────── FILTER + GROUP BY DATE ─────────────────

  void _applyFilterAndGroup() {
    List<WalletTransaction> filtered = [];

    if (_selectedFilter == "All") {
      filtered = _transactions;
    } else if (_selectedFilter == "Credit") {
      filtered = _transactions.where((t) =>
          t.type.contains('deposit') ||
          t.type.contains('service_income')).toList();
    } else if (_selectedFilter == "Debit") {
      filtered = _transactions.where((t) =>
          t.type.contains('payment')).toList();
    } else if (_selectedFilter == "Refund") {
      filtered = _transactions.where((t) =>
          t.type.contains('refund')).toList();
    }

    _grouped = _groupByDate(filtered);
  }

  Map<String, List<WalletTransaction>> _groupByDate(List<WalletTransaction> list) {
    Map<String, List<WalletTransaction>> map = {};

    final now = DateTime.now();

    for (var tx in list) {
      DateTime date = DateTime.parse(tx.date).toLocal();

      String key;

      if (_isSameDay(date, now)) {
        key = "Today";
      } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
        key = "Yesterday";
      } else if (now.difference(date).inDays <= 7) {
        key = "This Week";
      } else {
        key = "Older";
      }

      map.putIfAbsent(key, () => []).add(tx);
    }

    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  // ───────────────── TYPE STYLING ─────────────────

  Color _colorForType(String type) {
    if (type.contains("deposit")) return Colors.blue;
    if (type.contains("service_income")) return Colors.green;
    if (type.contains("refund")) return Colors.orange;
    if (type.contains("payment")) return Colors.red;
    return Colors.grey;
  }

  IconData _iconForType(String type) {
    if (type.contains("deposit")) return Icons.account_balance_wallet;
    if (type.contains("service_income")) return Icons.work;
    if (type.contains("refund")) return Icons.replay;
    if (type.contains("payment")) return Icons.payments;
    return Icons.swap_horiz;
  }

  String _titleForType(String type) {
    switch (type) {
      case "deposit":
        return "Money Added";
      case "service_income":
        return "Service Earnings";
      case "refund":
        return "Refund to Customer";
      case "refund_debit":
        return "Refund Deducted";
      default:
        return type.replaceAll("_", " ").toUpperCase();
    }
  }

  // ───────────────── RAZORPAY ─────────────────

  Future<void> _createBackendOrder(double amount) async {
    final res = await ServiceApi.createWalletOrder(_userId!, amount);
    if (res == null) return;

    _pendingBackendOrderId = res["backend_order_id"];

    _razorpay.open({
      'key': 'rzp_test_RKK3DuGSaxK9fR',
      'amount': (amount * 100).toInt(),
      'name': 'Service Wallet',
      'order_id': res["razorpay_order_id"],
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBackendOrderId == null) return;

    bool success = await ServiceApi.verifyWalletPayment({
      "backend_order_id": _pendingBackendOrderId,
      "payment_id": response.paymentId,
      "order_id": response.orderId,
      "signature": response.signature
    });

    if (success) _fetchData();
  }

  void _handlePaymentError(PaymentFailureResponse response) {}

  // ───────────────── UI ─────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        ),
      ),
      child: Column(
        children: [
          const Text("Available Balance",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            _hideBalance ? "₹ •••••" : "₹${_balance.toStringAsFixed(2)}",
            style: const TextStyle(
                fontSize: 34,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(
              _hideBalance ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _hideBalance = !_hideBalance),
          ),
          Text("Last updated: $_lastUpdated",
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    final color = _colorForType(tx.type);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(_iconForType(tx.type), color: color),
      ),
      title: Text(_titleForType(tx.type)),
      subtitle: Text(DateFormat("dd MMM yyyy, hh:mm a")
          .format(DateTime.parse(tx.date).toLocal())),
      trailing: Text(
        "₹${tx.amount}",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["All", "Credit", "Debit", "Refund"].map((f) {
        return ChoiceChip(
          label: Text(f),
          selected: _selectedFilter == f,
          onSelected: (_) {
            setState(() {
              _selectedFilter = f;
              _applyFilterAndGroup();
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGroupedList() {
    return ListView(
      children: _grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...entry.value.map(_buildTransactionItem).toList()
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Service Wallet")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createBackendOrder(500),
        label: const Text("Add Money"),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildGroupedList(),
          )
        ],
      ),
    );
  }
}
