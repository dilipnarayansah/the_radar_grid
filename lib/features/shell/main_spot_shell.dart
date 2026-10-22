import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_radar_grid/models/listing.dart';
import 'package:the_radar_grid/models/chat.dart';
import 'package:the_radar_grid/models/categories.dart';
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

  // Universal Taxonomy Filter State
  String _selectedPillarId = 'All';
  String? _selectedSubTrade;

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

  // Dual-Intent Creation Modal: OFFER A SKILL vs POST A REQUIREMENT / RFQ
  void _openDualIntentModal() {
    bool isOfferMode = !_isJobBoardMode;
    String selectedPillarId = UniversalTaxonomy.pillars.first.id;
    String selectedSubTrade = UniversalTaxonomy.pillars.first.subTrades.first.nameEn;
    
    final titleCtrl = TextEditingController(text: 'Full-Stack Flutter & AI Assistant');
    final rateCtrl = TextEditingController(text: '₹800/hr');
    final budgetCtrl = TextEditingController(text: '5000');
    final bioCtrl = TextEditingController(text: '');
    
    // Service delivery mode: On-Site vs Remote
    String deliveryMode = 'Remote';
    // Urgency tier for RFQ
    String urgencyTier = 'Immediate';
    int photoCount = 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          MarketplacePillar currentPillar;
          try {
            currentPillar = UniversalTaxonomy.pillars.firstWhere((p) => p.id == selectedPillarId);
          } catch (_) {
            currentPillar = UniversalTaxonomy.pillars.first;
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF10141C),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🚀 Spot Universal Creation Engine', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Color(0xFF8E9BAE), size: 18), onPressed: () => Navigator.of(dialogCtx).pop()),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intent Segmented Switch
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFF080B10), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2638))),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isOfferMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isOfferMode ? const Color(0xFF00E5FF) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text('OFFER A SKILL', style: TextStyle(color: isOfferMode ? Colors.black : const Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isOfferMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isOfferMode ? const Color(0xFFFF9F1C) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text('POST RFQ / NEED', style: TextStyle(color: !isOfferMode ? Colors.black : const Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pillar Selector
                    const Text('Select Core Pillar:', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPillarId,
                      dropdownColor: const Color(0xFF10141C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: UniversalTaxonomy.pillars.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.iconEmoji} ${p.nameEn}', style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedPillarId = val;
                            final newPillar = UniversalTaxonomy.pillars.firstWhere((p) => p.id == val);
                            if (newPillar.subTrades.isNotEmpty) {
                              selectedSubTrade = newPillar.subTrades.first.nameEn;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Sub-Trade Selector
                    const Text('Select Sub-Trade:', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: currentPillar.subTrades.any((s) => s.nameEn == selectedSubTrade) ? selectedSubTrade : currentPillar.subTrades.first.nameEn,
                      dropdownColor: const Color(0xFF10141C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: currentPillar.subTrades.map((sub) => DropdownMenuItem(
                        value: sub.nameEn,
                        child: Text('${sub.iconEmoji} ${sub.nameEn}', style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSubTrade = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Title Field
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: isOfferMode ? 'Skill / Service Title' : 'Problem Scope / RFQ Title',
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pricing / Budget Field
                    if (isOfferMode) ...[
                      TextField(
                        controller: rateCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Hourly or Flat Rate (e.g., ₹800/hr or ₹3000 flat)',
                          filled: true,
                          fillColor: const Color(0xFF080B10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Service Delivery Mode:', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: ['Remote', 'On-Site', 'Both'].map((mode) {
                          final isSelected = deliveryMode == mode;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(mode, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF00E5FF),
                              backgroundColor: const Color(0xFF080B10),
                              onSelected: (_) => setModalState(() => deliveryMode = mode),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      TextField(
                        controller: budgetCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Budget Cap (₹)',
                          filled: true,
                          fillColor: const Color(0xFF080B10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Urgency Tier:', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: ['Immediate', 'Today', 'Scheduled'].map((urgency) {
                          final isSelected = urgencyTier == urgency;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(urgency, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF9F1C),
                              backgroundColor: const Color(0xFF080B10),
                              onSelected: (_) => setModalState(() => urgencyTier = urgency),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Bio / Portfolio proof
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: isOfferMode ? 'Portfolio Proof & Bio' : 'Problem Scope Details',
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Photo Slots
                    const Text('📷 Portfolio / Evidence Proof Slots (Up to 3):', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(3, (index) => Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080B10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: index < photoCount ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                        ),
                        child: IconButton(
                          icon: Icon(index < photoCount ? Icons.check_circle : Icons.add_a_photo, color: index < photoCount ? const Color(0xFF00E5FF) : const Color(0xFF8E9BAE), size: 18),
                          onPressed: () => setModalState(() => photoCount = (photoCount < 3 ? photoCount + 1 : 3)),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E9BAE)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isOfferMode ? const Color(0xFF00E5FF) : const Color(0xFFFF9F1C)),
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  Navigator.of(dialogCtx).pop();
                  if (Firebase.apps.isNotEmpty && _firebaseUser != null) {
                    try {
                      await FirebaseFirestore.instance.collection('listings').add({
                        'title': titleCtrl.text.trim(),
                        'subtitle': '$selectedSubTrade • ${currentPillar.nameEn}',
                        'category': currentPillar.nameEn,
                        'tag': isOfferMode ? 'OFFERED SKILL' : 'WANTED RFQ ($urgencyTier)',
                        'iconEmoji': currentPillar.iconEmoji,
                        'rating': 5.0,
                        'reviewsCount': 1,
                        'eta': isOfferMode ? deliveryMode : urgencyTier,
                        'distanceKm': 0.8,
                        'price': isOfferMode ? rateCtrl.text : '₹${budgetCtrl.text}',
                        'bio': bioCtrl.text.trim(),
                        'phone': '+919876543210',
                        'sector': _activeLocationName,
                        'type': isOfferMode ? 'offer' : 'need',
                        'isVerified': false,
                        'authorId': _firebaseUser!.uid,
                        'timestamp': FieldValue.serverTimestamp(),
                        'imageUrls': [],
                        'conditionTag': 'New',
                        'isSold': false,
                      });
                    } catch (e) {
                      debugPrint('Error posting listing: $e');
                    }
                  }
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(isOfferMode ? 'Skill offer successfully broadcasted to ${currentPillar.nameEn}!' : 'Client RFQ successfully broadcasted to 5km radar zone!')),
                  );
                  setState(() {});
                },
                child: Text(isOfferMode ? 'Publish Skill Offer' : 'Broadcast RFQ', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, String providerName) {
    if (!_chats.containsKey(providerName)) {
      _chats[providerName] = [
        ChatMessage(sender: providerName, text: 'Hi! Ready to discuss your universal trade requirement.', time: 'Just now', isMe: false),
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

        // Apply radar radius and blocklist filter
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
            selectedPillarId: _selectedPillarId,
            selectedSubTrade: _selectedSubTrade,
            onToggleJobMode: (val) => setState(() => _isJobBoardMode = val),
            onRadiusChanged: (r) => setState(() => _radarRadius = r),
            onToggleSimpleMode: () => setState(() => _simpleMode = !_simpleMode),
            onToggleNeeds: (val) => setState(() => _showNeedsOnly = val),
            onOpenLocationSelector: () {},
            onOpenChat: (name) => _openChat(context, name),
            onTapCard: (item) => _openChat(context, item.title),
            onOpenBroadcastModal: _openDualIntentModal,
            onPillarChanged: (pillarId) => setState(() => _selectedPillarId = pillarId),
            onSubTradeChanged: (subTrade) => setState(() => _selectedSubTrade = subTrade),
          ),
          MapRadarView(
            listings: listings.where((item) {
              if (_selectedPillarId == 'All') return true;
              try {
                final pillar = UniversalTaxonomy.pillars.firstWhere((p) => p.id == _selectedPillarId);
                final pName = pillar.nameEn.toLowerCase();
                final matchCat = item.category.toLowerCase().contains(pName) || item.subtitle.toLowerCase().contains(pName);
                if (_selectedSubTrade == null) return matchCat;
                return matchCat && (item.category.toLowerCase().contains(_selectedSubTrade!.toLowerCase()) || item.subtitle.toLowerCase().contains(_selectedSubTrade!.toLowerCase()));
              } catch (_) {
                return true;
              }
            }).toList(),
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
            onPressed: _openDualIntentModal,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('+ Post / Offer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
