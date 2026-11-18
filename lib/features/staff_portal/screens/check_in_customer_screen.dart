import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/widgets/category_service_picker_sheet.dart';
import 'package:ruvexi_mobile/core/widgets/customer_picker_sheet.dart';
import 'package:ruvexi_mobile/shared/widgets/ruvexi_logo.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/seats_stations_screen.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/in_salon_screen.dart';
import 'package:ruvexi_mobile/shared/widgets/salon_notification_dialog.dart';

class CheckInCustomerScreen extends StatefulWidget {
  final RuvexiAppState appState;
  final String? preselectedSeatId;

  const CheckInCustomerScreen({
    super.key,
    required this.appState,
    this.preselectedSeatId,
  });

  @override
  State<CheckInCustomerScreen> createState() => _CheckInCustomerScreenState();
}

class _CheckInCustomerScreenState extends State<CheckInCustomerScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<ServiceItem> _selectedServices = [];
  String _assignedStaff = "Manoj K";
  String? _selectedSeatId;
  String _selectedGender = "Female";
  DateTime? _selectedDob;
  Customer? _matchedCustomer;

  void _onCustomerDetailsChanged() {
    final rawPhone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final rawName = _nameCtrl.text.trim().toLowerCase();

    Customer? match;
    if (rawPhone.length >= 7) {
      match = widget.appState.customers.cast<Customer?>().firstWhere(
        (c) => c != null && c.phone.replaceAll(RegExp(r'\D'), '').contains(rawPhone),
        orElse: () => null,
      );
    }
    if (match == null && rawName.length >= 3) {
      match = widget.appState.customers.cast<Customer?>().firstWhere(
        (c) => c != null && c.name.toLowerCase() == rawName,
        orElse: () => null,
      );
    }

    if (_matchedCustomer?.id != match?.id) {
      setState(() {
        _matchedCustomer = match;
      });
    }
  }

  void _selectExistingCustomer() {
    CustomerPickerSheet.show(
      context: context,
      appState: widget.appState,
      onSelected: (c) {
        if (c != null) {
          setState(() {
            _matchedCustomer = c;
            _nameCtrl.text = c.name;
            _phoneCtrl.text = c.phone;
            if (c.gender.isNotEmpty) _selectedGender = c.gender;
            if (c.dateOfBirth.isNotEmpty) {
              try {
                _selectedDob = DateTime.parse(c.dateOfBirth);
              } catch (_) {}
            }
          });
        }
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 24, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF22C55E),
              onPrimary: Colors.black,
              surface: Color(0xFF141815),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSeatId = widget.preselectedSeatId;
    _nameCtrl.addListener(_onCustomerDetailsChanged);
    _phoneCtrl.addListener(_onCustomerDetailsChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onCustomerDetailsChanged);
    _phoneCtrl.removeListener(_onCustomerDetailsChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _pickServices() async {
    final picked = await CategoryServicePickerSheet.showMulti(
      context: context,
      catalog: widget.appState.catalog,
      title: "Select Services by Category",
      selected: _selectedServices,
    );
    if (picked != null) {
      setState(() {
        _selectedServices.clear();
        _selectedServices.addAll(picked);
      });
    }
  }

  void _pickStaff() {
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
            const Text("Assign Staff", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...widget.appState.staff.map((st) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF18221B),
                    child: Text(st.name[0], style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(st.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(st.role, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  trailing: _assignedStaff == st.name ? const Icon(Icons.check_circle, color: Color(0xFF22C55E)) : null,
                  onTap: () {
                    setState(() => _assignedStaff = st.name);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSeat() async {
    final chosenSeat = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatsStationsScreen(
          appState: widget.appState,
          selectionMode: true,
        ),
      ),
    );
    if (chosenSeat != null) {
      setState(() => _selectedSeatId = chosenSeat);
    }
  }

  void _submitCheckIn() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Customer Name")),
      );
      return;
    }

    final servicesToAssign = _selectedServices.isNotEmpty
        ? List<ServiceItem>.from(_selectedServices)
        : [widget.appState.catalog.first];

    final seatToAssign = _selectedSeatId ?? "Waiting";

    final dobStr = _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : "";
    if (_matchedCustomer != null) {
      widget.appState.setPosCustomer(_matchedCustomer);
    }

    widget.appState.checkInCustomer(
      customerName: name,
      phone: _phoneCtrl.text.trim(),
      gender: _selectedGender,
      dateOfBirth: dobStr,
      services: servicesToAssign,
      assignedStaff: _assignedStaff,
      seatId: seatToAssign,
      notes: _notesCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$name checked in to $seatToAssign")),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InSalonScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesLabel = _selectedServices.isEmpty
        ? "Select Services *"
        : _selectedServices.map((s) => s.name).join(" + ");

    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Check-in Customer",
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  children: [
                    // Universal Client Quick Select
                    GestureDetector(
                      onTap: _selectExistingCustomer,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141815),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _matchedCustomer != null
                                ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, color: Color(0xFF22C55E), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _matchedCustomer != null
                                        ? "Client: ${_matchedCustomer!.name}"
                                        : "Search Existing / Universal Client",
                                    style: TextStyle(
                                      color: _matchedCustomer != null ? Colors.white : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: _matchedCustomer != null ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _matchedCustomer != null
                                        ? "${_matchedCustomer!.phone} • ${_matchedCustomer!.membership}"
                                        : "Recognize client across all salon branches",
                                    style: TextStyle(
                                      color: _matchedCustomer != null
                                          ? const Color(0xFF22C55E).withValues(alpha: 0.8)
                                          : Colors.white.withValues(alpha: 0.4),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _matchedCustomer != null ? "Change" : "Browse",
                                style: const TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Universal Cross-Branch Membership Recognized Banner
                    if (_matchedCustomer != null && _matchedCustomer!.hasActiveMembership) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFACC15).withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stars_rounded, color: Color(0xFFFACC15), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _matchedCustomer!.membership,
                                        style: const TextStyle(
                                          color: Color(0xFFFACC15),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          "CROSS-BRANCH ACCESS",
                                          style: TextStyle(
                                            color: Color(0xFF22C55E),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Membership recognized from salon network • ${_matchedCustomer!.membershipDiscountPercent.toInt()}% Member privilege will apply automatically at checkout!",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Customer Name *
                    _buildTextField(
                      controller: _nameCtrl,
                      icon: Icons.person_outline,
                      hint: "Customer Name *",
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    _buildTextField(
                      controller: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      hint: "Phone Number (Contact)",
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // Gender Selector
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              const Icon(Icons.transgender_rounded, color: Colors.white38, size: 18),
                              const SizedBox(width: 8),
                              Text("Gender", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ["Female", "Male", "Other"].map((g) {
                              final isSel = _selectedGender == g;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedGender = g),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFF1B3822) : const Color(0xFF161A17),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? const Color(0xFF22C55E) : Colors.transparent,
                                      ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date of Birth (DOB) Picker
                    _buildPickerTile(
                      icon: Icons.cake_outlined,
                      label: _selectedDob != null
                          ? "DOB: ${DateFormat('dd MMM yyyy').format(_selectedDob!)}"
                          : "Date of Birth (Optional)",
                      hasValue: _selectedDob != null,
                      onTap: _pickDob,
                    ),
                    const SizedBox(height: 12),

                    // Select Services *
                    _buildPickerTile(
                      icon: Icons.grid_view_rounded,
                      label: servicesLabel,
                      hasValue: _selectedServices.isNotEmpty,
                      onTap: _pickServices,
                    ),
                    const SizedBox(height: 12),

                    // Assign Staff (Optional)
                    _buildPickerTile(
                      icon: Icons.badge_outlined,
                      label: "Staff: $_assignedStaff",
                      hasValue: true,
                      onTap: _pickStaff,
                    ),
                    const SizedBox(height: 12),

                    // Select Seat / Station *
                    _buildPickerTile(
                      icon: Icons.chair_alt_outlined,
                      label: _selectedSeatId != null ? "Seat: $_selectedSeatId" : "Select Seat / Station *",
                      hasValue: _selectedSeatId != null,
                      onTap: _pickSeat,
                    ),
                    const SizedBox(height: 12),

                    // Notes (Optional)
                    _buildTextField(
                      controller: _notesCtrl,
                      icon: Icons.description_outlined,
                      hint: "Notes (Optional)",
                      maxLines: 2,
                    ),
                    const SizedBox(height: 28),

                    // Check-in Customer -> Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitCheckIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Check-in Customer",
                              style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101311),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF101311),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: hasValue ? Colors.white : Colors.white.withOpacity(0.45),
                  fontSize: 13.5,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

