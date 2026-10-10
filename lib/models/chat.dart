class ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final bool isSlotRequest;
  final bool isUpiRequest;
  final bool isPinVerified;
  final String? upiAmount;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.isSlotRequest = false,
    this.isUpiRequest = false,
    this.isPinVerified = false,
    this.upiAmount,
  });
}
