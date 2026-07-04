import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key, this.initialPosition});
  final LatLng? initialPosition;

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Using default location.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied. Using default location.';
            _isLoading = false;
          });
          return;
        }
      }

      if (_pickedLocation == null) {
        final position = await Geolocator.getCurrentPosition();
        _pickedLocation = LatLng(position.latitude, position.longitude);
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _pickedLocation = const LatLng(-25.7479, 28.2293); // Pretoria fallback
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (position) {
                    setState(() => _pickedLocation = position);
                  },
                  markers: _pickedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('picked-location'),
                            position: _pickedLocation!,
                          ),
                        },
                ),
                if (_errorMessage != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Material(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(_pickedLocation),
        label: const Text('Confirm Location'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
