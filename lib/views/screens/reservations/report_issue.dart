import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../utils/show_snackbar.dart';
import '../../../view_models/reservation_view_model.dart';

class ReportIssueScreen extends StatefulWidget {
  final int orderId;
  final String? phase;

  const ReportIssueScreen({super.key, required this.orderId, this.phase});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const Color _titleDark = Color(0xFF1A1A1A);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _fieldFill = Color(0xFFF7F7F9);
  static const Color _cardBorder = Color(0xFFE8E8EC);
  static const Color _issueAccent = Color(0xFF7C3AED);

  static const List<MapEntry<String, String>> _categories = [
    MapEntry('damage', 'Damage'),
    MapEntry('missing_item', 'Missing accessories'),
    MapEntry('other', 'Item not working properly'),
    MapEntry('no_show', 'Late return / not on time'),
    MapEntry('other_issue', 'Other'),
  ];

  String _category = 'damage';
  final _descriptionController = TextEditingController();
  final List<File> _photos = [];
  bool _submitting = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String get _apiCategory => _category == 'other_issue' ? 'other' : _category;

  @override
  Widget build(BuildContext context) {
    final noteLength = _descriptionController.text.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
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
          'Report an Issue',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                Text(
                  "What's the issue?",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _titleDark),
                ),
                const SizedBox(height: 12),
                ..._categories.map((entry) => _categoryTile(entry.key, entry.value)),
                const SizedBox(height: 20),
                Text(
                  'Add photos (required)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _titleDark),
                ),
                const SizedBox(height: 10),
                _photoRow(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Add notes (optional)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: _titleDark),
                    ),
                    const Spacer(),
                    Text(
                      '$noteLength/500',
                      style: GoogleFonts.inter(fontSize: 12, color: _labelGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  minLines: 4,
                  maxLength: 500,
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 15, color: _titleDark),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _fieldFill,
                    counterText: '',
                    hintText: 'Describe the issue in detail…',
                    hintStyle: GoogleFonts.inter(fontSize: 15, color: _labelGrey),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _issueAccent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: (_submitting || _photos.isEmpty) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _issueAccent,
                        disabledBackgroundColor: _issueAccent.withValues(alpha: 0.45),
                        disabledForegroundColor: Colors.white,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Jebby will review the report and contact both parties if needed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: _labelGrey, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(String value, String label) {
    final selected = _category == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? _issueAccent.withValues(alpha: 0.45) : _cardBorder),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _category,
        activeColor: _issueAccent,
        title: Text(label, style: GoogleFonts.inter(fontSize: 15, color: _titleDark)),
        onChanged: _submitting ? null : (next) => setState(() => _category = next ?? value),
      ),
    );
  }

  Widget _photoRow() {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._photos.map(
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
                      onTap: _submitting ? null : () => setState(() => _photos.remove(file)),
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
          InkWell(
            onTap: _submitting ? null : _pickPhoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: const Icon(Icons.photo_camera_outlined, color: _issueAccent, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add issue photo',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _titleDark,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: _issueAccent),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: _titleDark),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _issueAccent),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: _titleDark),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final source = await _showImageSourceSheet();
    if (source == null || !mounted) return;

    XFile? image;
    try {
      image = await _picker.pickImage(source: source, imageQuality: 85);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final cameraUnavailable = source == ImageSource.camera &&
          (e.code == 'camera_access_denied' ||
              e.code == 'camera_unavailable' ||
              e.message?.toLowerCase().contains('camera') == true);
      if (cameraUnavailable) {
        showAppErrorSnackbar('Camera unavailable. Choose a photo from your library instead.');
      } else {
        showAppErrorSnackbar('Unable to add photo. Please try again.');
      }
      return;
    }

    if (image == null || !mounted) return;
    final picked = File(image.path);
    setState(() => _photos.add(picked));
  }

  Future<void> _submit() async {
    if (_photos.isEmpty) {
      showAppErrorSnackbar('Please add at least one photo.', title: 'Required');
      return;
    }
    setState(() => _submitting = true);
    final vm = context.read<ReservationViewModel>();
    final ok = await vm.reportDispute(
      widget.orderId,
      phase: widget.phase,
      category: _apiCategory,
      description: _descriptionController.text.trim(),
      photos: _photos,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Get.back(result: true);
    }
  }
}
