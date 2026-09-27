import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
        scaffoldBackgroundColor: const Color(0xFF09090D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF14141C),
        ),
      ),
      home: const MainRadarShell(),
    );
  }
}

// ---------------- DATA MODELS ----------------
enum ListingType { offer, need, bounty, tool }

class GridListing {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String tag;
  final String iconEmoji;
  final double rating;
  final int reviewsCount;
  final String eta;
  final double distanceKm;
  final String price;
  final String bio;
  final String phone;
  final String sector;
  final ListingType type;
  final bool isVerified;
  final String paymentTag;
  final String statusText;
  bool isFavorite;

  GridListing({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.tag,
    required this.iconEmoji,
    required this.rating,
    required this.reviewsCount,
    required this.eta,
    required this.distanceKm,
    required this.price,
    required this.bio,
    required this.phone,
    required this.sector,
    this.type = ListingType.offer,
    this.isVerified = true,
    this.paymentTag = '📱 UPI / Cash',
    this.statusText = '🟢 Active Now',
    this.isFavorite = false,
  });
}

class ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final bool isSlotRequest;
  final bool isUpiRequest;
  final bool isPinVerified;
  final String? upiAmount;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.isSlotRequest = false,
    this.isUpiRequest = false,
    this.isPinVerified = false,
    this.upiAmount,
  });
}

// ---------------- ROOT MOBILE CONTAINER ----------------
class MainRadarShell extends StatefulWidget {
  const MainRadarShell({super.key});

  @override
  State<MainRadarShell> createState() => _MainRadarShellState();
}

class _MainRadarShellState extends State<MainRadarShell> {
  int _currentIndex = 0;
  String _activeLocationName = 'Home (Sector 14)';
  double _radarRadius = 3.0;
  bool _simpleMode = false;
  bool _showNeedsOnly = false;
  bool _lateNightSOS = false;

  late List<GridListing> _listings;
  final Map<String, List<ChatMessage>> _chats = {};
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _listings = [
      GridListing(
        id: '1',
        title: 'Rohan Tech Lab',
        subtitle: 'Laptop OS, Linux & Python Fix',
        category: 'Tech & Fix',
        tag: 'FREE CONSULT',
        iconEmoji: '💻',
        rating: 4.9,
        reviewsCount: 34,
        eta: '10-15 mins',
        distanceKm: 0.4,
        price: '₹150/hr',
        bio: 'On-spot Linux setup, Windows recovery, and Python bug fixing within the walking block. 50+ students helped.',
        phone: '+91 98765 43210',
        sector: 'Walking Block A',
        type: ListingType.offer,
        statusText: '🟢 Responding in 2m',
      ),
      GridListing(
        id: '2',
        title: 'Amit Mobile Care',
        subtitle: 'Screen & Battery Repair',
        category: 'Repairs',
        tag: 'SAME DAY FIX',
        iconEmoji: '📱',
        rating: 4.8,
        reviewsCount: 89,
        eta: '20-25 mins',
        distanceKm: 0.9,
        price: 'From ₹200',
        bio: 'Original display replacements, battery swaps, and water damage recovery done in front of you.',
        phone: '+91 98111 22334',
        sector: 'Main Market Block',
        type: ListingType.offer,
      ),
      GridListing(
        id: '3',
        title: 'Campus Notes & Printout SOS',
        subtitle: 'Need 15-page color printout',
        category: 'Bounty',
        tag: 'BOUNTY ₹80',
        iconEmoji: '🖨️',
        rating: 5.0,
        reviewsCount: 14,
        eta: 'Urgent',
        distanceKm: 0.6,
        price: '₹80 Bounty',
        bio: 'Need urgent color prints for tomorrow morning submission. Will collect from your hostel/block.',
        phone: '+91 98999 11223',
        sector: 'Hostel Block 3',
        type: ListingType.need,
      ),
      GridListing(
        id: '4',
        title: 'Bosch Impact Drill & Kit',
        subtitle: '1-Day Home Tool Lending',
        category: 'Tool Depot',
        tag: 'RENT / BORROW',
        iconEmoji: '🛠️',
        rating: 4.9,
        reviewsCount: 28,
        eta: 'Available',
        distanceKm: 1.1,
        price: '₹50/day',
        bio: 'Complete drilling kit with wall plugs and bits. Clean condition, pickup from Sector 14 Gate 2.',
        phone: '+91 97777 88990',
        sector: 'Pocket C Sector 14',
        type: ListingType.tool,
      ),
      GridListing(
        id: '5',
        title: 'Priya Bakes',
        subtitle: 'Custom Cakes & Pastries',
        category: 'Home Food',
        tag: 'FRESH BATCH',
        iconEmoji: '🍰',
        rating: 5.0,
        reviewsCount: 42,
        eta: '30 mins',
        distanceKm: 1.2,
        price: '₹80/piece',
        bio: 'Fresh eggless pastries, tea cakes, and custom party cakes baked with organic ingredients.',
        phone: '+91 99223 34455',
        sector: 'Sector 14 Pocket B',
        type: ListingType.offer,
      ),
      GridListing(
        id: '6',
        title: 'Vikram 4K Drone & Gimbal',
        subtitle: 'Sony Cam & Gimbal Kit Loan',
        category: 'Tool Depot',
        tag: 'CITY RING',
        iconEmoji: '📷',
        rating: 4.9,
        reviewsCount: 57,
        eta: '15 min drive',
        distanceKm: 6.4,
        price: '₹500/day',
        bio: 'Rent verified camera rigs, wireless mics, and travel gimbals across the city perimeter.',
        phone: '+91 96555 44332',
        sector: 'Tech Hub Sector 62',
        type: ListingType.tool,
      ),
      GridListing(
        id: '7',
        title: 'Cyber Hub Carpool',
        subtitle: '2 Seats Free • Mon-Fri 8:30 AM',
        category: 'Tech & Fix',
        tag: 'CARPOOL',
        iconEmoji: '🚗',
        rating: 5.0,
        reviewsCount: 22,
        eta: 'Daily',
        distanceKm: 8.5,
        price: '₹120/seat',
        bio: 'Comfortable AC sedan ride share for office goers traveling toward Cyber Hub.',
        phone: '+91 95444 33221',
        sector: 'Expressway Corridor',
        type: ListingType.offer,
      ),
    ];

