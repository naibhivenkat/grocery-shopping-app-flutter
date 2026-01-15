// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// import '../services/api_service.dart';
// import '../services/session_manager.dart';
// import '../models/order_model.dart';
// import 'invoice_view_screen.dart';

// class OrderDetailScreen extends StatefulWidget {
//   final String orderId;
//   final Map<String, dynamic>? preloadedOrder;

//   const OrderDetailScreen({super.key, required this.orderId, this.preloadedOrder});

//   @override
//   State<OrderDetailScreen> createState() => _OrderDetailScreenState();
// }

// class _OrderDetailScreenState extends State<OrderDetailScreen> {
//   Map<String, dynamic>? _orderData;
//   List<OrderItem> _orderItems = [];
//   final Map<String, double> _originalPrices = {};

//   bool _isLoading = true;
//   bool _isShopOwner = false;
//   String _currentStatus = "";

//   String _selectedStatus = "Pending";
//   final List<String> _statusOptions = ["Pending", "Packed", "Delivered", "Cancelled"];

//   // Extra Payment State (From backend)
//   String _extraPaymentStatus = ""; // pending, paid, ""
//   double _backendExtraDue = 0.0;

//   // ✅ NEW: Extra Paid (persistent backend display)
//   double _backendExtraPaidAmount = 0.0;
//   String _backendExtraPaidMode = "";

//   // Refund State
//   double _backendRefundAmount = 0.0;
//   String _refundStatus = "";

//   // Local calculation state
//   double _totalAmount = 0.0;
//   double _refundAmount = 0.0;
//   double _localExtraPayable = 0.0;

//   // ✅ Razorpay
//   late Razorpay _razorpay;
//   String? _pendingExtraPaymentMode; // "UPI"
//   double _pendingExtraAmount = 0.0;
//   String? _pendingExtraRazorpayOrderId; // ✅ store for verify

//   @override
//   void initState() {
//     super.initState();
//     _checkRole();

//     if (widget.preloadedOrder != null) {
//       _parseOrderData(widget.preloadedOrder!);
//     }

//     _fetchOrderDetails();

//     // ✅ init Razorpay
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpayPaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayPaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
//   }

//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }

//   // -------------------------------------------------------
//   // ✅ Razorpay callbacks
//   // -------------------------------------------------------
//   void _onRazorpayPaymentSuccess(PaymentSuccessResponse response) async {
//     if (_pendingExtraPaymentMode != "UPI") return;

//     setState(() => _isLoading = true);

//     final ok = await ApiService.verifyExtraPayment(
//       orderId: widget.orderId,
//       razorpayOrderId: response.orderId ?? _pendingExtraRazorpayOrderId ?? "",
//       paymentId: response.paymentId ?? "",
//       signature: response.signature ?? "",
//     );

//     if (ok) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("✅ Extra payment successful!")),
//       );

//       _pendingExtraPaymentMode = null;
//       _pendingExtraAmount = 0.0;
//       _pendingExtraRazorpayOrderId = null;

//       _fetchOrderDetails();
//     } else {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("❌ Payment verification failed in backend")),
//       );
//     }
//   }

//   void _onRazorpayPaymentError(PaymentFailureResponse response) {
//     _pendingExtraPaymentMode = null;
//     _pendingExtraAmount = 0.0;
//     _pendingExtraRazorpayOrderId = null;

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Payment Failed: ${response.message ?? "Cancelled"}")),
//       );
//     }

//     if (mounted) setState(() => _isLoading = false);
//   }

//   void _onRazorpayExternalWallet(ExternalWalletResponse response) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
//       );
//     }
//   }

//   // ✅ Create Razorpay Order for EXTRA PAYMENT UPI
//   Future<void> _startExtraPaymentUpiRazorpay() async {
//     try {
//       setState(() => _isLoading = true);

//       // ✅ Backend calculates amount from order.extra_amount_due
//       final result = await ApiService.createExtraPaymentRazorpayOrder(widget.orderId);

//       if (result == null || result['success'] != true || result['razorpay_order_id'] == null) {
//         if (mounted) setState(() => _isLoading = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(result?["message"] ?? "Failed to create Razorpay UPI Order")),
//           );
//         }
//         return;
//       }

//       String rzpOrderId = result['razorpay_order_id'];
//       double amount = double.tryParse(result['amount']?.toString() ?? "0") ?? _backendExtraDue;

//       _pendingExtraPaymentMode = "UPI";
//       _pendingExtraAmount = amount;
//       _pendingExtraRazorpayOrderId = rzpOrderId;

