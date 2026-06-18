import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as device_location;

import '../../../core/map_config.dart';

const _ink = Color(0xFF0F172A);
const _mutedInk = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _primaryBlue = Color(0xFF2563EB);
const _dangerRed = Color(0xFFEF4444);

class LocationMapPicker extends StatefulWidget {
  const LocationMapPicker({
    super.key,
    this.latitude,
    this.longitude,
    required this.onLocationChanged,
  });

  final double? latitude;
  final double? longitude;
  final ValueChanged<LatLng?> onLocationChanged;

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class TaggedLocationMap extends StatelessWidget {
  const TaggedLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  final double? latitude;
  final double? longitude;
  final String locationLabel;

  bool get _hasPinnedLocation => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasPinnedLocation) {
      return const _MapMessage(
        icon: Icons.location_off_outlined,
        message: 'No map pin was tagged for this item.',
      );
    }

    final position = LatLng(latitude!, longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 190,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: MapConfig.defaultZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const _OpenStreetMapTiles(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.location_pin,
                        color: _dangerRed,
                        size: 42,
                      ),
                    ),
                  ],
                ),
                const _MapAttribution(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place, color: _primaryBlue, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$locationLabel\nPinned at ${_formatCoordinate(latitude!)}, '
                '${_formatCoordinate(longitude!)}',
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final _mapController = MapController();
  final _locationService = device_location.Location();
  bool _isLocating = false;

  LatLng? get _selectedLocation {
    final latitude = widget.latitude;
    final longitude = widget.longitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = _selectedLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        selectedLocation ?? MapConfig.defaultCampusCenter,
                    initialZoom: MapConfig.defaultZoom,
                    onTap: (_, location) => _selectLocation(location),
                  ),
                  children: [
                    const _OpenStreetMapTiles(),
                    if (selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedLocation,
                            width: 42,
                            height: 42,
                            child: const Icon(
                              Icons.location_pin,
                              color: _dangerRed,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    const _MapAttribution(),
                  ],
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Text(
                        'OpenStreetMap',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      tooltip: 'Use my current location',
                      onPressed: _isLocating ? null : _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, color: _primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedLocation == null
              ? 'Tap the map to pin where the item was lost or found.'
              : 'Pinned at ${_formatCoordinate(selectedLocation.latitude)}, '
                    '${_formatCoordinate(selectedLocation.longitude)}',
          style: const TextStyle(color: _mutedInk, fontSize: 13),
        ),
        if (selectedLocation != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => widget.onLocationChanged(null),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear pin'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectLocation(LatLng location) async {
    widget.onLocationChanged(location);
    _mapController.move(location, MapConfig.defaultZoom);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      var serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
      }
      if (!serviceEnabled) {
        _showMessage('Turn on location services to use your current position.');
        return;
      }

      var permission = await _locationService.hasPermission();
      if (permission == device_location.PermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }
      if (permission == device_location.PermissionStatus.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. Enable it in settings.',
        );
        return;
      }
      if (permission != device_location.PermissionStatus.granted &&
          permission != device_location.PermissionStatus.grantedLimited) {
        _showMessage('Location permission is required to use your position.');
        return;
      }

      final currentLocation = await _locationService.getLocation();
      final latitude = currentLocation.latitude;
      final longitude = currentLocation.longitude;
      if (latitude == null || longitude == null) {
        _showMessage('Your current location is not available yet.');
        return;
      }

      final location = LatLng(latitude, longitude);
      widget.onLocationChanged(location);
      _mapController.move(location, MapConfig.defaultZoom);
    } catch (_) {
      _showMessage('Unable to get your current location. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _formatCoordinate(double value) {
  return value.toStringAsFixed(5);
}

class _OpenStreetMapTiles extends StatelessWidget {
  const _OpenStreetMapTiles();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.campusfind',
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '(c) OpenStreetMap contributors',
          style: TextStyle(color: _mutedInk, fontSize: 10),
        ),
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
