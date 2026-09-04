import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/handoff_window.dart';
import '../../models/transport_options.dart';
import '../../constants/color.dart';
import '../../utils/show_snackbar.dart';

class TransportOptionsSection extends StatefulWidget {
  final bool pickupEnabled;
  final bool deliveryEnabled;
  final TextEditingController deliveryFeeController;
  final TextEditingController radiusController;
  final List<HandoffWindow> windows;
  final ValueChanged<bool> onPickupChanged;
  final ValueChanged<bool> onDeliveryChanged;
  final ValueChanged<List<HandoffWindow>> onWindowsChanged;

  const TransportOptionsSection({
    super.key,
    required this.pickupEnabled,
    required this.deliveryEnabled,
    required this.deliveryFeeController,
    required this.radiusController,
    required this.windows,
    required this.onPickupChanged,
    required this.onDeliveryChanged,
    required this.onWindowsChanged,
  });

  @override
  State<TransportOptionsSection> createState() => _TransportOptionsSectionState();
}

class _TransportOptionsSectionState extends State<TransportOptionsSection> {
  static const Color _primaryGold = AppColors.primaryColor;
  static const Color _switchOffTrack = Color(0xFFE0E0E0);

  TimeOfDay? _start;
  TimeOfDay? _end;

  SwitchThemeData get _switchTheme => SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryGold;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryGold.withValues(alpha: 0.35);
          }
          return _switchOffTrack;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return _switchOffTrack;
        }),
      );

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: AppColors.darkBlue, size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryGold),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    final isNumericField =
        keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters:
          isNumericField ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _inputDecoration(hint: hint, prefixIcon: prefixIcon),
      style: GoogleFonts.inter(fontSize: 15),
    );
  }

  String _formatTimeOfDayDisplay(TimeOfDay time) {
    return HandoffWindow.formatClock(_formatTime(time));
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          value == null ? label : _formatTimeOfDayDisplay(value),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: value == null ? const Color(0xFF8F9098) : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _addWindow() {
    if (_start == null || _end == null) return;
    final start = _formatTime(_start!);
    final end = _formatTime(_end!);
    final updated = [...widget.windows, HandoffWindow(startTime: start, endTime: end)];
    widget.onWindowsChanged(updated);
    setState(() {
      _start = null;
      _end = null;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_start ?? TimeOfDay.now()) : (_end ?? TimeOfDay.now()),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
              surfaceTint: Colors.transparent,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _primaryGold.withValues(alpha: 0.15);
                }
                return Colors.grey.shade100;
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black87;
                }
                return Colors.black54;
              }),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _primaryGold.withValues(alpha: 0.15);
                }
                return Colors.transparent;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black87;
                }
                return Colors.black54;
              }),
              dialHandColor: _primaryGold,
              dialBackgroundColor: Colors.grey.shade100,
              dialTextColor: Colors.black87,
              entryModeIconColor: _primaryGold,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryGold,
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _showAtLeastOneFulfillmentToast() {
    showAppErrorSnackbar(
      'At least one of Pickup & Return or Delivery & Retrieval must stay enabled.',
      title: 'Required',
    );
  }

  void _handlePickupChanged(bool value) {
    if (!value && !widget.deliveryEnabled) {
      _showAtLeastOneFulfillmentToast();
      return;
    }
    widget.onPickupChanged(value);
  }

  void _handleDeliveryChanged(bool value) {
    if (!value && !widget.pickupEnabled) {
      _showAtLeastOneFulfillmentToast();
      return;
    }
    widget.onDeliveryChanged(value);
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 15, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.78,
            alignment: Alignment.centerRight,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwitchTheme(
      data: _switchTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup & delivery',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          _switchRow(
            title: 'Pickup & Return',
            subtitle: 'Turn off if you do not want renters coming to your location',
            value: widget.pickupEnabled,
            onChanged: _handlePickupChanged,
          ),
          _switchRow(
            title: 'Delivery & Retrieval',
            subtitle: 'You deliver and retrieve the item',
            value: widget.deliveryEnabled,
            onChanged: _handleDeliveryChanged,
          ),
        if (widget.deliveryEnabled) ...[
          const SizedBox(height: 16),
          _fieldLabel('Delivery fee'),
          const SizedBox(height: 8),
          _textField(
            controller: widget.deliveryFeeController,
            hint: '0',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Delivery radius (miles)'),
          const SizedBox(height: 8),
          _textField(
            controller: widget.radiusController,
            hint: '0',
            keyboardType: TextInputType.number,
          ),
        ],
        if (widget.pickupEnabled || widget.deliveryEnabled) ...[
          const SizedBox(height: 16),
          _fieldLabel('Handoff windows'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _timePickerField(
                  label: 'Start time',
                  value: _start,
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timePickerField(
                  label: 'End time',
                  value: _end,
                  onTap: () => _pickTime(false),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addWindow,
                icon: const Icon(Icons.add_circle, color: _primaryGold),
              ),
            ],
          ),
          ...widget.windows.map(
            (window) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                window.displayRange,
                style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  final updated = widget.windows.where((w) => w != window).toList();
                  widget.onWindowsChanged(updated);
                },
              ),
            ),
          ),
        ],
        ],
      ),
    );
  }
}

extension TransportOptionsDraft on TransportOptions {
  static const pickupKey = 'listing_draft_offers_pickup';
  static const deliveryKey = 'listing_draft_offers_delivery';
  static const radiusKey = 'listing_draft_delivery_radius';
  static const windowsKey = 'listing_draft_handoff_windows';
}
