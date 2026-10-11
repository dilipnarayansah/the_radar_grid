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

  final List<GridListing> _defaultListings = [
    GridListing(
      id: '1',
      title: 'Apex Industrial Fab & Welding',
      subtitle: 'Heavy Machinery & Steel Fabrication',
      category: 'Industrial & Fab',
      tag: 'VERIFIED PRO',
      iconEmoji: '🏭',
      rating: 4.9,
      reviewsCount: 42,
      eta: 'Available Today',
      distanceKm: 0.8,
      price: '₹450/hr',
      bio: 'Precision laser cutting, MIG/TIG welding, and industrial fabrication for plant extensions and repairs.',
      phone: '+919876543210',
      sector: 'Sector 14 Industrial Zone',
      type: ListingType.offer,
      statusText: '• Online Now',
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      authorId: 'apex_fab',
      conditionTag: 'New',
      isVerified: true,
      imageUrls: [
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500',
      ],
    ),
  ];

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
            onOpenBroadcastModal: () {},
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
