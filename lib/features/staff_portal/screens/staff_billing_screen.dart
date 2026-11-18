import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/widgets/category_service_picker_sheet.dart';
import 'package:ruvexi_mobile/core/widgets/customer_picker_sheet.dart';
import 'package:ruvexi_mobile/shared/widgets/ruvexi_logo.dart';
import 'package:ruvexi_mobile/shared/widgets/salon_notification_dialog.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/staff_payment_screen.dart';

class StaffBillingScreen extends StatefulWidget {
  final RuvexiAppState appState;
  final bool showBackButton;
  final VoidCallback? onBack;

  const StaffBillingScreen({
    super.key,
    required this.appState,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  State<StaffBillingScreen> createState() => _StaffBillingScreenState();
}

class _StaffBillingScreenState extends State<StaffBillingScreen> {
  double _discount = 0.0;
  String _selectedStylist = "Manoj K";

  @override
  void initState() {
    super.initState();
    final customer = widget.appState.posSelectedCustomer;
    if (customer != null && customer.hasActiveMembership && customer.membershipDiscountPercent > 0) {
      final subtotal = widget.appState.cartSubtotal;
      _discount = ((subtotal * customer.membershipDiscountPercent) / 100.0).roundToDouble();
      widget.appState.discountAmount = _discount;
    }
  }

  void _showStylistPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Stylist in Charge", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...widget.appState.staff.map((st) {
              final isSel = _selectedStylist == st.name;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF18221B),
                  child: Text(st.name[0], style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                ),
                title: Text(st.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(st.role, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF22C55E)) : null,
                onTap: () {
                  setState(() => _selectedStylist = st.name);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddProductSheet() {
    final products = widget.appState.inventory;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Color(0xFF22C55E), size: 20),
                    SizedBox(width: 8),
                    Text("Add Retail Product to Bill", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No retail products found. Add products in Services -> Products tab.",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${p.price.toInt()} • ${p.category} • ${p.stock} in stock",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              widget.appState.addProductToCart(p, staffName: _selectedStylist);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Added ${p.name} to bill")),
                              );
                            },
                            child: const Text("+ Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _pickCustomer() {
    CustomerPickerSheet.show(
      context: context,
      appState: widget.appState,
      onSelected: (c) {
        if (c != null && c.hasActiveMembership && c.membershipDiscountPercent > 0) {
          final subtotal = widget.appState.cartSubtotal;
          setState(() {
            _discount = ((subtotal * c.membershipDiscountPercent) / 100.0).roundToDouble();
            widget.appState.discountAmount = _discount;
          });
        }
        setState(() {});
      },
    );
  }

  void _showAddServiceSheet() {
    CategoryServicePickerSheet.showAddToCart(
      context: context,
      catalog: widget.appState.catalog,
      title: "Add Service to Bill",
      onAdd: (s) {
        widget.appState.addServiceToCart(s);
      },
    );
  }

  void _editDiscountDialog() {
    final subtotal = widget.appState.cartSubtotal;
    final ctrl = TextEditingController(text: _discount > 0 ? _discount.toInt().toString() : '');
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
                      "Apply Salon Discount",
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  "Owner discount for this bill (Subtotal: ₹${subtotal.toInt()})",
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip("No Discount (₹0)", () {
                        setState(() {
                          _discount = 0.0;
                          widget.appState.discountAmount = 0.0;
                        });
                        Navigator.pop(ctx);
                      }, isSelected: _discount == 0),
                      const SizedBox(width: 8),
                      _buildPresetChip("5%", () {
                        setState(() {
                          _discount = ((subtotal * 0.05)).roundToDouble();
                          widget.appState.discountAmount = _discount;
                        });
                        Navigator.pop(ctx);
                      }),
                      const SizedBox(width: 8),
                      _buildPresetChip("10%", () {
                        setState(() {
                          _discount = ((subtotal * 0.10)).roundToDouble();
                          widget.appState.discountAmount = _discount;
                        });
                        Navigator.pop(ctx);
                      }),
                      const SizedBox(width: 8),
                      _buildPresetChip("15%", () {
                        setState(() {
                          _discount = ((subtotal * 0.15)).roundToDouble();
                          widget.appState.discountAmount = _discount;
                        });
                        Navigator.pop(ctx);
                      }),
                      const SizedBox(width: 8),
                      _buildPresetChip("20%", () {
                        setState(() {
                          _discount = ((subtotal * 0.20)).roundToDouble();
                          widget.appState.discountAmount = _discount;
                        });
                        Navigator.pop(ctx);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                      setState(() {
                        _discount = val.clamp(0.0, subtotal);
                        widget.appState.discountAmount = _discount;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.appState,
          builder: (context, _) {
            final customer = widget.appState.posSelectedCustomer;
            final customerName = customer?.name ?? "Walk-in Customer";
            final customerPhone = customer?.phone ?? "Tap to link customer";

            final subtotal = widget.appState.cartSubtotal;
            final appliedDiscount = _discount > subtotal ? subtotal : _discount;
            final totalPayable = (subtotal - appliedDiscount).clamp(0.0, double.infinity);

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
                        tooltip: "Salon Alerts",
                        onPressed: () => showSalonNotificationModal(context, widget.appState),
                      ),
                    ],
                  ),
                ),

                // Back + Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
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
                      const Text(
                        "Billing (POS)",
                        style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Banner
                        GestureDetector(
                          onTap: _pickCustomer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101311),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: customer != null && customer.hasActiveMembership
                                    ? const Color(0xFFFACC15).withValues(alpha: 0.5)
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 19,
                                      backgroundColor: customer != null && customer.hasActiveMembership
                                          ? const Color(0xFF2B2612)
                                          : const Color(0xFF312E81),
                                      child: Text(
                                        customerName[0],
                                        style: TextStyle(
                                          color: customer != null && customer.hasActiveMembership
                                              ? const Color(0xFFFACC15)
                                              : const Color(0xFFA5B4FC),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
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
                                              Text(customerName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                              if (customer != null && customer.hasActiveMembership) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2B2612),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.4)),
                                                  ),
                                                  child: Text(
                                                    customer.membership,
                                                    style: const TextStyle(color: Color(0xFFFACC15), fontSize: 9.5, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(customerPhone, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                      onPressed: () => widget.appState.setPosCustomer(null),
                                    ),
                                  ],
                                ),
                                if (customer != null && customer.hasActiveMembership) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stars_rounded, color: Color(0xFFFACC15), size: 14),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Universal All-Branches Member: Auto ${customer.membershipDiscountPercent.toInt()}% discount active",
                                            style: const TextStyle(
                                              color: Color(0xFFFACC15),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stylist Selection Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101311),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.badge_outlined, color: Color(0xFF22C55E), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Stylist: $_selectedStylist",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showStylistPickerSheet,
                                child: const Text(
                                  "Change",
                                  style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Services & Products Header + Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Services & Products", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _showAddServiceSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF142419),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.content_cut, color: Color(0xFF22C55E), size: 11),
                                        SizedBox(width: 4),
                                        Text("+ Service", style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _showAddProductSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF142419),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.shopping_bag_outlined, color: Color(0xFF22C55E), size: 11),
                                        SizedBox(width: 4),
                                        Text("+ Product", style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Cart Items
                        if (widget.appState.posCart.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101311),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Center(
                              child: Text("No services added. Tap 'Add Service' above.",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ),
                          ),

                        ...widget.appState.posCart.map((cartItem) {
                          final isProd = cartItem.isProduct;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101311),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141815),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isProd ? Icons.shopping_bag_rounded : Icons.content_cut,
                                    color: const Color(0xFF22C55E),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(cartItem.name, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isProd ? const Color(0xFF251A10) : const Color(0xFF142419),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isProd ? "PRODUCT" : "SERVICE",
                                              style: TextStyle(color: isProd ? const Color(0xFFF59E0B) : const Color(0xFF22C55E), fontSize: 8.5, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text("₹${cartItem.price.toInt()}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141815),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => widget.appState.updateCartQuantity(cartItem.id, -1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          child: Text("−", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      Text("${cartItem.quantity}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      GestureDetector(
                                        onTap: () => widget.appState.updateCartQuantity(cartItem.id, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          child: Text("+", style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.bold)),
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

                        // Financial Breakdown Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101311),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow("Subtotal", "₹${subtotal.toInt()}"),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _editDiscountDialog,
                                child: _buildSummaryRow("Discount (Tap to edit)", "-₹${appliedDiscount.toInt()}", valueColor: const Color(0xFF22C55E)),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFF1C221E), height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total Payable", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text(
                                    "₹${totalPayable.round()}",
                                    style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.bold),
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
                            onPressed: widget.appState.posCart.isEmpty
                                ? null
                                : () {
                                    widget.appState.discountAmount = appliedDiscount;
                                    final itemsList = widget.appState.posCart
                                        .map((c) => {
                                              "name": c.name,
                                              "price": c.price,
                                              "qty": c.quantity,
                                              "type": c.type,
                                              "staffName": c.staffName ?? _selectedStylist,
                                            })
                                        .toList();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StaffPaymentScreen(
                                          appState: widget.appState,
                                          totalAmount: totalPayable.roundToDouble(),
                                          customerName: customerName,
                                          customerPhone: customerPhone,
                                          staffName: _selectedStylist,
                                          billedItems: itemsList,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              disabledBackgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Proceed to Payment", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

