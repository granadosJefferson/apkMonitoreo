import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/registro.dart';

/// Muestra los puntos de muestreo sobre OpenStreetMap. Los mosaicos del mapa
/// requieren internet, pero las coordenadas se guardan siempre por GPS.
class Mapa extends StatelessWidget {
  final List<Registro> registros;
  const Mapa({super.key, required this.registros});

  @override
  Widget build(BuildContext context) {
    final con = registros.where((r) => r.lat != null).toList();
    final centro = con.isEmpty
        ? const LatLng(9.93, -84.08)
        : LatLng(con.first.lat!, con.first.lon!);
    return Scaffold(
      appBar: AppBar(title: const Text('Puntos de muestreo')),
      body: FlutterMap(
        options: MapOptions(initialCenter: centro, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'cr.murcielagos.murcielagos_app',
          ),
          MarkerLayer(
            markers: [
              for (final r in con)
                Marker(
                  point: LatLng(r.lat!, r.lon!),
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: '${r.codigo} · ${r.especie}',
                    triggerMode: TooltipTriggerMode.tap,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 36),
                  ),
                ),
            ],
          ),
          const RichAttributionWidget(attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ]),
        ],
      ),
    );
  }
}
