import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init: $e");
  }
  runApp(const RadarGridApp());
}

class RadarGridApp extends StatelessWidget {
  const RadarGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Radar Grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF141414),
        ),
      ),
      home: const MainRadarScreen(),
    );
  }
}

class MainRadarScreen extends StatefulWidget {
  const MainRadarScreen({super.key});

  @override
  State<MainRadarScreen> createState() => _MainRadarScreenState();
}

class _MainRadarScreenState extends State<MainRadarScreen> {
  Position? _currentPosition;
  double _scopeRadiusKm = 2.0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (mounted) {
      setState(() => _currentPosition = pos);
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000.0;
  }

  void _openPublishDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'General Service');
    final upiController = TextEditingController(text: 'merchant@upi');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Publish Node to Live Radar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Service Title (e.g. Maths Tutor, Electrician)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(
                labelText: "Your UPI ID (for instant settlement)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final category = categoryController.text.trim();
                final upi = upiController.text.trim();
                if (title.isEmpty) return;

                double lat = _currentPosition?.latitude ?? 28.6139;
                double lng = _currentPosition?.longitude ?? 77.2090;

                await FirebaseFirestore.instance.collection('radar_nodes').add({
                  'title': title,
                  'category': category,
                  'upiId': upi,
                  'latitude': lat + (Random().nextDouble() - 0.5) * 0.01,
                  'longitude': lng + (Random().nextDouble() - 0.5) * 0.01,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("Broadcast Live Signal", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("THE RADAR GRID", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<double>(
            value: _scopeRadiusKm,
            dropdownColor: const Color(0xFF141414),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0.5, child: Text("0.5 km (Walking)")),
              DropdownMenuItem(value: 2.0, child: Text("2.0 km (Sector)")),
              DropdownMenuItem(value: 10.0, child: Text("10.0 km (City Scope)")),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _scopeRadiusKm = val);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        onPressed: _openPublishDialog,
        child: const Icon(Icons.add_location_alt),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('radar_nodes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Connection sync: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }

          final docs = snapshot.data?.docs ?? [];
          final liveNodes = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
            double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
            data['distanceKm'] = _calculateDistance(lat, lng);
            return data;
          }).where((node) => (node['distanceKm'] as double) <= _scopeRadiusKm).toList();

          return Column(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                color: Colors.black,
                child: CustomPaint(
                  painter: RadarVisualizerPainter(nodes: liveNodes, scopeRadius: _scopeRadiusKm),
                  child: Center(
                    child: Text(
                      "${liveNodes.length} Nodes within ${_scopeRadiusKm}km Scope",
                      style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: liveNodes.isEmpty
                    ? const Center(
                        child: Text("No live neighbor nodes broadcasted nearby.\nTap + to publish the first node.",
                            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF71717A))),
                      )
                    : ListView.separated(
                        itemCount: liveNodes.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF222222), height: 1),
                        itemBuilder: (context, index) {
                          final node = liveNodes[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1F1F1F),
                              child: Text(node['title'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF00E676))),
                            ),
                            title: Text(node['title'] ?? 'Listing', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text("${node['category']} • ${(node['distanceKm'] as double).toStringAsFixed(2)} km away",
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E1E1E),
                                foregroundColor: const Color(0xFF00E676),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => NodeDetailScreen(node: node)),
                                );
                              },
                              child: const Text("Connect"),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RadarVisualizerPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final double scopeRadius;

  RadarVisualizerPainter({required this.nodes, required this.scopeRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintRing = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (min(size.width, size.height) / 2) * (i / 3), paintRing);
    }

    final paintDot = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < nodes.length; i++) {
      double dist = (nodes[i]['distanceKm'] as double).clamp(0.0, scopeRadius);
      double normalizedDist = (dist / scopeRadius) * (min(size.width, size.height) / 2.2);
      double angle = (i * (2 * pi / max(1, nodes.length)));
      double x = center.dx + normalizedDist * cos(angle);
      double y = center.dy + normalizedDist * sin(angle);

      paintDot.color = const Color(0xFF00E676);
      canvas.drawCircle(Offset(x, y), 5.0, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NodeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> node;
  const NodeDetailScreen({super.key, required this.node});

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  final _messageController = TextEditingController();
  final String _handshakePin = (1000 + Random().nextInt(9000)).toString();
  final _pinInputController = TextEditingController();
  bool _isVerified = false;

  @override
  Widget build(BuildContext context) {
    final upiId = widget.node['upiId'] ?? 'merchant@upi';
    final upiUrl = "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(widget.node['title'])}&cu=INR";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.node['title']),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF141414),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Secure PIN: $_handshakePin", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00E676))),
                    const Text("Share this PIN with peer to complete transaction", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code, color: Color(0xFF00E676)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text("Scan to Settle via UPI"),
                        content: SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: QrImageView(
                              data: upiUrl,
                              version: QrVersions.auto,
                              size: 180.0,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF00E676)),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          if (!_isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1F1F1F),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pinInputController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Enter peer's 4-digit PIN", isDense: true),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_pinInputController.text == _handshakePin) {
                        setState(() => _isVerified = true);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Handshake Verified!")));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid PIN")));
                      }
                    },
                    child: const Text("Verify", style: TextStyle(color: Color(0xFF00E676))),
                  )
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('radar_nodes')
                  .doc(widget.node['id'])
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
                        child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Send real-time message...",
                      filled: true,
                      fillColor: const Color(0xFF141414),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00E676)),
                  onPressed: () async {
                    final text = _messageController.text.trim();
                    if (text.isEmpty) return;
                    _messageController.clear();
                    await FirebaseFirestore.instance
                        .collection('radar_nodes')
                        .doc(widget.node['id'])
                        .collection('messages')
                        .add({'text': text, 'timestamp': FieldValue.serverTimestamp()});
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
