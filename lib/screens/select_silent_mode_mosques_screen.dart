import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/mosque.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/silent_mode_service.dart';
import '../utils/constants.dart';

/// Lets the user pick exactly which nearby mosques should trigger automatic
/// silent mode - the phone is only silenced entering one of these, not
/// every mosque nearby.
///
/// Pops with the [SyncResult] from saving (or null if the user backed out
/// without saving) so the caller can refresh its own status/count.
class SelectSilentModeMosquesScreen extends StatefulWidget {
  final SilentModeService silentModeService;

  const SelectSilentModeMosquesScreen({super.key, required this.silentModeService});

  @override
  State<SelectSilentModeMosquesScreen> createState() =>
      _SelectSilentModeMosquesScreenState();
}

class _SelectSilentModeMosquesScreenState
    extends State<SelectSilentModeMosquesScreen> {
  final _locationService = LocationService();
  final _placesService = PlacesService(ApiKeys.googlePlacesApiKey);

  bool _isLoading = true;
  String? _error;
  List<Mosque> _candidates = [];
  final Set<String> _selectedIds = {};
  bool _saving = false;
  double? _userLat;
  double? _userLng;

  /// Straight-line distance from the user to [mosque], or null before a
  /// position is known.
  double? _distanceKmFor(Mosque mosque) {
    if (_userLat == null || _userLng == null) return null;
    return _locationService.distanceKm(
        _userLat!, _userLng!, mosque.latitude, mosque.longitude);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final access = await _locationService.checkAccess();
      if (access != LocationAccess.granted) {
        setState(() {
          _error = AppLocalizations.of(context)!.locationPermissionRequiredMosques;
          _isLoading = false;
        });
        return;
      }

      final position = await _locationService.getPosition();
      _userLat = position.latitude;
      _userLng = position.longitude;
      // Deliberately the same radius/maxResults as MosqueListScreen's own
      // fetch (both just call fetchNearbyMosques with its defaults) - this
      // is the same nearby-mosques list shown there, not a separate
      // search, and PlacesService's cache means it's often the literal
      // same result with no second network call at all.
      final results = await Future.wait([
        _placesService.fetchNearbyMosques(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        widget.silentModeService.getRegisteredMosques(),
      ]);
      final nearby = results[0] as List<Mosque>;
      final registered = results[1] as List<RegisteredMosque>;

      // A previously-selected mosque might not turn up in a fresh nearby
      // search (the user moved, Google's result set shifted slightly) -
      // keep it in the list anyway, still checked, so opening this screen
      // and hitting Save never silently drops something the user picked
      // before just because it's momentarily missing from the search.
      final missing = registered
          .where((r) => !nearby.any((m) => m.placeId == r.placeId))
          .map((r) => Mosque(
                placeId: r.placeId,
                name: r.name,
                address: '',
                latitude: r.latitude,
                longitude: r.longitude,
              ));

      // Requirement: the picker must list candidates nearest-to-farthest,
      // same as MosqueListScreen - previously this just showed Places' raw
      // search order, so "near to far" wasn't actually guaranteed here.
      final combined = [...nearby, ...missing];
      combined.sort(
          (a, b) => (_distanceKmFor(a) ?? 0).compareTo(_distanceKmFor(b) ?? 0));

      setState(() {
        _candidates = combined;
        _selectedIds
          ..clear()
          ..addAll(registered.map((r) => r.placeId));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.couldNotLoadNearbyMosques(e.toString());
        _isLoading = false;
      });
    }
  }

  void _toggle(String placeId) {
    setState(() {
      if (_selectedIds.contains(placeId)) {
        _selectedIds.remove(placeId);
      } else {
        _selectedIds.add(placeId);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final selected =
        _candidates.where((m) => _selectedIds.contains(m.placeId)).toList();
    final result = await widget.silentModeService.syncSelectedMosques(selected);
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppLocalizations.of(context)!.selectMosquesTitle,
          style: AppFonts.heading(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.richBlack,
          ),
        ),
        actions: [
          if (!_isLoading && _error == null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _buildSaveButton()),
            ),
          ],
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.mehndiGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.mehndiGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: _saving ? null : _save,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _saving
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                AppLocalizations.of(context)!.saveAction,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mehndiGreen),
      );
    }
    if (_error != null) {
      return _StateMessage(
        icon: Icons.location_off_rounded,
        message: _error!,
        actionLabel: l10n.retryAction,
        onAction: _load,
      );
    }
    if (_candidates.isEmpty) {
      return _StateMessage(
        icon: Icons.mosque_outlined,
        message: l10n.noMosquesFoundNearby,
      );
    }
    return RefreshIndicator(
      color: AppColors.mehndiGreen,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 18),
          _buildSummaryRow(),
          const SizedBox(height: 10),
          ...List.generate(_candidates.length, (index) {
            final mosque = _candidates[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MosqueSelectTile(
                mosque: mosque,
                distanceKm: _distanceKmFor(mosque),
                selected: _selectedIds.contains(mosque.placeId),
                isNearest: index == 0,
                onTap: () => _toggle(mosque.placeId),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
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
            child: const Icon(Icons.notifications_off_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.selectMosquesInfoBanner,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final total = _candidates.length;
    final selected = _selectedIds.length;
    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!.nearbyMosquesCount(total),
          style: AppFonts.heading(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.richBlack,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected == 0
                ? Colors.grey.withValues(alpha: 0.12)
                : AppColors.mehndiGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            AppLocalizations.of(context)!.selectedCountLabel(selected),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected == 0 ? Colors.grey.shade600 : AppColors.mehndiGreen,
            ),
          ),
        ),
      ],
    );
  }
}

