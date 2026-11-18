import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';
import 'package:ruvexi_mobile/core/widgets/category_service_picker_sheet.dart';
import 'package:ruvexi_mobile/core/widgets/customer_picker_sheet.dart';
import 'package:ruvexi_mobile/features/pos/screens/checkout_screen.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/staff_customers_screen.dart';
import 'package:ruvexi_mobile/shared/widgets/customer_avatar.dart';

class PosBillingScreen extends StatefulWidget {
  final RuvexiAppState appState;

  const PosBillingScreen({super.key, required this.appState});

  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  void _pickCustomer() {
    CustomerPickerSheet.show(
      context: context,
      appState: widget.appState,
      onSelected: (_) {
        setState(() {});
      },
    );
  }

  void _showAddMoreServices() {
    CategoryServicePickerSheet.showAddToCart(
      context: context,
      catalog: widget.appState.catalog,
      title: "Add Service to Bill",
      onAdd: (s) {
        widget.appState.addServiceToCart(s);
      },
    );
  }

  void _openPosDiscountDialog(BuildContext context) {
    final subtotal = widget.appState.cartSubtotal;
    final ctrl = TextEditingController(
      text: widget.appState.discountAmount > 0 ? widget.appState.discountAmount.toInt().toString() : '',
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
                  "Choose discount for this bill (Subtotal: ₹${subtotal.toInt()})",
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
                const SizedBox(height: 14),

                // Quick percentage chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip(ctx, "No Discount (₹0)", () {
                        widget.appState.setDiscountAmount(0.0);
                        Navigator.pop(ctx);
                      }, isSelected: widget.appState.discountAmount == 0),
                      const SizedBox(width: 8),
                      _buildChip(ctx, "5%", () {
                        widget.appState.setDiscountPercent(5.0);
                        Navigator.pop(ctx);
                      }),
                      const SizedBox(width: 8),
                      _buildChip(ctx, "10%", () {
                        widget.appState.setDiscountPercent(10.0);
                        Navigator.pop(ctx);
                      }),
                      const SizedBox(width: 8),
                      _buildChip(ctx, "15%", () {
                        widget.appState.setDiscountPercent(15.0);
                        Navigator.pop(ctx);
                      }),
                      const SizedBox(width: 8),
                      _buildChip(ctx, "20%", () {
                        widget.appState.setDiscountPercent(20.0);
                        Navigator.pop(ctx);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Custom amount text field
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF22C55E), size: 18),
                    hintText: "Enter custom discount (₹)",
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
                const SizedBox(height: 18),

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
                      widget.appState.setDiscountAmount(val);
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

  Widget _buildChip(BuildContext ctx, String label, VoidCallback onTap, {bool isSelected = false}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060706),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          "Billing (POS)",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Barcode & QR Scanner active")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF22C55E), size: 21),
            tooltip: "Today's Register & Payment Records",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffCustomersScreen(
                    appState: widget.appState,
                    showBackButton: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.appState,
        builder: (context, _) {
          final customer = widget.appState.posSelectedCustomer;
          final customerDisplayName = customer != null ? customer.name : "Walk-in Customer";
          final customerSub = customer != null ? customer.phone : "Tap to assign registered client";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select Customer Card
                GestureDetector(
                  onTap: _pickCustomer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101311),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1E2620),
                          child: const Icon(Icons.person_outline, color: Color(0xFF22C55E), size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Select Customer",
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                  ),
                                  if (customer != null && customer.hasActiveMembership) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.stars_rounded, color: Color(0xFFFACC15), size: 10),
                                          const SizedBox(width: 3),
                                          Text(
                                            "${customer.membership} (All Branches)",
                                            style: const TextStyle(color: Color(0xFFFACC15), fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customerDisplayName,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              if (customer != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  customer.hasActiveMembership
                                      ? "${customer.phone.isNotEmpty ? customer.phone : 'Universal Client'} • ${customer.membershipDiscountPercent.toInt()}% Auto Discount"
                                      : (customer.phone.isNotEmpty ? customer.phone : "Registered Client"),
                                  style: TextStyle(
                                    color: customer.hasActiveMembership ? const Color(0xFF22C55E) : Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                    fontWeight: customer.hasActiveMembership ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Add Services Section Header
                const Text(
                  "Add Services",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Services in Cart
                ...widget.appState.posCart.map((cartItem) {
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
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF181D1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.content_cut, color: Color(0xFF22C55E), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartItem.service.name,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "₹${cartItem.service.price.toInt()}",
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Stepper [- 1 +]
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141815),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => widget.appState.updateCartQuantity(cartItem.service.id, -1),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Text("-", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Text(
                                "${cartItem.quantity}",
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () => widget.appState.updateCartQuantity(cartItem.service.id, 1),
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

                // Add More Services button
                Center(
                  child: TextButton.icon(
                    onPressed: _showAddMoreServices,
                    icon: const Icon(Icons.add, color: Color(0xFF22C55E), size: 16),
                    label: const Text(
                      "Add More Services",
                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101311),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow("Subtotal", "₹${widget.appState.cartSubtotal.toInt()}"),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _openPosDiscountDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.appState.discountAmount > 0 ? const Color(0xFF1B3822).withOpacity(0.4) : const Color(0xFF141815),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.appState.discountAmount > 0 ? const Color(0xFF22C55E).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_offer_outlined, color: Color(0xFF22C55E), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.appState.discountAmount > 0 ? "Discount (Tap to edit)" : "Discount (Tap to set)",
                                    style: TextStyle(
                                      color: widget.appState.discountAmount > 0 ? const Color(0xFF22C55E) : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    widget.appState.discountAmount > 0 ? "-₹${widget.appState.discountAmount.toInt()}" : "₹0",
                                    style: const TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined, color: Color(0xFF22C55E), size: 13),
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
                            "₹${widget.appState.cartTotalPayable.toInt()}",
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Proceed to Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(appState: widget.appState),
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
                const SizedBox(height: 30),
              ],
            ),
          );
        },
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
