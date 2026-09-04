import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/inspection.dart';
import '../../../models/reservation.dart';
import '../../../constants/app_url.dart';
import '../../../constants/color.dart';
import '../../../utils/api_headers.dart';
import '../../../utils/inspection_roles.dart';
import '../../../utils/order_status.dart';
import '../../../utils/profile_image.dart';
import '../../../utils/api_datetime.dart';
import '../../../utils/rental_date.dart';
import '../../../utils/show_snackbar.dart';
import '../../../view_models/reservation_view_model.dart';
import '../../../view_models/user_view_model.dart';
import 'report_issue.dart';
import 'reservation_flow_theme.dart';

enum _FlowStep { inspect, review, confirm, waiting, waitingForInitiator, success }

class InspectionFlowScreen extends StatefulWidget {
  final int orderId;
  final String phase;

  const InspectionFlowScreen({super.key, required this.orderId, required this.phase});

  @override
  State<InspectionFlowScreen> createState() => _InspectionFlowScreenState();
}

class _InspectionFlowScreenState extends State<InspectionFlowScreen> {
  static const _titleDark = Color(0xFF1A1A1A);
  static const _labelGrey = Color(0xFF6B7280);
  static const _cardBorder = Color(0xFFE8E8EC);
  static const _maxInspectionPhotos = 3;

