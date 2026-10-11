import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_radar_grid/models/listing.dart';
import 'package:the_radar_grid/features/feed/widgets/spot_listing_card.dart';

// ---------------- TAB 1: EXPLORE FEED WITH COLLAPSIBLE MAP & CATEGORY RIBBON ----------------
class ExploreFeedScreen extends StatefulWidget {
  final List<GridListing> listings;
  final String activeLocation;
  final double radarRadius;
  final bool simpleMode;
  final bool showNeedsOnly;
  final Set<String> bookmarkedIds;
  final User? currentUser;
  final String? errorMessage;
  final bool isJobBoardMode;
  final Function(bool) onToggleJobMode;
  final Function(double) onRadiusChanged;
  final VoidCallback onToggleSimpleMode;
  final Function(bool) onToggleNeeds;
  final VoidCallback onOpenLocationSelector;
  final Function(String) onOpenChat;
  final Function(GridListing) onTapCard;
  final VoidCallback onOpenBroadcastModal;

  const ExploreFeedScreen({
    super.key,
    required this.listings,
    required this.activeLocation,
    required this.radarRadius,
    required this.simpleMode,
    required this.showNeedsOnly,
    required this.bookmarkedIds,
    required this.currentUser,
    required this.errorMessage,
    required this.isJobBoardMode,
    required this.onToggleJobMode,
    required this.onRadiusChanged,
    required this.onToggleSimpleMode,
    required this.onToggleNeeds,
    required this.onOpenLocationSelector,
    required this.onOpenChat,
    required this.onTapCard,
    required this.onOpenBroadcastModal,
  });

  @override
  State<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends State<ExploreFeedScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isRadarCollapsed = false;

  final List<String> categories = [
    'All',
    'Industrial & Fab',
    'Electrical',
    'Repairs & AC',
    'Tech & Design',
    'Urgent RFQs',
  ];

  Future<void> _launchUrlSafe(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('URL launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final withinRange = widget.listings.where((item) {
      final matchesJobMode = widget.isJobBoardMode ? (item.type == ListingType.need || item.category == 'Urgent RFQs') : (item.type == ListingType.offer);
      final matchesCategory = _selectedCategory == 'All' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase() ||
          item.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.bio.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sector.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesJobMode && matchesCategory && matchesSearch;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (widget.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
              child: Text(widget.errorMessage!, style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
            ),

          // Custom "SPOT" Wordmark Header with Radar Pin Glyph and Alert Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.radar, color: Color(0xFF00E5FF), size: 22),
                  const SizedBox(width: 6),
                  const Text('S P O T', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF10141C), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF1E2638))),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF00E5FF), size: 11),
                        const SizedBox(width: 2),
                        Text(widget.activeLocation, style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFF00E5FF), size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spot Live Radar Alert: 3 nodes active nearby')));
                    },
                  ),
                  GestureDetector(
                    onTap: widget.onOpenLocationSelector,
                    child: const Icon(Icons.tune, color: Color(0xFF8E9BAE), size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mode Toggle: SERVICES AVAILABLE vs WANTED / RFQs with Animated / Pill Indicator
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF10141C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2638)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onToggleJobMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !widget.isJobBoardMode ? const Color(0xFF00E5FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SERVICES AVAILABLE',
                        style: TextStyle(
                          color: !widget.isJobBoardMode ? Colors.black : const Color(0xFF8E9BAE),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onToggleJobMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isJobBoardMode ? const Color(0xFFFF9F1C) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'WANTED / RFQS',
                        style: TextStyle(
                          color: widget.isJobBoardMode ? Colors.black : const Color(0xFF8E9BAE),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10141C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF8E9BAE), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search services & RFQs near you...',
                            hintStyle: TextStyle(color: Color(0xFF8E9BAE), fontSize: 12),
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
                onTap: widget.onOpenBroadcastModal,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: widget.isJobBoardMode ? const Color(0xFFFF9F1C) : const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Collapsible Radar Card: Integrated container showing dark radar sweep with live pin markers
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10141C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2638)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.radar, color: Color(0xFF00E5FF), size: 16),
                        SizedBox(width: 6),
                        Text('LIVE P2P RADAR SWEEP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isRadarCollapsed = !_isRadarCollapsed),
                      child: Icon(_isRadarCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: const Color(0xFF8E9BAE), size: 18),
                    ),
                  ],
                ),
                if (!_isRadarCollapsed) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF080B10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2638)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Concentric Radar Rings
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3))),
                        ),
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.15))),
                        ),
                        const Icon(Icons.my_location, color: Color(0xFF00E5FF), size: 18),
                        // Live pin markers on radar
                        const Positioned(top: 20, left: 40, child: Icon(Icons.circle, color: Color(0xFF00E5FF), size: 8)),
                        const Positioned(bottom: 25, right: 50, child: Icon(Icons.circle, color: Color(0xFFFF9F1C), size: 8)),
                        Positioned(
                          bottom: 8,
                          left: 10,
                          child: Text('${withinRange.length} nodes active within ${widget.radarRadius}km', style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontally Scrollable Category Ribbon with subtle active border
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0E272B) : const Color(0xFF10141C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF8E9BAE),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Feed Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isJobBoardMode ? '📋 ACTIVE CLIENT RFQS (${withinRange.length})' : '⚡ SPOT SERVICES AVAILABLE (${withinRange.length})',
                style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (withinRange.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: const Color(0xFF10141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2638))),
              child: Column(
                children: [
                  const Text('No active listings in this category. Be the first to post!', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(widget.isJobBoardMode ? 'Post the first job requirement or RFQ to receive competitive quotes.' : 'No commercial services found in this sector. Tap + to broadcast your capabilities.', style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: widget.isJobBoardMode ? const Color(0xFFFF9F1C) : const Color(0xFF00E5FF)),
                    onPressed: widget.onOpenBroadcastModal,
                    child: Text(widget.isJobBoardMode ? 'Post Client Job RFQ' : 'Post Spot Service Listing', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
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
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                final item = withinRange[index];
                return SpotListingCard(
                  item: item,
                  isJobMode: widget.isJobBoardMode,
                  onTap: () => widget.onTapCard(item),
                  onChat: () => widget.onOpenChat(item.title),
                  onCall: () => _launchUrlSafe('tel:${item.phone}'),
                  onWhatsApp: () => _launchUrlSafe('https://wa.me/${item.phone.replaceAll(RegExp(r'[^0-9]'), '')}?text=Hi, inquiring about your Spot listing: ${item.title}'),
                );
              },
            ),
        ],
      ),
    );
  }
}
