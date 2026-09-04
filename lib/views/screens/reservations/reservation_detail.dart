import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/reservation.dart';
import '../../../constants/app_url.dart';
import '../../../constants/color.dart';
import '../../../utils/inspection_roles.dart';
import '../../../utils/order_status.dart';
import '../../../utils/api_datetime.dart';
import '../../../utils/profile_image.dart';
import '../../../utils/rental_date.dart';
import '../../../view_models/reservation_view_model.dart';
import 'inspection_flow.dart';
import 'report_issue.dart';
import 'reservation_flow_theme.dart';
import '../profile/user_profile.dart';

const _titleDark = Color(0xFF1A1A1A);
const _labelGrey = Color(0xFF6B7280);
const _cardBorder = Color(0xFFE8E8EC);

TextStyle _titleStyle({double size = 16}) {
  return GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: size, color: _titleDark);
}

TextStyle _bodyStyle({double size = 14}) {
  return GoogleFonts.inter(fontSize: size, color: _labelGrey);
}

TextStyle _valueStyle({double size = 14}) {
  return GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w500, color: _titleDark);
}

ButtonStyle _primaryButton({double height = 48}) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
    disabledBackgroundColor: Colors.grey.shade300,
    disabledForegroundColor: Colors.grey.shade600,
    elevation: 0,
    minimumSize: Size.fromHeight(height),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
  );
}

ButtonStyle _secondaryButton(Color accent, {double height = 48}) {
  return OutlinedButton.styleFrom(
    foregroundColor: accent,
    disabledForegroundColor: accent.withValues(alpha: 0.55),
    side: BorderSide(color: accent),
    disabledBackgroundColor: Colors.transparent,
    minimumSize: Size.fromHeight(height),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _cardBorder),
  );
}

bool _isHandoffTraveler(Reservation reservation) {
  return reservation.canUpdateHandoff ||
      OrderStatus.canUpdateHandoffStatus(
        transportType: reservation.transportType,
        role: reservation.role,
      );
}

String _handoffArrivedConfirmMessage(Reservation reservation) {
  final role = reservation.role?.trim().toLowerCase();
  if (role == 'earner') return 'Are you sure you have found the renter?';
  if (role == 'renter') return 'Are you sure you have found the earner?';
  return 'Are you sure you are at the location with the other party?';
}

Future<void> _confirmHandoffArrival(
  BuildContext context,
  Reservation reservation,
  ReservationViewModel vm, {
  VoidCallback? onStart,
  VoidCallback? onEnd,
}) async {
  final phase = OrderStatus.handoffPhaseForOrder(
    reservation.orderStatus,
    handoffPhase: reservation.handoffPhase,
  );
  final theme = ReservationFlowTheme(phase);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Confirm arrival', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
      content: Text(
        _handoffArrivedConfirmMessage(reservation),
        style: GoogleFonts.inter(fontSize: 14, color: _labelGrey, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _labelGrey),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text("Yes, I'm here", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: theme.accent)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  onStart?.call();
  await vm.markArrived(reservation.id);
  if (context.mounted) onEnd?.call();
}

Widget _summaryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: _bodyStyle(size: 13))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: _valueStyle(size: 13)),
        ),
      ],
    ),
  );
}

String _formatMoney(num? value) {
  if (value == null) return '—';
  final amount = value.toDouble();
  if (amount == amount.roundToDouble()) {
    return '\$${amount.toStringAsFixed(0)}';
  }
  return '\$${amount.toStringAsFixed(2)}';
}

String _reservationPriceLabel(Reservation reservation) {
  return _formatMoney(reservation.paymentAmountDue ?? reservation.totalPrice);
}

String _depositStatusMessage(Reservation reservation) {
  final status = reservation.depositRefundStatus?.trim().toLowerCase() ?? 'pending';
  switch (status) {
    case 'refunded':
      final when = formatApiDate(reservation.depositRefundedAt, pattern: 'M/d/yyyy');
      return when.isEmpty
          ? 'Refunded to your original payment method.'
          : 'Refunded to your original payment method on $when.';
    case 'withheld':
      return 'Held while a reported issue is reviewed.';
    case 'failed':
      return 'Refund is processing. We will retry automatically.';
    case 'skipped':
      return '';
    default:
      if (reservation.orderStatus == 'DISPUTE_WINDOW_24H') {
        return 'Held until the dispute window ends, then refunded if no issue is filed.';
      }
      if (OrderStatus.isTerminal(reservation.orderStatus)) {
        return 'Refund to your original payment method is processing.';
      }
      return 'Held until the return is complete, then refunded if no issue is reported.';
  }
}

