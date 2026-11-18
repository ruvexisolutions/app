import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/features/staff_portal/screens/in_salon_screen.dart';

class FrontDeskScreen extends StatelessWidget {
  final RuvexiAppState appState;

  const FrontDeskScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return InSalonScreen(appState: appState);
  }
}
