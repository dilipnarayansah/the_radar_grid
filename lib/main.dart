import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const RadarGridApp());
}

class RadarGridApp extends StatelessWidget {
  const RadarGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Radar Grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF15151C),
        ),
      ),
      home: const MainRadarShell(),
    );
  }
}

// ---------------- DATA MODEL ----------------
class GridItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String tag;
  final double lat;
  final double lng;
  final String price;
  final double rating;
  final IconData icon;

  GridItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.tag,
    required this.lat,
    required this.lng,
    required this.price,
    required this.rating,
    required this.icon,
  });
}

// ---------------- ROOT NAVIGATION SHELL ----------------
class MainRadarShell extends StatefulWidget {
  const MainRadarShell({super.key});

  @override
  State<MainRadarShell> createState() => _MainRadarShellState();
}

class _MainRadarShellState extends State<MainRadarShell> {
  int _currentIndex = 0;

  final double userLat = 25.5941;
  final double userLng = 85.1376;

  late List<GridItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      GridItem(
        id: '1',
        title: 'Rohan Tech Lab',
        subtitle: 'Python, OS & Network Setup',
        category: 'Tech',
        tag: 'INDIVIDUAL',
        lat: 25.5960,
        lng: 85.1390,
        price: '₹150/hr',
        rating: 4.9,
        icon: Icons.laptop_chromebook,
      ),
      GridItem(
        id: '2',
        title: 'Verma Mobile Care',
        subtitle: 'Display, IC & Battery Change',
        category: 'Repairs',
        tag: 'STORE',
        lat: 25.5990,
        lng: 85.1420,
        price: 'Same-day',
        rating: 4.8,
        icon: Icons.smartphone,
      ),
      GridItem(
        id: '3',
        title: "Pooja's Tiffin",
        subtitle: 'Healthy Thalis & Fresh Rotis',
        category: 'Kitchen',
        tag: 'HOME CHEF',
        lat: 25.5920,
        lng: 85.1350,
        price: '₹80/meal',
        rating: 5.0,
        icon: Icons.soup_kitchen,
      ),
      GridItem(
        id: '4',
        title: 'Sony 50mm Lens',
        subtitle: 'Available for 24h equipment rent',
        category: 'Rent/Tools',
        tag: 'RENTAL',
        lat: 25.5910,
        lng: 85.1480,
        price: '₹300/day',
        rating: 4.9,
        icon: Icons.camera_alt,
      ),
    ];
  }

  // Proximity Calculation Engine
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _addNewListing(GridItem item) {
    setState(() {
      _items.insert(0, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExploreFeed(
        items: _items,
        userLat: userLat,
        userLng: userLng,
        calcDistance: calculateDistance,
        onAdd: _addNewListing,
      ),
      MapRadarScreen(
        items: _items,
        userLat: userLat,
        userLng: userLng,
        calcDistance: calculateDistance,
      ),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF121218),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: const Color(0xFF71717A),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar Map'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Direct Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

// ---------------- TAB 1: EXPLORE FEED ----------------
class ExploreFeed extends StatefulWidget {
  final List<GridItem> items;
  final double userLat;
  final double userLng;
  final Function(double, double, double, double) calcDistance;
  final Function(GridItem) onAdd;

  const ExploreFeed({
    super.key,
    required this.items,
    required this.userLat,
    required this.userLng,
    required this.calcDistance,
    required this.onAdd,
  });

  @override
  State<ExploreFeed> createState() => _ExploreFeedState();
}

class _ExploreFeedState extends State<ExploreFeed> {
  String _activeCategory = 'All';

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.bolt},
    {'name': 'Tech', 'icon': Icons.laptop},
    {'name': 'Repairs', 'icon': Icons.build},
    {'name': 'Tutors', 'icon': Icons.menu_book},
    {'name': 'Kitchen', 'icon': Icons.soup_kitchen},
    {'name': 'Rent/Tools', 'icon': Icons.inventory_2},
  ];

  void _openCreatePostModal() {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15151C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡ Broadcast to 2.0 km Radar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title / Service Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Short Description', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (e.g., ₹200/hr, ₹50)', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  widget.onAdd(GridItem(
                    id: DateTime.now().toString(),
                    title: titleCtrl.text,
                    subtitle: subCtrl.text,
                    category: 'Tech',
                    tag: 'LIVE BROADCAST',
                    lat: widget.userLat + 0.002,
                    lng: widget.userLng + 0.002,
                    price: priceCtrl.text.isEmpty ? 'Negotiable' : priceCtrl.text,
                    rating: 5.0,
                    icon: Icons.offline_bolt,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Post to Live Grid', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _activeCategory == 'All'
        ? widget.items
        : widget.items.where((i) => i.category == _activeCategory).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090C),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF00E676), size: 18),
                SizedBox(width: 4),
                Text('Active Node Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('2.0 km Universal Grid Active', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF181820),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF272732)),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E676)),
                const SizedBox(width: 6),
                Text('${widget.items.length} LIVE', style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF15151C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF272732))),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF00E676), size: 20),
                      SizedBox(width: 8),
                      Text('Search skills, trades, rentals...', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openCreatePostModal,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add, color: Colors.black, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _activeCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat['name']),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isSelected ? const Color(0xFF00E676) : const Color(0xFF181820),
                        child: Icon(cat['icon'], color: isSelected ? Colors.black : const Color(0xFFA1A1AA), size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(cat['name'], style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF71717A), fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Text('DISCOVERIES WITHIN RANGE', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final dist = widget.calcDistance(widget.userLat, widget.userLng, item.lat, item.lng);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF15151C), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF272732))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 75,
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF1E1E28), borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.icon, size: 36, color: const Color(0xFF00E676)),
                    ),
                    const SizedBox(height: 8),
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                    Text(item.subtitle, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10), overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('⚡ ${dist.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(item.price, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 28,
                      decoration: BoxDecoration(color: const Color(0xFF1E1E28), borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: const Text('Direct Chat', style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- TAB 2: RADAR MAP SCREEN ----------------
class MapRadarScreen extends StatelessWidget {
  final List<GridItem> items;
  final double userLat;
  final double userLng;
  final Function(double, double, double, double) calcDistance;

  const MapRadarScreen({
    super.key,
    required this.items,
    required this.userLat,
    required this.userLng,
    required this.calcDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Radar Scope View'), backgroundColor: const Color(0xFF09090C)),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withOpacity(0.15), width: 2))),
            Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3), width: 2))),
            Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5), width: 2))),
            const CircleAvatar(radius: 8, backgroundColor: Color(0xFF00E676)),
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final offset = (idx + 1) * 35.0;
              return Positioned(
                top: 160 + (idx % 2 == 0 ? offset : -offset) * 0.6,
                left: 160 + (idx % 2 == 1 ? offset : -offset) * 0.7,
                child: Tooltip(
                  message: item.title,
                  child: const CircleAvatar(radius: 6, backgroundColor: Colors.white),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ---------------- TAB 3: DIRECT CHAT SCREEN ----------------
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peer-to-Peer Messages'), backgroundColor: const Color(0xFF09090C)),
      body: const Center(
        child: Text('No active local chats yet.\nConnect directly via listings!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// ---------------- TAB 4: PROFILE SCREEN ----------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grid Node Profile'), backgroundColor: const Color(0xFF09090C)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1E1E28), child: Icon(Icons.person, size: 40, color: Color(0xFF00E676))),
          const SizedBox(height: 12),
          const Center(child: Text('Local Provider Node', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),
          ListTile(tileColor: const Color(0xFF15151C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const Icon(Icons.verified, color: Color(0xFF00E676)), title: const Text('Verification Badge'), subtitle: const Text('Local Phone Verified')),
        ],
      ),
    );
  }
}