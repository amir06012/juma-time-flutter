import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../services/silent_mode_service.dart';
import '../utils/constants.dart';
import 'select_silent_mode_mosques_screen.dart';

/// Status + setup screen for mosque-entry silent mode.
///
/// The user explicitly picks which nearby mosques should trigger it (see
/// [SelectSilentModeMosquesScreen]) - this screen surfaces a master on/off
/// switch, how many/which mosques are selected, which one (if any) the
/// phone currently thinks it's at, and recent enter/exit activity.
///
/// Permissions are deliberately *not* shown as a standing checklist here -
/// a wall of "Location: granted / Background location: denied" rows is
/// confusing to a non-technical user and stays visible even once
/// everything is already fine. Instead, [_withAllPermissions] is run right
/// before any action that needs a permission: already-granted permissions
/// are silently skipped, and a missing one shows exactly one explanatory
/// dialog before the OS prompt, re-asking (not blocking silently) until
/// it's actually granted or the user backs out. Actually detecting
/// entering/exiting a selected mosque is still done natively, on-device,
/// from real GPS dwell time.
class SilentModeScreen extends StatefulWidget {
  const SilentModeScreen({super.key});

  @override
  State<SilentModeScreen> createState() => _SilentModeScreenState();
}

class _SilentModeScreenState extends State<SilentModeScreen> with WidgetsBindingObserver {
  final _service = SilentModeService();
  StreamSubscription<MosqueSilentModeEvent>? _sub;

  bool _automationEnabled = true;
  int _mosqueCount = 0;
  Map<String, String>? _activeMosque;
  bool _busy = false;
  String? _statusMessage;
  final List<String> _log = [];