  late ReservationFlowTheme _theme;
  _FlowStep _step = _FlowStep.inspect;
  bool _ready = false;
  final List<File> _pendingPhotos = [];
  final Map<String, bool> _checked = {};
  bool _busy = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _theme = ReservationFlowTheme(widget.phase);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final vm = context.read<ReservationViewModel>();
    if (vm.reservation?.id != widget.orderId) {
      await vm.loadReservation(widget.orderId);
    }
    if (!mounted) return;
    await vm.prefetchTrust(widget.orderId, phase: widget.phase);
    if (!mounted) return;
    final role = vm.reservation?.role ?? vm.trustStatus?.role;
    final reservationAfterTrust = vm.reservation;
    if (reservationAfterTrust != null &&
        !OrderStatus.handoffReadyForInspection(
          orderStatus: reservationAfterTrust.orderStatus,
          handoffStatus: reservationAfterTrust.handoffStatus,
          phase: widget.phase,
        ) &&
        vm.trustStatus?.inspection == null) {
      final message = InspectionRoles.isInitiator(widget.phase, role)
          ? 'Confirm arrival on the reservation screen first.'
          : OrderStatus.handoffWaitingMessage(transportType: reservationAfterTrust.transportType);
      showAppErrorSnackbar(message);
      if (mounted) Get.back();
      return;
    }
    var step = _resolveStep(vm.trustStatus, role);
    if (step == _FlowStep.inspect &&
        vm.trustStatus?.inspection == null &&
        InspectionRoles.isInitiator(widget.phase, role)) {
      await vm.startInspection(widget.orderId, widget.phase);
      await vm.prefetchTrust(widget.orderId, phase: widget.phase);
      step = _resolveStep(vm.trustStatus, role);
    } else if (step == _FlowStep.review) {
      await vm.prefetchTrust(widget.orderId, phase: widget.phase);
    }
    if (!mounted) return;
    _seedChecklist(vm.trustStatus);
    setState(() {
      _step = step;
      _ready = true;
    });
  }

  int _photoCount() => _pendingPhotos.length;

  bool get _canAddPhoto => _photoCount() < _maxInspectionPhotos;

  bool _checklistSubmitted(TrustStatus? trust) {
    if (trust == null || trust.inspection == null || trust.checklistTemplate.isEmpty) {
      return false;
    }
    return trust.checklistTemplate.every(
      (item) => trust.responses.any((r) => r.itemKey == item.key && r.response == 'yes'),
    );
  }

  _FlowStep _resolveStep(TrustStatus? trust, String? role) {
    if (trust?.bothConfirmed == true) return _FlowStep.success;
    if (trust?.myConfirmation != null && trust?.otherConfirmation == null) {
      return _FlowStep.waiting;
    }

    final initiator = InspectionRoles.isInitiator(widget.phase, role);

    if (!initiator) {
      if (trust?.inspection == null || !_checklistSubmitted(trust)) {
        return _FlowStep.waitingForInitiator;
      }
      if (trust?.otherConfirmation?.isConfirmed != true) {
        return _FlowStep.waitingForInitiator;
      }
      if (trust?.myConfirmation == null) {
        return _FlowStep.review;
      }
      return _FlowStep.waiting;
    }

    if (trust?.inspection != null) {
      if (_checklistSubmitted(trust) && trust?.myConfirmation == null) {
        return _FlowStep.confirm;
      }
      return _FlowStep.inspect;
    }

    return _FlowStep.inspect;
  }

  void _seedChecklist(TrustStatus? trust) {
    if (trust == null) return;
    for (final item in trust.checklistTemplate) {
      OrderInspectionChecklistResponse? existing;
      for (final response in trust.responses) {
        if (response.itemKey == item.key) {
          existing = response;
          break;
        }
      }
      _checked[item.key] = existing?.response == 'yes';
    }
  }

  String _screenTitle() {
    if (!_ready) {
      return widget.phase == 'return' ? 'Return Inspection' : 'Pickup Inspection';
    }
    switch (_step) {
      case _FlowStep.inspect:
        return _theme.inspectTitle;
      case _FlowStep.review:
        return widget.phase == 'return' ? 'Review Return' : 'Review Pickup';
      case _FlowStep.confirm:
        return _theme.confirmTitle;
      case _FlowStep.waiting:
        return 'Waiting for Other Party';
      case _FlowStep.waitingForInitiator:
        return widget.phase == 'return' ? 'Return Inspection' : 'Pickup Inspection';
      case _FlowStep.success:
        return _theme.successTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _ready && _step == _FlowStep.success;
    const successBackground = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: isSuccess ? successBackground : Colors.grey.shade100,
      appBar: isSuccess
          ? null
          : AppBar(
              backgroundColor: Colors.grey.shade100,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              leading: InkWell(
                onTap: Get.back,
                borderRadius: BorderRadius.circular(50),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              ),
              title: Text(
                _screenTitle(),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
              ),
            ),
      body: Consumer<ReservationViewModel>(
        builder: (context, vm, _) {
          if (!_ready || (vm.reservation?.id != widget.orderId && vm.loading)) {
            return Center(child: CircularProgressIndicator(color: _theme.accent));
          }
          final reservation = vm.reservation;
          if (reservation == null) {
            return Center(
              child: Text(vm.error ?? 'Unable to load reservation', style: GoogleFonts.inter(color: _labelGrey)),
            );
          }
          return Column(
            children: [
              Expanded(child: _buildStepBody(context, vm, reservation)),
              if (_step != _FlowStep.waiting &&
                  _step != _FlowStep.waitingForInitiator &&
                  _step != _FlowStep.success)
                _buildBottomBar(context, vm, reservation),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepBody(BuildContext context, ReservationViewModel vm, Reservation reservation) {
    switch (_step) {
      case _FlowStep.inspect:
        return _inspectStep(vm, readOnly: false);
      case _FlowStep.review:
        return _inspectStep(vm, readOnly: true);
      case _FlowStep.confirm:
        return _confirmStep(reservation);
      case _FlowStep.waiting:
        return _waitingStep(vm, reservation);
      case _FlowStep.waitingForInitiator:
        return _waitingForInitiatorStep(vm);
      case _FlowStep.success:
        return _successStep(reservation, vm);
    }
  }

  Widget _waitingForInitiatorStep(ReservationViewModel vm) {
    final trust = vm.trustStatus;
    final checklistReady = trust != null && _checklistSubmitted(trust);
    final waitingForInitiatorConfirm =
        checklistReady && trust.otherConfirmation?.isConfirmed != true;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.hourglass_top, size: 48, color: _theme.accent),
        const SizedBox(height: 16),
        Text(
          waitingForInitiatorConfirm
              ? InspectionRoles.waitingForInitiatorConfirmationMessage(widget.phase)
              : InspectionRoles.waitingForInitiatorMessage(widget.phase),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: _titleDark, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          waitingForInitiatorConfirm
              ? 'You will be notified when you can review and confirm.'
              : 'You will be notified when the inspection is ready for your review.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: _labelGrey, height: 1.4),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: _theme.secondaryButton(),
            onPressed: () async {
              await vm.prefetchTrust(widget.orderId, phase: widget.phase);
              if (!mounted) return;
              final role = vm.reservation?.role ?? vm.trustStatus?.role;
              setState(() => _step = _resolveStep(vm.trustStatus, role));
              _seedChecklist(vm.trustStatus);
            },
            child: const Text('Refresh status'),
          ),
        ),
      ],
    );
  }

  Widget _inspectStep(ReservationViewModel vm, {required bool readOnly}) {
    final trust = vm.trustStatus;
    final items = trust?.checklistTemplate ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          readOnly
              ? InspectionRoles.reviewSubtitle(widget.phase)
              : 'Complete the checklist with the other party present, then continue.',
          style: GoogleFonts.inter(fontSize: 14, color: _labelGrey, height: 1.4),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _checklistTile(item, readOnly: readOnly)),
        if (readOnly) ...[
          if ((trust?.media ?? []).isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Inspection photos',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _titleDark),
            ),
            const SizedBox(height: 10),
            _SubmittedPhotoStrip(media: trust!.media),
          ],
        ] else ...[
          const SizedBox(height: 20),
          Text(
            'Add photos (optional, max $_maxInspectionPhotos)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _photoStrip(vm),
        ],
      ],
    );
  }

  Widget _checklistTile(InspectionChecklistItem item, {required bool readOnly}) {
    final checked = _checked[item.key] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: checked ? _theme.accent.withValues(alpha: 0.35) : _cardBorder),
      ),
      child: InkWell(
        onTap: readOnly ? null : () => setState(() => _checked[item.key] = !checked),
        child: Row(
          children: [
            Expanded(
              child: Text(item.label, style: GoogleFonts.inter(fontSize: 14, color: _titleDark, height: 1.35)),
            ),
            Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: checked ? _theme.accent : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoStrip(ReservationViewModel vm) {
    final canAdd = _canAddPhoto;
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._pendingPhotos.map(
            (file) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file, width: 88, height: 88, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: _busy ? null : () => setState(() => _pendingPhotos.remove(file)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canAdd)
            InkWell(
              onTap: _busy ? null : () => _pickPhoto(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: Icon(Icons.photo_camera_outlined, color: _theme.accent, size: 28),
              ),
            ),
        ],
      ),
    );
  }

  Widget _confirmStep(Reservation reservation) {
    final headline = widget.phase == 'return'
        ? 'Is the returned item in acceptable condition?'
        : 'Is the item in acceptable condition?';
    final body = widget.phase == 'return'
        ? 'The item was returned in the expected condition and the rental can be completed.'
        : 'The item matches the listing and is in acceptable condition for the rental to begin.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: _titleDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _waitingStep(ReservationViewModel vm, Reservation reservation) {
    final trust = vm.trustStatus;
    final myRole = trust?.role ?? reservation.role ?? 'renter';
    final myConfirmed = trust?.myConfirmation?.isConfirmed == true;
    final otherConfirmed = trust?.otherConfirmation?.isConfirmed == true;
    final user = context.watch<UserViewModel>();
    final isRenter = myRole == 'renter';
    final waitingOnRole = isRenter ? 'provider' : 'renter';
    final waitingHint = widget.phase == 'return'
        ? "You'll be notified when the $waitingOnRole confirms."
        : "You'll be notified when the $waitingOnRole confirms.";

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          widget.phase == 'return'
              ? 'Both parties must confirm to complete the rental.'
              : 'Both parties must confirm to start the rental.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _titleDark,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _partyProfileRow(
                roleLabel: 'Renter',
                subtitle: isRenter ? '(You)' : _partyName(reservation.counterpartyName, fallback: 'Renter'),
                imagePath: isRenter ? user.profileImage : reservation.counterpartyImage,
                confirmed: isRenter ? myConfirmed : otherConfirmed,
              ),
              Divider(height: 1, thickness: 1, color: _cardBorder.withValues(alpha: 0.9)),
              _partyProfileRow(
                roleLabel: 'Provider',
                subtitle: !isRenter ? '(You)' : _partyName(reservation.counterpartyName, fallback: 'Provider'),
                imagePath: !isRenter ? user.profileImage : reservation.counterpartyImage,
                confirmed: !isRenter ? myConfirmed : otherConfirmed,
              ),
            ],
          ),
        ),
        if (!otherConfirmed) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryColorLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryColorLightBorder),
            ),
            child: Text(
              waitingHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
                height: 1.45,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: _theme.secondaryButton(),
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await vm.prefetchTrust(widget.orderId, phase: widget.phase);
                    if (!mounted) return;
                    final role = vm.reservation?.role ?? vm.trustStatus?.role;
                    setState(() {
                      _busy = false;
                      _step = _resolveStep(vm.trustStatus, role);
                    });
                  },
            child: _busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _theme.accent),
                  )
                : const Text('Refresh status'),
          ),
        ),
      ],
    );
  }

  String _partyName(String? name, {required String fallback}) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return fallback;
    return trimmed;
  }

  Widget _partyProfileRow({
    required String roleLabel,
    required String subtitle,
    required String? imagePath,
    required bool confirmed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ProfileImage.circularAvatar(
            radius: 24,
            baseUrl: AppUrl.baseUrlM,
            imagePath: imagePath,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _titleDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _labelGrey,
                  ),
                ),
              ],
            ),
          ),
          if (confirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirmed',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _successStep(Reservation reservation, ReservationViewModel vm) {
    final isReturn = widget.phase == 'return';
    const successNavy = Color(0xFF1E3A8A);
    const titleNavy = Color(0xFF1E3A8A);

    return Container(
      width: double.infinity,
      color: successNavy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _RentalSuccessCheckWithConfetti(),
              const SizedBox(height: 24),
              Text(
                _theme.successTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _theme.successSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _RentalSuccessDetailsCard(
                isReturn: isReturn,
                returnDateLabel: _formatReturnDateForSuccess(reservation),
                titleColor: titleNavy,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  onPressed: () {
                    vm.loadReservation(widget.orderId);
                    Get.back();
                  },
                  child: const Text('View Reservation'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatReturnDateForSuccess(Reservation reservation) {
    final end = reservation.returnWindowEnd?.trim();
    if (end != null && end.isNotEmpty) {
      final dt = parseApiDateTime(end);
      if (dt != null) {
        return '${DateFormat('MMMM d, yyyy').format(dt)} at ${DateFormat('h:mm a').format(dt)}';
      }
    }
    final fallback = formatRentalDateForDisplay(reservation.rentalEndDate, pattern: 'MMMM d, yyyy');
    return fallback == '—' ? '—' : fallback;
  }

  Widget _buildBottomBar(BuildContext context, ReservationViewModel vm, Reservation reservation) {
    String label;
    VoidCallback? onPressed;

    switch (_step) {
      case _FlowStep.inspect:
        label = 'Continue';
        onPressed = _busy ? null : () => _continueFromInspect(vm);
        break;
      case _FlowStep.review:
        return _buildConfirmationActions(vm);
      case _FlowStep.confirm:
        return _buildConfirmationActions(vm);
      default:
        return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: _theme.primaryButton(),
            onPressed: onPressed,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationActions(ReservationViewModel vm) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: _theme.primaryButton(),
                onPressed: _busy ? null : () => _confirmCondition(vm),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_theme.confirmButtonLabel),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: _theme.secondaryButton(),
                onPressed: _busy
                    ? null
                    : () => Get.to(
                          () => ReportIssueScreen(orderId: widget.orderId, phase: widget.phase),
                        ),
                child: const Text('Report an Issue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (!_canAddPhoto) {
      showAppErrorSnackbar('You can add up to $_maxInspectionPhotos photos.');
      return;
    }

    const source = ImageSource.camera;
    XFile? image;
    try {
      image = await _picker.pickImage(source: source, imageQuality: 85);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final cameraUnavailable = e.code == 'camera_access_denied' ||
          e.code == 'camera_unavailable' ||
          e.message?.toLowerCase().contains('camera') == true;
      if (cameraUnavailable) {
        showAppErrorSnackbar('Camera unavailable. Please check camera permissions and try again.');
      } else {
        showAppErrorSnackbar('Unable to add photo. Please try again.');
      }
      return;
    }

    if (image == null || !mounted) return;
    final picked = File(image.path);
    setState(() => _pendingPhotos.add(picked));
  }

  Future<void> _continueFromInspect(ReservationViewModel vm) async {
    final trust = vm.trustStatus;
    if (trust == null) return;
    final allChecked = trust.checklistTemplate.every((item) => _checked[item.key] == true);
    if (!allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please review every checklist item.', style: GoogleFonts.inter())),
      );
      return;
    }

    setState(() => _busy = true);
    for (final file in List<File>.from(_pendingPhotos)) {
      final uploaded = await vm.uploadInspectionPhoto(widget.orderId, widget.phase, file);
      if (!uploaded) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      _pendingPhotos.remove(file);
    }
    final responses = trust.checklistTemplate
        .map(
          (item) => InspectionResponse(
            itemKey: item.key,
            response: _checked[item.key] == true ? 'yes' : 'no',
          ),
        )
        .toList();
    final saved = await vm.saveChecklist(widget.orderId, widget.phase, responses);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (saved) {
        _step = _FlowStep.confirm;
      }
    });
  }

  Future<void> _confirmCondition(ReservationViewModel vm) async {
    if (_busy) return;
    setState(() => _busy = true);
    await WidgetsBinding.instance.endOfFrame;

    final ok = await vm.confirmInspection(widget.orderId, widget.phase);
    if (!mounted) return;

    if (!ok) {
      setState(() => _busy = false);
      final message = vm.error?.replaceFirst('Exception: ', '').trim();
      showAppErrorSnackbar(
        (message != null && message.isNotEmpty)
            ? message
            : 'Unable to confirm condition. Please try again.',
      );
      return;
    }

    final role = vm.reservation?.role ?? vm.trustStatus?.role;
    setState(() {
      _busy = false;
      _step = _resolveStep(vm.trustStatus, role);
    });
  }
}

String _inspectionMediaUrl(OrderInspectionMedia item) {
  final signed = item.signedUrl?.trim() ?? '';
  if (signed.isNotEmpty) {
    if (signed.toLowerCase().startsWith('http')) return signed;
    return reservationImageUrl(signed);
  }
  return reservationImageUrl(item.filePath);
}

class _SubmittedPhotoStrip extends StatefulWidget {
  final List<OrderInspectionMedia> media;

  const _SubmittedPhotoStrip({required this.media});

  @override
  State<_SubmittedPhotoStrip> createState() => _SubmittedPhotoStripState();
}

class _SubmittedPhotoStripState extends State<_SubmittedPhotoStrip> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    ApiHeaders.authOnly().then((headers) {
      if (mounted) setState(() => _headers = headers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: widget.media.map((item) {
          final url = _inspectionMediaUrl(item);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildThumb(url),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThumb(String url) {
    if (url.isEmpty) {
      return _thumbPlaceholder(Icons.image_not_supported_outlined);
    }
    if (_headers == null) {
      return _thumbPlaceholder(null, loading: true);
    }
    return Image.network(
      url,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      headers: _headers,
      errorBuilder: (_, __, ___) => _thumbPlaceholder(Icons.broken_image_outlined),
    );
  }

  Widget _thumbPlaceholder(IconData? icon, {bool loading = false}) {
    return Container(
      width: 88,
      height: 88,
      color: Colors.grey.shade200,
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: const Color(0xFF6B7280)),
    );
  }
}

class _RentalSuccessDetailsCard extends StatelessWidget {
  final bool isReturn;
  final String returnDateLabel;
  final Color titleColor;

  const _RentalSuccessDetailsCard({
    required this.isReturn,
    required this.returnDateLabel,
    required this.titleColor,
  });

  static const _labelGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReturn ? 'Return Summary' : 'Rental Details',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!isReturn) ...[
            Text(
              'Return date',
              style: GoogleFonts.inter(fontSize: 13, color: _labelGrey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              returnDateLabel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: titleColor,
                height: 1.35,
              ),
            ),
          ] else ...[
            _returnSummaryRow('Deposit', 'Processed to renter', titleColor),
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
            _returnSummaryRow('Payout', 'Processed to provider', titleColor),
          ],
        ],
      ),
    );
  }

  Widget _returnSummaryRow(String label, String value, Color labelColor) {
    const successGreen = Color(0xFF22C55E);
    const rowStyle = TextStyle(height: 1.2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: labelColor,
              ).merge(rowStyle),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: successGreen,
              ).merge(rowStyle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confetti + checkmark pattern from [ListingSuccessScreen], with green success circle.
class _RentalSuccessCheckWithConfetti extends StatelessWidget {
  const _RentalSuccessCheckWithConfetti();

  static const Color _successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const _SuccessConfettiPiece(
            left: 8,
            top: 18,
            width: 10,
            height: 4,
            color: Color(0xFF4285F4),
            angle: -0.6,
          ),
          const _SuccessConfettiPiece(
            right: 6,
            top: 8,
            width: 8,
            height: 8,
            color: Color(0xFFF6AE02),
            shape: BoxShape.circle,
          ),
          const _SuccessConfettiPiece(
            left: 22,
            top: 4,
            width: 6,
            height: 6,
            color: Color(0xFFFF8A50),
            shape: BoxShape.circle,
          ),
          const _SuccessConfettiPiece(
            right: 18,
            top: 28,
            width: 12,
            height: 4,
            color: Color(0xFF4285F4),
            angle: 0.8,
          ),
          const _SuccessConfettiPiece(
            left: 4,
            bottom: 24,
            width: 8,
            height: 4,
            color: Color(0xFFFF8A50),
            angle: -1.1,
          ),
          const _SuccessConfettiPiece(
            right: 10,
            bottom: 18,
            width: 6,
            height: 6,
            color: Color(0xFFF6AE02),
            shape: BoxShape.circle,
          ),
          const _SuccessConfettiPiece(
            left: 36,
            bottom: 8,
            width: 10,
            height: 4,
            color: Color(0xFF4285F4),
            angle: 0.4,
          ),
          const _SuccessConfettiPiece(
            right: 28,
            bottom: 6,
            width: 8,
            height: 4,
            color: Color(0xFFFF8A50),
            angle: -0.3,
          ),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

class _SuccessConfettiPiece extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;
  final Color color;
  final double angle;
  final BoxShape shape;

  const _SuccessConfettiPiece({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
    required this.color,
    this.angle = 0,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(2) : null,
          ),
        ),
      ),
    );
  }
}