Widget _statusBadge(String label, {String? orderStatus}) {
  final normalized = OrderStatus.normalize(orderStatus);
  final Color bg;
  final Color fg;
  if (OrderStatus.isCompleted(normalized)) {
    bg = const Color(0xFFE8F5E9);
    fg = const Color(0xFF2E7D32);
  } else if (OrderStatus.isTerminal(normalized)) {
    bg = const Color(0xFFF5F5F5);
    fg = const Color(0xFF616161);
  } else {
    bg = AppColors.primaryColor.withValues(alpha: 0.12);
    fg = AppColors.primaryColor;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    ),
  );
}

class ReservationDetailScreen extends StatefulWidget {
  final int orderId;

  const ReservationDetailScreen({super.key, required this.orderId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ReservationViewModel>();
      await vm.loadReservation(widget.orderId);
      _prefetchTrustIfNeeded(vm);
    });
  }

  void _prefetchTrustIfNeeded(ReservationViewModel vm) {
    final reservation = vm.reservation;
    if (reservation == null || OrderStatus.isTerminal(reservation.orderStatus)) return;
    final phase = _inspectionPhaseFor(reservation);
    if (phase == null) return;
    final status = OrderStatus.normalize(reservation.orderStatus);
    final handoffReady = OrderStatus.handoffReadyForInspection(
      orderStatus: reservation.orderStatus,
      handoffStatus: reservation.handoffStatus,
      phase: phase,
    );
    final needsTrust = handoffReady ||
        status == OrderStatus.pickupInProgress ||
        status == OrderStatus.returnInProgress ||
        status == OrderStatus.waitingPickupConfirmation ||
        status == OrderStatus.waitingReturnConfirmation;
    if (needsTrust) {
      vm.prefetchTrust(widget.orderId, phase: phase);
    }
  }

  String? _inspectionPhaseFor(Reservation reservation) {
    final action = reservation.nextAction.type;
    if (action.contains('return') || reservation.orderStatus.contains('RETURN')) {
      return 'return';
    }
    if (action.contains('inspection') ||
        action.startsWith('handoff') ||
        reservation.orderStatus.contains('PICKUP') ||
        reservation.orderStatus == 'SCHEDULED_HANDOFF' ||
        reservation.orderStatus == 'PAYMENT_CONFIRMED') {
      return 'pickup';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          borderRadius: BorderRadius.circular(50),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        ),
        title: Text(
          'Reservation',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
        ),
      ),
      body: Consumer<ReservationViewModel>(
        builder: (context, vm, _) {
          if (vm.loading && vm.reservation == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
          }
          final reservation = vm.reservation;
          if (reservation == null) {
            return Center(
              child: Text(vm.error ?? 'Reservation unavailable', style: _bodyStyle()),
            );
          }
          final terminal = OrderStatus.isTerminal(reservation.orderStatus);
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryColor,
                  onRefresh: () async {
                    await vm.loadReservation(widget.orderId);
                    if (!OrderStatus.isTerminal(vm.reservation?.orderStatus)) {
                      _prefetchTrustIfNeeded(vm);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _ReservationHeroCard(reservation: reservation),
                      if (reservation.role == 'renter' &&
                          (reservation.securityDeposit ?? 0) > 0 &&
                          _depositStatusMessage(reservation).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DepositStatusCard(reservation: reservation),
                      ],
                      if (terminal) ...[
                        const SizedBox(height: 12),
                        _TerminalStatusCard(reservation: reservation),
                      ] else ...[
                        const SizedBox(height: 12),
                        _HandoffInfoCard(reservation: reservation),
                        if (OrderStatus.showHandoffActionsOnReservation(
                          orderStatus: reservation.orderStatus,
                          handoffStatus: reservation.handoffStatus,
                          transportType: reservation.transportType,
                          role: reservation.role,
                          canUpdateHandoff: reservation.canUpdateHandoff,
                        )) ...[
                          const SizedBox(height: 12),
                          _HandoffActionsCard(reservation: reservation),
                        ] else if (OrderStatus.showHandoffWaitingOnReservation(
                          orderStatus: reservation.orderStatus,
                          handoffStatus: reservation.handoffStatus,
                          transportType: reservation.transportType,
                          role: reservation.role,
                          canUpdateHandoff: reservation.canUpdateHandoff,
                        )) ...[
                          const SizedBox(height: 12),
                          _HandoffWaitingCard(reservation: reservation),
                        ],
                        if (_showTrustModule(reservation)) ...[
                          const SizedBox(height: 12),
                          _TrustInfoCard(reservation: reservation),
                        ],
                        if (_needsInlineAction(reservation)) ...[
                          const SizedBox(height: 12),
                          _PrimaryAction(reservation: reservation, vm: vm),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (!terminal)
                _ReservationBottomBar(
                  reservation: reservation,
                  vm: vm,
                  orderId: widget.orderId,
                ),
            ],
          );
        },
      ),
    );
  }

  bool _needsInlineAction(Reservation reservation) {
    final action = reservation.nextAction.type;
    return action == 'wait_acceptance' || action == 'wait_payment';
  }

  bool _showTrustModule(Reservation reservation) {
    if (OrderStatus.isTerminal(reservation.orderStatus)) return false;
    const hiddenActions = {
      'pay',
      'wait_payment',
      'wait_acceptance',
      'accept_booking',
      'active_rental',
    };
    return !hiddenActions.contains(reservation.nextAction.type);
  }
}

