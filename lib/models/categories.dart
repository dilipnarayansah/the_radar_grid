class SubTrade {
  final String nameEn;
  final String nameHi;
  final String iconEmoji;

  const SubTrade({
    required this.nameEn,
    required this.nameHi,
    required this.iconEmoji,
  });
}

class MarketplacePillar {
  final String id;
  final String nameEn;
  final String nameHi;
  final String iconEmoji;
  final List<SubTrade> subTrades;

  const MarketplacePillar({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.iconEmoji,
    required this.subTrades,
  });
}

class UniversalTaxonomy {
  static const List<MarketplacePillar> pillars = [
    MarketplacePillar(
      id: 'tech_digital',
      nameEn: 'Tech & Digital',
      nameHi: 'टेक और डिजिटल',
      iconEmoji: '💻',
      subTrades: [
        SubTrade(nameEn: 'Coding', nameHi: 'कोडिंग', iconEmoji: '⚡'),
        SubTrade(nameEn: 'PC/Phone Repair', nameHi: 'पीसी/फोन रिपेयर', iconEmoji: '📱'),
        SubTrade(nameEn: 'AI/Data', nameHi: 'एआई/डेटा', iconEmoji: '🤖'),
        SubTrade(nameEn: 'Web Design', nameHi: 'वेब डिज़ाइन', iconEmoji: '🌐'),
      ],
    ),
    MarketplacePillar(
      id: 'education_academics',
      nameEn: 'Education & Academics',
      nameHi: 'शिक्षा और एकेडमिक्स',
      iconEmoji: '📚',
      subTrades: [
        SubTrade(nameEn: 'K-12 Tutoring', nameHi: 'के-12 ट्यूशन', iconEmoji: '📖'),
        SubTrade(nameEn: 'Coding Mentorship', nameHi: 'कोडिंग मेंटरशिप', iconEmoji: '👨‍💻'),
        SubTrade(nameEn: 'Language', nameHi: 'भाषा', iconEmoji: '🗣️'),
        SubTrade(nameEn: 'Exam Prep', nameHi: 'परीक्षा तैयारी', iconEmoji: '📝'),
      ],
    ),
    MarketplacePillar(
      id: 'applied_trades',
      nameEn: 'Applied Trades & Industry',
      nameHi: 'व्यावहारिक ट्रेड और उद्योग',
      iconEmoji: '⚙️',
      subTrades: [
        SubTrade(nameEn: 'Machining/Lathe', nameHi: 'मशीनिंग/लेथ', iconEmoji: '🔩'),
        SubTrade(nameEn: 'Motor Rewinding', nameHi: 'मोटर रिवाइंडिंग', iconEmoji: '⚡'),
        SubTrade(nameEn: 'Welding', nameHi: 'वेल्डिंग', iconEmoji: '🔥'),
        SubTrade(nameEn: 'Electrical', nameHi: 'इलेक्ट्रिकल', iconEmoji: '🔌'),
        SubTrade(nameEn: 'Plumbing', nameHi: 'प्लंबिंग', iconEmoji: '🔧'),
      ],
    ),
    MarketplacePillar(
      id: 'creative_media',
      nameEn: 'Creative & Media',
      nameHi: 'क्रिएटिव और मीडिया',
      iconEmoji: '🎨',
      subTrades: [
        SubTrade(nameEn: 'Video Editing', nameHi: 'वीडियो एडिटिंग', iconEmoji: '🎬'),
        SubTrade(nameEn: 'Graphic Design', nameHi: 'ग्राफिक डिज़ाइन', iconEmoji: '🖼️'),
        SubTrade(nameEn: 'Photography', nameHi: 'फोटोग्राफी', iconEmoji: '📷'),
        SubTrade(nameEn: 'Content Writing', nameHi: 'कंटेंट राइटिंग', iconEmoji: '✍️'),
      ],
    ),
    MarketplacePillar(
      id: 'commerce_professional',
      nameEn: 'Commerce & Professional',
      nameHi: 'वाणिज्य और प्रोफेशनल',
      iconEmoji: '💼',
      subTrades: [
        SubTrade(nameEn: 'GST/Tax', nameHi: 'जीएसटी/टैक्स', iconEmoji: '🧾'),
        SubTrade(nameEn: 'Accounting', nameHi: 'अकाउंटिंग', iconEmoji: '📊'),
        SubTrade(nameEn: 'Documentation Aid', nameHi: 'दस्तावेज़ीकरण सहायता', iconEmoji: '📁'),
        SubTrade(nameEn: 'Legal Drafting', nameHi: 'कानूनी ड्राफ्टिंग', iconEmoji: '⚖️'),
      ],
    ),
    MarketplacePillar(
      id: 'home_lifestyle',
      nameEn: 'Home & Lifestyle',
      nameHi: 'होम और लाइफस्टाइल',
      iconEmoji: '🏠',
      subTrades: [
        SubTrade(nameEn: 'Tiffin/Cooking', nameHi: 'टिफिन/कुकिंग', iconEmoji: '🍲'),
        SubTrade(nameEn: 'Personal Fitness/Yoga', nameHi: 'पर्सनल फिटनेस/योग', iconEmoji: '🧘'),
        SubTrade(nameEn: 'Logistics', nameHi: 'लॉजिस्टिक्स', iconEmoji: '🚚'),
        SubTrade(nameEn: 'Tool Rental', nameHi: 'टूल रेंटल', iconEmoji: '🛠️'),
      ],
    ),
  ];
}
