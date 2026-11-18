import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruvexi_mobile/core/network/api_config.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/shared/widgets/customer_avatar.dart';

void showWhatsAppCampaignRunnerModal(BuildContext context, RuvexiAppState appState) {
  int runnerStep = 0; // 0: Config, 1: Active Runner, 2: Done
  String targetAudience = "all"; // all, vip, inactive
  int currentIndex = 0;
  int sentCount = 0;
  int skippedCount = 0;

  final templateCtrl = TextEditingController(
    text: "Dear {name}, we miss seeing you at {salon}! ✨ Special privilege offer for your next visit. Book: {booking_link}",
  );

  Widget buildFilterPill({required String label, required bool isSelected, required VoidCallback onTap}) {
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

  Widget buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: const Color(0xFF141815),
      side: BorderSide(color: Colors.white.withOpacity(0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: onTap,
    );
  }

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
        final salonName = appState.salonName;
        final bookingUrl = "${RuvexiApiConfig.webAppUrl}/book";

        final targetList = appState.customers.where((c) {
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
                              "100% Free • Direct WhatsApp",
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
                  Text("Select Audience:", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      buildFilterPill(
                        label: "All (${appState.customers.length})",
                        isSelected: targetAudience == "all",
                        onTap: () => setSheetState(() => targetAudience = "all"),
                      ),
                      const SizedBox(width: 8),
                      buildFilterPill(
                        label: "VIP Tier",
                        isSelected: targetAudience == "vip",
                        onTap: () => setSheetState(() => targetAudience = "vip"),
                      ),
                      const SizedBox(width: 8),
                      buildFilterPill(
                        label: "1-Visit Clients",
                        isSelected: targetAudience == "inactive",
                        onTap: () => setSheetState(() => targetAudience = "inactive"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text("Quick Templates:", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildPresetChip("✨ 20% Off", () {
                          templateCtrl.text = "Dear {name}, we miss seeing you at {salon}! ✨ Special 20% off on your next visit. Book: {booking_link}";
                          setSheetState(() {});
                        }),
                        const SizedBox(width: 6),
                        buildPresetChip("💆 Hair Spa Glow", () {
                          templateCtrl.text = "Hi {name}! Treat yourself this weekend at {salon} with our premium Hair Spa & Aesthetics. Reserve: {booking_link}";
                          setSheetState(() {});
                        }),
                        const SizedBox(width: 6),
                        buildPresetChip("🎉 Festive Offer", () {
                          templateCtrl.text = "Festival greetings from {salon}! 🌟 Celebrate with our exclusive festive makeover packages, {name}. Book: {booking_link}";
                          setSheetState(() {});
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

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