class _TerminalStatusCard extends StatelessWidget {
  final Reservation reservation;
  const _TerminalStatusCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final message = OrderStatus.terminalStatusMessage(reservation.orderStatus);
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Text(message, style: _bodyStyle()),
    );
  }
}

class _ReservationHeroCard extends StatelessWidget {
  final Reservation reservation;
  const _ReservationHeroCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final imageUrl = reservationImageUrl(reservation.productImage);
    final dateRange =
        '${formatRentalDateForDisplay(reservation.rentalStartDate)} – ${formatRentalDateForDisplay(reservation.rentalEndDate)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reservation Details', style: _titleStyle(size: 18)),
          const SizedBox(height: 4),
          Text(
            '#${reservation.id}',
            style: GoogleFonts.inter(fontSize: 13, color: _labelGrey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imageUrl.isEmpty
                      ? ColoredBox(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: const Color(0xFFF5F5F5),
                            child: Icon(Icons.chair_outlined, color: Colors.grey.shade500),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.productName ?? 'Reservation',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _titleDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _reservationPriceLabel(reservation),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _titleDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dateRange, style: _bodyStyle(size: 13)),
                    const SizedBox(height: 8),
                    _statusBadge(
                      OrderStatus.renterBadgeLabel(reservation.orderStatus),
                      orderStatus: reservation.orderStatus,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: _cardBorder.withValues(alpha: 0.9), height: 1),
          const SizedBox(height: 16),
          _CounterpartyRow(reservation: reservation),
        ],
      ),
    );
  }
}

class _CounterpartyRow extends StatelessWidget {
  final Reservation reservation;
  const _CounterpartyRow({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final label = reservation.counterpartyLabel?.trim().isNotEmpty == true
        ? reservation.counterpartyLabel!
        : (reservation.role == 'earner' ? 'Renter' : 'Provider');
    final name = reservation.counterpartyName?.trim().isNotEmpty == true
        ? reservation.counterpartyName!.trim()
        : label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(
            () => UserProfileScreen(
              vendorID: reservation.counterpartyId.toString(),
              vendorName: name,
              vendorImage: reservation.counterpartyImage,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              ProfileImage.circularAvatar(
                radius: 24,
                baseUrl: AppUrl.baseUrlM,
                imagePath: reservation.counterpartyImage,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(fontSize: 12, color: _labelGrey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _titleDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepositStatusCard extends StatelessWidget {
  final Reservation reservation;
  const _DepositStatusCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final message = _depositStatusMessage(reservation);
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security deposit', style: _titleStyle()),
          const SizedBox(height: 8),
          Text(
            _formatMoney(reservation.securityDeposit),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _titleDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, style: _bodyStyle()),
        ],
      ),
    );
  }
}

class _HandoffInfoCard extends StatelessWidget {
  final Reservation reservation;
  const _HandoffInfoCard({required this.reservation});

  bool get _isReturnPhase {
    return OrderStatus.handoffPhaseForOrder(
          reservation.orderStatus,
          handoffPhase: reservation.handoffPhase,
        ) ==
        'return';
  }

  static String _transportLabel(String? type) {
    if (type == 'delivery') return 'Delivery & Retrieval';
    return 'Pickup & Return';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ReservationFlowTheme(_isReturnPhase ? 'return' : 'pickup');
    final address = reservation.addressRevealed
        ? (reservation.location?.trim().isNotEmpty == true ? reservation.location! : '—')
        : 'Address hidden until payment is confirmed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(theme.handoffInfoTitle, style: _titleStyle()),
          const SizedBox(height: 12),
          _summaryRow('Method', _transportLabel(reservation.transportType)),
          if (!_isReturnPhase && reservation.pickupWindowBegin != null)
            _summaryRow(
              'Date & time',
              formatHandoffWindowRange(reservation.pickupWindowBegin, reservation.pickupWindowEnd),
            ),
          if (_isReturnPhase && reservation.returnWindowBegin != null)
            _summaryRow(
              'Date & time',
              formatHandoffWindowRange(reservation.returnWindowBegin, reservation.returnWindowEnd),
            ),
          _summaryRow('Address', address),
        ],
      ),
    );
  }
}

