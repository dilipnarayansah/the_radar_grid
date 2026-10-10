import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'package:the_radar_grid/models/listing.dart';
import 'package:the_radar_grid/models/chat.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_radar_grid/services/media_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RadarGridApp());
}

class RadarGridApp extends StatelessWidget {
  const RadarGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Radar Grid - Wave 3 Enterprise',
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

  User? _firebaseUser;
  final Set<String> _bookmarkedIds = {};
  final Set<String> _blockedUserIds = {};
  final Map<String, List<ChatMessage>> _chats = {};
  String? _errorMessage;

  final List<GridListing> _defaultListings = [
    GridListing(
      id: '1',
      title: 'Rohan Tech Lab',
      subtitle: 'Laptop OS, Linux & Python Fix',
      category: 'Tech',
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
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      authorId: 'rohan_123',
      conditionTag: 'Refurbished',
      isVerified: true,
      imageUrls: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500'],
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
      latitude: 28.6150,
      longitude: 77.2100,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      authorId: 'amit_456',
      conditionTag: 'New',
      isVerified: true,
      imageUrls: ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500'],
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
      latitude: 28.6120,
      longitude: 77.2080,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      authorId: 'student_789',
      conditionTag: 'Used',
      isVerified: false,
    ),
    GridListing(
      id: '4',
      title: 'Bosch Impact Drill & Kit',
      subtitle: '1-Day Home Tool Lending',
      category: 'Tools',
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
      latitude: 28.6160,
      longitude: 77.2120,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      authorId: 'tool_depot',
      conditionTag: 'Used',
      isVerified: true,
      imageUrls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500'],
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
      latitude: 28.6110,
      longitude: 77.2070,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      authorId: 'priya_bakes',
      conditionTag: 'New',
      isVerified: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseUser = FirebaseAuth.instance.currentUser;
        if (_firebaseUser == null) {
          UserCredential cred = await FirebaseAuth.instance.signInAnonymously();
          _firebaseUser = cred.user;
        }
      }
    } catch (e) {
      debugPrint('Auth initialization warning: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('Location permission warning: $e');
    }
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

  void _blockUser(String? authorId) {
    if (authorId != null) {
      setState(() {
        _blockedUserIds.add(authorId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked successfully. Listings hidden.')),
      );
    }
  }

  void _reportListing(BuildContext context, GridListing item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        title: const Text('🚨 Report Listing', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Select reason for reporting this commercial node:', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing reported to moderators.')));
            },
            child: const Text('Spam or Misleading', style: TextStyle(color: Color(0xFF00E676))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing reported to moderators.')));
            },
            child: const Text('Prohibited Item', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
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
                    child: item.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(item.imageUrls.first, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(item.iconEmoji, style: const TextStyle(fontSize: 32))),
                          )
                        : Text(item.iconEmoji, style: const TextStyle(fontSize: 38)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(child: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  if (item.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: Color(0xFF00E676), size: 16),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Color(0xFF71717A), size: 20),
                              color: const Color(0xFF1B1B26),
                              onSelected: (val) {
                                Navigator.pop(ctx);
                                if (val == 'report') {
                                  _reportListing(context, item);
                                } else if (val == 'block') {
                                  _blockUser(item.authorId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'report', child: Text('🚨 Report Listing', style: TextStyle(fontSize: 12, color: Colors.white))),
                                const PopupMenuItem(value: 'block', child: Text('🚫 Block User', style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text('${item.subtitle} • ${item.sector}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(4)),
                              child: Text(item.conditionTag, style: const TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
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
              // Safety Meetup Tip Card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF10281C), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3))),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: Color(0xFF00E676), size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('🛡️ Safety Tip: Meet in well-lit public zones (Sector Gate, Canteen) and verify item before paying.', style: TextStyle(fontSize: 11, color: Colors.white70))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('ABOUT COMMERCIAL NODE', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text(item.bio, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              const SizedBox(height: 14),
              // GPS Coordinates & Distance Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📍 SPATIAL PROXIMITY & METADATA', style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.latitude != null && item.longitude != null
                              ? 'Lat: ${item.latitude!.toStringAsFixed(4)}, Lng: ${item.longitude!.toStringAsFixed(4)}'
                              : 'Sector 14 (Fuzzy Offset Active)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '${item.distanceKm.toStringAsFixed(1)} km away',
                          style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2B2B3C))),
                    child: IconButton(
                      icon: Icon(_bookmarkedIds.contains(item.id) ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFF00E676), size: 20),
                      tooltip: 'Bookmark Listing',
                      onPressed: () {
                        _toggleBookmark(item.id);
                        setSheetState(() {});
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
                      child: const Text('Contact Seller / Inquiry Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Firebase.apps.isNotEmpty
          ? FirebaseFirestore.instance.collection('listings').orderBy('timestamp', descending: true).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        List<GridListing> listings = [];
        try {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            listings = snapshot.data!.docs.map(GridListing.fromFirestore).toList();
          } else {
            listings = _defaultListings;
          }
        } catch (e) {
          debugPrint('Error parsing Firestore snapshot: $e');
          listings = _defaultListings;
          _errorMessage = 'Network sync warning: displaying local cache.';
        }

        // Filter out blocked users & prune out-of-bounds listings dynamically
        listings = listings.where((l) => !(_blockedUserIds.contains(l.authorId)) && l.distanceKm <= _radarRadius).toList();

        final screens = [
          ExploreFeedScreen(
            listings: listings,
            activeLocation: _activeLocationName,
            radarRadius: _radarRadius,
            simpleMode: _simpleMode,
            showNeedsOnly: _showNeedsOnly,
            lateNightSOS: _lateNightSOS,
            bookmarkedIds: _bookmarkedIds,
            currentUser: _firebaseUser,
            errorMessage: _errorMessage,
            onRadiusChanged: (r) => setState(() => _radarRadius = r),
            onToggleSimpleMode: () => setState(() => _simpleMode = !_simpleMode),
            onToggleNeeds: (val) => setState(() => _showNeedsOnly = val),
            onToggleNightSOS: (val) => setState(() => _lateNightSOS = val),
            onOpenLocationSelector: _openLocationSelector,
            onOpenChat: (name) => _openChat(context, name),
            onTapCard: (item) => _showListingDetails(context, item),
          ),
          MapRadarView(
            listings: listings,
            radarRadius: _radarRadius,
            onSelectListing: (listing) => _showListingDetails(context, listing),
          ),
          ChatListScreen(
            chats: _chats,
            onOpenChat: (name) => _openChat(context, name),
          ),
          ProfileScreen(
            user: _firebaseUser,
            listings: listings,
            onAuthChanged: () => setState(() {}),
          ),
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
      },
    );
  }
}

// ---------------- TAB 1: EXPLORE FEED ----------------
class ExploreFeedScreen extends StatefulWidget {
  final List<GridListing> listings;
  final String activeLocation;
  final double radarRadius;
  final bool simpleMode;
  final bool showNeedsOnly;
  final bool lateNightSOS;
  final Set<String> bookmarkedIds;
  final User? currentUser;
  final String? errorMessage;
  final Function(double) onRadiusChanged;
  final VoidCallback onToggleSimpleMode;
  final Function(bool) onToggleNeeds;
  final Function(bool) onToggleNightSOS;
  final VoidCallback onOpenLocationSelector;
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
    required this.currentUser,
    required this.errorMessage,
    required this.onRadiusChanged,
    required this.onToggleSimpleMode,
    required this.onToggleNeeds,
    required this.onToggleNightSOS,
    required this.onOpenLocationSelector,
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
    {'name': 'Tech', 'emoji': '💻'},
    {'name': 'Tools', 'emoji': '🛠️'},
    {'name': 'Vehicles', 'emoji': '🚗'},
    {'name': 'Services', 'emoji': '🔧'},
    {'name': 'Bounty', 'emoji': '💸'},
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
    String selectedCat = 'Tech';
    String conditionTag = 'Used';
    bool isVerified = true;
    bool isBoosted = false;
    bool isSaving = false;
    String? modalError;
    String? pickedImagePath;

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
                  Text('⚡ Broadcast Enterprise Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF00E676)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Offering Listing', style: TextStyle(fontSize: 11)),
                    selected: selectedType == ListingType.offer,
                    onSelected: (val) => setModalState(() => selectedType = ListingType.offer),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Community Need / Bounty', style: TextStyle(fontSize: 11)),
                    selected: selectedType == ListingType.need,
                    onSelected: (val) {
                      setModalState(() {
                        selectedType = ListingType.need;
                        selectedCat = 'Bounty';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      dropdownColor: const Color(0xFF1B1B26),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: const Color(0xFF1B1B26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Tech', 'Tools', 'Vehicles', 'Services', 'Bounty', 'Home Food', 'Repairs']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCat = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: conditionTag,
                      dropdownColor: const Color(0xFF1B1B26),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Condition',
                        filled: true,
                        fillColor: const Color(0xFF1B1B26),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['New', 'Used', 'Refurbished']
                          .map((cond) => DropdownMenuItem(value: cond, child: Text(cond)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => conditionTag = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title * (e.g. Sony 4K Camera Rig)',
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
                  labelText: 'Price / Bounty * (e.g. ₹500, Free)',
                  filled: true,
                  fillColor: const Color(0xFF1B1B26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00E676),
                  side: const BorderSide(color: Color(0xFF00E676)),
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.cloud_upload, size: 16),
                label: Text(pickedImagePath != null ? '✅ Image Uploaded via Cloudinary CDN' : '☁️ Upload Photo to Free Cloudinary CDN'),
                onPressed: () async {
                  try {
                    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() => isSaving = true);
                      final secureUrl = await MediaService.uploadImage(image.path);
                      setModalState(() {
                        pickedImagePath = secureUrl;
                        isSaving = false;
                      });
                    }
                  } catch (e) {
                    debugPrint('Media upload error: $e');
                    setModalState(() => isSaving = false);
                  }
                },
              ),
              if (modalError != null) ...[
                const SizedBox(height: 8),
                Text(modalError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('🛡️ Verified Commercial Badge', style: TextStyle(fontSize: 13, color: Colors.white)),
                subtitle: const Text('Display blue verified checkmark', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                value: isVerified,
                activeThumbColor: const Color(0xFF00E676),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setModalState(() => isVerified = val),
              ),
              SwitchListTile(
                title: const Text('⚡ Boost Listing (₹29 Pay-to-Boost)', style: TextStyle(fontSize: 13, color: Colors.white)),
                subtitle: const Text('Pin to top of neighborhood radar feed', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                value: isBoosted,
                activeThumbColor: const Color(0xFF00E676),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setModalState(() => isBoosted = val),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          setModalState(() => modalError = 'Please enter a valid listing title.');
                          return;
                        }
                        if (priceCtrl.text.trim().isEmpty) {
                          setModalState(() => modalError = 'Please enter pricing or bounty amount.');
                          return;
                        }

                        setModalState(() {
                          isSaving = true;
                          modalError = null;
                        });

                        try {
                          double? lat;
                          double? lng;
                          try {
                            Position pos = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                            );
                            lat = pos.latitude;
                            lng = pos.longitude;
                          } catch (e) {
                            debugPrint('GPS warning: $e');
                          }

                          final authorId = widget.currentUser?.uid ?? 'guest_uid';
                          final imageUrls = pickedImagePath != null
                              ? [pickedImagePath!, 'https://images.unsplash.com/photo-1526738549149-8e07eca6c147?w=500']
                              : ['https://images.unsplash.com/photo-1526738549149-8e07eca6c147?w=500'];

                          final newListing = GridListing(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text.trim(),
                            subtitle: subCtrl.text.trim().isEmpty ? 'Available in Local Grid' : subCtrl.text.trim(),
                            category: selectedCat,
                            tag: isBoosted ? '⚡ BOOSTED' : (selectedType == ListingType.need ? 'BOUNTY' : 'NEW SIGNAL'),
                            iconEmoji: selectedCat == 'Bounty' ? '💸' : (selectedCat == 'Tools' ? '🛠️' : (selectedCat == 'Vehicles' ? '🚗' : '⚡')),
                            rating: 5.0,
                            reviewsCount: 1,
                            eta: 'Available Now',
                            distanceKm: 0.1,
                            price: priceCtrl.text.trim(),
                            bio: 'Commercial broadcast via verified enterprise node.',
                            phone: widget.currentUser?.phoneNumber ?? '+91 90000 00000',
                            sector: widget.activeLocation,
                            latitude: lat,
                            longitude: lng,
                            type: selectedType,
                            isBoosted: isBoosted,
                            timestamp: DateTime.now(),
                            authorId: authorId,
                            conditionTag: conditionTag,
                            isVerified: isVerified,
                            imageUrls: imageUrls,
                          );

                          if (Firebase.apps.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('listings').add(newListing.toMap());
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚡ Commercial listing broadcast successfully via Cloudinary CDN!')),
                            );
                          }
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                            modalError = 'Broadcast failed: $e';
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Post Enterprise Listing', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCatName = categories[_selectedCat]['name'];

    final withinRange = widget.listings.where((item) {
      if (item.isSold) return false;
      final matchesCategory = _selectedCat == 0 ||
          item.category.toLowerCase() == activeCatName!.toLowerCase() ||
          item.category.toLowerCase().contains(activeCatName.toLowerCase());
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = widget.showNeedsOnly ? (item.type == ListingType.need) : true;
      return matchesCategory && matchesSearch && matchesType;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          if (widget.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
              child: Text(widget.errorMessage!, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            ),
          ],

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
                    const SnackBar(content: Text('Enterprise Marketplace Invite Copied to Clipboard!')),
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

          // Interactive Categories Bar
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

          // Active Listings Section
          Text(
            'WITHIN YOUR ${widget.radarRadius.toStringAsFixed(0)} KM SCOPE',
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),

          if (withinRange.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF22222E))),
              child: Column(
                children: [
                  const Text('📭 No items found in this area', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('No items found in this area - Post the first listing to spark your local neighborhood grid.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                    onPressed: _openBroadcastModal,
                    child: const Text('Post the First Listing', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            )
          else if (widget.simpleMode)
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
                  title: Row(
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (item.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFF00E676), size: 14),
                      ],
                    ],
                  ),
                  subtitle: Text('${item.subtitle} • ${item.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  trailing: Text(item.price, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                  onTap: () => widget.onTapCard(item),
                );
              },
            )
          else
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
        ],
      ),
    );
  }
}

// ---------------- INTERACTIVE CARD ITEM WITH VERIFIED BADGE & DISTANCE ----------------
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF09090D), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.isBoosted ? '⚡ BOOSTED' : item.tag, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(4)),
                    child: Text(item.conditionTag, style: const TextStyle(color: Color(0xFF00E676), fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: item.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(item.imageUrls.first, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(item.iconEmoji, style: const TextStyle(fontSize: 44))),
                            )
                          : Text(item.iconEmoji, style: const TextStyle(fontSize: 44)),
                    ),
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
              Row(
                children: [
                  Flexible(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (item.isVerified) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.verified, color: Color(0xFF00E676), size: 13),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(item.subtitle, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('${item.distanceKm.toStringAsFixed(1)} km away', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text(item.price, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                  child: const Text('Inquiry Chat', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- TAB 2: INTERACTIVE OPENSTREETMAP RADAR VIEW (`flutter_map`) ----------------
class MapRadarView extends StatelessWidget {
  final List<GridListing> listings;
  final double radarRadius;
  final Function(GridListing) onSelectListing;

  const MapRadarView({super.key, required this.listings, required this.radarRadius, required this.onSelectListing});

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
                    '🗺️ OPENSTREETMAP RADAR (${radarRadius.toStringAsFixed(0)} KM)',
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0E2719), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E676))),
                  child: Text('${activeInRadar.length} Active Pins', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(28.6139, 77.2090), // Sector 14 Default Center
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.radargrid.app',
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
                            border: Border.all(color: const Color(0xFF00E676), width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
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
          const Text('DIRECT INQUIRY CHANNELS', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (keys.isEmpty)
            const Center(child: Text('No active inquiries. Connect with a seller on Explore!', style: TextStyle(color: Colors.grey)))
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
                _send('🤝 [Handshake PIN Generated]: $randomPin. Share with seller upon completion.', isPin: true);
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
                      hintText: 'Type an inquiry...',
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

// ---------------- TAB 4: PROFILE SCREEN WITH COMMERCIAL IDENTITY ARCHITECTURE ----------------
class ProfileScreen extends StatefulWidget {
  final User? user;
  final List<GridListing> listings;
  final VoidCallback onAuthChanged;

  const ProfileScreen({super.key, required this.user, required this.listings, required this.onAuthChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openAuthDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isSignUp = false;
    String? authError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF14141C),
          title: Text(isSignUp ? '📝 Enterprise Sign Up' : '🔐 Enterprise Sign In', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: const Color(0xFF1B1B26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: const Color(0xFF1B1B26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              if (authError != null) ...[
                const SizedBox(height: 8),
                Text(authError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() => isSignUp = !isSignUp),
              child: Text(isSignUp ? 'Have account? Sign In' : 'Need account? Sign Up', style: const TextStyle(color: Color(0xFF00E676), fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
              onPressed: () async {
                try {
                  if (Firebase.apps.isNotEmpty) {
                    if (isSignUp) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    } else {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onAuthChanged();
                } catch (e) {
                  setDialogState(() => authError = e.toString());
                }
              },
              child: Text(isSignUp ? 'Register' : 'Sign In', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      widget.onAuthChanged();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  void _deleteListing(String id) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('listings').doc(id).delete();
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted successfully.')));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  void _toggleSold(GridListing item) async {
    try {
      item.isSold = !item.isSold;
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('listings').doc(item.id).update({'isSold': item.isSold});
      }
      setState(() {});
    } catch (e) {
      debugPrint('Update sold error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final userListings = widget.listings.where((l) => l.authorId == user?.uid || l.authorId == 'rohan_123').toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF14141C),
              child: Icon(Icons.person, size: 40, color: Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.email ?? (user == null || user.isAnonymous ? 'Guest Neighbor' : 'Commercial Enterprise Node'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Color(0xFF00E676), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Center(child: Text('Joined October 2026 • ★ 4.9 Enterprise Rating', style: TextStyle(fontSize: 12, color: Color(0xFF71717A)))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user == null || user.isAnonymous)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                  onPressed: _openAuthDialog,
                  child: const Text('Sign In / Register Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00E676))),
                  onPressed: _signOut,
                  child: const Text('Sign Out', style: TextStyle(color: Color(0xFF00E676))),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('📦 MY COMMERCIAL LISTINGS', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (userListings.isEmpty)
            const Center(child: Text('You have not posted any commercial listings yet.', style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
            ...userListings.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF22222E))),
              child: Row(
                children: [
                  Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (item.isVerified) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.verified, color: Color(0xFF00E676), size: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${item.price} • ${item.isSold ? '🔴 SOLD' : '🟢 ACTIVE'}', style: TextStyle(color: item.isSold ? Colors.redAccent : const Color(0xFF00E676), fontSize: 11)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF71717A)),
                    color: const Color(0xFF1B1B26),
                    onSelected: (val) {
                      if (val == 'sold') {
                        _toggleSold(item);
                      } else if (val == 'delete') {
                        _deleteListing(item.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'sold', child: Text(item.isSold ? 'Mark Active' : 'Mark Sold', style: const TextStyle(fontSize: 12, color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Listing', style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                    ],
                  ),
                ],
              ),
            )),
          const SizedBox(height: 24),
          ListTile(
            tileColor: const Color(0xFF14141C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.verified_user, color: Color(0xFF00E676)),
            title: const Text('Enterprise Commercial Tier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Verified Merchant Status • 12 Completed Deals', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
          ),
        ],
      ),
    );
  }
}
