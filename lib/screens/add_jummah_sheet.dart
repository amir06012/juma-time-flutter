import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/mosque.dart';
import '../services/connectivity_service.dart';
import '../services/realtime_jummah_service.dart';
import '../utils/constants.dart';

class AddJummahSheet extends StatefulWidget {
  final Mosque mosque;
  final RealtimeJummahService jummahService;

  /// Which Jummah time this sheet is adding - 1 for the first (no time set
  /// yet), 2 for the second (first is already set).
  final int slot;

  const AddJummahSheet({
    super.key,
    required this.mosque,
    required this.jummahService,
    required this.slot,
  });

  @override
  State<AddJummahSheet> createState() => _AddJummahSheetState();
}

class _AddJummahSheetState extends State<AddJummahSheet> {
  final _connectivityService = ConnectivityService();
  TimeOfDay? _time;
  bool _isSubmitting = false;

  /// Basic sanity-check: Jummah is always early-to-mid afternoon, so
  /// anything wildly outside that range is almost certainly a mis-tap.
  String? _validateTime(TimeOfDay? time) {
    final l10n = AppLocalizations.of(context)!;
    if (time == null) return l10n.pleasePickTime;
    if (time.hour < 11 || time.hour > 16) {
      return l10n.jummahTimeRangeWarning;
    }
    return null;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 13, minute: 30),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _submit() async {
    final error = _validateTime(_time);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isSubmitting = true);

    if (!await _connectivityService.hasInternetConnection()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.offlineTryAgain),
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    try {
      await widget.jummahService.submitJummahTime(
        placeId: widget.mosque.placeId,
        mosqueName: widget.mosque.name,
        slot: widget.slot,
        time: _formatTime(_time!),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.jummahTimeAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSubmit(e.toString()))),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = widget.slot == 1 ? l10n.jummahTimeLabel : l10n.secondJummahTimeLabel;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label - ${widget.mosque.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            // Same mehndiGreen border used across the rest of the app's
            // cards/lists (nearby mosques, silent mode, mosque picker), so
            // this sheet reads as part of the same design instead of a bare
            // unstyled ListTile.
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.mehndiGreen.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(label),
              subtitle: Text(_time != null ? _formatTime(_time!) : l10n.tapToPick),
              onTap: _pickTime,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? l10n.savingEllipsis : l10n.saveAction),
            ),
          ),
        ],
      ),
    );
  }
}