//       var options = {
//         'key': 'rzp_test_RKK3DuGSaxK9fR',
//         'amount': (amount * 100).toInt(),
//         'name': _orderData?['shop_name'] ?? "Shop",
//         'description': 'Extra Payment for Order',
//         'order_id': rzpOrderId,
//         'currency': 'INR',
//         'prefill': {
//           'contact': '9999999999',
//           'email': 'user@grocery.com',
//         },
//       };

//       setState(() => _isLoading = false);
//       _razorpay.open(options);
//     } catch (e) {
//       if (mounted) setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Razorpay error: $e")),
//         );
//       }
//     }
//   }

//   // -------------------------------------------------------
//   // Role check + Fetch
//   // -------------------------------------------------------
//   Future<void> _checkRole() async {
//     String? role = await SessionManager.getRole();
//     if (!mounted) return;

//     setState(() {
//       _isShopOwner = role?.toLowerCase() == "shopowner" || role?.toLowerCase() == "shopkeeper";
//     });
//   }

//   Future<void> _fetchOrderDetails() async {
//     setState(() => _isLoading = true);
//     final data = await ApiService.getOrderDetails(widget.orderId);

//     if (mounted && data != null) {
//       _parseOrderData(data);
//     }

//     if (mounted) setState(() => _isLoading = false);
//   }

//   void _parseOrderData(Map<String, dynamic> data) {
//     _orderData = data;

//     _currentStatus = (data['status'] ?? "Pending").toString();
//     if (_statusOptions.contains(_currentStatus)) {
//       _selectedStatus = _currentStatus;
//     } else {
//       _selectedStatus = "Pending";
//     }

//     var itemsList = (data['items'] ?? []) as List;
//     _orderItems = itemsList.map((i) => OrderItem.fromJson(i)).toList();

//     for (var item in _orderItems) {
//       if (item.originalQuantity == 0) item.originalQuantity = item.quantity;
//       if (!_originalPrices.containsKey(item.itemId)) {
//         _originalPrices[item.itemId] = item.price;
//       }
//     }

//     // Backend flags
//     _extraPaymentStatus = (data['extra_payment_status'] ?? "").toString();
//     _backendExtraDue = double.tryParse(data['extra_amount_due']?.toString() ?? "0") ?? 0.0;

//     // ✅ NEW: persistent extra paid display values
//     _backendExtraPaidAmount =
//         double.tryParse(data['extra_payment_paid_amount']?.toString() ?? "0") ?? 0.0;
//     _backendExtraPaidMode = (data['extra_payment_mode'] ?? "").toString();

//     _backendRefundAmount = double.tryParse(data['refund_amount']?.toString() ?? "0") ?? 0.0;
//     _refundStatus = (data['refund_status'] ?? "").toString();

//     _calculateTotals();
//   }

//   // ✅ Calculates Refund OR Extra Payment based on Total Value Difference
//   void _calculateTotals() {
//     double currentTotal = 0.0;
//     double originalTotalValue = 0.0;

//     for (var item in _orderItems) {
//       currentTotal += item.quantity * item.price;
//       double origPrice = _originalPrices[item.itemId] ?? item.price;
//       originalTotalValue += item.originalQuantity * origPrice;
//     }

//     double diff = originalTotalValue - currentTotal;

//     if (!mounted) return;
//     setState(() {
//       _totalAmount = currentTotal;
//       _refundAmount = diff > 0 ? diff : 0.0;
//       _localExtraPayable = diff < 0 ? diff.abs() : 0.0;
//     });
//   }

//   // -------------------------------------------------------
//   // 🟢 CUSTOMER ACTION: PAY EXTRA
//   // -------------------------------------------------------
//   Future<void> _handleCustomerPayExtra() async {
//     if (_backendExtraDue <= 0 || _extraPaymentStatus != "pending") {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No extra payment pending.")),
//         );
//       }
//       return;
//     }

//     _showPaymentMethodDialog((mode) async {
//       // ✅ UPI -> open Razorpay
//       if (mode == "UPI") {
//         await _startExtraPaymentUpiRazorpay();
//         return;
//       }

//       // ✅ Wallet / Cash / Khata -> confirm directly
//       setState(() => _isLoading = true);

//       bool success = await ApiService.confirmExtraPayment(widget.orderId, mode);

//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Payment Confirmed! Shopkeeper notified.")),
//           );
//         }
//         _fetchOrderDetails();
//       } else {
//         if (mounted) setState(() => _isLoading = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Payment Failed. Check Wallet / Backend settings.")),
//           );
//         }
//       }
//     });
//   }