class _HandoffWaitingCard extends StatelessWidget {
  final Reservation reservation;
  const _HandoffWaitingCard({required this.reservation});

  String get _phase => OrderStatus.handoffPhaseForOrder(
        reservation.orderStatus,
        handoffPhase: reservation.handoffPhase,
      );

  @override
  Widget build(BuildContext context) {
    final theme = ReservationFlowTheme(_phase);
    final status = reservation.handoffStatus;
    final message = OrderStatus.handoffWaitingStatusMessage(
      transportType: reservation.transportType,
      handoffStatus: status,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Arrival Status', style: _titleStyle()),
          const SizedBox(height: 12),
          Text(
            OrderStatus.handoffStatusLabel(status),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.accent,
            ),
          ),
          if (status == 'ON_THE_WAY' && reservation.handoffEtaMinutes != null) ...[
            const SizedBox(height: 4),
            Text(
              'ETA: ${reservation.handoffEtaMinutes} minutes',
              style: _valueStyle(size: 13),
            ),
          ],
          const SizedBox(height: 8),
          Text(message, style: _bodyStyle(size: 13)),
        ],
      ),
    );
  }
}

class _HandoffActionsCard extends StatefulWidget {
  final Reservation reservation;
  const _HandoffActionsCard({required this.reservation});

  @override
  State<_HandoffActionsCard> createState() => _HandoffActionsCardState();
}

class _HandoffActionsCardState extends State<_HandoffActionsCard> {
  bool _busy = false;

  Reservation get reservation => widget.reservation;

  String get _phase => OrderStatus.handoffPhaseForOrder(
        reservation.orderStatus,
        handoffPhase: reservation.handoffPhase,
      );

  ReservationFlowTheme get _theme => ReservationFlowTheme(_phase);