/// One selectable mosque row, styled to match [MosqueCard]'s card language
/// (gradient avatar, gold distance pill, "Nearest" ribbon) but built for
/// tap-to-select instead of the read-only display MosqueCard is for.
class _MosqueSelectTile extends StatelessWidget {
  final Mosque mosque;
  final double? distanceKm;
  final bool selected;
  final bool isNearest;
  final VoidCallback onTap;

  const _MosqueSelectTile({
    required this.mosque,
    required this.distanceKm,
    required this.selected,
    required this.isNearest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.mehndiGreen
                  : Colors.black.withValues(alpha: 0.06),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? AppColors.mehndiGreen : Colors.black)
                    .withValues(alpha: selected ? 0.12 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: selected
                              ? [AppColors.mehndiGreen, AppColors.mehndiGreenDark]
                              : [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                      ),
                      child: const Icon(Icons.mosque, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mosque.name,
                            style: AppFonts.heading(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.richBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (distanceKm != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.directions_walk, size: 12, color: Color(0xFF9A7B1F)),
                                      const SizedBox(width: 3),
                                      Text(
                                        AppLocalizations.of(context)!.distanceKm(
                                          distanceKm!.toStringAsFixed(distanceKm! < 10 ? 2 : 1),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9A7B1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (mosque.address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.location_on, size: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  // Whole address, no line cap - a clipped
                                  // address here can hide the detail that
                                  // tells two same-named mosques apart.
                                  child: Text(
                                    mosque.address,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SelectionMark(selected: selected),
                  ],
                ),
              ),
              if (isNearest)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.lightGold,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(19),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 11, color: AppColors.richBlack),
                        const SizedBox(width: 3),
                        Text(
                          AppLocalizations.of(context)!.nearestBadge,
                          style: const TextStyle(
                            fontSize: 10,
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
        ),
      ),
    );
  }
}

/// The filled-when-selected circular check indicator on the right of each
/// [_MosqueSelectTile] - a custom checkbox rather than [Checkbox] so it can
/// match the app's rounded, colored visual language instead of Material's
/// default square box.
class _SelectionMark extends StatelessWidget {
  final bool selected;

  const _SelectionMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.mehndiGreen : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.mehndiGreen : Colors.grey.shade400,
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

/// Centered icon + message (+ optional retry action) used for the error and
/// empty states, styled to match the rest of this screen instead of plain
/// unstyled text.
class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.mehndiGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.mehndiGreen),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mehndiGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
