import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/mosque.dart';
import '../models/jummah_info.dart';
import '../utils/constants.dart';

class MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final double distanceKm;
  final JummahInfo jummahInfo;
  final bool isNearest;

  /// Called with 1 to add the first Jummah time, or 2 to add the second.
  final void Function(int slot) onAddJummahTap;

  const MosqueCard({
    super.key,
    required this.mosque,
    required this.distanceKm,
    required this.jummahInfo,
    required this.onAddJummahTap,
    this.isNearest = false,
  });

  Future<void> _openDirections() async {
    // Try the native Google Maps navigation intent first (Android + iOS
    // both understand this scheme when the Maps app is installed).
    final navUri = Uri.parse(
      'google.navigation:q=${mosque.latitude},${mosque.longitude}&mode=d',
    );
    final webFallback = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${mosque.latitude},${mosque.longitude}',
    );

    if (await canLaunchUrl(navUri)) {
      await launchUrl(navUri);
    } else {
      await launchUrl(webFallback, mode: LaunchMode.externalApplication);
    }
  }

  bool get _hasTime1 => jummahInfo.jummahTime1 != null;
  bool get _hasTime2 => jummahInfo.jummahTime2 != null;

  Widget _timeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mehndiGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.mehndiGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_filled, size: 13, color: AppColors.mehndiGreen),
          const SizedBox(width: 5),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.mehndiGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJummahSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasTime1 && !_hasTime2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.jummahTimeNotAdded,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () => onAddJummahTap(1),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text(l10n.addAction),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mehndiGreen,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (_hasTime1) _timeChip(jummahInfo.jummahTime1!),
            if (_hasTime2) _timeChip(jummahInfo.jummahTime2!),
          ],
        ),
        const Spacer(),
        if (_hasTime1 && !_hasTime2)
          TextButton(
            onPressed: () => onAddJummahTap(2),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mehndiGreen,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(l10n.secondTimeShort, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Same mehndiGreen used everywhere else in the app (distance pill,
        // buttons, the mosque-picker card borders) - keeps this list
        // visually consistent with the rest of the app instead of a plain
        // shadow-only white card.
        border: Border.all(color: AppColors.mehndiGreen.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.mehndiGreen, AppColors.mehndiGreenDark],
                        ),
                      ),
                      child: const Icon(Icons.mosque, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mosque.name,
                            style: AppFonts.heading(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.richBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.location_on, size: 13, color: Colors.grey),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  // Full address (no line/ellipsis cap) -
                                  // was 1 line with an ellipsis, which cut
                                  // off most of it.
                                  mosque.address,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.lightGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_walk, size: 14, color: Color(0xFF9A7B1F)),
                      const SizedBox(width: 4),
                      Text(
                        l10n.distanceKmAway(distanceKm.toStringAsFixed(2)),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A7B1F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildJummahSection(context),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openDirections,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mehndiGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: Text(l10n.getDirections),
                  ),
                ),
              ],
            ),
          ),
          if (isNearest)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: AppColors.lightGold,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: AppColors.richBlack),
                    const SizedBox(width: 4),
                    Text(
                      l10n.nearestBadge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.richBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}