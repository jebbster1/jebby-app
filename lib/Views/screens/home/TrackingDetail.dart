import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';

import 'package:jebby/utils/profile_image.dart';
import '../../../view_model/apiServices.dart';

class TrackingDetailScreen extends StatefulWidget {
  final dynamic date;
  final dynamic vendorId;
  final dynamic status;
  final dynamic created;
  final dynamic approve;
  final dynamic complete;
  final dynamic cancel;

  const TrackingDetailScreen({
    super.key,
    this.date,
    this.vendorId,
    this.status,
    this.created,
    this.approve,
    this.complete,
    this.cancel,
  });

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);

  bool userError = false;
  bool userEmpty = true;
  var userImage = "";
  var userName = "";
  var userNumber = "";
  var userAddress = "";

  void getUserData() {
    ApiRepository.shared.userCredential(
      (List) {
        if (!mounted) return;
        if (List.data!.isEmpty) {
          setState(() {
            userError = false;
            userEmpty = true;
            userImage = "";
          });
        } else {
          setState(() {
            userError = false;
            userEmpty = false;
            userImage = ProfileImage.sanitizePath(
              ApiRepository.shared.getUserCredentialModelList!.data![0].profileImage?.toString(),
            );
            userName =
                ApiRepository.shared.getUserCredentialModelList!.data![0].name.toString();
            userNumber =
                ApiRepository.shared.getUserCredentialModelList!.data![0].phoneNumber.toString();
            userAddress =
                ApiRepository.shared.getUserCredentialModelList!.data![0].address.toString();
          });
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            userError = true;
            userEmpty = false;
            userImage = "";
          });
        }
      },
      widget.vendorId.toString(),
    );
  }

  String get _statusStr => widget.status?.toString() ?? '';

  String? _formatDisplayDate(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty || t == '0') return null;
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(t));
    } catch (_) {
      return t;
    }
  }

  String? _formatShortDate(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty || t == '0') return null;
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(t));
    } catch (_) {
      return t;
    }
  }

  /// Renter [MyOrders] may pass a preformatted string (e.g. dd-MM-yy).
  String? _placingDateLine(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty || t == '0') return null;
    return t;
  }

  String _rentSummary() {
    final d = widget.date?.toString() ?? '';
    if (d.isEmpty) return 'Rent start date not available';
    return 'Rent starts ${_formatDisplayDate(d) ?? d}';
  }

  String _vendorImageUrl() {
    return ProfileImage.resolveUrl(AppUrl.baseUrlM, userImage) ?? '';
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF1A1A1A),
        displayColor: const Color(0xFF1A1A1A),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Get.back(),
            style: IconButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking Details',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Status and details for this rental.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              _summaryCard(_rentSummary()),
              const SizedBox(height: 16),
              _vendorCard(),
              const SizedBox(height: 16),
              _progressCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String line) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_today_outlined, color: AppColors.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                line,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vendorCard() {
    if (userError) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Couldn't load provider details",
            style: GoogleFonts.inter(color: _subtitleGrey, fontSize: 14),
          ),
        ),
      );
    }
    if (userEmpty) {
      return const SizedBox.shrink();
    }

    final url = _vendorImageUrl();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child:
                    url.isEmpty
                        ? ColoredBox(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.storefront_outlined, color: Colors.grey.shade600, size: 32),
                        )
                        : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.storefront_outlined, color: Colors.grey.shade600, size: 32),
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _subtitleGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName.isEmpty ? 'Vendor' : userName,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (userNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      userNumber,
                      style: GoogleFonts.inter(fontSize: 13, color: _subtitleGrey),
                    ),
                  ],
                  if (userAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      userAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6D6D75),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order progress',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Updates appear as your order moves forward.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _subtitleGrey,
              ),
            ),
            const SizedBox(height: 20),
            _buildTimelineForStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineForStatus() {
    final c = widget.created?.toString() ?? '';
    final ap = widget.approve?.toString() ?? '';
    final comp = widget.complete?.toString() ?? '';
    final can = widget.cancel?.toString() ?? '';

    switch (_statusStr) {
      case '3':
        return _timeline(
          [
            _TrackNode(
              title: 'Order cancelled',
              date: can != '0' ? _formatShortDate(can) : null,
            ),
          ],
        );
      case '0':
        return _timeline(
          [
            _TrackNode(
              title: 'Order is pending',
              date: c.isNotEmpty && c != '0' ? _placingDateLine(c) : null,
            ),
          ],
        );
      case '1':
        return _timeline(
          [
            _TrackNode(
              title: 'Placed',
              date: _placingDateLine(c),
            ),
            _TrackNode(
              title: 'Approved',
              date: ap != '0' && ap.isNotEmpty ? _formatShortDate(ap) : null,
            ),
          ],
        );
      default:
        return _timeline(
          [
            _TrackNode(
              title: 'Placed',
              date: _placingDateLine(c),
            ),
            _TrackNode(
              title: 'Approved',
              date: ap != '0' && ap.isNotEmpty ? _formatShortDate(ap) : null,
            ),
            _TrackNode(
              title: 'Shipped',
              date: comp != '0' && comp.isNotEmpty ? _formatShortDate(comp) : null,
            ),
          ],
        );
    }
  }

  Widget _timeline(List<_TrackNode> steps) {
    if (steps.isEmpty) {
      return Text('No status updates', style: GoogleFonts.inter(color: _subtitleGrey));
    }
    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        final last = i == steps.length - 1;
        final nodeDone = s.date != null && s.date!.isNotEmpty;
        final prev = i > 0 ? steps[i - 1] : null;
        final lineFromAbove = prev != null && prev.date != null && prev.date!.isNotEmpty;
        return _TimelineRow(
          isFirst: i == 0,
          isLast: last,
          title: s.title,
          date: s.date,
          isNodeDone: nodeDone,
          lineFromAboveActive: lineFromAbove,
        );
      }),
    );
  }
}

class _TrackNode {
  final String title;
  final String? date;
  _TrackNode({required this.title, this.date});
}

class _TimelineRow extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final String title;
  final String? date;
  final bool isNodeDone;
  final bool lineFromAboveActive;

  const _TimelineRow({
    required this.isFirst,
    required this.isLast,
    required this.title,
    required this.date,
    required this.isNodeDone,
    required this.lineFromAboveActive,
  });

  static const _subtitleGrey = Color(0xFF72747A);
  static const _lineMuted = Color(0xFFE0E0E0);
  static const _segmentH = 44.0;

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null && date!.isNotEmpty;
    final showInProgress = !hasDate && title != 'Order cancelled' && title != 'Placed';
    const lineW = 2.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: lineW,
                height: 10,
                color: lineFromAboveActive ? AppColors.primaryColor : _lineMuted,
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNodeDone ? AppColors.primaryColor : _lineMuted,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  isNodeDone
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
            ),
            if (!isLast)
              Container(
                width: lineW,
                height: _segmentH,
                color: isNodeDone ? AppColors.primaryColor.withValues(alpha: 0.5) : _lineMuted,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasDate) ...[
                  const SizedBox(height: 4),
                  Text(
                    date!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _subtitleGrey,
                    ),
                  ),
                ] else if (showInProgress) ...[
                  const SizedBox(height: 4),
                  Text(
                    'In progress',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _subtitleGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
