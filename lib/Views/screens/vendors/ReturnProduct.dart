import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';
import 'package:intl/intl.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_model/getTax_modal.dart';

class ProductReturnScreen extends StatefulWidget {
  const ProductReturnScreen({super.key});

  @override
  State<ProductReturnScreen> createState() => _ProductReturnScreenState();
}

class _ProductReturnScreenState extends State<ProductReturnScreen> {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);

  String url = dotenv.env['baseUrlM'] ?? 'No url found';
  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  List<dynamic> array = [];

  Future<void> _loadData() async {
    try {
      final data = await GetreturnProduct2.fetchData();
      if (!mounted) return;
      final raw = data['data'];
      final list = raw is List ? List<dynamic>.from(raw) : <dynamic>[];
      final filtered = list.where((e) => e['return_status'] != 0).toList();
      setState(() {
        array = filtered;
        isLoading = false;
        isError = false;
        isEmpty = filtered.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isError = true;
          isEmpty = false;
        });
      }
    }
  }

  String _imageUrl(dynamic path) {
    final p = path?.toString().trim() ?? '';
    if (p.isEmpty) return '';
    if (p.toLowerCase().startsWith('http')) return p;
    final base = AppUrl.baseUrlM;
    if (base.endsWith('/')) return base + (p.startsWith('/') ? p.substring(1) : p);
    return '$base/${p.startsWith('/') ? p.substring(1) : p}';
  }

  String _formatCompleteDate(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString().trim();
    if (s.isEmpty || s == '0') return '—';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  bool _canConfirmReceipt(dynamic item) {
    final r = item['return_status'];
    if (r == null) return false;
    if (r is int) return r == 1;
    return r.toString() == '1';
  }

  Future<void> _submitReceived(dynamic id) async {
    setState(() {
      isLoading = true;
    });
    final seenMessageUrl = '$url/orderReceived';
    final body = {'id': id};
    try {
      final response = await http.post(
        Uri.parse(seenMessageUrl),
        headers: await ApiHeaders.json(),
        body: json.encode(body),
      );
      final responseBody = jsonDecode(response.body);

      if (!mounted) return;

      if (responseBody['message'].toString() == 'product has been received') {
        showAppSuccessSnackbar('Product has been received.');
        await _loadData();
      } else {
        showAppErrorSnackbar(
          responseBody['message']?.toString() ?? 'Something went wrong',
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        showAppErrorSnackbar(
          'Something went wrong. Please check your internet connection.',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Return Product',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirm when you’ve received items renters have returned.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    if (isError) {
      return Center(
        child: Text(
          'Could not load return items. Please try again later.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: _subtitleGrey, fontSize: 15),
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Text(
          'No return items right now',
          style: GoogleFonts.inter(color: _subtitleGrey, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: array.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = array[index];
        final name = item['product_name']?.toString() ?? '—';
        final dateStr = _formatCompleteDate(item['complete_date']);
        final id = item['id'];
        final image = item['product_image'];
        final canConfirm = _canConfirmReceipt(item);

        return _VendorReceiveItemCard(
          name: name,
          completedDate: dateStr,
          imageUrl: _imageUrl(image),
          canConfirm: canConfirm,
          onConfirm: canConfirm ? () => _submitReceived(id) : null,
        );
      },
    );
  }
}

class _VendorReceiveItemCard extends StatelessWidget {
  final String name;
  final String completedDate;
  final String imageUrl;
  final bool canConfirm;
  final VoidCallback? onConfirm;

  const _VendorReceiveItemCard({
    required this.name,
    required this.completedDate,
    required this.imageUrl,
    required this.canConfirm,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child:
                        imageUrl.isEmpty
                            ? ColoredBox(
                              color: const Color(0xFFF5F5F5),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey.shade400,
                              ),
                            )
                            : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => ColoredBox(
                                    color: const Color(0xFFF5F5F5),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryColor.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => ColoredBox(
                                    color: const Color(0xFFF5F5F5),
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey.shade500,
                                    ),
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
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Completed: $completedDate',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9A9AA1),
                        ),
                      ),
                      if (!canConfirm) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'RECEIPT CONFIRMED',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  canConfirm ? 'Product received' : 'Already confirmed',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