  String get _locationPrompt {
    if (_phase == 'return') {
      return 'Please go to the return location.';
    }
    return OrderStatus.isDeliveryTransport(reservation.transportType)
        ? 'Please go to the delivery location.'
        : 'Please go to the pickup location.';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReservationViewModel>();
    final status = reservation.handoffStatus;
    final isDelayed = status == 'DELAYED';
    final address = reservation.addressRevealed
        ? (reservation.location?.trim().isNotEmpty == true ? reservation.location! : '—')
        : 'Address hidden until payment is confirmed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_theme.arrivalTitle, style: _titleStyle()),
          const SizedBox(height: 8),
          Text(_locationPrompt, style: _bodyStyle(size: 13)),
          const SizedBox(height: 12),
          Text(
            OrderStatus.handoffStatusLabel(status),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _theme.accent,
            ),
          ),
          if (reservation.handoffEtaMinutes != null && status == 'ON_THE_WAY') ...[
            const SizedBox(height: 4),
            Text(
              'ETA: ${reservation.handoffEtaMinutes} minutes',
              style: _valueStyle(size: 13),
            ),
          ],
          const SizedBox(height: 12),
          Text(address, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _titleDark)),
          if (reservation.addressRevealed) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: _theme.accent,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _openDirections(address),
              icon: const Icon(Icons.near_me_outlined, size: 18),
              label: const Text('Get directions'),
            ),
          ],
          if (!isDelayed && status != 'ARRIVED') ...[
            const SizedBox(height: 16),
            if (status != 'ON_THE_WAY')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: _secondaryButton(_theme.accent),
                  onPressed: _busy ? null : () => _showEtaPicker(vm),
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _theme.accent.withValues(alpha: 0.55),
                          ),
                        )
                      : const Text("I'm On My Way"),
                ),
              ),
          ],
          if (isDelayed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: _secondaryButton(_theme.accent),
                onPressed: () => Get.to(
                  () => ReportIssueScreen(orderId: reservation.id, phase: _phase),
                ),
                child: const Text('Report a problem'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDirections(String address) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showEtaPicker(ReservationViewModel vm) async {
    const options = [15, 30, 45, 60];
    final eta = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Estimated arrival', style: _titleStyle(size: 15)),
              ),
              ...options.map(
                (minutes) => ListTile(
                  title: Text('$minutes minutes', style: GoogleFonts.inter(fontSize: 15)),
                  trailing: Icon(Icons.chevron_right, color: _theme.accent, size: 20),
                  onTap: () => Navigator.pop(context, minutes),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (eta != null && mounted) {
      setState(() => _busy = true);
      await vm.markOnTheWay(reservation.id, eta);
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _HandoffArrivalButton extends StatefulWidget {
  final Reservation reservation;
  final ReservationViewModel vm;
  final double height;

  const _HandoffArrivalButton({
    required this.reservation,
    required this.vm,
    this.height = 52,
  });

  @override
  State<_HandoffArrivalButton> createState() => _HandoffArrivalButtonState();
}

class _HandoffArrivalButtonState extends State<_HandoffArrivalButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final phase = OrderStatus.handoffPhaseForOrder(
      widget.reservation.orderStatus,
      handoffPhase: widget.reservation.handoffPhase,
    );
    final theme = ReservationFlowTheme(phase);

    return FilledButton(
      style: theme.primaryButton(height: widget.height),
      onPressed: _busy
          ? null
          : () => _confirmHandoffArrival(
                context,
                widget.reservation,
                widget.vm,
                onStart: () => setState(() => _busy = true),
                onEnd: () => setState(() => _busy = false),
              ),
      child: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(theme.arrivalButtonLabel),
    );
  }
}

class _TrustInfoCard extends StatelessWidget {
  final Reservation reservation;
  const _TrustInfoCard({required this.reservation});

  bool get _isReturnPhase => reservation.nextAction.type.contains('return');

  @override
  Widget build(BuildContext context) {
    final theme = ReservationFlowTheme(_isReturnPhase ? 'return' : 'pickup');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: theme.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trust & Security', style: _titleStyle()),
                const SizedBox(height: 6),
                    Text(
                      _isReturnPhase
                          ? (InspectionRoles.isInitiator('return', reservation.role)
                              ? 'You will complete the return inspection. The renter will review and confirm.'
                              : 'The provider will complete the return inspection. You will review and confirm.')
                          : InspectionRoles.isInitiator('pickup', reservation.role)
                          ? 'You will complete the pickup inspection. The provider will review and confirm.'
                          : 'The renter will complete the pickup inspection. You will review and confirm.',
                      style: GoogleFonts.inter(fontSize: 13, color: _labelGrey, height: 1.4),
                    ),
                const SizedBox(height: 6),
                Text(
                  'Learn more about safety.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationBottomBar extends StatelessWidget {
  final Reservation reservation;
  final ReservationViewModel vm;
  final int orderId;

  const _ReservationBottomBar({
    required this.reservation,
    required this.vm,
    required this.orderId,
  });

  String? _inspectionPhase() {
    final action = reservation.nextAction.type;
    if (action.contains('return') || reservation.orderStatus.contains('RETURN')) {
      return 'return';
    }
    if (action.contains('inspection') ||
        action.startsWith('handoff') ||
        reservation.orderStatus.contains('PICKUP') ||
        reservation.orderStatus == 'SCHEDULED_HANDOFF' ||
        reservation.orderStatus == 'PAYMENT_CONFIRMED') {
      return 'pickup';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final action = reservation.nextAction.type;
    final phase = _inspectionPhase();
    final theme = ReservationFlowTheme(phase ?? 'pickup');

    Widget? child;
    if (action == 'accept_booking') {
      final accepting = vm.bookingActionLoading == 'accept';
      final declining = vm.bookingActionLoading == 'decline';
      final busy = vm.bookingActionLoading != null;
      child = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: _secondaryButton(Colors.red.shade700, height: 52),
              onPressed: busy
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('Decline booking?', style: _titleStyle()),
                          content: Text(
                            'Decline this rental request? The renter will be notified.',
                            style: _bodyStyle(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: const Text('Decline'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final ok = await vm.declineOrder(
                        reservation.id,
                        reason: 'Order declined',
                      );
                      if (ok && context.mounted) {
                        Get.back(result: true);
                      }
                    },
              child: declining
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade700,
                      ),
                    )
                  : const Text('Decline'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              style: _primaryButton(height: 52),
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await vm.acceptOrder(reservation.id);
                      if (ok && context.mounted) {
                        await vm.loadReservation(reservation.id);
                      }
                    },
              child: accepting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Accept booking'),
            ),
          ),
        ],
      );
    } else if (action == 'pay') {
      child = FilledButton(
        style: _primaryButton(height: 52),
        onPressed: vm.paymentLoading ? null : () => vm.payForAcceptedOrder(reservation),
        child: vm.paymentLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                reservation.paymentAmountDue == null
                    ? 'Complete payment'
                    : 'Complete payment · \$${reservation.paymentAmountDue}',
                textAlign: TextAlign.center,
              ),
      );
    } else if (phase != null &&
        (action.startsWith('inspection') ||
            action.startsWith('handoff') ||
            reservation.orderStatus == 'PICKUP_IN_PROGRESS' ||
            reservation.orderStatus == 'RETURN_IN_PROGRESS' ||
            reservation.orderStatus == 'WAITING_PICKUP_CONFIRMATION' ||
            reservation.orderStatus == 'WAITING_RETURN_CONFIRMATION')) {
      final isInitiator = InspectionRoles.isInitiator(phase, reservation.role);
      final handoffReady = OrderStatus.handoffReadyForInspection(
        orderStatus: reservation.orderStatus,
        handoffStatus: reservation.handoffStatus,
        phase: phase,
      );
      final isTraveler = _isHandoffTraveler(reservation);
      final arrivalAvailable = OrderStatus.showHandoffActionsOnReservation(
            orderStatus: reservation.orderStatus,
            handoffStatus: reservation.handoffStatus,
            transportType: reservation.transportType,
            role: reservation.role,
            canUpdateHandoff: reservation.canUpdateHandoff,
          ) &&
          reservation.handoffStatus != 'DELAYED';
      final showTravelerArrivalInBottom =
          isTraveler && !isInitiator && !handoffReady && arrivalAvailable;
      final showInitiatorArrivalInBottom = isInitiator &&
          !handoffReady &&
          arrivalAvailable &&
          reservation.handoffStatus != 'DELAYED';
      final showArrivalInBottom = showTravelerArrivalInBottom || showInitiatorArrivalInBottom;
      final canOpenInspection = handoffReady;
      final showContinueInspection = OrderStatus.showContinueInspectionLabel(
        orderStatus: reservation.orderStatus,
        hasStartedInspection: vm.trustStatus?.inspection != null,
      );
      if (showArrivalInBottom) {
        child = _HandoffArrivalButton(reservation: reservation, vm: vm, height: 52);
      } else {
        final label = isInitiator
            ? (showContinueInspection ? theme.continueInspectionLabel : theme.beginInspectionLabel)
            : theme.reviewConfirmLabel;
        child = FilledButton(
          style: theme.primaryButton(height: 52),
          onPressed: canOpenInspection
              ? () => Get.to(() => InspectionFlowScreen(orderId: orderId, phase: phase))
              : null,
          child: Text(label),
        );
      }
    } else if (OrderStatus.canReportIssueOrNoShow(reservation.orderStatus) &&
        reservation.openDispute == null) {
      child = OutlinedButton(
        style: _secondaryButton(AppColors.primaryColor, height: 48),
        onPressed: () => Get.to(() => ReportIssueScreen(orderId: orderId)),
        child: const Text('Report issue or no-show'),
      );
    }

    if (child == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(top: BorderSide(color: _cardBorder.withValues(alpha: 0.8))),
        ),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final Reservation reservation;
  final ReservationViewModel vm;
  const _PrimaryAction({required this.reservation, required this.vm});

  @override
  Widget build(BuildContext context) {
    final action = reservation.nextAction.type;
    if (action == 'wait_acceptance' || action == 'wait_payment') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Text(
          reservation.nextAction.label,
          textAlign: TextAlign.center,
          style: _bodyStyle(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