//   void _showPaymentMethodDialog(Function(String) onConfirm) {
//     String mode = "SHOP_WALLET";

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: Text("Pay Extra ₹${_backendExtraDue.toStringAsFixed(2)}"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               RadioListTile(
//                 title: const Text("My Wallet"),
//                 value: "SHOP_WALLET",
//                 groupValue: mode,
//                 onChanged: (v) => setState(() => mode = v!),
//               ),
//               RadioListTile(
//                 title: const Text("UPI (Razorpay)"),
//                 value: "UPI",
//                 groupValue: mode,
//                 onChanged: (v) => setState(() => mode = v!),
//               ),
//               RadioListTile(
//                 title: const Text("Add to Khata"),
//                 value: "KHATA",
//                 groupValue: mode,
//                 onChanged: (v) => setState(() => mode = v!),
//               ),
//               RadioListTile(
//                 title: const Text("Cash on Delivery"),
//                 value: "CASH",
//                 groupValue: mode,
//                 onChanged: (v) => setState(() => mode = v!),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(ctx);
//                 onConfirm(mode);
//               },
//               child: const Text("Pay Now"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // -------------------------------------------------------
//   // 🔵 SHOPKEEPER ACTIONS (Save Changes)
//   // -------------------------------------------------------
//   Future<void> _handleShopkeeperSave() async {
//     _calculateTotals();

//     if (_extraPaymentStatus == "pending") {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Extra payment already pending. Wait for customer confirmation.")),
//         );
//       }
//       return;
//     }

//     if (_refundAmount > 0) {
//       _showRefundDialog((mode) => _sendItemUpdate(refundMode: mode));
//     } else {
//       _sendItemUpdate();
//     }
//   }

//   Future<void> _sendItemUpdate({String? refundMode}) async {
//     setState(() => _isLoading = true);

//     List<Map<String, dynamic>> itemsPayload = _orderItems.map((item) => item.toJson()).toList();

//     bool success = await ApiService.updateOrderItems(
//       widget.orderId,
//       itemsPayload,
//       refundMode: refundMode,
//     );

//     if (success) {
//       if (mounted) {
//         String msg = _localExtraPayable > 0
//             ? "Updated. Request sent to customer for extra payment."
//             : (_refundAmount > 0 ? "Updated. Refund initiated." : "Updated Successfully");

//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//         _fetchOrderDetails();
//       }
//     } else {
//       if (mounted) setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
//       }
//     }
//   }

//   // --- ACTIONS: UPDATE STATUS ---
//   Future<void> _handleUpdateStatus() async {
//     if (_selectedStatus.toLowerCase() == "cancelled") {
//       _showRefundDialog((refundMode) => _sendStatusUpdate(refundMode));
//     } else {
//       _sendStatusUpdate(null);
//     }
//   }

//   Future<void> _sendStatusUpdate(String? refundMode) async {
//     setState(() => _isLoading = true);

//     Map<String, dynamic> body = {
//       "order_id": widget.orderId,
//       "status": _selectedStatus,
//     };

//     if (refundMode != null) body["refund_mode"] = refundMode;

//     bool success = await ApiService.updateOrderStatus(body);

//     if (success) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Status Updated Successfully")),
//         );
//         _fetchOrderDetails();
//       }
//     } else {
//       if (mounted) setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
//       }
//     }
//   }

//   // --- POPUPS ---
//   void _showRefundDialog(Function(String) onConfirm) {
//     _showSelectionDialog("Select Refund Method", ["RAZORPAY", "SHOP_WALLET", "CASH"], "RAZORPAY", onConfirm);
//   }

//   void _showSelectionDialog(String title, List<String> options, String defaultMode, Function(String) onConfirm) {
//     String selected = defaultMode;

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: Text(title),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: options
//                 .map((opt) => RadioListTile(
//                       title: Text(opt.replaceAll("_", " ")),
//                       value: opt,
//                       groupValue: selected,
//                       onChanged: (v) => setState(() => selected = v!),
//                     ))
//                 .toList(),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(ctx);
//                 onConfirm(selected);
//               },
//               child: const Text("Confirm"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(String? utcDate) {
//     if (utcDate == null) return "";
//     try {
//       DateTime dt = DateTime.parse(utcDate).toLocal();
//       return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
//     } catch (e) {
//       return utcDate;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool showLoader = _isLoading && _orderData == null;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Order Details"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrderDetails),
//         ],
//       ),
//       body: showLoader
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _buildHeaderCard(),

//                   if (!_isShopOwner && _extraPaymentStatus == "pending" && _backendExtraDue > 0)
//                     Container(
//                       margin: const EdgeInsets.symmetric(vertical: 10),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.orange.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.orange),
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: const [
//                               Icon(Icons.warning, color: Colors.orange),
//                               SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   "Order Modified! Extra payment needed.",
//                                   style: TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                               )
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: _handleCustomerPayExtra,
//                               style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//                               child: Text("Pay ₹${_backendExtraDue.toStringAsFixed(2)}"),
//                             ),
//                           )
//                         ],
//                       ),
//                     ),

//                   if (_isShopOwner && _extraPaymentStatus == "pending")
//                     Container(
//                       margin: const EdgeInsets.symmetric(vertical: 10),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.blue),
//                       ),
//                       child: Row(
//                         children: const [
//                           Icon(Icons.info, color: Colors.blue),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Waiting for customer to approve extra payment.",
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           )
//                         ],
//                       ),
//                     ),

//                   const SizedBox(height: 10),

//                   ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _orderItems.length,
//                     itemBuilder: (context, index) => OrderItemTile(
//                       item: _orderItems[index],
//                       isEditable: _isShopOwner,
//                       onChanged: () => _calculateTotals(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   _buildTotalsSection(),
//                   const SizedBox(height: 20),

//                   if (_isShopOwner) _buildOwnerControls(),

//                   if (!_isShopOwner && _currentStatus.toLowerCase() == "delivered")
//                     Padding(
//                       padding: const EdgeInsets.only(top: 20.0),
//                       child: ElevatedButton.icon(
//                         icon: const Icon(Icons.receipt),
//                         label: const Text("View Invoice"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                         ),
//                         onPressed: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => InvoiceViewScreen(orderId: widget.orderId)),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildHeaderCard() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Order #${_orderData?['order_uuid'] ?? '...'}", style: const TextStyle(fontWeight: FontWeight.bold)),
//             const Divider(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(_isShopOwner
//                     ? "Customer: ${_orderData?['customer']?['username'] ?? ''}"
//                     : "Shop: ${_orderData?['shop_name'] ?? ''}"),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(color: _getStatusColor(_currentStatus), borderRadius: BorderRadius.circular(4)),
//                   child: Text(
//                     _currentStatus.toUpperCase(),
//                     style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                   ),
//                 )
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text("📅 ${_formatDate(_orderData?['created_at'])}", style: const TextStyle(color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ MIN CHANGE: Added "Extra Paid" persistent block
//   Widget _buildTotalsSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children: [
//           // ✅ Refund (persistent)
//           if (_backendRefundAmount > 0)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Refund (${_refundStatus.isEmpty ? "initiated" : _refundStatus}):",
//                   style: const TextStyle(color: Colors.red, fontSize: 16),
//                 ),
//                 Text(
//                   "- ₹${_backendRefundAmount.toStringAsFixed(2)}",
//                   style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),

//           // ✅ NEW: Extra Paid (persistent)
//           if (_backendExtraPaidAmount > 0)
//             Padding(
//               padding: const EdgeInsets.only(top: 6.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Extra Paid (${_backendExtraPaidMode.isEmpty ? "UPI/WALLET" : _backendExtraPaidMode}):",
//                     style: const TextStyle(color: Color.fromARGB(255, 229, 3, 90), fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   Text(
//                     "+ ₹${_backendExtraPaidAmount.toStringAsFixed(2)}",
//                     style: const TextStyle(color: Color.fromARGB(255, 245, 111, 2), fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),

//           // ✅ Local Refund preview
//           if (_backendRefundAmount <= 0 && _refundAmount > 0)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text("Partial Refund:", style: TextStyle(color: Colors.red, fontSize: 16)),
//                 Text(
//                   "- ₹${_refundAmount.toStringAsFixed(2)}",
//                   style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),

//           // ✅ Local Extra payable preview
//           if (_localExtraPayable > 0)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text("Extra Payable:", style: TextStyle(color: Colors.orange, fontSize: 16)),
//                 Text(
//                   "+ ₹${_localExtraPayable.toStringAsFixed(2)}",
//                   style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),

//           // ✅ Pending Due (persistent)
//           if (_extraPaymentStatus == "pending" && _backendExtraDue > 0)
//             Padding(
//               padding: const EdgeInsets.only(top: 6.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text("Pending Due:", style: TextStyle(color: Colors.orange, fontSize: 15)),
//                   Text(
//                     "₹${_backendExtraDue.toStringAsFixed(2)}",
//                     style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
//                   ),
//                 ],
//               ),
//             ),

//           const Divider(),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               Text(
//                 "₹${_totalAmount.toStringAsFixed(2)}",
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOwnerControls() {
//     bool isPending = _extraPaymentStatus == "pending";

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Text("Update Status", style: TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 5),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: _statusOptions.contains(_selectedStatus) ? _selectedStatus : "Pending",
//               isExpanded: true,
//               items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
//               onChanged: (val) => setState(() => _selectedStatus = val!),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: _handleUpdateStatus,
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
//                 child: const Text("Update Status"),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: isPending ? null : _handleShopkeeperSave,
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
//                 child: const Text("Save Changes"),
//               ),
//             ),
//           ],
//         ),
//         if (isPending)
//           const Padding(
//             padding: EdgeInsets.only(top: 8.0),
//             child: Text(
//               "⚠ Order has pending payment request.",
//               style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//           )
//       ],
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case "pending":
//         return Colors.orange;
//       case "packed":
//         return Colors.blue;
//       case "delivered":
//         return Colors.green;
//       case "cancelled":
//         return Colors.red;
//       default:
//         return Colors.black;
//     }
//   }
// }

// class OrderItemTile extends StatefulWidget {
//   final OrderItem item;
//   final bool isEditable;
//   final VoidCallback onChanged;

//   const OrderItemTile({super.key, required this.item, required this.isEditable, required this.onChanged});

//   @override
//   State<OrderItemTile> createState() => _OrderItemTileState();
// }

// class _OrderItemTileState extends State<OrderItemTile> {
//   late TextEditingController _qtyController;
//   late TextEditingController _priceController;
//   late TextEditingController _commentController;

//   @override
//   void initState() {
//     super.initState();
//     _qtyController = TextEditingController(text: widget.item.quantity.toString());
//     _priceController = TextEditingController(text: widget.item.price.toString());
//     _commentController = TextEditingController(text: widget.item.comment ?? "");
//   }

//   @override
//   void dispose() {
//     _qtyController.dispose();
//     _priceController.dispose();
//     _commentController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool hasReduced = widget.item.quantity < widget.item.originalQuantity;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const SizedBox(height: 8),
//             if (widget.isEditable) ...[
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _qtyController,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder()),
//                       onChanged: (val) {
//                         double? newVal = double.tryParse(val);
//                         if (newVal != null && newVal >= 0) {
//                           widget.item.quantity = newVal;
//                           widget.onChanged();
//                           setState(() {});
//                         }
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: TextField(
//                       controller: _priceController,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()),
//                       onChanged: (val) {
//                         double? newVal = double.tryParse(val);
//                         if (newVal != null && newVal >= 0) {
//                           widget.item.price = newVal;
//                           widget.onChanged();
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Text("/ Ordered: ${widget.item.originalQuantity}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _commentController,
//                 decoration: const InputDecoration(labelText: "Comment (Optional)", border: OutlineInputBorder()),
//                 onChanged: (val) => widget.item.comment = val,
//               ),
//             ] else ...[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   if (hasReduced)
//                     Text(
//                       "Delivered: ${widget.item.quantity} (Ord: ${widget.item.originalQuantity})",
//                       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//                     )
//                   else
//                     Text("Qty: ${widget.item.quantity}"),
//                   Text("₹${widget.item.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               if (widget.item.comment != null && widget.item.comment!.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Text(
//                     "Note: ${widget.item.comment}",
//                     style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
//                   ),
//                 ),
//             ]
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/order_model.dart';
import 'invoice_view_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? preloadedOrder;

  const OrderDetailScreen({super.key, required this.orderId, this.preloadedOrder});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _orderData;
  List<OrderItem> _orderItems = [];
  final Map<String, double> _originalPrices = {};

  bool _isLoading = true;
  bool _isShopOwner = false;
  String _currentStatus = "";

  String _selectedStatus = "Pending";
  final List<String> _statusOptions = ["Pending", "Packed", "Delivered", "Cancelled"];

  // Extra Payment State (From backend)
  String _extraPaymentStatus = ""; // pending, paid, ""
  double _backendExtraDue = 0.0;

  // ✅ NEW: Extra Paid (persistent backend display)
  double _backendExtraPaidAmount = 0.0;
  String _backendExtraPaidMode = "";

  // Refund State
  double _backendRefundAmount = 0.0;
  String _refundStatus = "";

  // Local calculation state
  double _totalAmount = 0.0;
  double _refundAmount = 0.0;
  double _localExtraPayable = 0.0;

  // ✅ Razorpay
  late Razorpay _razorpay;
  String? _pendingExtraPaymentMode; // "UPI"
  double _pendingExtraAmount = 0.0;
  String? _pendingExtraRazorpayOrderId; // ✅ store for verify

  // ✅ MIN CHANGE: helper for Active/History order
  bool _isHistoryOrder() {
    final s = _currentStatus.toLowerCase();
    return s == "delivered" || s == "cancelled";
  }

  @override
  void initState() {
    super.initState();
    _checkRole();

    if (widget.preloadedOrder != null) {
      _parseOrderData(widget.preloadedOrder!);
    }

    _fetchOrderDetails();

    // ✅ init Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpayPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // -------------------------------------------------------
  // ✅ Razorpay callbacks
  // -------------------------------------------------------
  void _onRazorpayPaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingExtraPaymentMode != "UPI") return;

    setState(() => _isLoading = true);

    final ok = await ApiService.verifyExtraPayment(
      orderId: widget.orderId,
      razorpayOrderId: response.orderId ?? _pendingExtraRazorpayOrderId ?? "",
      paymentId: response.paymentId ?? "",
      signature: response.signature ?? "",
    );

    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Extra payment successful!")),
      );

      _pendingExtraPaymentMode = null;
      _pendingExtraAmount = 0.0;
      _pendingExtraRazorpayOrderId = null;

      _fetchOrderDetails();
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Payment verification failed in backend")),
      );
    }
  }

  void _onRazorpayPaymentError(PaymentFailureResponse response) {
    _pendingExtraPaymentMode = null;
    _pendingExtraAmount = 0.0;
    _pendingExtraRazorpayOrderId = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment Failed: ${response.message ?? "Cancelled"}")),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
      );
    }
  }

  // ✅ Create Razorpay Order for EXTRA PAYMENT UPI
  Future<void> _startExtraPaymentUpiRazorpay() async {
    try {
      setState(() => _isLoading = true);

      // ✅ Backend calculates amount from order.extra_amount_due
      final result = await ApiService.createExtraPaymentRazorpayOrder(widget.orderId);

      if (result == null || result['success'] != true || result['razorpay_order_id'] == null) {
        if (mounted) setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?["message"] ?? "Failed to create Razorpay UPI Order")),
          );
        }
        return;
      }

      String rzpOrderId = result['razorpay_order_id'];
      double amount = double.tryParse(result['amount']?.toString() ?? "0") ?? _backendExtraDue;

      _pendingExtraPaymentMode = "UPI";
      _pendingExtraAmount = amount;
      _pendingExtraRazorpayOrderId = rzpOrderId;

      var options = {
        'key': 'rzp_test_RKK3DuGSaxK9fR',
        'amount': (amount * 100).toInt(),
        'name': _orderData?['shop_name'] ?? "Shop",
        'description': 'Extra Payment for Order',
        'order_id': rzpOrderId,
        'currency': 'INR',
        'prefill': {
          'contact': '9999999999',
          'email': 'user@grocery.com',
        },
      };

      setState(() => _isLoading = false);
      _razorpay.open(options);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Razorpay error: $e")),
        );
      }
    }
  }

  // -------------------------------------------------------
  // Role check + Fetch
  // -------------------------------------------------------
  Future<void> _checkRole() async {
    String? role = await SessionManager.getRole();
    if (!mounted) return;

    setState(() {
      _isShopOwner = role?.toLowerCase() == "shopowner" || role?.toLowerCase() == "shopkeeper";
    });
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getOrderDetails(widget.orderId);

    if (mounted && data != null) {
      _parseOrderData(data);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _parseOrderData(Map<String, dynamic> data) {
    _orderData = data;

    _currentStatus = (data['status'] ?? "Pending").toString();
    if (_statusOptions.contains(_currentStatus)) {
      _selectedStatus = _currentStatus;
    } else {
      _selectedStatus = "Pending";
    }

    var itemsList = (data['items'] ?? []) as List;
    _orderItems = itemsList.map((i) => OrderItem.fromJson(i)).toList();

    for (var item in _orderItems) {
      if (item.originalQuantity == 0) item.originalQuantity = item.quantity;
      if (!_originalPrices.containsKey(item.itemId)) {
        _originalPrices[item.itemId] = item.price;
      }
    }

    // Backend flags
    _extraPaymentStatus = (data['extra_payment_status'] ?? "").toString();
    _backendExtraDue = double.tryParse(data['extra_amount_due']?.toString() ?? "0") ?? 0.0;

    // ✅ persistent extra paid display values
    _backendExtraPaidAmount =
        double.tryParse(data['extra_payment_paid_amount']?.toString() ?? "0") ?? 0.0;
    _backendExtraPaidMode = (data['extra_payment_mode'] ?? "").toString();

    _backendRefundAmount = double.tryParse(data['refund_amount']?.toString() ?? "0") ?? 0.0;
    _refundStatus = (data['refund_status'] ?? "").toString();

    _calculateTotals();
  }

  // ✅ Calculates Refund OR Extra Payment based on Total Value Difference
  void _calculateTotals() {
    double currentTotal = 0.0;
    double originalTotalValue = 0.0;

    for (var item in _orderItems) {
      currentTotal += item.quantity * item.price;
      double origPrice = _originalPrices[item.itemId] ?? item.price;
      originalTotalValue += item.originalQuantity * origPrice;
    }

    double diff = originalTotalValue - currentTotal;

    if (!mounted) return;
    setState(() {
      _totalAmount = currentTotal;
      _refundAmount = diff > 0 ? diff : 0.0;
      _localExtraPayable = diff < 0 ? diff.abs() : 0.0;
    });
  }

  // -------------------------------------------------------
  // 🟢 CUSTOMER ACTION: PAY EXTRA
  // -------------------------------------------------------
  Future<void> _handleCustomerPayExtra() async {
    if (_backendExtraDue <= 0 || _extraPaymentStatus != "pending") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No extra payment pending.")),
        );
      }
      return;
    }

    _showPaymentMethodDialog((mode) async {
      // ✅ UPI -> open Razorpay
      if (mode == "UPI") {
        await _startExtraPaymentUpiRazorpay();
        return;
      }

      // ✅ Wallet / Cash / Khata -> confirm directly
      setState(() => _isLoading = true);

      bool success = await ApiService.confirmExtraPayment(widget.orderId, mode);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Confirmed! Shopkeeper notified.")),
          );
        }
        _fetchOrderDetails();
      } else {
        if (mounted) setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Failed. Check Wallet / Backend settings.")),
          );
        }
      }
    });
  }

  void _showPaymentMethodDialog(Function(String) onConfirm) {
    String mode = "SHOP_WALLET";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Pay Extra ₹${_backendExtraDue.toStringAsFixed(2)}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text("My Wallet"),
                value: "SHOP_WALLET",
                groupValue: mode,
                onChanged: (v) => setState(() => mode = v!),
              ),
              RadioListTile(
                title: const Text("UPI (Razorpay)"),
                value: "UPI",
                groupValue: mode,
                onChanged: (v) => setState(() => mode = v!),
              ),
              RadioListTile(
                title: const Text("Add to Khata"),
                value: "KHATA",
                groupValue: mode,
                onChanged: (v) => setState(() => mode = v!),
              ),
              RadioListTile(
                title: const Text("Cash on Delivery"),
                value: "CASH",
                groupValue: mode,
                onChanged: (v) => setState(() => mode = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm(mode);
              },
              child: const Text("Pay Now"),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 🔵 SHOPKEEPER ACTIONS (Save Changes)
  // -------------------------------------------------------
  Future<void> _handleShopkeeperSave() async {
    _calculateTotals();

    if (_extraPaymentStatus == "pending") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Extra payment already pending. Wait for customer confirmation.")),
        );
      }
      return;
    }

    if (_refundAmount > 0) {
      _showRefundDialog((mode) => _sendItemUpdate(refundMode: mode));
    } else {
      _sendItemUpdate();
    }
  }

  Future<void> _sendItemUpdate({String? refundMode}) async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> itemsPayload = _orderItems.map((item) => item.toJson()).toList();

    bool success = await ApiService.updateOrderItems(
      widget.orderId,
      itemsPayload,
      refundMode: refundMode,
    );

    if (success) {
      if (mounted) {
        String msg = _localExtraPayable > 0
            ? "Updated. Request sent to customer for extra payment."
            : (_refundAmount > 0 ? "Updated. Refund initiated." : "Updated Successfully");

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        _fetchOrderDetails();
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
      }
    }
  }

  // --- ACTIONS: UPDATE STATUS ---
  Future<void> _handleUpdateStatus() async {
    if (_selectedStatus.toLowerCase() == "cancelled") {
      _showRefundDialog((refundMode) => _sendStatusUpdate(refundMode));
    } else {
      _sendStatusUpdate(null);
    }
  }

  Future<void> _sendStatusUpdate(String? refundMode) async {
    setState(() => _isLoading = true);

    Map<String, dynamic> body = {
      "order_id": widget.orderId,
      "status": _selectedStatus,
    };

    if (refundMode != null) body["refund_mode"] = refundMode;

    bool success = await ApiService.updateOrderStatus(body);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status Updated Successfully")),
        );
        _fetchOrderDetails();
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
      }
    }
  }

  // --- POPUPS ---
  void _showRefundDialog(Function(String) onConfirm) {
    _showSelectionDialog("Select Refund Method", ["RAZORPAY", "SHOP_WALLET", "CASH"], "RAZORPAY", onConfirm);
  }

  void _showSelectionDialog(String title, List<String> options, String defaultMode, Function(String) onConfirm) {
    String selected = defaultMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((opt) => RadioListTile(
                      title: Text(opt.replaceAll("_", " ")),
                      value: opt,
                      groupValue: selected,
                      onChanged: (v) => setState(() => selected = v!),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm(selected);
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? utcDate) {
    if (utcDate == null) return "";
    try {
      DateTime dt = DateTime.parse(utcDate).toLocal();
      return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
    } catch (e) {
      return utcDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showLoader = _isLoading && _orderData == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrderDetails),
        ],
      ),
      body: showLoader
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeaderCard(),

                  if (!_isShopOwner && _extraPaymentStatus == "pending" && _backendExtraDue > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Order Modified! Extra payment needed.",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleCustomerPayExtra,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: Text("Pay ₹${_backendExtraDue.toStringAsFixed(2)}"),
                            ),
                          )
                        ],
                      ),
                    ),

                  if (_isShopOwner && _extraPaymentStatus == "pending")
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Waiting for customer to approve extra payment.",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _orderItems.length,
                    itemBuilder: (context, index) => OrderItemTile(
                      item: _orderItems[index],

                      // ✅ MIN CHANGE: if History -> disable edit
                      isEditable: _isShopOwner && !_isHistoryOrder(),

                      onChanged: () => _calculateTotals(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTotalsSection(),
                  const SizedBox(height: 20),

                  // ✅ MIN CHANGE: hide owner controls in History orders
                  if (_isShopOwner && !_isHistoryOrder()) _buildOwnerControls(),

                  if (!_isShopOwner && _currentStatus.toLowerCase() == "delivered")
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt),
                        label: const Text("View Invoice"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InvoiceViewScreen(orderId: widget.orderId)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order #${_orderData?['order_uuid'] ?? '...'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isShopOwner
                    ? "Customer: ${_orderData?['customer']?['username'] ?? ''}"
                    : "Shop: ${_orderData?['shop_name'] ?? ''}"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusColor(_currentStatus), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    _currentStatus.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text("📅 ${_formatDate(_orderData?['created_at'])}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ✅ MIN CHANGE: Added "Extra Paid" persistent block
  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ✅ Refund (persistent)
          if (_backendRefundAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Refund (${_refundStatus.isEmpty ? "initiated" : _refundStatus}):",
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                Text(
                  "- ₹${_backendRefundAmount.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

          // ✅ Extra Paid (persistent)
          if (_backendExtraPaidAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Extra Paid (${_backendExtraPaidMode.isEmpty ? "UPI/WALLET" : _backendExtraPaidMode}):",
                    style: const TextStyle(color: Color.fromARGB(255, 21, 1, 237), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "+ ₹${_backendExtraPaidAmount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color.fromARGB(255, 239, 73, 2), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

          // ✅ Local Refund preview
          if (_backendRefundAmount <= 0 && _refundAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Partial Refund:", style: TextStyle(color: Colors.red, fontSize: 16)),
                Text(
                  "- ₹${_refundAmount.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

          // ✅ Local Extra payable preview
          if (_localExtraPayable > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Extra Payable:", style: TextStyle(color: Colors.orange, fontSize: 16)),
                Text(
                  "+ ₹${_localExtraPayable.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

          // ✅ Pending Due (persistent)
          if (_extraPaymentStatus == "pending" && _backendExtraDue > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pending Due:", style: TextStyle(color: Colors.orange, fontSize: 15)),
                  Text(
                    "₹${_backendExtraDue.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),

          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                "₹${_totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerControls() {
    bool isPending = _extraPaymentStatus == "pending";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Update Status", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusOptions.contains(_selectedStatus) ? _selectedStatus : "Pending",
              isExpanded: true,
              items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _handleUpdateStatus,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: const Text("Update Status"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isPending ? null : _handleShopkeeperSave,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
        if (isPending)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "⚠ Order has pending payment request.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          )
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "packed":
        return Colors.blue;
      case "delivered":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}

class OrderItemTile extends StatefulWidget {
  final OrderItem item;
  final bool isEditable;
  final VoidCallback onChanged;

  const OrderItemTile({super.key, required this.item, required this.isEditable, required this.onChanged});

  @override
  State<OrderItemTile> createState() => _OrderItemTileState();
}

class _OrderItemTileState extends State<OrderItemTile> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.quantity.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    _commentController = TextEditingController(text: widget.item.comment ?? "");
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasReduced = widget.item.quantity < widget.item.originalQuantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (widget.isEditable) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder()),
                      onChanged: (val) {
                        double? newVal = double.tryParse(val);
                        if (newVal != null && newVal >= 0) {
                          widget.item.quantity = newVal;
                          widget.onChanged();
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()),
                      onChanged: (val) {
                        double? newVal = double.tryParse(val);
                        if (newVal != null && newVal >= 0) {
                          widget.item.price = newVal;
                          widget.onChanged();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("/ Ordered: ${widget.item.originalQuantity}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: "Comment (Optional)", border: OutlineInputBorder()),
                onChanged: (val) => widget.item.comment = val,
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasReduced)
                    Text(
                      "Delivered: ${widget.item.quantity} (Ord: ${widget.item.originalQuantity})",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    )
                  else
                    Text("Qty: ${widget.item.quantity}"),
                  Text("₹${widget.item.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (widget.item.comment != null && widget.item.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Note: ${widget.item.comment}",
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}
