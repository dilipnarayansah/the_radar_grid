import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_radar_grid/models/listing.dart';
import 'package:the_radar_grid/models/categories.dart';
import 'package:the_radar_grid/features/feed/widgets/spot_listing_card.dart';

// ---------------- TAB 1: EXPLORE FEED WITH UNIVERSAL TAXONOMY & RADAR SYNC ----------------
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
  final String selectedPillarId;
  final String? selectedSubTrade;
  final Function(bool) onToggleJobMode;
  final Function(double) onRadiusChanged;
  final VoidCallback onToggleSimpleMode;
  final Function(bool) onToggleNeeds;
  final VoidCallback onOpenLocationSelector;
  final Function(String) onOpenChat;
  final Function(GridListing) onTapCard;
  final VoidCallback onOpenBroadcastModal;
  final Function(String) onPillarChanged;
  final Function(String?) onSubTradeChanged;

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
    required this.selectedPillarId,
    required this.selectedSubTrade,
    required this.onToggleJobMode,
    required this.onRadiusChanged,
    required this.onToggleSimpleMode,
    required this.onToggleNeeds,
    required this.onOpenLocationSelector,
    required this.onOpenChat,
    required this.onTapCard,
    required this.onOpenBroadcastModal,
    required this.onPillarChanged,
    required this.onSubTradeChanged,
  });

  @override
  State<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends State<ExploreFeedScreen> {
  String _searchQuery = '';
  bool _isRadarCollapsed = false;

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
    // Find selected pillar object if not 'All'
    MarketplacePillar? currentPillar;
    if (widget.selectedPillarId != 'All') {
      try {
        currentPillar = UniversalTaxonomy.pillars.firstWhere((p) => p.id == widget.selectedPillarId);
      } catch (_) {}
    }

    final withinRange = widget.listings.where((item) {
      final matchesJobMode = widget.isJobBoardMode
          ? (item.type == ListingType.need || item.category == 'Urgent RFQs' || item.tag.contains('RFQ') || item.tag.contains('WANTED'))
          : (item.type == ListingType.offer || item.type == ListingType.tool);

      bool matchesPillar = true;
      if (widget.selectedPillarId != 'All' && currentPillar != null) {
        final pillarName = currentPillar.nameEn.toLowerCase();
        final itemCat = item.category.toLowerCase();
        final itemSub = item.subtitle.toLowerCase();
        final matchesPillarName = itemCat.contains(pillarName) || itemSub.contains(pillarName);
        
        final matchesSub = widget.selectedSubTrade == null ||
            itemCat.contains(widget.selectedSubTrade!.toLowerCase()) ||
            itemSub.contains(widget.selectedSubTrade!.toLowerCase()) ||
            item.title.toLowerCase().contains(widget.selectedSubTrade!.toLowerCase());

        matchesPillar = matchesPillarName || matchesSub;
      }

      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.bio.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sector.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesJobMode && matchesPillar && matchesSearch;
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Spot Live Radar Alert: ${withinRange.length} nodes active nearby')));
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
                        'OFFERED SKILLS & TRADES',
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
                        'CLIENT RFQS & NEEDS',
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

          // Search Bar & Dual-Intent Post Button
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
                            hintText: 'Search universal trades, skills & RFQs...',
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

          // Collapsible Radar Card
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
                        Text('LIVE P2P RADAR SWEEP (SYNCED)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
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
                        const Positioned(top: 20, left: 40, child: Icon(Icons.circle, color: Color(0xFF00E5FF), size: 8)),
                        const Positioned(bottom: 25, right: 50, child: Icon(Icons.circle, color: Color(0xFFFF9F1C), size: 8)),
                        Positioned(
                          bottom: 8,
                          left: 10,
                          child: Text('${withinRange.length} nodes active within ${widget.radarRadius}km (${widget.selectedPillarId})', style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Master Pillar Bar (Horizontally Scrollable)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 'All' Pillar Option
                GestureDetector(
                  onTap: () {
                    widget.onPillarChanged('All');
                    widget.onSubTradeChanged(null);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.selectedPillarId == 'All' ? const Color(0xFF0E272B) : const Color(0xFF10141C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.selectedPillarId == 'All' ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                    ),
                    child: const Text('🌟 All Pillars', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                ...UniversalTaxonomy.pillars.map((pillar) {
                  final isSelected = widget.selectedPillarId == pillar.id;
                  return GestureDetector(
                    onTap: () {
                      widget.onPillarChanged(pillar.id);
                      widget.onSubTradeChanged(null);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0E272B) : const Color(0xFF10141C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                      ),
                      child: Row(
                        children: [
                          Text(pillar.iconEmoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            pillar.nameEn,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF8E9BAE),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Nested Sub-Trade Chips Bar (Rendered dynamically when a pillar is selected)
          if (currentPillar != null && currentPillar.subTrades.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () => widget.onSubTradeChanged(null),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.selectedSubTrade == null ? const Color(0xFF1A2634) : const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.selectedSubTrade == null ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                      ),
                      child: Text('All ${currentPillar.nameEn}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ...currentPillar.subTrades.map((sub) {
                    final isSubSelected = widget.selectedSubTrade == sub.nameEn;
                    return GestureDetector(
                      onTap: () => widget.onSubTradeChanged(sub.nameEn),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSubSelected ? const Color(0xFF1A2634) : const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSubSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2638)),
                        ),
                        child: Row(
                          children: [
                            Text(sub.iconEmoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              sub.nameEn,
                              style: TextStyle(
                                color: isSubSelected ? const Color(0xFF00E5FF) : const Color(0xFF8E9BAE),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Feed Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isJobBoardMode ? '📋 ACTIVE CLIENT RFQS & NEEDS (${withinRange.length})' : '⚡ AVAILABLE SKILLS & TRADES (${withinRange.length})',
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
                  const Text('No listings in this category yet. Be the first to post a skill or request!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: widget.isJobBoardMode ? const Color(0xFFFF9F1C) : const Color(0xFF00E5FF)),
                    onPressed: widget.onOpenBroadcastModal,
                    child: Text(widget.isJobBoardMode ? 'Post Client Job RFQ' : 'Offer a Skill / Service', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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
