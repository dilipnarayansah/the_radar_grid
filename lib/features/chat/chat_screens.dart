import 'package:flutter/material.dart';
import 'package:the_radar_grid/models/chat.dart';
import 'package:the_radar_grid/services/ai_copilot_service.dart';

// ---------------- TAB 3: CHAT LIST ----------------
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
          const Text('DIRECT NEGOTIATION CHANNELS', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (keys.isEmpty)
            const Center(child: Text('No active negotiations. Connect on Spot!', style: TextStyle(color: Color(0xFF8E9BAE))))
          else
            ...keys.map((name) {
              final lastMsg = chats[name]!.last;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: const Color(0xFF10141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2638))),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1B1B26), child: Icon(Icons.factory, color: Color(0xFF00E5FF))),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  subtitle: Text(lastMsg.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 11)),
                  trailing: Text(lastMsg.time, style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 10)),
                  onTap: () => onOpenChat(name),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ---------------- ACTIVE CHAT SCREEN WITH NEGOTIATION WIDGET & AI COPILOT ----------------
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
  final _offerController = TextEditingController(text: '450');
  bool _isAiEstimating = false;
  bool _handshakeVerified = false;
  bool _showOfferPanel = false;

  final List<String> quickPrompts = [
    'Can you deliver by tomorrow?',
    'What is your lowest bid?',
    'Send commercial specification sheet',
    'Ready for direct settlement',
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
    final advice = await AiCopilotService.estimateFairPrice(widget.providerName, '₹${_offerController.text}/hr');
    setState(() {
      _isAiEstimating = false;
    });
    if (mounted) {
      widget.onSendMessage(advice, isSlot: true);
    }
  }

  void _sendOffer() {
    final amt = _offerController.text;
    final handshakeText = _handshakeVerified ? '🔒 [Handshake Verified]' : '';
    _send('🤝 [MAKE AN OFFER / SEND QUOTE]: ₹$amt/hr $handshakeText');
    setState(() => _showOfferPanel = false);
  }

  void _openUpiSettlementModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10141C),
        title: const Text('Direct Settlement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text(
          'In-app digital escrow is currently in private testing. Please settle payment directly with the provider upon verified completion of work.',
          style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(child: Text(widget.providerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 14),
          ],
        ),
        backgroundColor: const Color(0xFF10141C),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isAiEstimating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF))) : const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 20),
            tooltip: 'AI Copilot Price Estimator',
            onPressed: _isAiEstimating ? null : _runAiPriceEstimator,
          ),
          IconButton(
            icon: const Icon(Icons.currency_rupee, color: Color(0xFF00E5FF), size: 20),
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
                          ? const Color(0xFF0E272B)
                          : (m.isSlotRequest || m.isPinVerified
                              ? const Color(0xFF10141C)
                              : (m.isMe ? const Color(0xFF00E5FF) : const Color(0xFF10141C))),
                      borderRadius: BorderRadius.circular(14),
                      border: (m.isUpiRequest || m.isSlotRequest || m.isPinVerified) ? Border.all(color: const Color(0xFF00E5FF)) : Border.all(color: const Color(0xFF1E2638)),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: (m.isUpiRequest || m.isSlotRequest || m.isPinVerified)
                            ? const Color(0xFF00E5FF)
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
          // MAKE AN OFFER / SEND QUOTE Collapsible Panel
          if (_showOfferPanel)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF10141C),
                border: Border(top: BorderSide(color: Color(0xFF1E2638))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🤝 MAKE AN OFFER / SEND QUOTE', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => setState(() => _showOfferPanel = false),
                        child: const Icon(Icons.close, color: Color(0xFF8E9BAE), size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _offerController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Proposed Amount (₹/hr)',
                            labelStyle: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFF080B10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                        onPressed: _sendOffer,
                        child: const Text('Send Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _handshakeVerified,
                            activeColor: const Color(0xFF00E5FF),
                            onChanged: (val) => setState(() => _handshakeVerified = val ?? true),
                          ),
                          const Text('Secure P2P Handshake Verification', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11)),
                        ],
                      ),
                      const Text('Estimated Rate (Subject to agreement)', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
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
                  label: Text(prompt, style: const TextStyle(fontSize: 11, color: Color(0xFF00E5FF))),
                  backgroundColor: const Color(0xFF10141C),
                  side: const BorderSide(color: Color(0xFF1E2638), width: 1),
                  onPressed: () => _send(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF10141C),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.handshake, color: Color(0xFF00E5FF)),
                  tooltip: 'Make an Offer / Quote',
                  onPressed: () => setState(() => _showOfferPanel = !_showOfferPanel),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type negotiation message...',
                      hintStyle: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF080B10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF00E5FF)), onPressed: () => _send(_textController.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
