import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruvexi_mobile/core/network/api_config.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/shared/widgets/ruvexi_logo.dart';
import 'package:ruvexi_mobile/shared/widgets/customer_avatar.dart';
import 'package:ruvexi_mobile/shared/widgets/salon_notification_dialog.dart';
import 'package:ruvexi_mobile/features/crm/screens/customer_profile_screen.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/check_in_customer_screen.dart';
import 'package:ruvexi_mobile/shared/widgets/whatsapp_campaign_dialog.dart';
import 'package:ruvexi_mobile/shared/widgets/import_clients_dialog.dart';

class StaffCustomersScreen extends StatefulWidget {
  final RuvexiAppState appState;
  final bool showBackButton;
  final VoidCallback? onBack;

  const StaffCustomersScreen({
    super.key,
    required this.appState,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<StaffCustomersScreen> createState() => _StaffCustomersScreenState();
}

class _StaffCustomersScreenState extends State<StaffCustomersScreen> {
  // 0: Daily Payment Records (Default), 1: Clients Directory
  int _viewMode = 0;

  // Selected date for payment records
  DateTime _selectedDate = DateTime.now();

  // Payment method filter: "ALL", "UPI", "CASH", "CARD"
  String _paymentFilter = "ALL";

  // Search query
  String _query = "";
  final _searchCtrl = TextEditingController();

  // Client list filter index (when in Clients CRM mode)
  int _clientFilter = 0; // 0: All, 1: In Salon

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _extractInvoiceDate(Map<String, dynamic> inv) {
    final paidAt = inv['paidAt'] ?? inv['paid_at'] ?? inv['createdAt'] ?? inv['created_at'];
    if (paidAt != null) {
      try {
        return DateTime.parse(paidAt.toString());
      } catch (_) {}
    }
    final dateStr = (inv['date'] ?? '').toString();
    if (dateStr.toLowerCase().contains('today')) {
      return DateTime.now();
    }
    return null;
  }

  List<Map<String, dynamic>> _getInvoicesForSelectedDate() {
    final q = _query.trim().toLowerCase();
    final allInvoices = widget.appState.invoices;

    // Filter by selected date
    final list = allInvoices.where((inv) {
      final invDate = _extractInvoiceDate(inv);
      final isDateMatch = invDate != null
          ? _isSameDay(invDate, _selectedDate)
          : (_isSameDay(_selectedDate, DateTime.now()) &&
              (inv['date'] ?? '').toString().toLowerCase().contains('today'));

      if (!isDateMatch) return false;

      // Method filter
      final method = (inv['paymentMethod'] ?? inv['payment_method'] ?? 'CASH').toString().toUpperCase();
      if (_paymentFilter != "ALL" && !method.contains(_paymentFilter)) {
        return false;
      }

      // Query filter
      if (q.isNotEmpty) {
        final name = (inv['customerName'] ?? inv['customer_name'] ?? '').toString().toLowerCase();
        final phone = (inv['customerPhone'] ?? inv['customer_phone'] ?? '').toString();
        final number = (inv['invoiceNumber'] ?? inv['invoice_number'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !phone.contains(q) && !number.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    return list;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF22C55E),
              onPrimary: Colors.black,
              surface: Color(0xFF101311),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _sendWhatsAppReceipt(Map<String, dynamic> inv) async {
    final name = (inv['customerName'] ?? inv['customer_name'] ?? 'Guest').toString();
    String phone = (inv['customerPhone'] ?? inv['customer_phone'] ?? '').toString();
    final invNum = (inv['invoiceNumber'] ?? inv['invoice_number'] ?? 'RVX').toString();
    final amount = ((inv['grandTotal'] ?? inv['grand_total'] ?? 0) as num).toDouble();
    final method = (inv['paymentMethod'] ?? inv['payment_method'] ?? 'UPI').toString();

    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneParam = digits.length == 10 ? '91$digits' : digits;

    if (phoneParam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No mobile number attached to this bill")),
      );
      return;
    }

    final message = "🌟 *${widget.appState.salonName}* — Payment Receipt\n\n"
        "Dear *$name*,\n"
        "Thank you for visiting us! Your payment of ₹${amount.toInt()} has been settled successfully.\n\n"
        "🧾 *Invoice:* #$invNum\n"
        "💰 *Amount Paid:* ₹${amount.toInt()}\n"
        "💳 *Method:* $method\n\n"
        "Book your next appointment online anytime:\n"
        "🔗 ${RuvexiApiConfig.webAppUrl}/book\n\n"
        "Have a wonderful day! ✨";

    final uri = Uri.parse("https://wa.me/$phoneParam?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Opening WhatsApp with $name ($phone)...")),
      );
    }
  }

  void _showReceiptModal(Map<String, dynamic> inv) {
    final name = (inv['customerName'] ?? inv['customer_name'] ?? 'Walk-in Guest').toString();
    final phone = (inv['customerPhone'] ?? inv['customer_phone'] ?? '').toString();
    final invNum = (inv['invoiceNumber'] ?? inv['invoice_number'] ?? 'RVX').toString();
    final grandTotal = ((inv['grandTotal'] ?? inv['grand_total'] ?? 0) as num).toDouble();
    final subtotal = ((inv['subtotal'] ?? grandTotal) as num).toDouble();
    final tax = ((inv['taxAmount'] ?? inv['tax_amount'] ?? 0) as num).toDouble();
    final discount = ((inv['discountAmount'] ?? inv['discount_amount'] ?? 0) as num).toDouble();
    final custMatch = widget.appState.customers.firstWhere(
      (c) => (phone.isNotEmpty && c.phone == phone) || c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Customer(
        id: '',
        name: name,
        phone: phone,
        email: '',
        gender: (inv['gender'] ?? inv['customerGender'] ?? '').toString(),
        dateOfBirth: (inv['dob'] ?? inv['birthday'] ?? inv['customerDob'] ?? '').toString(),
        visitsCount: 1,
        totalSpent: grandTotal,
      ),
    );
    final stylistName = (inv['staffName'] ?? inv['staff_name'] ?? inv['stylist'] ?? '').toString();
    final method = (inv['paymentMethod'] ?? inv['payment_method'] ?? 'UPI').toString().toUpperCase();
    final dateStr = (inv['date'] ?? inv['paidAt'] ?? 'Today').toString();
    final txnRef = (inv['paymentReference'] ?? inv['payment_reference'] ?? '').toString();

    // Parse items
    List<dynamic> items = [];
    if (inv['items'] is List) {
      items = inv['items'];
    } else if (inv['items_json'] != null) {
      try {
        items = jsonDecode(inv['items_json'].toString());
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: Color(0xFF22C55E), width: 1),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Official Payment Receipt",
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142419),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF22C55E)),
                  ),
                  child: Text(
                    invNum,
                    style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "${widget.appState.salonName} • ${widget.appState.salonLocation}",
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
            ),
            const Divider(color: Color(0xFF1C221E), height: 24),

            // Customer & Stylist Details Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141815),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CUSTOMER PROFILE", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9.5, letterSpacing: 0.8, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (phone.isNotEmpty)
                            Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF142419),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text("PAID", style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          const SizedBox(height: 3),
                          Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (custMatch.gender.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF18221B), borderRadius: BorderRadius.circular(4)),
                          child: Text("Gender: ${custMatch.gender}", style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (custMatch.dateOfBirth.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF18221B), borderRadius: BorderRadius.circular(4)),
                          child: Text("DOB: ${custMatch.dateOfBirth}", style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (stylistName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF18221B), borderRadius: BorderRadius.circular(4)),
                          child: Text("Stylist: $stylistName", style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1C221E), height: 24),

            // Services list
            if (items.isNotEmpty) ...[
              const Text("Services Rendered", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((itm) {
                final itmName = (itm['name'] ?? 'Service').toString();
                final price = ((itm['price'] ?? 0) as num).toDouble();
                final qty = (itm['quantity'] ?? itm['qty'] ?? 1) as num;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$itmName × $qty", style: const TextStyle(color: Colors.white, fontSize: 13)),
                      Text("₹${(price * qty).toInt()}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                );
              }),
              const Divider(color: Color(0xFF1C221E), height: 20),
            ],

            // Financial Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal", style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                Text("₹${subtotal.toInt()}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Discount", style: TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
                  Text("-₹${discount.toInt()}", style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Paid", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  "₹${grandTotal.toInt()}",
                  style: const TextStyle(color: Color(0xFF22C55E), fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Settled via $method ${txnRef.isNotEmpty ? '• Ref: $txnRef' : ''}",
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
            ),
            const SizedBox(height: 22),

            // WhatsApp Share Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share, size: 16),
                label: const Text("Resend WhatsApp Receipt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _sendWhatsAppReceipt(inv);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftReconciliationModal(double dayTotal, double cashTotal, double upiTotal, int billsCount) {
    double openingFloat = 1000.0;
    double countedCash = cashTotal + openingFloat;
    final floatController = TextEditingController(text: openingFloat.toInt().toString());
    final cashController = TextEditingController(text: countedCash.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final curFloat = double.tryParse(floatController.text) ?? 0.0;
          final curCounted = double.tryParse(cashController.text) ?? 0.0;
          final expectedCashInDrawer = curFloat + cashTotal;
          final variance = curCounted - expectedCashInDrawer;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B3822),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF22C55E), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Daily Shift & Cash Drawer",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Reconciliation for ${DateFormat('EEE, dd MMM yyyy').format(_selectedDate)}",
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141815),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Day Revenue", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text("₹${dayTotal.toInt()}", style: const TextStyle(color: Color(0xFF22C55E), fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("UPI / Online Settled", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text("₹${upiTotal.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Cash Sales Collected", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text("₹${cashTotal.toInt()}", style: const TextStyle(color: Color(0xFFFACC15), fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Closed Bills", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text("$billsCount Invoices", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Opening Cash Float (₹)", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: floatController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Enter opening float amount",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white54, size: 16),
                      filled: true,
                      fillColor: const Color(0xFF141815),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  const Text("Counted Cash in Drawer (₹)", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Enter physical cash counted",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.payments_outlined, color: Colors.white54, size: 16),
                      filled: true,
                      fillColor: const Color(0xFF141815),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: variance == 0
                          ? const Color(0xFF1B3822).withOpacity(0.3)
                          : (variance < 0 ? const Color(0xFF381B1B).withOpacity(0.4) : const Color(0xFF38311B).withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: variance == 0 ? const Color(0xFF22C55E) : (variance < 0 ? Colors.redAccent : Colors.amber),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Expected in Drawer: ₹${expectedCashInDrawer.toInt()}",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              variance == 0
                                  ? "Drawer Balanced"
                                  : (variance < 0 ? "Short by ₹${(-variance).toInt()}" : "Surplus of ₹${variance.toInt()}"),
                              style: TextStyle(
                                color: variance == 0 ? const Color(0xFF22C55E) : (variance < 0 ? Colors.redAccent : Colors.amber),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          variance == 0 ? Icons.check_circle_rounded : (variance < 0 ? Icons.warning_rounded : Icons.info_rounded),
                          color: variance == 0 ? const Color(0xFF22C55E) : (variance < 0 ? Colors.redAccent : Colors.amber),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text("Confirm & Close Shift", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Shift closed! Day total: ₹${dayTotal.toInt()} • Drawer: ₹${curCounted.toInt()} (Variance: ₹${variance.toInt()})",
                            ),
                            backgroundColor: const Color(0xFF141815),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF22C55E)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.appState,
          builder: (context, _) {
            final dayInvoices = _getInvoicesForSelectedDate();

            // Calculate day financial totals
            double dayTotal = 0;
            double upiTotal = 0;
            double cashTotal = 0;
            double cardTotal = 0;

            for (final inv in dayInvoices) {
              final g = ((inv['grandTotal'] ?? inv['grand_total'] ?? 0) as num).toDouble();
              dayTotal += g;
              final m = (inv['paymentMethod'] ?? inv['payment_method'] ?? '').toString().toUpperCase();
              if (m.contains('UPI')) {
                upiTotal += g;
              } else if (m.contains('CASH')) {
                cashTotal += g;
              } else if (m.contains('CARD')) {
                cardTotal += g;
              }
            }

            // Fallback for today if state has todayRevenue recorded
            if (dayTotal == 0 && _isSameDay(_selectedDate, DateTime.now()) && widget.appState.todayRevenue > 0) {
              dayTotal = widget.appState.todayRevenue;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const RuvexiLogoWidget(fontSize: 16, showSubtitle: true),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                        tooltip: "Salon Operations Alerts",
                        onPressed: () => showSalonNotificationModal(context, widget.appState),
                      ),
                    ],
                  ),
                ),

                // Title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                  child: Row(
                    children: [
                      if (widget.showBackButton)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          onPressed: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        )
                      else
                        const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _viewMode == 0 ? "Daily Register & Payments" : "Customers CRM",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _viewMode == 0
                                ? "Settled customer bills for ${DateFormat('EEE, dd MMM').format(_selectedDate)}"
                                : "${widget.appState.visibleCustomers.length} clients (${widget.appState.activeBranch?.name ?? 'This Branch'})",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_viewMode == 1) ...[
                        IconButton(
                          icon: const Icon(Icons.campaign_outlined, color: Color(0xFF22C55E), size: 20),
                          tooltip: "WhatsApp Campaign",
                          onPressed: () => showWhatsAppCampaignRunnerModal(context, widget.appState),
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF22C55E), size: 20),
                          tooltip: "Import Clients",
                          onPressed: () => showImportClientsModal(context, widget.appState),
                        ),
                      ],
                    ],
                  ),
                ),

                // View Mode Switcher: [Payment Records] vs [Clients Directory]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101311),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _viewMode = 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _viewMode == 0 ? const Color(0xFF1B3822) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 15,
                                    color: _viewMode == 0 ? const Color(0xFF22C55E) : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Payment Records",
                                    style: TextStyle(
                                      color: _viewMode == 0 ? const Color(0xFF22C55E) : Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _viewMode = 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _viewMode == 1 ? const Color(0xFF1B3822) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_alt_rounded,
                                    size: 15,
                                    color: _viewMode == 1 ? const Color(0xFF22C55E) : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Clients CRM (${widget.appState.visibleCustomers.length})",
                                    style: TextStyle(
                                      color: _viewMode == 1 ? const Color(0xFF22C55E) : Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ================= VIEW MODE 0: DAILY PAYMENT RECORDS =================
                if (_viewMode == 0) ...[
                  // Date Picker Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateChip(
                            label: "Today (${DateFormat('dd MMM').format(DateTime.now())})",
                            isSelected: _isSameDay(_selectedDate, DateTime.now()),
                            onTap: () => setState(() => _selectedDate = DateTime.now()),
                          ),
                          const SizedBox(width: 8),
                          _buildDateChip(
                            label: "Yesterday (${DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 1)))})",
                            isSelected: _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))),
                            onTap: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1))),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101311),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.calendar_month_rounded, color: Color(0xFF22C55E), size: 14),
                                  SizedBox(width: 4),
                                  Text("Pick Date", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Financial KPI Banner for that Day
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF101E14), Color(0xFF0F1411)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOTAL COLLECTED",
                                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10, letterSpacing: 1),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${dayTotal.toInt()}",
                                  style: const TextStyle(color: Color(0xFF22C55E), fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "BILLS CLOSED",
                                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10, letterSpacing: 1),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${dayInvoices.length} Paid",
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Container(width: 1, height: 32, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "UPI: ₹${upiTotal.toInt()}",
                                style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Cash: ₹${cashTotal.toInt()}",
                                style: const TextStyle(color: Color(0xFFFACC15), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Shift Reconciliation Action Strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF22C55E), width: 1.1),
                          backgroundColor: const Color(0xFF101311),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF22C55E), size: 16),
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Shift Close & Cash Drawer Reconciliation",
                              style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF22C55E), size: 12),
                          ],
                        ),
                        onPressed: () => _showShiftReconciliationModal(dayTotal, cashTotal, upiTotal, dayInvoices.length),
                      ),
                    ),
                  ),

                  // Search + Method Filter Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF101311),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 16),
                                hintText: "Search customer, mobile or invoice...",
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMethodFilter("ALL"),
                        const SizedBox(width: 4),
                        _buildMethodFilter("UPI"),
                        const SizedBox(width: 4),
                        _buildMethodFilter("CASH"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Payment Records List
                  Expanded(
                    child: dayInvoices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, color: Colors.white.withOpacity(0.2), size: 48),
                                const SizedBox(height: 10),
                                Text(
                                  "No payment records for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Bills confirmed at POS or Counter will automatically appear here.",
                                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            itemCount: dayInvoices.length,
                            itemBuilder: (context, index) {
                              final inv = dayInvoices[index];
                              final name = (inv['customerName'] ?? inv['customer_name'] ?? 'Walk-in Guest').toString();
                              final phone = (inv['customerPhone'] ?? inv['customer_phone'] ?? '').toString();
                              final invNum = (inv['invoiceNumber'] ?? inv['invoice_number'] ?? 'RVX').toString();
                              final grandTotal = ((inv['grandTotal'] ?? inv['grand_total'] ?? 0) as num).toDouble();
                              final method = (inv['paymentMethod'] ?? inv['payment_method'] ?? 'UPI').toString().toUpperCase();
                              final dateStr = (inv['date'] ?? inv['paidAt'] ?? 'Today').toString();

                              // Customer Profile Lookup (Gender, DOB)
                              final custMatch = widget.appState.customers.firstWhere(
                                (c) => (phone.isNotEmpty && c.phone == phone) || c.name.toLowerCase() == name.toLowerCase(),
                                orElse: () => Customer(
                                  id: '',
                                  name: name,
                                  phone: phone,
                                  email: '',
                                  gender: (inv['gender'] ?? inv['customerGender'] ?? '').toString(),
                                  dateOfBirth: (inv['dob'] ?? inv['birthday'] ?? inv['customerDob'] ?? '').toString(),
                                  visitsCount: 1,
                                  totalSpent: grandTotal,
                                ),
                              );
                              final gender = custMatch.gender.isNotEmpty ? custMatch.gender : (inv['gender'] ?? inv['customerGender'] ?? '').toString();
                              final dob = custMatch.dateOfBirth.isNotEmpty ? custMatch.dateOfBirth : (inv['dob'] ?? inv['birthday'] ?? inv['customerDob'] ?? '').toString();
                              final stylist = (inv['staffName'] ?? inv['staff_name'] ?? inv['stylist'] ?? '').toString();
                              final discount = ((inv['discountAmount'] ?? inv['discount_amount'] ?? inv['discount'] ?? 0) as num).toDouble();

                              // Parse items & separate Services vs Products
                              List<dynamic> items = [];
                              if (inv['items'] is List) {
                                items = inv['items'];
                              } else if (inv['items_json'] != null) {
                                try {
                                  items = jsonDecode(inv['items_json'].toString());
                                } catch (_) {}
                              }
                              final serviceItems = items.where((i) => i['type'] != 'product').toList();
                              final productItems = items.where((i) => i['type'] == 'product').toList();

                              final isGooglePay = method.contains("GOOGLE") || method.contains("GPAY");
                              final isPhonePe = method.contains("PHONEPE");
                              final isUpi = method.contains("UPI") && !isGooglePay && !isPhonePe;
                              final isCash = method.contains("CASH");

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101311),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CustomerAvatarWidget(name: name, radius: 18),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF142419),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text("PAID", style: TextStyle(color: Color(0xFF22C55E), fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                phone.isNotEmpty ? phone : "Walk-in Guest",
                                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "₹${grandTotal.toInt()}",
                                              style: const TextStyle(color: Color(0xFF22C55E), fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isGooglePay
                                                    ? const Color(0xFF172B38)
                                                    : (isPhonePe
                                                        ? const Color(0xFF2A1738)
                                                        : (isUpi
                                                            ? const Color(0xFF1B3822)
                                                            : (isCash ? const Color(0xFF2D2311) : const Color(0xFF152238)))),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                method,
                                                style: TextStyle(
                                                  color: isGooglePay
                                                      ? const Color(0xFF60A5FA)
                                                      : (isPhonePe
                                                          ? const Color(0xFFC084FC)
                                                          : (isUpi
                                                              ? const Color(0xFF22C55E)
                                                              : (isCash ? const Color(0xFFFACC15) : const Color(0xFF93C5FD)))),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Customer Demographics (Gender, DOB) & Stylist in Charge & Discount
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (gender.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF141815), borderRadius: BorderRadius.circular(4)),
                                            child: Text("Gender: $gender", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                                          ),
                                        if (dob.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF141815), borderRadius: BorderRadius.circular(4)),
                                            child: Text("DOB: $dob", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                                          ),
                                        if (stylist.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF142419), borderRadius: BorderRadius.circular(4)),
                                            child: Text("Stylist: $stylist", style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        if (discount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF2E2211), borderRadius: BorderRadius.circular(4)),
                                            child: Text("Discount: -₹${discount.toInt()}", style: const TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Services List
                                    if (serviceItems.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF141815),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.content_cut, color: Color(0xFF22C55E), size: 12),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Services: ${serviceItems.map((i) => "${i['name']} × ${i['quantity'] ?? i['qty'] ?? 1}").join(', ')}",
                                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Products List
                                    if (productItems.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF191612),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.shopping_bag_outlined, color: Color(0xFFF59E0B), size: 12),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Products: ${productItems.map((i) => "${i['name']} × ${i['quantity'] ?? i['qty'] ?? 1}").join(', ')}",
                                                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                        ),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              icon: const Icon(Icons.share, size: 13, color: Color(0xFF22C55E)),
                                              label: const Text(
                                                "WhatsApp",
                                                style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              onPressed: () => _sendWhatsAppReceipt(inv),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              icon: const Icon(Icons.receipt_long, size: 13, color: Colors.white70),
                                              label: const Text(
                                                "Receipt",
                                                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                              onPressed: () => _showReceiptModal(inv),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],

                // ================= VIEW MODE 1: CLIENTS CRM DIRECTORY =================
                if (_viewMode == 1) ...[
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101311),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v.toLowerCase()),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                          hintText: "Search customer by name or phone",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildClientChip(0, "All (${widget.appState.visibleCustomers.length})"),
                        const SizedBox(width: 8),
                        _buildClientChip(1, "In Salon (${widget.appState.inSalonActiveCount})"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Customer list
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final inSalonNames = widget.appState.inSalonClients
                            .where((i) => i.status == "In Salon")
                            .map((i) => i.customerName.toLowerCase())
                            .toSet();

                        final filtered = widget.appState.visibleCustomers.where((c) {
                          final matches = c.name.toLowerCase().contains(_query.toLowerCase()) || c.phone.contains(_query);
                          if (!matches) return false;
                          if (_clientFilter == 1) return inSalonNames.contains(c.name.toLowerCase());
                          return true;
                        }).toList();

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final customer = filtered[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerProfileScreen(
                                      appState: widget.appState,
                                      customer: customer,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101311),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Row(
                                  children: [
                                    CustomerAvatarWidget(
                                      name: customer.name,
                                      radius: 19,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(customer.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(customer.phone, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CheckInCustomerScreen(appState: widget.appState)),
          );
        },
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildDateChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF101311),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodFilter(String method) {
    final isSelected = _paymentFilter == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentFilter = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3822) : const Color(0xFF101311),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: isSelected ? const Color(0xFF22C55E) : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildClientChip(int index, String label) {
    final isSelected = _clientFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _clientFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF101311),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
