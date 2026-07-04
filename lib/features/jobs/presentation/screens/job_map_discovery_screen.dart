import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/utils/marker_utils.dart';

final nearbyPhysicalJobsProvider = FutureProvider.autoDispose.family<List<Job>, Map<String, double>>((ref, params) async {
  final supabase = ref.read(supabaseServiceProvider).client;
  final response = await supabase.rpc('get_nearby_jobs', params: {
    'user_lat': params['lat'],
    'user_lng': params['lng'],
    'radius_km': 50.0,
  });

  final List<dynamic> data = response as List<dynamic>;

  // Filter for physical jobs locally as RPC might return all
  return data
      .map((e) => Job.fromJson(e as Map<String, dynamic>))
      .where((job) => job.jobType == 'physical')
      .toList();
});

class JobMapDiscoveryScreen extends ConsumerStatefulWidget {
  const JobMapDiscoveryScreen({super.key});

  @override
  ConsumerState<JobMapDiscoveryScreen> createState() => _JobMapDiscoveryScreenState();
}

class _JobMapDiscoveryScreenState extends ConsumerState<JobMapDiscoveryScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  BitmapDescriptor? _customIcon;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Load custom logo marker using shared utility
      final icon = await createLogoMarker(size: 80);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _customIcon = icon;
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_currentPosition == null || _customIcon == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final jobsAsync = ref.watch(nearbyPhysicalJobsProvider({
      'lat': _currentPosition!.latitude,
      'lng': _currentPosition!.longitude,
    }));

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Jobs Nearby')),
      body: jobsAsync.when(
        data: (jobs) => GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 12),
          onMapCreated: (controller) => _mapController = controller,
          markers: jobs.map((job) => Marker(
            markerId: MarkerId(job.id),
            position: LatLng(job.latitude!, job.longitude!),
            icon: _customIcon!,
            infoWindow: InfoWindow(
              title: job.title,
              snippet: 'R${job.budget.toStringAsFixed(0)}',
            ),
          )).toSet(),
          myLocationEnabled: true,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
