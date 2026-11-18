import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/shared/widgets/customer_avatar.dart';

class CustomerPickerSheet extends StatefulWidget {
  final RuvexiAppState appState;
  final Function(Customer?) onSelected;

  const CustomerPickerSheet({
    super.key,
    required this.appState,
    required this.onSelected,
  });

  static void show({
    required BuildContext context,
    required RuvexiAppState appState,
    required Function(Customer?) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: Color(0xFF22C55E), width: 1),
      ),
      builder: (ctx) => CustomerPickerSheet(
        appState: appState,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddNewCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: "+91 ");
    String selectedGender = "Female";
    DateTime? selectedDob;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141815),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: Color(0xFF22C55E), width: 1.2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
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
                        Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF22C55E), size: 22),
                        SizedBox(width: 8),
                        Text(
                          "New Customer for Bill",
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Enter client details. They will be saved to your CRM and selected for this bill.",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Name field
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Customer Full Name",
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    hintText: "e.g. Ananya Rao",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF101311),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone field
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: "Mobile Number (for WhatsApp Bill)",
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    hintText: "+91 98765 43210",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF101311),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Gender selector
                Row(
                  children: ["Female", "Male", "Other"].map((g) {
                    final isSel = selectedGender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedGender = g),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF1B3822) : const Color(0xFF101311),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFF22C55E) : Colors.white.withValues(alpha: 0.1)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSel ? const Color(0xFF22C55E) : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Date of Birth picker
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime(now.year - 24, now.month, now.day),
                      firstDate: DateTime(1940),
                      lastDate: now,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDob = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101311),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: Colors.white38, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          selectedDob != null
                              ? "DOB: ${DateFormat('dd MMM yyyy').format(selectedDob!)}"
                              : "Date of Birth (Optional)",
                          style: TextStyle(
                            color: selectedDob != null ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter the customer name")),
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            try {
                              final dobStr = selectedDob != null ? DateFormat('yyyy-MM-dd').format(selectedDob!) : "";
                              final newCustomer = Customer(
                                id: "cst_${DateTime.now().millisecondsSinceEpoch}",
                                name: name,
                                phone: phone.isNotEmpty && phone != "+91" ? phone : "",
                                email: "${name.toLowerCase().replaceAll(' ', '.')}@example.com",
                                gender: selectedGender,
                                dateOfBirth: dobStr,
                                visitsCount: 1,
                                totalSpent: 0,
                                membership: "Silver Regular",
                                tag: "New",
                              );

                              await widget.appState.addCustomer(newCustomer);
                              widget.appState.setPosCustomer(newCustomer);
                              widget.onSelected(newCustomer);

                              if (!mounted) return;
                              Navigator.pop(ctx); // Close Add Dialog
                              Navigator.pop(context); // Close Customer Picker Sheet

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Selected $name for billing!"),
                                  backgroundColor: const Color(0xFF122C1A),
                                ),
                              );
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            "Add & Select for Billing",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final matchingCustomers = widget.appState.customers.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Select Customer",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  "New Customer",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _showAddNewCustomerDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF141815),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                hintText: "Search by client name or phone...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Walk-in Option Tile
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141815),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.appState.posSelectedCustomer == null
                    ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: ListTile(
              dense: true,
              leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1F2420),
                child: Icon(Icons.person_outline, color: Color(0xFF22C55E), size: 18),
              ),
              title: const Text(
                "Walk-in Customer",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: Text(
                "Anonymous guest bill without phone number",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
              trailing: widget.appState.posSelectedCustomer == null
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20)
                  : null,
              onTap: () {
                widget.appState.setPosCustomer(null);
                widget.onSelected(null);
                Navigator.pop(context);
              },
            ),
          ),

          const Divider(color: Color(0xFF1C221E), height: 16),

          // Scrollable list of registered customers
          Expanded(
            child: matchingCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, color: Colors.white.withValues(alpha: 0.3), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          "No customer found matching '$_searchQuery'",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF22C55E),
                            side: const BorderSide(color: Color(0xFF22C55E)),
                          ),
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: Text("Add '$_searchQuery' as New Customer"),
                          onPressed: _showAddNewCustomerDialog,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: matchingCustomers.length,
                    itemBuilder: (ctx, idx) {
                      final c = matchingCustomers[idx];
                      final isSelected = widget.appState.posSelectedCustomer?.id == c.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF142419) : const Color(0xFF141815),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF22C55E) : Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CustomerAvatarWidget(
                            name: c.name,
                            radius: 16,
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          subtitle: Text(
                            c.phone.isNotEmpty ? c.phone : "No phone number",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20)
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.membership,
                                    style: TextStyle(
                                      color: c.membership.toLowerCase().contains("vip")
                                          ? const Color(0xFF22C55E)
                                          : Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          onTap: () {
                            widget.appState.setPosCustomer(c);
                            widget.onSelected(c);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
