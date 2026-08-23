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

// ---------------- DATA MODELS ----------------
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

class ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;

  ChatMessage({required this.sender, required this.text, required this.time, required this.isMe});
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
  final Map<String, List<ChatMessage>> _chats = {};

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

    // Seed initial demo message threads
    _chats['Rohan Tech Lab'] = [
      ChatMessage(sender: 'Rohan Tech Lab', text: 'Hey! Need help setting up Linux or Python environment?', time: '10:45 AM', isMe: false),
    ];
    _chats['Verma Mobile Care'] = [
      ChatMessage(sender: 'Verma Mobile Care', text: 'Original parts available with 6 months warranty.', time: '09:12 AM', isMe: false),
    ];
  }

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

  void _openChatWith(BuildContext context, String providerName) {
    if (!_chats.containsKey(providerName)) {
      _chats[providerName] = [
        ChatMessage(sender: providerName, text: 'Hi! How can I help you today?', time: 'Just now', isMe: false),
      ];
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ActiveChatScreen(
          providerName: providerName,
          messages: _chats[providerName]!,
          onSendMessage: (msg) {
            setState(() {
              _chats[providerName]!.add(
                ChatMessage(sender: 'Me', text: msg, time: 'Just now', isMe: true),
              );
            });
          },
        ),
      ),
    );
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
        onOpenChat: (name) => _openChatWith(context, name),
      ),
      MapRadarScreen(
        items: _items,
        userLat: userLat,
        userLng: userLng,
        calcDistance: calculateDistance,
        onSelectNode: (item) => _openChatWith(context, item.title),
      ),
      ChatListScreen(
        chats: _chats,
        onOpenChat: (name) => _openChatWith(context, name),
      ),
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
  final Function(String) onOpenChat;

  const ExploreFeed({
    super.key,
    required this.items,
    required this.userLat,
    required this.userLng,
    required this.calcDistance,
    required this.onAdd,
    required this.onOpenChat,
  });

  @override
  State<ExploreFeed> createState() => _ExploreFeedState();
}

class _ExploreFeedState extends State<ExploreFeed> {
  String _activeCategory = 'All';
  String _searchQuery = '';

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
    String selectedCat = 'Tech';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15151C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('⚡ Broadcast to Radar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E676)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Listing / Service Name',
                  filled: true,
                  fillColor: const Color(0xFF1E1E28),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subCtrl,
                decoration: InputDecoration(
                  labelText: 'Description / What you offer',
                  filled: true,
                  fillColor: const Color(0xFF1E1E28),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Price (e.g. ₹200/hr, ₹50/meal)',
                  filled: true,
                  fillColor: const Color(0xFF1E1E28),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    widget.onAdd(GridItem(
                      id: DateTime.now().toString(),
                      title: titleCtrl.text,
                      subtitle: subCtrl.text.isEmpty ? 'Local Grid Resource' : subCtrl.text,
                      category: selectedCat,
                      tag: 'BROADCAST',
                      lat: widget.userLat + 0.002,
                      lng: widget.userLng + 0.002,
                      price: priceCtrl.text.isEmpty ? 'Negotiable' : priceCtrl.text,
                      rating: 5.0,
                      icon: Icons.offline_bolt,
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Broadcast Signal Live', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      final matchesCat = _activeCategory == 'All' || i.category == _activeCategory;
      final matchesSearch = i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

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
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF272732)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF00E676), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search skills, trades, rentals...',
                            hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF15151C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF272732)),
                ),
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
                    GestureDetector(
                      onTap: () => widget.onOpenChat(item.title),
                      child: Container(
                        width: double.infinity,
                        height: 28,
                        decoration: BoxDecoration(color: const Color(0xFF1E1E28), borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: const Text('Direct Chat', style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
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

// ---------------- TAB 2: ANIMATED RADAR SCOPE SCREEN ----------------
class MapRadarScreen extends StatefulWidget {
  final List<GridItem> items;
  final double userLat;
  final double userLng;
  final Function(double, double, double, double) calcDistance;
  final Function(GridItem) onSelectNode;

  const MapRadarScreen({
    super.key,
    required this.items,
    required this.userLat,
    required this.userLng,
    required this.calcDistance,
    required this.onSelectNode,
  });

  @override
  State<MapRadarScreen> createState() => _MapRadarScreenState();
}

class _MapRadarScreenState extends State<MapRadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _sweepCtrl;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Radar Scope'), backgroundColor: const Color(0xFF09090C)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withOpacity(0.15), width: 2))),
                Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3), width: 2))),
                Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5), width: 2))),
                AnimatedBuilder(
                  animation: _sweepCtrl,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _sweepCtrl.value * 2 * pi,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [Colors.transparent, const Color(0xFF00E676).withOpacity(0.3)],
                            stops: const [0.75, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const CircleAvatar(radius: 8, backgroundColor: Color(0xFF00E676)),
                ...widget.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final offset = (idx + 1) * 35.0;
                  final top = 160 + (idx % 2 == 0 ? offset : -offset) * 0.6;
                  final left = 160 + (idx % 2 == 1 ? offset : -offset) * 0.7;
                  return Positioned(
                    top: top,
                    left: left,
                    child: GestureDetector(
                      onTap: () => widget.onSelectNode(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676)),
                        child: const Icon(Icons.bolt, size: 14, color: Colors.black),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Tap any radar blip to open direct P2P chat', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ---------------- TAB 3: CONVERSATION LIST SCREEN ----------------
class ChatListScreen extends StatelessWidget {
  final Map<String, List<ChatMessage>> chats;
  final Function(String) onOpenChat;

  const ChatListScreen({super.key, required this.chats, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final keys = chats.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Peer-to-Peer Messages'), backgroundColor: const Color(0xFF09090C)),
      body: keys.isEmpty
          ? const Center(child: Text('No active local chats yet.\nConnect directly via listings!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: keys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final name = keys[index];
                final lastMsg = chats[name]!.last;
                return ListTile(
                  tileColor: const Color(0xFF15151C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1E1E28), child: Icon(Icons.person, color: Color(0xFF00E676))),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lastMsg.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                  trailing: Text(lastMsg.time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  onTap: () => onOpenChat(name),
                );
              },
            ),
    );
  }
}

// ---------------- ACTIVE CHAT SCREEN ----------------
class ActiveChatScreen extends StatefulWidget {
  final String providerName;
  final List<ChatMessage> messages;
  final Function(String) onSendMessage;

  const ActiveChatScreen({super.key, required this.providerName, required this.messages, required this.onSendMessage});

  @override
  State<ActiveChatScreen> createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends State<ActiveChatScreen> {
  final _textController = TextEditingController();

  void _send() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.providerName),
        backgroundColor: const Color(0xFF15151C),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final m = widget.messages[index];
                return Align(
                  alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isMe ? const Color(0xFF00E676) : const Color(0xFF1E1E28),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.isMe ? Colors.black : Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF121218),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type an encrypted message...',
                      filled: true,
                      fillColor: const Color(0xFF1E1E28),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00E676)),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
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
          ListTile(
            tileColor: const Color(0xFF15151C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.verified, color: Color(0xFF00E676)),
            title: const Text('Verification Badge'),
            subtitle: const Text('Local Phone Verified'),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF15151C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.security, color: Color(0xFF00E676)),
            title: const Text('Offline Storage Mode'),
            subtitle: const Text('P2P Local Encryption Enabled'),
          ),
        ],
      ),
    );
  }
}