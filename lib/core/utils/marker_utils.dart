import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cached custom marker bitmap — loaded once and reused.
BitmapDescriptor? _cachedLogoMarker;

/// Creates a [BitmapDescriptor] from the app's SVG logo, sized for map markers.
Future<BitmapDescriptor> createLogoMarker({int size = 80}) async {
  if (_cachedLogoMarker != null) return _cachedLogoMarker!;

  final svgString = await rootBundle.loadString('assets/icons/logo.svg');
  final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
  final picture = pictureInfo.picture;

  // Convert to image bytes
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  _cachedLogoMarker = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  return _cachedLogoMarker!;
}