  // Set right before sending the user to the OS Settings app for a
  // permission with no in-app request dialog (Do Not Disturb access, or a
  // permanently-denied runtime permission) - resumed automatically when
  // they come back instead of leaving them to notice and tap the button
  // again themselves. This is what makes "keep asking until everything is
  // granted" actually true across a Settings round-trip.
  VoidCallback? _resumeAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = _service.events.listen(_onEvent);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshStatus();
    final resume = _resumeAction;
    if (resume != null) {
      _resumeAction = null;
      resume();
    }
  }

  void _onEvent(MosqueSilentModeEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      final name = event.name ?? l10n.defaultMosqueName;
      final label = switch (event.type) {
        'enter' => l10n.silencedEntered(name),
        'exit' => l10n.restoredLeft,
        _ => l10n.nowAttributedTo(name),
      };
      _log.insert(0, label);
      if (_log.length > 10) _log.removeLast();
    });
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final results = await Future.wait([
      _service.isAutomationEnabled(),
      _service.getRegisteredMosqueCount(),
      _service.getActiveMosque(),
    ]);
    if (!mounted) return;
    setState(() {
      _automationEnabled = results[0] as bool;
      _mosqueCount = results[1] as int;
      _activeMosque = results[2] as Map<String, String>?;
    });
  }

  /// Runs [onReady] once every permission Silent Mode needs is granted -
  /// already-granted ones are skipped with no dialog at all. A missing one
  /// shows exactly one explanatory dialog, then the real request (an OS
  /// prompt, or - for Do Not Disturb access, which has none - a trip to
  /// Settings). If it's still not granted afterwards, the same dialog shows
  /// again rather than silently giving up, until the user either grants it
  /// or explicitly cancels (which aborts [onReady] entirely).
  Future<void> _withAllPermissions(Future<void> Function() onReady) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final l10n = AppLocalizations.of(context)!;
      void resume() => _withAllPermissions(onReady);

      final hasFineLocation = await _ensureRuntimePermission(
        isGranted: _service.hasFineLocation,
        permission: Permission.locationWhenInUse,
        icon: Icons.location_on_outlined,
        title: l10n.locationAccessNeededTitle,
        message: l10n.locationAccessNeededMessage,
        resume: resume,
      );
      if (!hasFineLocation) return;

      final hasBackgroundLocation = await _ensureRuntimePermission(
        isGranted: _service.hasBackgroundLocation,
        permission: Permission.locationAlways,
        icon: Icons.my_location_outlined,
        title: l10n.backgroundLocationNeededTitle,
        message: l10n.backgroundLocationNeededMessage,
        resume: resume,
      );
      if (!hasBackgroundLocation) return;

      final hasNotifications = await _ensureRuntimePermission(
        isGranted: () async {
          final status = await Permission.notification.status;
          return status.isGranted || status.isLimited;
        },
        permission: Permission.notification,
        icon: Icons.notifications_active_outlined,
        title: l10n.notificationsNeededTitle,
        message: l10n.notificationsNeededMessage,
        resume: resume,
      );
      if (!hasNotifications) return;

      if (!await _ensureDndAccess(resume)) return;

      await onReady();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Handles one runtime (OS-dialog-backed) permission: skip silently if
  /// already granted, otherwise explain-then-request, looping back to
  /// explain again if it's still missing afterwards. Once Android has
  /// permanently denied a permission it stops showing its own prompt at
  /// all, so that case routes to the app's Settings page instead.
  Future<bool> _ensureRuntimePermission({
    required Future<bool> Function() isGranted,
    required Permission permission,
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback resume,
  }) async {
    while (!await isGranted()) {
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context)!;
      final permanentlyDenied = await permission.isPermanentlyDenied;
      final proceed = await _showPermissionDialog(
        icon: icon,
        title: title,
        message: permanentlyDenied
            ? "$message${l10n.deniedBeforeSuffix}"
            : message,
        actionLabel: permanentlyDenied ? l10n.openSettingsAction : l10n.allowAction,
      );
      if (!proceed) return false;
      if (permanentlyDenied) {
        _resumeAction = resume;
        await openAppSettings();
        return false; // re-checked automatically once the user comes back
      }
      await permission.request();
    }
    return true;
  }

  /// Do Not Disturb access has no runtime-permission dialog at all - it's a
  /// special-access toggle the user has to flip manually in Settings, so
  /// this always routes there rather than calling `.request()`.
  Future<bool> _ensureDndAccess(VoidCallback resume) async {
    if (await _service.isNotificationPolicyAccessGranted()) return true;
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final proceed = await _showPermissionDialog(
      icon: Icons.do_not_disturb_on_outlined,
      title: l10n.dndAccessNeededTitle,
      message: l10n.dndAccessNeededMessage,
      actionLabel: l10n.openSettingsAction,
    );
    if (!proceed) return false;
    _resumeAction = resume;
    await _service.openNotificationPolicySettings();
    return false; // re-checked automatically once the user comes back
  }

  Future<bool> _showPermissionDialog({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, color: AppColors.mehndiGreen, size: 32),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancelAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.mehndiGreen),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onToggle(bool value) async {
    if (!value) {
      await _service.setAutomationEnabled(false);
      await _refreshStatus();
      return;
    }
    await _withAllPermissions(() => _service.setAutomationEnabled(true));
    await _refreshStatus();
  }

  Future<void> _openMosquePicker() async {
    await _withAllPermissions(() async {
      final result = await Navigator.push<SyncResult>(
        context,
        MaterialPageRoute(
          builder: (_) => SelectSilentModeMosquesScreen(silentModeService: _service),
        ),
      );
      if (result != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _statusMessage = result.hasError
              ? l10n.couldNotSaveSelectedMosques(result.error.toString())
              : result.total == 0
                  ? l10n.noMosquesSelectedOff
                  : l10n.silentModeWatchingCountForMode(result.total);
        });
      }
    });
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.silentModeTitle)),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              // Same mehndiGreen border used on the nearby-mosques cards and
              // the mosque-picker cards, kept here too for one consistent
              // border color across the whole app rather than a plain
              // shadow-only card on this screen alone.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.mehndiGreen.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeMosque != null
                          ? l10n.silencedNearMosque(_activeMosque!['name'] ?? '')
                          : l10n.notAtSelectedMosque,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mosqueCount == 0
                          ? l10n.noMosquesSelectedYet
                          : l10n.silentModeWatchingCount(_mosqueCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l10n.silentModeSwitchTitle),
              subtitle: Text(l10n.silentModeSwitchSubtitle),
              value: _automationEnabled,
              onChanged: _busy ? null : _onToggle,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _openMosquePicker,
              child: _busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_mosqueCount == 0 ? l10n.selectMosquesAction : l10n.editSelectedMosquesAction),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(_statusMessage!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(l10n.recentActivity, style: Theme.of(context).textTheme.titleSmall),
              ..._log.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(e))),
            ],
          ],
        ),
      ),
    );
  }
}
