import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruvexi_mobile/core/network/api_config.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';
import 'package:ruvexi_mobile/features/crm/screens/customer_profile_screen.dart';
import 'package:ruvexi_mobile/shared/widgets/customer_avatar.dart';
import 'package:ruvexi_mobile/shared/widgets/salon_notification_dialog.dart';

class CustomersCrmScreen extends StatefulWidget {
  final RuvexiAppState appState;

  const CustomersCrmScreen({super.key, required this.appState});

  @override
  State<CustomersCrmScreen> createState() => _CustomersCrmScreenState();
}

class _CustomersCrmScreenState extends State<CustomersCrmScreen> {
  int _selectedFilterIndex = 0; // 0: All (348), 1: Regular, 2: New, 3: Inactive
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: "+91 ");
    String selectedGender = "Female";
    DateTime? selectedDob;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF101311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF22C55E), width: 1),
          ),
          title: const Text("Add New Customer Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Customer Name *",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Customer Contact (Phone) *",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ["Female", "Male", "Other"].map((g) {
                    final isSel = selectedGender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDlgState(() => selectedGender = g),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF1B3822) : const Color(0xFF141815),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? const Color(0xFF22C55E) : Colors.transparent),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSel ? const Color(0xFF22C55E) : Colors.white60,
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
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
                      setDlgState(() => selectedDob = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141815),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: Colors.white38, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          selectedDob != null
                              ? "DOB: ${DateFormat('dd MMM yyyy').format(selectedDob!)}"
                              : "Date of Birth (Optional)",
                          style: TextStyle(
                            color: selectedDob != null ? Colors.white : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final dobStr = selectedDob != null ? DateFormat('yyyy-MM-dd').format(selectedDob!) : "";
                  final newCustomer = Customer(
                    id: "c_${DateTime.now().millisecondsSinceEpoch}",
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: "${nameCtrl.text.toLowerCase().replaceAll(' ', '.')}@example.com",
                    gender: selectedGender,
                    dateOfBirth: dobStr,
                    visitsCount: 1,
                    totalSpent: 0,
                    tag: "New",
                    branchId: widget.appState.activeBranch?.id ?? "",
                  );
                widget.appState.addCustomer(newCustomer);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${newCustomer.name} added successfully")),
                );
              }
            },
            child: const Text("Add Customer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

  void _showImportClientsSheet() {
    final textCtrl = TextEditingController();
    bool isSubmitting = false;
    String duplicateStrategy = "merge";
    int detectedCount = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF22C55E), width: 1.2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          void updateCount() {
            final lines = textCtrl.text.split(RegExp(r'[\r\n]+'));
            int count = 0;
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              final digits = line.replaceAll(RegExp(r'\D'), '');
              if (digits.length >= 10) count++;
            }
            setSheetState(() => detectedCount = count);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.file_upload_outlined, color: Color(0xFF22C55E), size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Import Clients List",
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
                    "Paste from Excel, Google Sheets, or WhatsApp (Format: Name, Phone)",
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Multi-line Text Area
                  TextField(
                    controller: textCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                    onChanged: (_) => updateCount(),
                    decoration: InputDecoration(
                      hintText: "Full Name, Phone Number\nClient Two, 98XXXXXXXX",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF141815),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Strategy selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141815),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "If phone already exists:",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                        DropdownButton<String>(
                          value: duplicateStrategy,
                          dropdownColor: const Color(0xFF181C19),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: "merge", child: Text("Merge & Update")),
                            DropdownMenuItem(value: "skip", child: Text("Skip Duplicate")),
                          ],
                          onChanged: (val) {
                            if (val != null) setSheetState(() => duplicateStrategy = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Submit Button
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
                      onPressed: isSubmitting || detectedCount == 0
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              try {
                                final lines = textCtrl.text.split(RegExp(r'[\r\n]+'));
                                final customersToImport = <Map<String, dynamic>>[];

                                for (final line in lines) {
                                  if (line.trim().isEmpty) continue;
                                  final parts = line.split(RegExp(r'[,;\t]'));
                                  String name = parts.isNotEmpty ? parts[0].trim() : "Valued Client";
                                  String phone = parts.length > 1 ? parts[1].trim() : "";
                                  if (phone.isEmpty && parts.length == 1) {
                                    phone = parts[0].trim();
                                    name = "Valued Client";
                                  }
                                  final digits = phone.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length >= 10) {
                                    customersToImport.add({
                                      'name': name,
                                      'phone': digits.length > 10 ? digits.substring(digits.length - 10) : digits,
                                      'vipTier': 'Silver Regular',
                                      'totalVisits': 1,
                                    });
                                  }
                                }

                                if (customersToImport.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("No valid 10-digit phone numbers detected")),
                                  );
                                  setSheetState(() => isSubmitting = false);
                                  return;
                                }

                                final res = await widget.appState.importCustomers(
                                  customersToImport,
                                  duplicateStrategy: duplicateStrategy,
                                );

                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Successfully imported ${res['imported']} clients (${res['updated'] ?? 0} updated)!",
                                    ),
                                    backgroundColor: const Color(0xFF122C1A),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                setSheetState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              "Import $detectedCount Clients",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
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

  void _showWhatsAppCampaignSheet() {
    int runnerStep = 0; // 0: Config, 1: Active Runner, 2: Done
    String targetAudience = "all"; // all, vip, inactive
    int currentIndex = 0;
    int sentCount = 0;
    int skippedCount = 0;

    final templateCtrl = TextEditingController(
      text: "Dear {name}, we miss seeing you at {salon}! ✨ Here is a special 20% privilege off on your next visit. Book your slot online: {booking_link}",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF22C55E), width: 1.2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final salonName = widget.appState.salonName;
          final bookingUrl = "${RuvexiApiConfig.webAppUrl}/book";

          // Filter eligible clients with >=10 digits phone
          final targetList = widget.appState.visibleCustomers.where((c) {
            final digits = c.phone.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 10) return false;
            if (targetAudience == "vip") {
              final tier = c.membership.toLowerCase();
              return tier.contains("vip") || tier.contains("gold") || tier.contains("platinum");
            }
            if (targetAudience == "inactive") {
              return c.visitsCount <= 1;
            }
            return true;
          }).toList();

          String formatMsg(Customer c) {
            return templateCtrl.text
                .replaceAll("{name}", c.name)
                .replaceAll("{salon}", salonName)
                .replaceAll("{booking_link}", bookingUrl);
          }

          Future<void> sendAndAdvance(Customer current) async {
            final digits = current.phone.replaceAll(RegExp(r'\D'), '');
            final phoneParam = digits.length == 10 ? '91$digits' : digits;
            final message = formatMsg(current);
            final uri = Uri.parse("https://wa.me/$phoneParam?text=${Uri.encodeComponent(message)}");

            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } catch (_) {}

            setSheetState(() {
              sentCount++;
              if (currentIndex + 1 >= targetList.length) {
                runnerStep = 2;
              } else {
                currentIndex++;
              }
            });
          }

          void skipAndAdvance() {
            setSheetState(() {
              skippedCount++;
              if (currentIndex + 1 >= targetList.length) {
                runnerStep = 2;
              } else {
                currentIndex++;
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Color(0xFF22C55E), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "WhatsApp Campaign Runner",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "100% Free • No Meta API Required",
                                style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (runnerStep == 0) ...[
                    // Audience Filter Chips
                    Text("Select Audience:", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterPill(
                          label: "All (${widget.appState.visibleCustomers.length})",
                          isSelected: targetAudience == "all",
                          onTap: () => setSheetState(() => targetAudience = "all"),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: "VIP Tier",
                          isSelected: targetAudience == "vip",
                          onTap: () => setSheetState(() => targetAudience = "vip"),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: "1-Visit Clients",
                          isSelected: targetAudience == "inactive",
                          onTap: () => setSheetState(() => targetAudience = "inactive"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Template Pills
                    Text("Quick Templates:", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip("✨ 20% Off", () {
                            templateCtrl.text = "Dear {name}, we miss seeing you at {salon}! ✨ Special 20% off on your next visit. Book: {booking_link}";
                            setSheetState(() {});
                          }),
                          const SizedBox(width: 6),
                          _buildPresetChip("💆 Hair Spa Glow", () {
                            templateCtrl.text = "Hi {name}! Treat yourself this weekend at {salon} with our premium Hair Spa & Aesthetics. Reserve: {booking_link}";
                            setSheetState(() {});
                          }),
                          const SizedBox(width: 6),
                          _buildPresetChip("🎉 Festive Offer", () {
                            templateCtrl.text = "Festival greetings from {salon}! 🌟 Celebrate with our exclusive festive makeover packages, {name}. Book: {booking_link}";
                            setSheetState(() {});
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Message Editor
                    TextField(
                      controller: templateCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF141815),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live preview for first customer
                    if (targetList.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142318),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Preview for ${targetList.first.name}:",
                              style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMsg(targetList.first),
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Start Runner Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                        label: Text(
                          "Start Runner (${targetList.length} Clients)",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: targetList.isEmpty
                            ? null
                            : () {
                                setSheetState(() {
                                  runnerStep = 1;
                                  currentIndex = 0;
                                  sentCount = 0;
                                  skippedCount = 0;
                                });
                              },
                      ),
                    ),
                  ] else if (runnerStep == 1 && currentIndex < targetList.length) ...[
                    // Runner Active Queue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Client ${currentIndex + 1} of ${targetList.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${(((currentIndex) / targetList.length) * 100).toInt()}% Done",
                          style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / targetList.length,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Client Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          CustomerAvatarWidget(name: targetList[currentIndex].name, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetList[currentIndex].name,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  targetList[currentIndex].phone,
                                  style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              targetList[currentIndex].membership,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pre-composed Message Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF142318),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ready Message:", style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            formatMsg(targetList[currentIndex]),
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons (Skip & Send)
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white60,
                            side: BorderSide(color: Colors.white.withOpacity(0.15)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: skipAndAdvance,
                          child: const Text("Skip"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.black),
                            label: const Text(
                              "Open WhatsApp & Next ➔",
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => sendAndAdvance(targetList[currentIndex]),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Completed View
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF22C55E).withOpacity(0.15),
                              border: Border.all(color: const Color(0xFF22C55E), width: 2),
                            ),
                            child: const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Campaign Run Completed!",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$sentCount messages opened in WhatsApp • $skippedCount skipped",
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Done & Close", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF141815),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: const Color(0xFF141815),
      side: BorderSide(color: Colors.white.withOpacity(0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Customers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.campaign_outlined, color: Color(0xFF22C55E), size: 22),
                        tooltip: "WhatsApp Campaign",
                        onPressed: _showWhatsAppCampaignSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF22C55E), size: 22),
                        tooltip: "Import Clients",
                        onPressed: _showImportClientsSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.sync_rounded, color: Color(0xFF22C55E), size: 22),
                        tooltip: "Sync with Cloud",
                        onPressed: () => widget.appState.syncWorkspace(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                        tooltip: "Salon Notifications",
                        onPressed: () => showSalonNotificationModal(context, widget.appState),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF101311),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                    hintText: "Search by name or phone",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Filter Chips: All (348), Regular, New, Inactive
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(0, "All (348)"),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, "Regular"),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, "New"),
                  const SizedBox(width: 8),
                  _buildFilterChip(3, "Inactive"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer List
            Expanded(
              child: ListenableBuilder(
                listenable: widget.appState,
                builder: (context, _) {
                  final upcomingBirthdays = widget.appState.visibleCustomers
                      .where((c) => c.hasUpcomingBirthday)
                      .toList()
                    ..sort((a, b) => (a.daysUntilBirthday ?? 99).compareTo(b.daysUntilBirthday ?? 99));

                  final filtered = widget.appState.visibleCustomers.where((c) {
                    final matchesQuery = c.name.toLowerCase().contains(_searchQuery) || c.phone.contains(_searchQuery);
                    if (!matchesQuery) return false;
                    if (_selectedFilterIndex == 1) return c.tag == "Regular";
                    if (_selectedFilterIndex == 2) return c.tag == "New";
                    if (_selectedFilterIndex == 3) return c.tag == "Inactive";
                    return true;
                  }).toList()
                    ..sort((a, b) {
                      if (a.hasUpcomingBirthday && !b.hasUpcomingBirthday) return -1;
                      if (!a.hasUpcomingBirthday && b.hasUpcomingBirthday) return 1;
                      if (a.hasUpcomingBirthday && b.hasUpcomingBirthday) {
                        return (a.daysUntilBirthday ?? 99).compareTo(b.daysUntilBirthday ?? 99);
                      }
                      return 0;
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filtered.length + (upcomingBirthdays.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (upcomingBirthdays.isNotEmpty && index == 0) {
                        return _buildUpcomingBirthdaysBanner(upcomingBirthdays);
                      }
                      final custIndex = upcomingBirthdays.isNotEmpty ? index - 1 : index;
                      final customer = filtered[custIndex];
                      return _buildCustomerCard(customer);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        elevation: 4,
        onPressed: _showAddCustomerDialog,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF101311),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
          ),
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

  Future<void> _launchCustomerWhatsApp(Customer customer, {String? customMessage}) async {
    final digits = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid phone number for this customer")),
      );
      return;
    }
    final phoneParam = digits.length == 10 ? '91$digits' : digits;
    final msg = customMessage ??
        "Hello ${customer.name}, greetings from ${widget.appState.salonName}!";
    final uri = Uri.parse("https://wa.me/$phoneParam?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildUpcomingBirthdaysBanner(List<Customer> birthdayCustomers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.18),
            const Color(0xFF141815),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text("🎂", style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Upcoming Birthdays (< 7 Days)",
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...birthdayCustomers.map((bCust) {
            final days = bCust.daysUntilBirthday ?? 0;
            final whenLabel = days == 0 ? "Today!" : (days == 1 ? "Tomorrow" : "In $days days");
            final offerMsg = days == 0
                ? "Happy Birthday ${bCust.name}! 🎂 Celebrate your special day with an exclusive Birthday Offer at ${widget.appState.salonName} ✨"
                : "Happy Birthday in advance ${bCust.name}! 🎂 Celebrate your birthday week with a special offer at ${widget.appState.salonName} ✨";
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${bCust.name} • $whenLabel",
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _launchCustomerWhatsApp(bCust, customMessage: offerMsg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_rounded, color: Colors.black, size: 12),
                          SizedBox(width: 4),
                          Text("Send Offer", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final isBdaySoon = customer.hasUpcomingBirthday;
    final days = customer.daysUntilBirthday;

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
          border: Border.all(
            color: isBdaySoon
                ? const Color(0xFFF59E0B).withOpacity(0.55)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            CustomerAvatarWidget(
              name: customer.name,
              radius: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: TextStyle(
                            color: isBdaySoon ? const Color(0xFFFBBF24) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBdaySoon && days != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            days == 0 ? "🎂 Today!" : "🎂 ${days}d",
                            style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phone,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "Visits: ${customer.visitsCount}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _launchCustomerWhatsApp(
                customer,
                customMessage: isBdaySoon
                    ? "Happy Birthday ${days == 0 ? '' : 'in advance '}${customer.name}! 🎂 Enjoy a special Birthday Offer at ${widget.appState.salonName} ✨"
                    : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4)),
                ),
                child: const Icon(Icons.chat_rounded, color: Color(0xFF22C55E), size: 16),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
