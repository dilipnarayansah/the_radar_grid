import 'package:flutter/material.dart';
import 'package:the_radar_grid/models/listing.dart';

class SpotListingCard extends StatefulWidget {
  final GridListing item;
  final bool isJobMode;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const SpotListingCard({
    super.key,
    required this.item,
    required this.isJobMode,
    required this.onTap,
    required this.onChat,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  State<SpotListingCard> createState() => _SpotListingCardState();
}

class _SpotListingCardState extends State<SpotListingCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isRfq = widget.isJobMode || item.type == ListingType.need || item.category == 'Urgent RFQs';

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
            color: const Color(0xFF10141C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRfq ? const Color(0xFFFF9F1C).withValues(alpha: 0.5) : const Color(0xFF1E2638),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header / Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isRfq)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFF9F1C).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('🔥 WANTED / RFQ', style: TextStyle(color: Color(0xFFFF9F1C), fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  else
                    Flexible(
                      child: Text(item.statusText, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  Row(
                    children: [
                      if (item.isBoosted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(4)),
                          child: const Text('⚡ BOOSTED', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1E2638), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.conditionTag, style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Media or Icon area + 3 horizontal thumbnails preview if available
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
                    if (!isRfq)
                      Positioned(
                        bottom: 2,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(6)),
                          child: Text('★ ${item.rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 2,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFF9F1C), borderRadius: BorderRadius.circular(6)),
                          child: Text(item.price, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // 3 horizontal image thumbnails preview row if multiple images exist
              if (item.imageUrls.length > 1) ...[
                Row(
                  children: item.imageUrls.take(3).map((url) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(url, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 4),
              ],
              // Title & Verified Badge
              Row(
                children: [
                  Flexible(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (item.isVerified) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 13),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text('${item.distanceKm.toStringAsFixed(1)} km away • ${item.sector}', style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              if (!isRfq)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.price, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(height: 6),
              // Action Row
              if (isRfq)
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9F1C),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: widget.onChat,
                    child: const Text('Send Quote', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onChat,
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: const Text('Negotiate / Bid', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(8)),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                        onPressed: widget.onWhatsApp,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(color: const Color(0xFF10141C), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5FF))),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.phone, color: Color(0xFF00E5FF), size: 16),
                        onPressed: widget.onCall,
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
}
