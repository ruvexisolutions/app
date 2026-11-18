import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';
import 'package:ruvexi_mobile/core/widgets/customer_picker_sheet.dart';
import 'package:ruvexi_mobile/features/pos/screens/payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final RuvexiAppState appState;

  const CheckoutScreen({super.key, required this.appState});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Local checkout items if cart was empty or customized
  List<Map<String, dynamic>> _items = [
    {"name": "Hair Cut", "price": 399.0, "qty": 1},
    {"name": "Hair Spa", "price": 1199.0, "qty": 1},
  ];

  double _customDiscountAmount = 0.0;
  double _selectedDiscountPercent = 0.0;
  bool _isPercentDiscount = false;

  @override
  void initState() {
    super.initState();
    if (widget.appState.posCart.isNotEmpty) {
      _items = widget.appState.posCart.map((c) => {
        "name": c.service.name,
        "price": c.service.price,
        "qty": c.quantity,
      }).toList();
    }
    if (widget.appState.discountAmount > 0) {
      _customDiscountAmount = widget.appState.discountAmount;
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + ((i["price"] as double) * (i["qty"] as int)));
  double get _discount {
    if (_isPercentDiscount) {
      return ((_subtotal * _selectedDiscountPercent) / 100.0).clamp(0.0, _subtotal);
    }
    return _customDiscountAmount.clamp(0.0, _subtotal);
  }
  double get _totalPayable => (_subtotal - _discount).clamp(0.0, double.infinity);

  void _openDiscountDialog() {
    int mode = _isPercentDiscount ? 1 : 0; // 0: Rupees (₹), 1: Percent (%)
    final ctrl = TextEditingController(
      text: _isPercentDiscount
          ? (_selectedDiscountPercent > 0 ? _selectedDiscountPercent.toInt().toString() : '')
          : (_customDiscountAmount > 0 ? _customDiscountAmount.toInt().toString() : ''),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Set Salon Discount",
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  "Decide custom discount for this bill (Subtotal: ₹${_subtotal.toInt()})",
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Toggle: Flat Amount (₹) vs Percentage (%)
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141815),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => mode = 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: mode == 0 ? const Color(0xFF22C55E) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Flat Amount (₹)",
                              style: TextStyle(
                                color: mode == 0 ? Colors.black : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => mode = 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: mode == 1 ? const Color(0xFF22C55E) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Percentage (%)",
                              style: TextStyle(
                                color: mode == 1 ? Colors.black : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick percentage / amount chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip("No Discount (₹0)", () {
                        setState(() {
                          _isPercentDiscount = false;
                          _customDiscountAmount = 0.0;
                          _selectedDiscountPercent = 0.0;
                          widget.appState.discountAmount = 0.0;
                        });
                        Navigator.pop(ctx);
                      }, isSelected: _discount == 0),
                      const SizedBox(width: 8),
                      _buildPresetChip("5%", () {
                        setState(() {
                          _isPercentDiscount = true;
                          _selectedDiscountPercent = 5.0;
                          _customDiscountAmount = ((_subtotal * 0.05)).roundToDouble();
                          widget.appState.discountAmount = _customDiscountAmount;
                        });
                        Navigator.pop(ctx);
                      }, isSelected: _isPercentDiscount && _selectedDiscountPercent == 5),
                      const SizedBox(width: 8),
                      _buildPresetChip("10%", () {
                        setState(() {
                          _isPercentDiscount = true;
                          _selectedDiscountPercent = 10.0;
                          _customDiscountAmount = ((_subtotal * 0.10)).roundToDouble();
                          widget.appState.discountAmount = _customDiscountAmount;
                        });
                        Navigator.pop(ctx);
                      }, isSelected: _isPercentDiscount && _selectedDiscountPercent == 10),
                      const SizedBox(width: 8),
                      _buildPresetChip("15%", () {
                        setState(() {
                          _isPercentDiscount = true;
                          _selectedDiscountPercent = 15.0;
                          _customDiscountAmount = ((_subtotal * 0.15)).roundToDouble();
                          widget.appState.discountAmount = _customDiscountAmount;
                        });
                        Navigator.pop(ctx);
                      }, isSelected: _isPercentDiscount && _selectedDiscountPercent == 15),
                      const SizedBox(width: 8),
                      _buildPresetChip("20%", () {
                        setState(() {
                          _isPercentDiscount = true;
                          _selectedDiscountPercent = 20.0;
                          _customDiscountAmount = ((_subtotal * 0.20)).roundToDouble();
                          widget.appState.discountAmount = _customDiscountAmount;
                        });
                        Navigator.pop(ctx);
                      }, isSelected: _isPercentDiscount && _selectedDiscountPercent == 20),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Custom Value Input Field
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      mode == 0 ? Icons.currency_rupee : Icons.percent,
                      color: const Color(0xFF22C55E),
                      size: 18,
                    ),
                    hintText: mode == 0 ? "Enter discount in ₹ (e.g. 100)" : "Enter discount % (e.g. 12)",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22C55E)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
                      setState(() {
                        if (mode == 1) {
                          _isPercentDiscount = true;
                          _selectedDiscountPercent = val.clamp(0.0, 100.0);
                          _customDiscountAmount = ((_subtotal * _selectedDiscountPercent) / 100.0).roundToDouble();
                        } else {
                          _isPercentDiscount = false;
                          _customDiscountAmount = val.clamp(0.0, _subtotal);
                          _selectedDiscountPercent = _subtotal > 0 ? ((_customDiscountAmount / _subtotal) * 100.0).roundToDouble() : 0.0;
                        }
                        widget.appState.discountAmount = _customDiscountAmount;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text("Apply Discount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, {bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3822) : const Color(0xFF141815),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF22C55E) : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _addMoreServices() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Service to Bill",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ...widget.appState.catalog.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.content_cut, color: Color(0xFF22C55E)),
                title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text("₹${s.price.toInt()}", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF22C55E)),
                onTap: () {
                  setState(() {
                    final existingIdx = _items.indexWhere((i) => i["name"] == s.name);
                    if (existingIdx >= 0) {
                      _items[existingIdx]["qty"] = (_items[existingIdx]["qty"] as int) + 1;
                    } else {
                      _items.add({"name": s.name, "price": s.price, "qty": 1});
                    }
                  });
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.appState.posSelectedCustomer ??
        Customer(
          id: "cst_walkin",
          name: "Walk-in Guest",
          phone: "Tap to assign or register client",
          email: "",
          visitsCount: 1,
          totalSpent: 0,
        );

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
          "Checkout",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Bar
            GestureDetector(
              onTap: () {
                CustomerPickerSheet.show(
                  context: context,
                  appState: widget.appState,
                  onSelected: (_) {
                    setState(() {});
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101311),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.appState.posSelectedCustomer != null
                        ? const Color(0xFF22C55E).withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: widget.appState.posSelectedCustomer != null
                          ? const Color(0xFF1B3822)
                          : const Color(0xFF1F2420),
                      child: Text(
                        customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : "W",
                        style: TextStyle(
                          color: widget.appState.posSelectedCustomer != null
                              ? const Color(0xFF22C55E)
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              if (widget.appState.posSelectedCustomer != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF122C1A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Selected",
                                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.phone.isNotEmpty ? customer.phone : "Tap to link or add new customer",
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt, size: 14, color: Color(0xFF22C55E)),
                          SizedBox(width: 4),
                          Text(
                            "Change / Add",
                            style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Services Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Services (${_items.length})",
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _addMoreServices,
                  child: const Text(
                    "Add More",
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items List
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101311),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.content_cut, color: Color(0xFF22C55E), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["name"] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹${(item["price"] as double).toInt()}",
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if ((item["qty"] as int) > 1) {
                                  item["qty"] = (item["qty"] as int) - 1;
                                } else {
                                  _items.removeAt(index);
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text("-", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Text(
                            "${item["qty"]}",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                item["qty"] = (item["qty"] as int) + 1;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text("+", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Summary Breakdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF101311),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Subtotal", "₹${_subtotal.toInt()}"),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _openDiscountDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _discount > 0 ? const Color(0xFF1B3822).withOpacity(0.4) : const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _discount > 0 ? const Color(0xFF22C55E).withOpacity(0.5) : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer_outlined, color: Color(0xFF22C55E), size: 15),
                              const SizedBox(width: 8),
                              Text(
                                _discount > 0
                                    ? "Discount (${_isPercentDiscount ? '${_selectedDiscountPercent.toInt()}%' : '₹${_discount.toInt()}'})"
                                    : "Discount (Tap to set)",
                                style: TextStyle(
                                  color: _discount > 0 ? const Color(0xFF22C55E) : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _discount > 0 ? "-₹${_discount.toInt()}" : "₹0",
                                style: const TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_outlined, color: Color(0xFF22C55E), size: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFF1C221E), height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Payable",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "₹${_totalPayable.toInt()}",
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Proceed to Payment Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.appState.discountAmount = _discount;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        appState: widget.appState,
                        amount: _totalPayable,
                        customerName: customer.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Proceed to Payment",
                      style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