    _chats['Rohan Tech Lab'] = [
      ChatMessage(sender: 'Rohan Tech Lab', text: 'Hey neighbor! Need help with your OS or code debugging?', time: '10:45 AM', isMe: false),
    ];
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _addListing(GridListing listing) {
    setState(() {
      _listings.insert(0, listing);
    });
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
  }

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📍 Switch Neighborhood Radar Grid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            ListTile(
              tileColor: const Color(0xFF1B1B26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.my_location, color: Color(0xFF00E676)),
              title: const Text('📍 Current Live GPS (Home)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Active Sector 14 Perimeter (Fuzzy Offset Active)', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
              onTap: () {
                setState(() => _activeLocationName = 'Home (Sector 14)');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1B1B26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.school, color: Color(0xFF00E676)),
              title: const Text('🎓 Campus & Student Grid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Hostels, Tech Labs, Gaming Rooms & Canteen', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
              onTap: () {
                setState(() => _activeLocationName = 'University Campus Grid');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1B1B26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.apartment, color: Color(0xFF00E676)),
              title: const Text('💼 Cyber City & Office Hub', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Carpools, WFH Hardware SOS & Coworking', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
              onTap: () {
                setState(() => _activeLocationName = 'Cyber Hub Grid');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, String providerName) {
    if (!_chats.containsKey(providerName)) {
      _chats[providerName] = [
        ChatMessage(sender: providerName, text: 'Hi! How can I help you today in the local grid?', time: 'Just now', isMe: false),
      ];
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ActiveChatScreen(
          providerName: providerName,
          messages: _chats[providerName]!,
          onSendMessage: (msg, {bool isSlot = false, bool isUpi = false, bool isPin = false, String? amount}) {
            setState(() {
              _chats[providerName]!.add(
                ChatMessage(
                  sender: 'Me',
                  text: msg,
                  time: 'Just now',
                  isMe: true,
                  isSlotRequest: isSlot,
                  isUpiRequest: isUpi,
                  isPinVerified: isPin,
                  upiAmount: amount,
                ),
              );
            });
          },
        ),
      ),
    );
  }

  void _showListingDetails(BuildContext context, GridListing item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF2B2B38), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: const Color(0xFF1C1C28), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2B2B3C))),
                    alignment: Alignment.center,
                    child: Text(item.iconEmoji, style: const TextStyle(fontSize: 38)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            GestureDetector(
                              onTap: () {
                                _toggleBookmark(item.id);
                                setSheetState(() {});
                              },
                              child: Icon(
                                _bookmarkedIds.contains(item.id) ? Icons.bookmark : Icons.bookmark_border,
                                color: _bookmarkedIds.contains(item.id) ? const Color(0xFF00E676) : const Color(0xFF71717A),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('${item.subtitle} • ${item.sector}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(6)),
                              child: Text('★ ${item.rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Text('(${item.reviewsCount} reviews)', style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                            const Spacer(),
                            Text(item.price, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Audio Assist Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Color(0xFF00E676), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('🔊 Audio Assist: Tap to read description aloud', style: TextStyle(fontSize: 11, color: Colors.white70))),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reading out: ${item.title}, ${item.price}, ${item.distanceKm} km away.')),
                        );
                      },
                      child: const Text('Listen', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('ABOUT NEIGHBORHOOD SERVICE', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text(item.bio, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROXIMITY & PRIVACY', style: TextStyle(color: Color(0xFF71717A), fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('⚡ ${item.distanceKm.toStringAsFixed(1)} km (Fuzzy GPS)', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAYMENT & STATUS', style: TextStyle(color: Color(0xFF71717A), fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(item.paymentTag, style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2B2B3C))),
                    child: IconButton(
                      icon: const Icon(Icons.call, color: Color(0xFF00E676), size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dialing ${item.title} (${item.phone})...')));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openChat(context, item.title);
                      },
                      child: const Text('Open Direct Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExploreFeedScreen(
        listings: _listings,
        activeLocation: _activeLocationName,
        radarRadius: _radarRadius,
        simpleMode: _simpleMode,
        showNeedsOnly: _showNeedsOnly,
        lateNightSOS: _lateNightSOS,
        bookmarkedIds: _bookmarkedIds,
        onRadiusChanged: (r) => setState(() => _radarRadius = r),
        onToggleSimpleMode: () => setState(() => _simpleMode = !_simpleMode),
        onToggleNeeds: (val) => setState(() => _showNeedsOnly = val),
        onToggleNightSOS: (val) => setState(() => _lateNightSOS = val),
        onOpenLocationSelector: _openLocationSelector,
        onAddListing: _addListing,
        onOpenChat: (name) => _openChat(context, name),
        onTapCard: (item) => _showListingDetails(context, item),
      ),
      MapRadarScreen(
        listings: _listings,
        radarRadius: _radarRadius,
        onSelectListing: (listing) => _showListingDetails(context, listing),
      ),
      ChatListScreen(
        chats: _chats,
        onOpenChat: (name) => _openChat(context, name),
      ),
      ProfileScreen(listingsCount: _listings.length),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: const Color(0xFF09090D),
            border: Border.symmetric(vertical: BorderSide(color: const Color(0xFF232330).withValues(alpha: 0.4))),
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFF09090D),
            body: screens[_currentIndex],
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1B1B26), width: 1))),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (idx) => setState(() => _currentIndex = idx),
                backgroundColor: const Color(0xFF0D0D12),
                selectedItemColor: const Color(0xFF00E676),
                unselectedItemColor: const Color(0xFF71717A),
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Explore'),
                  BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar Map'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- TAB 1: EXPLORE FEED WITH COMPLETE FEATURE ENGINE ----------------
class ExploreFeedScreen extends StatefulWidget {
  final List<GridListing> listings;
  final String activeLocation;
  final double radarRadius;
  final bool simpleMode;
  final bool showNeedsOnly;
  final bool lateNightSOS;
  final Set<String> bookmarkedIds;
  final Function(double) onRadiusChanged;
  final VoidCallback onToggleSimpleMode;
  final Function(bool) onToggleNeeds;
  final Function(bool) onToggleNightSOS;
  final VoidCallback onOpenLocationSelector;
  final Function(GridListing) onAddListing;
  final Function(String) onOpenChat;
  final Function(GridListing) onTapCard;

  const ExploreFeedScreen({
    super.key,
    required this.listings,
    required this.activeLocation,
    required this.radarRadius,
    required this.simpleMode,
    required this.showNeedsOnly,
    required this.lateNightSOS,
    required this.bookmarkedIds,
    required this.onRadiusChanged,
    required this.onToggleSimpleMode,
    required this.onToggleNeeds,
    required this.onToggleNightSOS,
    required this.onOpenLocationSelector,
    required this.onAddListing,
    required this.onOpenChat,
    required this.onTapCard,
  });

  @override
  State<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends State<ExploreFeedScreen> {
  int _selectedCat = 0;
  String _searchQuery = '';

  final List<Map<String, String>> categories = [
    {'name': 'All', 'emoji': '⚡'},
    {'name': 'Tech & Fix', 'emoji': '💻'},
    {'name': 'Bounty', 'emoji': '💸'},
    {'name': 'Tool Depot', 'emoji': '🛠️'},
    {'name': 'Home Food', 'emoji': '🍲'},
    {'name': 'Repairs', 'emoji': '📱'},
  ];

  final List<Map<String, dynamic>> radiusTiers = [
    {'label': '📍 Walking (1 km)', 'radius': 1.0},
    {'label': '🚲 Sector / Campus (3 km)', 'radius': 3.0},
    {'label': '🚗 City Scope (15 km)', 'radius': 15.0},
  ];

  void _openBroadcastModal() {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    ListingType selectedType = ListingType.offer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('⚡ Broadcast Signal to Radar Grid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E676)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Offering Skill/Service', style: TextStyle(fontSize: 11)),
                    selected: selectedType == ListingType.offer,
                    onSelected: (val) => setModalState(() => selectedType = ListingType.offer),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Community Need / Bounty', style: TextStyle(fontSize: 11)),
                    selected: selectedType == ListingType.need,
                    onSelected: (val) => setModalState(() => selectedType = ListingType.need),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title (e.g. Spare 65W Charger, Python Tutor)',
                  filled: true,
                  fillColor: const Color(0xFF1B1B26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subCtrl,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subtitle / Sector Details',
                  filled: true,
                  fillColor: const Color(0xFF1B1B26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Price / Bounty (e.g. ₹100, Free, Mutual)',
                  filled: true,
                  fillColor: const Color(0xFF1B1B26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    widget.onAddListing(GridListing(
                      id: DateTime.now().toString(),
                      title: titleCtrl.text,
                      subtitle: subCtrl.text.isEmpty ? 'Available in Local Grid' : subCtrl.text,
                      category: selectedType == ListingType.need ? 'Bounty' : 'Tech & Fix',
                      tag: selectedType == ListingType.need ? 'BOUNTY' : 'NEW SIGNAL',
                      iconEmoji: selectedType == ListingType.need ? '💸' : '⚡',
                      rating: 5.0,
                      reviewsCount: 1,
                      eta: 'Available Now',
                      distanceKm: 0.2,
                      price: priceCtrl.text.isEmpty ? 'Free' : priceCtrl.text,
                      bio: 'Newly registered listing broadcast across the neighborhood scope.',
                      phone: '+91 90000 00000',
                      sector: 'Immediate Sector',
                      type: selectedType,
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Post Signal to Grid', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final withinRange = widget.listings.where((item) {
      final matchesCategory = _selectedCat == 0 || item.category == categories[_selectedCat]['name'];
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRange = item.distanceKm <= widget.radarRadius;
      final matchesType = widget.showNeedsOnly ? (item.type == ListingType.need) : true;
      return matchesCategory && matchesSearch && matchesRange && matchesType;
    }).toList();

    final outsideRange = widget.listings.where((item) {
      final matchesCategory = _selectedCat == 0 || item.category == categories[_selectedCat]['name'];
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final isOutside = item.distanceKm > widget.radarRadius;
      return matchesCategory && matchesSearch && isOutside;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Top Bar with Location, Simple Mode & Active Count
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onOpenLocationSelector,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📍', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(widget.activeLocation, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          ),
                          const SizedBox(width: 4),
                          const Text('▼', style: TextStyle(fontSize: 10, color: Color(0xFF00E676))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Active Perimeter: ${widget.radarRadius.toStringAsFixed(0)} km (Fuzzy GPS)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(widget.simpleMode ? Icons.view_agenda : Icons.grid_view, color: const Color(0xFF00E676), size: 20),
                    tooltip: 'Toggle Simple Mode',
                    onPressed: widget.onToggleSimpleMode,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2417),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF00E676)),
                        const SizedBox(width: 5),
                        Text('${withinRange.length} NODES', style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Master Switcher: Offerings vs Community Needs & SOS
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onToggleNeeds(false),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !widget.showNeedsOnly ? const Color(0xFF00E676) : const Color(0xFF14141C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('⚡ Offerings', style: TextStyle(color: !widget.showNeedsOnly ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onToggleNeeds(true),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.showNeedsOnly ? const Color(0xFF00E676) : const Color(0xFF14141C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('💸 Needs & Bounties', style: TextStyle(color: widget.showNeedsOnly ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('WhatsApp Society Invite Card Copied to Clipboard!')),
                  );
                },
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.share, color: Color(0xFF00E676), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field + Broadcast Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF22222E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF71717A), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Search 'drone', 'drill', 'tutor'...",
                            hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openBroadcastModal,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add, color: Colors.black, size: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Macro-Zoom Radius Tiers
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: radiusTiers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tier = radiusTiers[index];
                final isSelected = widget.radarRadius == tier['radius'];
                return GestureDetector(
                  onTap: () => widget.onRadiusChanged(tier['radius']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0E2719) : const Color(0xFF14141C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? const Color(0xFF00E676) : const Color(0xFF22222E)),
                    ),
                    child: Text(
                      tier['label'],
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00E676) : const Color(0xFFA1A1AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Categories Bar
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCat == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCat = index),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF00E676) : const Color(0xFF171720),
                          border: Border.all(color: isSelected ? const Color(0xFF00E676) : const Color(0xFF242432)),
                        ),
                        alignment: Alignment.center,
                        child: Text(cat['emoji']!, style: TextStyle(fontSize: 20, color: isSelected ? Colors.black : Colors.white)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF8E8E9A),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Spotlight of the Week Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10281C), Color(0xFF14141C)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: Color(0xFF00E676), child: Text('🌟', style: TextStyle(fontSize: 18))),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SPOTLIGHT OF THE WEEK', style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      SizedBox(height: 2),
                      Text('Rohan fixed 18 student laptops during exams!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Active Listings Section
          Text(
            'WITHIN YOUR ${widget.radarRadius.toStringAsFixed(0)} KM SCOPE',
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),

          if (withinRange.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF22222E))),
              child: Column(
                children: [
                  const Text('No direct nodes found within this radius.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                    onPressed: () => widget.onRadiusChanged(15.0),
                    child: const Text('Expand Radar Scope to City (15 km)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            )
          else if (widget.simpleMode)
            // Accessible 1-Column View for Seniors/First-Time Users
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: withinRange.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = withinRange[index];
                return ListTile(
                  tileColor: const Color(0xFF14141C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: Text(item.iconEmoji, style: const TextStyle(fontSize: 32)),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${item.subtitle} • ${item.distanceKm} km', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  trailing: Text(item.price, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                  onTap: () => widget.onTapCard(item),
                );
              },
            )
          else
            // Standard Bento Grid Layout
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: withinRange.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.67,
              ),
              itemBuilder: (context, index) {
                final item = withinRange[index];
                return InteractiveCardItem(
                  item: item,
                  onTap: () => widget.onTapCard(item),
                  onChat: () => widget.onOpenChat(item.title),
                );
              },
            ),

          // Macro-Zoom Surrounding Rings
          if (outsideRange.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SURROUNDING SECTORS & CITY SCOPE', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                GestureDetector(
                  onTap: () => widget.onRadiusChanged(15.0),
                  child: const Text('Expand >', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...outsideRange.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF22222E))),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(item.iconEmoji, style: const TextStyle(fontSize: 22)),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                subtitle: Text('${item.sector} • ⚡ ${item.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B1B26), elevation: 0),
                  onPressed: () => widget.onTapCard(item),
                  child: const Text('View', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ---------------- INTERACTIVE CARD ITEM WITH TACTILE BOUNCE ----------------
class InteractiveCardItem extends StatefulWidget {
  final GridListing item;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const InteractiveCardItem({super.key, required this.item, required this.onTap, required this.onChat});

  @override
  State<InteractiveCardItem> createState() => _InteractiveCardItemState();
}

class _InteractiveCardItemState extends State<InteractiveCardItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF14141C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF22222E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF09090D), borderRadius: BorderRadius.circular(6)),
                child: Text(item.tag, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(child: Text(item.iconEmoji, style: const TextStyle(fontSize: 44))),
                    Positioned(
                      bottom: 2,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(6)),
                        child: Text('★ ${item.rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(item.subtitle, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('⚡ ${item.eta}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  Text('${item.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: widget.onChat,
                child: Container(
                  height: 32,
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Text('Chat Now', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- TAB 2: ANIMATED RADAR SCOPE SCREEN ----------------
class MapRadarScreen extends StatefulWidget {
  final List<GridListing> listings;
  final double radarRadius;
  final Function(GridListing) onSelectListing;

  const MapRadarScreen({super.key, required this.listings, required this.radarRadius, required this.onSelectListing});

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
    final activeInRadar = widget.listings.where((l) => l.distanceKm <= widget.radarRadius).toList();

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('RADAR CONCENTRIC SCOPE (${widget.radarRadius.toStringAsFixed(0)} KM)', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.15), width: 1.5))),
                Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3), width: 1.5))),
                Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1.5))),
                AnimatedBuilder(
                  animation: _sweepCtrl,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _sweepCtrl.value * 2 * pi,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [Colors.transparent, const Color(0xFF00E676).withValues(alpha: 0.35)],
                            stops: const [0.75, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const CircleAvatar(radius: 8, backgroundColor: Color(0xFF00E676)),
                ...activeInRadar.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final offset = (idx + 1) * 36.0;
                  final top = 150 + (idx % 2 == 0 ? offset : -offset) * 0.55;
                  final left = 150 + (idx % 2 == 1 ? offset : -offset) * 0.65;
                  return Positioned(
                    top: top,
                    left: left,
                    child: GestureDetector(
                      onTap: () => widget.onSelectListing(item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF14141C), border: Border.all(color: const Color(0xFF00E676), width: 1.5)),
                        child: Text(item.iconEmoji, style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            Text('${activeInRadar.length} active neighborhood nodes inside current scope', style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ---------------- TAB 3: CONVERSATION LIST ----------------
class ChatListScreen extends StatelessWidget {
  final Map<String, List<ChatMessage>> chats;
  final Function(String) onOpenChat;

  const ChatListScreen({super.key, required this.chats, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final keys = chats.keys.toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('DIRECT NEIGHBOR CHATS', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (keys.isEmpty)
            const Center(child: Text('No active chats. Connect with a neighbor on Explore!', style: TextStyle(color: Colors.grey)))
          else
            ...keys.map((name) {
              final lastMsg = chats[name]!.last;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF22222E))),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1B1B26), child: Icon(Icons.person, color: Color(0xFF00E676))),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  subtitle: Text(lastMsg.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                  trailing: Text(lastMsg.time, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                  onTap: () => onOpenChat(name),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ---------------- ACTIVE CHAT SCREEN WITH UPI, PIN & FAST SLOTS ----------------
class ActiveChatScreen extends StatefulWidget {
  final String providerName;
  final List<ChatMessage> messages;
  final Function(String, {bool isSlot, bool isUpi, bool isPin, String? amount}) onSendMessage;

  const ActiveChatScreen({
    super.key,
    required this.providerName,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  State<ActiveChatScreen> createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends State<ActiveChatScreen> {
  final _textController = TextEditingController();

  final List<String> quickPrompts = [
    'Is this available right now?',
    'Can you do today evening?',
    'What is your exact location?',
    'Can we negotiate the price?',
  ];

  void _send(String text, {bool isSlot = false, bool isUpi = false, bool isPin = false, String? amount}) {
    if (text.trim().isNotEmpty) {
      widget.onSendMessage(text.trim(), isSlot: isSlot, isUpi: isUpi, isPin: isPin, amount: amount);
      _textController.clear();
      setState(() {});
    }
  }

  void _openSlotScheduler() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📅 Propose Fast Neighborhood Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            ListTile(
              tileColor: const Color(0xFF1B1B26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.bolt, color: Color(0xFF00E676)),
              title: const Text('⚡ Within 30 Mins (Urgent Walk-in)', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                _send('⚡ [Slot Proposed]: Can we connect within 30 mins?', isSlot: true);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1B1B26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.wb_twilight, color: Color(0xFF00E676)),
              title: const Text('🌅 Today Evening (5:00 PM - 8:00 PM)', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                _send('📅 [Slot Proposed]: Today evening between 5 - 8 PM', isSlot: true);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1B1B26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.pin, color: Color(0xFF00E676)),
              title: const Text('🤝 Generate 4-Digit Handshake PIN', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Exchange in person to verify trade completion', style: TextStyle(fontSize: 11, color: Colors.white60)),
              onTap: () {
                Navigator.pop(ctx);
                final randomPin = 1000 + Random().nextInt(9000);
                _send('🤝 [Handshake PIN Generated]: $randomPin. Share with neighbor upon completion.', isPin: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openUpiRequestModal() {
    final upiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        title: const Text('💰 Request Direct UPI Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: upiCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Enter Amount in ₹',
            filled: true,
            fillColor: const Color(0xFF1B1B26),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () {
              if (upiCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                _send('💳 [UPI Payment Request]: ₹${upiCtrl.text} via GPay/PhonePe', isUpi: true, amount: upiCtrl.text);
              }
            },
            child: const Text('Send Chip', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      appBar: AppBar(
        title: Text(widget.providerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14141C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_rupee, color: Color(0xFF00E676), size: 20),
            tooltip: 'Request UPI Payment',
            onPressed: _openUpiRequestModal,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF00E676), size: 20),
            tooltip: 'Slot & PIN',
            onPressed: _openSlotScheduler,
          ),
        ],
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
                      color: m.isUpiRequest
                          ? const Color(0xFF0E2719)
                          : (m.isSlotRequest || m.isPinVerified
                              ? const Color(0xFF1B1B26)
                              : (m.isMe ? const Color(0xFF00E676) : const Color(0xFF1B1B26))),
                      borderRadius: BorderRadius.circular(14),
                      border: (m.isUpiRequest || m.isSlotRequest || m.isPinVerified) ? Border.all(color: const Color(0xFF00E676)) : null,
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: (m.isUpiRequest || m.isSlotRequest || m.isPinVerified)
                            ? const Color(0xFF00E676)
                            : (m.isMe ? Colors.black : Colors.white),
                        fontSize: 13,
                        fontWeight: (m.isUpiRequest || m.isSlotRequest || m.isPinVerified) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = quickPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 11, color: Color(0xFF00E676))),
                  backgroundColor: const Color(0xFF10281C),
                  side: const BorderSide(color: Color(0xFF00E676), width: 0.5),
                  onPressed: () => _send(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF14141C),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1B1B26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF00E676)), onPressed: () => _send(_textController.text)),
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
  final int listingsCount;

  const ProfileScreen({super.key, required this.listingsCount});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Color(0xFF14141C), child: Icon(Icons.person, size: 40, color: Color(0xFF00E676))),
          const SizedBox(height: 12),
          const Center(child: Text('Local Community Node', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
          const SizedBox(height: 4),
          Center(child: Text('$listingsCount Active Listings Synced Across Radar Scope', style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)))),
          const SizedBox(height: 24),
          ListTile(
            tileColor: const Color(0xFF14141C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.verified_user, color: Color(0xFF00E676)),
            title: const Text('Verified Resident Node', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Fuzzy GPS & 4-Digit Handshake PIN Active', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFF14141C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF00E676)),
            title: const Text('Side-Income Dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Earned ₹1,850 helping 6 neighbors this month', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
          ),
        ],
      ),
    );
  }
}
