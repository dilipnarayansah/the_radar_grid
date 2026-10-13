import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_radar_grid/models/listing.dart';
import 'package:the_radar_grid/models/chat.dart';
import 'package:the_radar_grid/features/map/spot_radar_map.dart';
import 'package:the_radar_grid/features/feed/explore_feed_screen.dart';
import 'package:the_radar_grid/features/chat/chat_screens.dart';
import 'package:the_radar_grid/features/profile/profile_screen.dart';

class MainSpotShell extends StatefulWidget {
  const MainSpotShell({super.key});

  @override
  State<MainSpotShell> createState() => _MainSpotShellState();
}

class _MainSpotShellState extends State<MainSpotShell> {
  int _currentIndex = 0;
  final String _activeLocationName = 'Sector 14 Industrial Hub';
  double _radarRadius = 5.0;
  bool _simpleMode = false;
  bool _showNeedsOnly = false;
  bool _isJobBoardMode = false;

  User? _firebaseUser;
  final Set<String> _bookmarkedIds = {};
  final Set<String> _blockedUserIds = {};
  final Map<String, List<ChatMessage>> _chats = {};
  String? _errorMessage;

  final List<GridListing> _defaultListings = [];

  @override
  void initState() {
    super.initState();
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

  void _openPostJobModal() {
    String selectedTemplate = 'Generator Rewinding';
    final titleCtrl = TextEditingController(text: 'Generator Rewinding - 250kVA Cummins');
    final budgetCtrl = TextEditingController(text: '3500');
    bool hasVoiceBrief = false;
    int photoCount = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF10141C),
          title: const Text('📋 + Post a Job / RFQ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Trade Template:', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Generator Rewinding', 'Lathe Job', 'Switch Tripping'].map((template) {
                    final isSelected = selectedTemplate == template;
                    return ChoiceChip(
                      label: Text(template, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00E5FF),
                      backgroundColor: const Color(0xFF080B10),
                      onSelected: (val) {
                        setModalState(() {
                          selectedTemplate = template;
                          titleCtrl.text = '$template - Industrial Service';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Job Title / Description',
                    filled: true,
                    fillColor: const Color(0xFF080B10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: budgetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Estimated Budget (₹)',
                    filled: true,
                    fillColor: const Color(0xFF080B10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('📷 Photo Slots (Up to 3):', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(3, (index) => Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080B10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: index < photoCount ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                    ),
                    child: IconButton(
                      icon: Icon(index < photoCount ? Icons.check_circle : Icons.add_a_photo, color: index < photoCount ? const Color(0xFF00E5FF) : const Color(0xFF8E9BAE), size: 20),
                      onPressed: () => setModalState(() => photoCount = (photoCount < 3 ? photoCount + 1 : 3)),
                    ),
                  )),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: hasVoiceBrief ? Colors.greenAccent : const Color(0xFF1E2638)),
                      icon: Icon(hasVoiceBrief ? Icons.mic : Icons.mic_none, color: hasVoiceBrief ? Colors.black : Colors.white),
                      label: Text(hasVoiceBrief ? 'Voice Brief Recorded' : 'Hold to Record Voice Brief', style: TextStyle(color: hasVoiceBrief ? Colors.black : Colors.white, fontSize: 11)),
                      onPressed: () => setModalState(() => hasVoiceBrief = !hasVoiceBrief),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E9BAE)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              onPressed: () async {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (Firebase.apps.isNotEmpty && _firebaseUser != null) {
                  try {
                    FirebaseFirestore.instance.collection('listings').add({
                      'title': titleCtrl.text.trim(),
                      'subtitle': selectedTemplate,
                      'category': 'Urgent RFQs',
                      'tag': 'WANTED RFQ',
                      'iconEmoji': selectedTemplate.contains('Generator') ? '⚡' : selectedTemplate.contains('Lathe') ? '⚙️' : '🔌',
                      'rating': 5.0,
                      'reviewsCount': 1,
                      'eta': 'Immediate',
                      'distanceKm': 1.2,
                      'price': '₹${budgetCtrl.text}',
                      'bio': 'Voice brief attached. Professional RFQ posted via Spot 5km radar zone.',
                      'phone': '+919876543210',
                      'sector': 'Sector 14 Industrial Hub',
                      'type': 'need',
                      'isVerified': true,
                      'authorId': _firebaseUser!.uid,
                      'timestamp': FieldValue.serverTimestamp(),
                      'imageUrls': [],
                      'conditionTag': 'New',
                      'isSold': false,
                    });
                  } catch (e) {
                    debugPrint('Post job error: $e');
                  }
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job RFQ broadcasted to 5km radar zone!')));
                setState(() {});
              },
              child: const Text('Broadcast Job', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, String providerName) {
    if (!_chats.containsKey(providerName)) {
      _chats[providerName] = [
        ChatMessage(sender: providerName, text: 'Hi! Ready to discuss your Spot commercial requirement.', time: 'Just now', isMe: false),
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
          listings = _defaultListings;
          _errorMessage = 'Network warning: displaying cached Spot grid nodes.';
        }

        listings = listings.where((l) => !(_blockedUserIds.contains(l.authorId)) && l.distanceKm <= _radarRadius).toList();

        final screens = [
          ExploreFeedScreen(
            listings: listings,
            activeLocation: _activeLocationName,
            radarRadius: _radarRadius,
            simpleMode: _simpleMode,
            showNeedsOnly: _showNeedsOnly,
            bookmarkedIds: _bookmarkedIds,
            currentUser: _firebaseUser,
            errorMessage: _errorMessage,
            isJobBoardMode: _isJobBoardMode,
            onToggleJobMode: (val) => setState(() => _isJobBoardMode = val),
            onRadiusChanged: (r) => setState(() => _radarRadius = r),
            onToggleSimpleMode: () => setState(() => _simpleMode = !_simpleMode),
            onToggleNeeds: (val) => setState(() => _showNeedsOnly = val),
            onOpenLocationSelector: () {},
            onOpenChat: (name) => _openChat(context, name),
            onTapCard: (item) {},
            onOpenBroadcastModal: _openPostJobModal,
          ),
          MapRadarView(
            listings: listings,
            radarRadius: _radarRadius,
            onSelectListing: (item) => _openChat(context, item.title),
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
          backgroundColor: const Color(0xFF080B10),
          body: screens[_currentIndex],
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF00E5FF),
            onPressed: _openPostJobModal,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('+ Post a Job', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = idx);
            },
            backgroundColor: const Color(0xFF10141C),
            selectedItemColor: const Color(0xFF00E5FF),
            unselectedItemColor: const Color(0xFF8E9BAE),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
              BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chats'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
