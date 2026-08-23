import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../services/qibla_service.dart';
import '../utils/constants.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _locationService = LocationService();
  final _qiblaService = QiblaService();

  static const _degToRad = math.pi / 180;
  // Same tolerance window used to decide when the marker turns green - kept
  // as one constant so the dial color and the "Aligned" text can never
  // disagree with each other.
  static const _alignmentToleranceDeg = 5;

  double? _qiblaBearing;
  StreamSubscription<CompassEvent>? _compassSub;
  double _heading = 0;
  bool _isAligned = false;
  bool _isLoading = true;
  LocationAccess? _locationAccess;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // checkAccess (rather than getCurrentPosition's internal check) is what
    // lets the error state below tell "location is off" apart from
    // "permission denied" and offer the right fix instead of one generic
    // message.
    final access = await _locationService.checkAccess();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _locationAccess = access;
    if (access != LocationAccess.granted) {
      setState(() {
        _error = switch (access) {
          LocationAccess.serviceDisabled => l10n.turnOnLocationQibla,
          LocationAccess.permissionDenied ||
          LocationAccess.permissionDeniedForever =>
            l10n.locationPermissionRequiredQibla,
          LocationAccess.granted => null,
        };
        _isLoading = false;
      });
      return;
    }

    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      setState(() {
        _error = l10n.couldNotGetLocation;
        _isLoading = false;
      });
      return;
    }

    _qiblaBearing = _qiblaService.calculateQiblaBearing(
      position.latitude,
      position.longitude,
    );

    if (FlutterCompass.events == null) {
      setState(() {
        _error = l10n.compassNotAvailable;
        _isLoading = false;
      });
      return;
    }

    _compassSub = FlutterCompass.events!.listen((event) {
      if (event.heading == null || !mounted || _qiblaBearing == null) return;
      final heading = event.heading!;
      final diff = (_qiblaBearing! - heading + 360) % 360;
      final aligned = diff < _alignmentToleranceDeg || diff > 360 - _alignmentToleranceDeg;
      // A short buzz right as the marker turns green - a small tactile
      // confirmation you don't have to keep staring at the screen for,
      // fired only on the misaligned-to-aligned transition so it doesn't
      // repeat on every compass tick while already aligned.
      if (aligned && !_isAligned) HapticFeedback.mediumImpact();
      setState(() {
        _heading = heading;
        _isAligned = aligned;
      });
    });

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resolveLocationAccess() async {
    switch (_locationAccess) {
      case LocationAccess.serviceDisabled:
        await _locationService.openLocationSettings();
        break;
      case LocationAccess.permissionDenied:
      case LocationAccess.permissionDeniedForever:
        await _locationService.openAppSettings();
        break;
      case LocationAccess.granted:
      case null:
        break;
    }
    await _init();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.qiblaDirectionTitle,
          style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.richBlack),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.mehndiGreen))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    final needsAction = _locationAccess != null && _locationAccess != LocationAccess.granted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.mehndiGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_off_rounded, size: 34, color: AppColors.mehndiGreen),
            ),
            const SizedBox(height: 18),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: needsAction ? _resolveLocationAccess : _init,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mehndiGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                switch (_locationAccess) {
                  LocationAccess.serviceDisabled => l10n.turnOnLocationAction,
                  LocationAccess.permissionDenied ||
                  LocationAccess.permissionDeniedForever =>
                    l10n.grantLocationPermissionAction,
                  LocationAccess.granted || null => l10n.tryAgainAction,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final markerAngle = ((_qiblaBearing! - _heading + 360) % 360) * _degToRad;
    final accent = _isAligned ? AppColors.mehndiGreen : AppColors.lightGold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _buildStatusBanner(accent),
        const SizedBox(height: 28),
        Center(child: _buildDial(markerAngle, accent)),
        const SizedBox(height: 28),
        _buildBearingCard(),
        const SizedBox(height: 18),
        _buildTipBanner(),
      ],
    );
  }

  Widget _buildStatusBanner(Color accent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _isAligned ? AppColors.mehndiGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: _isAligned ? 0 : 0.4)),
        boxShadow: [
          BoxShadow(
            color: (_isAligned ? AppColors.mehndiGreen : Colors.black).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isAligned ? Icons.check_circle_rounded : Icons.explore_rounded,
            color: _isAligned ? Colors.white : AppColors.lightGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isAligned
                  ? AppLocalizations.of(context)!.qiblaAligned
                  : AppLocalizations.of(context)!.qiblaRotatePrompt,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _isAligned ? Colors.white : AppColors.richBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDial(double markerAngle, Color accent) {
    const dialSize = 280.0;
    return Container(
      width: dialSize + 24,
      height: dialSize + 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: dialSize,
        height: dialSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating dial with tick marks + N/E/S/W, counter-rotates with
            // device heading so North always points to true North.
            Transform.rotate(
              angle: (-_heading) * _degToRad,
              child: Container(
                width: dialSize,
                height: dialSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 3),
                  gradient: const RadialGradient(
                    colors: [AppColors.creamBackground, Colors.white],
                  ),
                ),
                child: CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _CompassTicksPainter(color: AppColors.richBlack.withValues(alpha: 0.35)),
                  child: const Stack(
                    children: [
                      Positioned(
                        top: 18, left: 0, right: 0,
                        child: Center(
                          child: Text('N', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.richBlack)),
                        ),
                      ),
                      Positioned(
                        bottom: 18, left: 0, right: 0,
                        child: Center(
                          child: Text('S', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.richBlack)),
                        ),
                      ),
                      Positioned(
                        left: 18, top: 0, bottom: 0,
                        child: Center(
                          child: Text('W', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.richBlack)),
                        ),
                      ),
                      Positioned(
                        right: 18, top: 0, bottom: 0,
                        child: Center(
                          child: Text('E', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.richBlack)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Qibla marker: a Kaaba icon at the tip of a pointer, rotating
            // to always point toward Mecca. Turns mehndiGreen when the
            // phone is correctly aligned, gold otherwise.
            Transform.rotate(
              angle: markerAngle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isAligned
                            ? [AppColors.mehndiGreen, AppColors.mehndiGreenDark]
                            : [AppColors.lightGold, const Color(0xFF9A7B1F)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mosque, size: 26, color: Colors.white),
                  ),
                  Container(
                    width: 4,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withValues(alpha: 0.05)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Fixed center hub representing the user's position.
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.richBlack,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBearingCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mehndiGreen.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.qiblaBearingLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_qiblaBearing!.toStringAsFixed(1)}°',
                  style: AppFonts.heading(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.richBlack,
                  ),
                ),
                Text(l10n.fromTrueNorth, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.facingLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_heading.toStringAsFixed(0)}°',
                style: AppFonts.heading(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _isAligned ? AppColors.mehndiGreen : AppColors.richBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mehndiGreen, AppColors.mehndiGreenDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.mehndiGreen.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smartphone_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.qiblaTip,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the minor/major tick marks around the compass dial - a small
/// touch that reads as an actual measuring instrument rather than a plain
/// circle with four letters on it.
class _CompassTicksPainter extends CustomPainter {
  final Color color;

  const _CompassTicksPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // A few pixels inside the dial's own border stroke so ticks don't
    // overlap/clip against it.
    final radius = size.width / 2 - 6;
    final paint = Paint()..color = color;

    for (var deg = 0; deg < 360; deg += 5) {
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 30 == 0;
      if (isCardinal) continue; // the N/E/S/W labels already mark these
      final tickLength = isMajor ? 10.0 : 5.0;
      paint.strokeWidth = isMajor ? 2 : 1;
      final angle = deg * (math.pi / 180);
      final outer = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - tickLength) * math.sin(angle),
        center.dy - (radius - tickLength) * math.cos(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassTicksPainter oldDelegate) => oldDelegate.color != color;
}
