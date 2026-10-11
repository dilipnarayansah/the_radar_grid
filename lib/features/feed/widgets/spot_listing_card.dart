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
                    child: Text(item.statusText, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      if (item.isBoosted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFF9800), borderRadius: BorderRadius.circular(4)),
                          child: const Text('⚡ BOOSTED', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(4)),
                        child: Text(item.conditionTag, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                        decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(6)),
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
                    const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 13),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text('${item.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.price, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              // Prominent Primary Action + Two Compact Circular Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onChat,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text(widget.isJobMode ? 'Send Quote' : 'Negotiate / Bid', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5FF))),
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
