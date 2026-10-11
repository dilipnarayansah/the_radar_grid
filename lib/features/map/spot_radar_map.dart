import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:the_radar_grid/models/listing.dart';

class MapRadarView extends StatelessWidget {
  final List<GridListing> listings;
  final double radarRadius;
  final Function(GridListing) onSelectListing;

  const MapRadarView({
    super.key,
    required this.listings,
    required this.radarRadius,
    required this.onSelectListing,
  });

  @override
  Widget build(BuildContext context) {
    final activeInRadar = listings.where((l) => l.distanceKm <= radarRadius && !l.isSold).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '🗺️ OPENSTREETMAP SPOT RADAR (${radarRadius.toStringAsFixed(0)} KM)',
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0E272B), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5FF))),
                  child: Text('${activeInRadar.length} Active Pins', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(28.6139, 77.2090),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.spotapp.industrial',
                ),
                MarkerLayer(
                  markers: activeInRadar.map((item) {
                    final lat = item.latitude ?? 28.6139;
                    final lng = item.longitude ?? 77.2090;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => onSelectListing(item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF14141C),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
