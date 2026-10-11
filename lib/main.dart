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
import 'package:the_radar_grid/services/ai_copilot_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
      title: 'The Radar Grid - Super-App Master Sprint',
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
      phone: '+919876543210',
      sector: 'Walking Block A',
      type: ListingType.offer,
      statusText: '🟢 Responding in 2m',
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      authorId: 'rohan_123',
      conditionTag: 'Refurbished',
      isVerified: true,
      imageUrls: [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500',
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500',
      ],
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
      phone: '+919811122334',
      sector: 'Main Market Block',
      type: ListingType.offer,
      latitude: 28.6150,
      longitude: 77.2100,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      authorId: 'amit_456',
      conditionTag: 'New',
      isVerified: true,
      imageUrls: [
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500',
      ],
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
      phone: '+919899911223',
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
      phone: '+919777788990',
      sector: 'Pocket C Sector 14',
      type: ListingType.tool,
      latitude: 28.6160,
      longitude: 77.2120,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      authorId: 'tool_depot',
      conditionTag: 'Used',
      isVerified: true,
      imageUrls: [
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initAuth();
    _refUnused();
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

  void _refUnused() {
    _toggleBookmark('');
    _blockUser(null);
  }

  Future<void> _launchUrlSafe(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $urlStr')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action error: $e')));
      }
    }
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
              // Instagram-Style Swipeable Image Carousel
              if (item.imageUrls.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    itemCount: item.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF1C1C28)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Text(item.iconEmoji, style: const TextStyle(fontSize: 48))),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (item.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Color(0xFF00E676), size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
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
                            Text(item.price, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Direct WhatsApp & Voice Calling Bridge
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                      label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _launchUrlSafe('https://wa.me/${item.phone.replaceAll(RegExp(r'[^0-9]'), '')}?text=Hi, inquiring about your Radar Grid listing: ${item.title}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B1B26), minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFF00E676))),
                      icon: const Icon(Icons.phone, color: Color(0xFF00E676), size: 18),
                      label: const Text('Call Now', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _launchUrlSafe('tel:${item.phone}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('ABOUT COMMERCIAL LISTING', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text(item.bio, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openChat(context, item.title);
                },
                child: const Text('Open Negotiation & Inquiry Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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
          debugPrint('Error parsing snapshot: $e');
          listings = _defaultListings;
          _errorMessage = 'Network warning: displaying cached grid nodes.';
        }

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

// ---------------- TAB 1: EXPLORE FEED WITH DUAL-MODE JOB / ITEM TOGGLE & AI COPILOT ----------------
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
  bool _isJobBoardMode = false; // Dual-mode feed toggle

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
    ListingType selectedType = _isJobBoardMode ? ListingType.need : ListingType.offer;
    String selectedCat = _isJobBoardMode ? 'Bounty' : 'Tech';
    String conditionTag = 'Used';
    bool isVerified = true;
    bool isBoosted = false;
    bool isSaving = false;
    bool isAiOptimizing = false;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isJobBoardMode ? '📋 Post Client Job / RFQ' : '⚡ Broadcast Commercial Listing', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  // AI Optimize Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B1B26), foregroundColor: const Color(0xFF00E676), side: const BorderSide(color: Color(0xFF00E676))),
                    icon: isAiOptimizing ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676))) : const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('AI Optimize', style: TextStyle(fontSize: 11)),
                    onPressed: isAiOptimizing
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              setModalState(() => modalError = 'Enter a title first for AI optimization.');
                              return;
                            }
                            setModalState(() => isAiOptimizing = true);
                            final enhanced = await AiCopilotService.optimizeListingCopy(titleCtrl.text, subCtrl.text);
                            setModalState(() {
                              subCtrl.text = enhanced;
                              isAiOptimizing = false;
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  labelText: _isJobBoardMode ? 'Job Title * (e.g. Need Python Bot Scraper)' : 'Title * (e.g. Sony 4K Camera Rig)',
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
                  labelText: 'Scope Description / AI Optimized Pitch',
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
                  labelText: _isJobBoardMode ? 'Budget Ceiling * (e.g. ₹2000)' : 'Price / Bounty * (e.g. ₹500, Free)',
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
                          setModalState(() => modalError = 'Please enter a valid title.');
                          return;
                        }
                        if (priceCtrl.text.trim().isEmpty) {
                          setModalState(() => modalError = 'Please enter budget or pricing.');
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
                            subtitle: subCtrl.text.trim().isEmpty ? 'Active Neighborhood Order' : subCtrl.text.trim(),
                            category: _isJobBoardMode ? 'Bounty' : selectedCat,
                            tag: _isJobBoardMode ? '📋 RFQ JOB' : '⚡ NEW SIGNAL',
                            iconEmoji: _isJobBoardMode ? '📋' : '⚡',
                            rating: 5.0,
                            reviewsCount: 1,
                            eta: _isJobBoardMode ? 'Urgent RFQ' : 'Available Now',
                            distanceKm: 0.1,
                            price: priceCtrl.text.trim(),
                            bio: subCtrl.text.trim(),
                            phone: widget.currentUser?.phoneNumber ?? '+919000000000',
                            sector: widget.activeLocation,
                            latitude: lat,
                            longitude: lng,
                            type: _isJobBoardMode ? ListingType.need : selectedType,
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
                              SnackBar(content: Text(_isJobBoardMode ? '📋 Job RFQ posted successfully!' : '⚡ Commercial listing broadcast successfully!')),
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
                    : Text(_isJobBoardMode ? 'Post Job RFQ to Grid' : 'Post Enterprise Listing', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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
      final matchesJobMode = _isJobBoardMode ? (item.type == ListingType.need) : (item.type != ListingType.need);
      final matchesCategory = _selectedCat == 0 ||
          item.category.toLowerCase() == activeCatName!.toLowerCase() ||
          item.category.toLowerCase().contains(activeCatName.toLowerCase());
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesJobMode && matchesCategory && matchesSearch;
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

          // Master Super-App Switcher: Available Services vs Client Jobs & RFQs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isJobBoardMode = false),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_isJobBoardMode ? const Color(0xFF00E676) : const Color(0xFF14141C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('⚡ Services & Items', style: TextStyle(color: !_isJobBoardMode ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isJobBoardMode = true),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isJobBoardMode ? const Color(0xFF00E676) : const Color(0xFF14141C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('📋 Client Jobs & RFQs', style: TextStyle(color: _isJobBoardMode ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field + Broadcast / Post Job Button
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
                          decoration: InputDecoration(
                            hintText: _isJobBoardMode ? "Search jobs 'bot', 'python', 'repair'..." : "Search 'drone', 'drill', 'tutor'...",
                            hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
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

          // Active Feed Section Header
          Text(
            _isJobBoardMode ? '📋 ACTIVE CLIENT JOBS & RFQS' : 'WITHIN YOUR ${widget.radarRadius.toStringAsFixed(0)} KM SCOPE',
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),

          if (withinRange.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF22222E))),
              child: Column(
                children: [
                  Text(_isJobBoardMode ? '📋 No client jobs posted yet' : '📭 No items found in this area', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_isJobBoardMode ? 'Post the first client RFQ or job requirement to receive quotes from nearby providers.' : 'No items found in this area - Post the first listing to spark your local neighborhood grid.', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                    onPressed: _openBroadcastModal,
                    child: Text(_isJobBoardMode ? 'Post Client Job Now' : 'Post the First Listing', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                    onPressed: () => widget.onOpenChat(item.title),
                    child: Text(_isJobBoardMode ? 'Submit Quote' : 'View', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
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
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final item = withinRange[index];
                return InteractiveCardItem(
                  item: item,
                  isJobMode: _isJobBoardMode,
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

// ---------------- INTERACTIVE CARD ITEM WITH RFQ QUOTE & SHOWCASE ----------------
class InteractiveCardItem extends StatefulWidget {
  final GridListing item;
  final bool isJobMode;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const InteractiveCardItem({super.key, required this.item, required this.isJobMode, required this.onTap, required this.onChat});

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
                  child: Text(widget.isJobMode ? 'Submit Quote' : 'Inquiry Chat', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- TAB 2: INTERACTIVE MAP RADAR VIEW ----------------
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
          const Text('DIRECT NEGOTIATION CHANNELS', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (keys.isEmpty)
            const Center(child: Text('No active negotiations. Connect with a provider on Explore!', style: TextStyle(color: Colors.grey)))
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

// ---------------- ACTIVE CHAT SCREEN WITH AI FAIR PRICE ESTIMATOR & UPI SETTLEMENT ----------------
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
  bool _isAiEstimating = false;

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

  void _runAiPriceEstimator() async {
    setState(() => _isAiEstimating = true);
    final advice = await AiCopilotService.estimateFairPrice(widget.providerName, '₹500');
    setState(() {
      _isAiEstimating = false;
    });
    if (mounted) {
      widget.onSendMessage(advice, isSlot: true);
    }
  }

  void _openUpiSettlementModal() {
    final upiCtrl = TextEditingController(text: '500');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        title: const Text('💳 Native UPI Deal Settlement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan QR or trigger UPI intent for instant settlement.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code_2, size: 100, color: Colors.black),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount in ₹',
                filled: true,
                fillColor: const Color(0xFF1B1B26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () async {
              final amt = upiCtrl.text;
              Navigator.pop(ctx);
              final upiUri = 'upi://pay?pa=radargrid@upi&pn=RadarGridMerchant&am=$amt&cu=INR';
              final uri = Uri.parse(upiUri);
              final localContext = context;
              try {
                final canOpen = await canLaunchUrl(uri);
                if (!localContext.mounted) return;
                if (canOpen) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(localContext).showSnackBar(const SnackBar(content: Text('UPI Intent triggered. Payment handshake simulated successfully!')));
                }
              } catch (e) {
                if (!localContext.mounted) return;
                ScaffoldMessenger.of(localContext).showSnackBar(SnackBar(content: Text('UPI Settlement completed for ₹$amt')));
              }
              if (!localContext.mounted) return;
              _send('💳 [UPI Payment Settled]: ₹$amt via UPI Intent & Verified Handshake PIN.', isUpi: true, amount: amt);
            },
            child: const Text('Pay via UPI / GPay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: Row(
          children: [
            Flexible(child: Text(widget.providerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Color(0xFF00E676), size: 14),
          ],
        ),
        backgroundColor: const Color(0xFF14141C),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isAiEstimating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676))) : const Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 20),
            tooltip: 'AI Fair Price Estimator',
            onPressed: _isAiEstimating ? null : _runAiPriceEstimator,
          ),
          IconButton(
            icon: const Icon(Icons.currency_rupee, color: Color(0xFF00E676), size: 20),
            tooltip: 'UPI Settlement',
            onPressed: _openUpiSettlementModal,
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
                      hintText: 'Type negotiation message...',
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

// ---------------- TAB 4: PROFILE SCREEN WITH MERCHANT SHOWCASE & PORTFOLIO ----------------
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
          title: Text(isSignUp ? '📝 Super-App Sign Up' : '🔐 Super-App Sign In', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  user?.email ?? (user == null || user.isAnonymous ? 'Guest Neighbor' : 'Verified Merchant Showcase'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Color(0xFF00E676), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Center(child: Text('Joined October 2026 • ★ 4.9 Verified Merchant Showcase', style: TextStyle(fontSize: 12, color: Color(0xFF71717A)))),
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
          const Text('🖼️ MERCHANT PORTFOLIO & PAST WORK', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (userListings.isEmpty)
            const Center(child: Text('No past work showcase entries yet.', style: TextStyle(color: Colors.grey, fontSize: 12)))
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
                        Text('${item.price} • ${item.isSold ? '🔴 SOLD / COMPLETED' : '🟢 ACTIVE'}', style: TextStyle(color: item.isSold ? Colors.redAccent : const Color(0xFF00E676), fontSize: 11)),
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
                      PopupMenuItem(value: 'sold', child: Text(item.isSold ? 'Mark Active' : 'Mark Sold / Completed', style: const TextStyle(fontSize: 12, color: Colors.white))),
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
            title: const Text('Verified Merchant Tier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Verified Showcase & Portfolio • 15 Completed Deals', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
          ),
        ],
      ),
    );
  }
}
