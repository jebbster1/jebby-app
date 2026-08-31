import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../view_model/reservation_view_model.dart';
import '../screens/reservations/reservation_detail_screen.dart';

class ReservationActionCard extends StatefulWidget {
  const ReservationActionCard({super.key});

  @override
  State<ReservationActionCard> createState() => _ReservationActionCardState();
}

class _ReservationActionCardState extends State<ReservationActionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationViewModel>().loadActionRequired();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservationViewModel>(
      builder: (context, vm, _) {
        if (vm.actionItems.isEmpty) return const SizedBox.shrink();
        final item = vm.actionItems.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Get.to(() => ReservationDetailScreen(orderId: item.orderId)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_outlined, color: Color(0xFFF6AE02)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Action required',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.nextAction.label,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
