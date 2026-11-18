import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';

void showImportClientsModal(BuildContext context, RuvexiAppState appState) {
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
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
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
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

                // Strategy selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141815),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "If phone already exists:",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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

                              final res = await appState.importCustomers(
                                customersToImport,
                                duplicateStrategy: duplicateStrategy,
                              );

                              if (!ctx.mounted) return;
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
                              if (!ctx.mounted) return;
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
