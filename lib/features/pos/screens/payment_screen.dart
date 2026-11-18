import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruvexi_mobile/core/network/api_config.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';
import 'package:ruvexi_mobile/shared/widgets/upi_qr_dialog.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/checkout_complete_screen.dart';

class PaymentScreen extends StatefulWidget {
  final RuvexiAppState appState;
  final double amount;
  final String customerName;

  const PaymentScreen({
    super.key,
    required this.appState,
    required this.amount,
    this.customerName = "Walk-in Guest",
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethodIndex = 0; // 0: UPI, 1: Card, 2: Cash, 3: Other
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {
      "title": "Google Pay",
      "subtitle": "GPay instant counter settlement",
      "icon": Icons.account_balance_wallet_rounded,
      "tag": "Google Pay",
    },
    {
      "title": "PhonePe",
      "subtitle": "PhonePe instant UPI settlement",
      "icon": Icons.phone_android_rounded,
      "tag": "PhonePe",
    },
    {
      "title": "UPI / QR Code",
      "subtitle": "Scan with any UPI QR App",
      "icon": Icons.qr_code_2_rounded,
      "tag": "UPI",
    },
    {
      "title": "Cash",
      "subtitle": "Direct physical counter currency",
      "icon": Icons.payments_outlined,
      "tag": "CASH",
    },
    {
      "title": "Card",
      "subtitle": "Credit / Debit Card POS",
      "icon": Icons.credit_card_rounded,
      "tag": "CARD",
    },
    {
      "title": "Other",
      "subtitle": "Split / Store Credit / Cheque",
      "icon": Icons.swap_horiz_rounded,
      "tag": "OTHER",
    },
  ];

  Future<void> _collectPayment() async {
    final activeCustomerName = widget.appState.posSelectedCustomer?.name ?? (widget.customerName.isNotEmpty ? widget.customerName : "Walk-in Guest");
    final methodTag = _methods[_selectedMethodIndex]["tag"] as String;
    if (methodTag == "UPI" || methodTag == "Google Pay" || methodTag == "PhonePe") {
      final invNum = "RVX-${DateTime.now().millisecondsSinceEpoch % 100000}";
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => UpiQrModalDialog(
          appState: widget.appState,
          amount: widget.amount,
          customerName: activeCustomerName,
          invoiceNumber: invNum,
          onPaymentConfirmed: () => _executePaymentBackend(methodTag, invNum),
        ),
      );
      return;
    }
    await _executePaymentBackend(methodTag);
  }

  Future<void> _executePaymentBackend(String methodTag, [String? explicitInvoiceNum]) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final activeCustomerName = widget.appState.posSelectedCustomer?.name ?? (widget.customerName.isNotEmpty ? widget.customerName : "Walk-in Guest");
    final billed = widget.appState.posCart
        .map((c) => {
              'name': c.name,
              'price': c.price,
              'qty': c.quantity,
              'type': c.type,
              'staffName': c.staffName ?? '',
            })
        .toList();
    final customerPhone = widget.appState.posSelectedCustomer?.phone ?? '';

    final invNum = explicitInvoiceNum ?? "RVX-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000000}";

    try {
      await widget.appState.completePayment(
        method: methodTag,
        amount: widget.amount,
        invoiceNumber: invNum,
      );
    } catch (e) {
      debugPrint("Payment completion notice: $e");
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CheckoutCompleteScreen(
          appState: widget.appState,
          amount: widget.amount,
          customerName: activeCustomerName,
          customerPhone: customerPhone,
          paymentMethod: methodTag,
          billedItems: billed,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060706),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount to Pay Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF101311),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF122C1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF22C55E), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount to Pay",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${widget.amount.toInt()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Payment Method Header
            const Text(
              "Select Payment Method",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Options
            ...List.generate(_methods.length, (index) {
              final item = _methods[index];
              final isSelected = _selectedMethodIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedMethodIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101311),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item["icon"] as IconData, color: isSelected ? const Color(0xFF22C55E) : Colors.white60, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item["subtitle"] as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF22C55E) : Colors.white38,
                            width: 2,
                          ),
                          color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 12, color: Colors.black)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 36),

            // Collect Payment Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _collectPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  disabledBackgroundColor: const Color(0xFF1B3822),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                      )
                    : Text(
                        _selectedMethodIndex == 0
                            ? "Show UPI QR Code (₹${widget.amount.toInt()})"
                            : "Collect Payment ₹${widget.amount.toInt()}",
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

