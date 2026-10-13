import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'features/shell/main_spot_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }
  runApp(const SpotApp());
}

class _BouncingScrollBehavior extends MaterialScrollBehavior {
  const _BouncingScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class SpotLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'explore': 'Explore',
      'radar': 'Radar',
      'chats': 'Chats',
      'profile': 'Profile',
      'empty_jobs': 'No jobs near you yet — post the first one.',
      'post_job': 'Post Client Job RFQ',
      'post_service': 'Post Spot Service Listing',
      'theme': 'Obsidian Dark / Sunlight Light',
      'lang': 'Language: English / हिंदी',
    },
    'hi': {
      'explore': 'एक्सप्लोर',
      'radar': 'राडार',
      'chats': 'चैट्स',
      'profile': 'प्रोफ़ाइल',
      'empty_jobs': 'आपके पास अभी कोई काम नहीं है — पहला पोस्ट करें।',
      'post_job': 'क्लाइंट जॉब RFQ पोस्ट करें',
      'post_service': 'स्पॉट सर्विस लिस्टिंग पोस्ट करें',
      'theme': 'ऑब्सीडियन डार्क / सनलाइट लाइट',
      'lang': 'भाषा: English / हिंदी',
    },
  };

  static String get(String lang, String key) {
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

class SpotAppController extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;
  final String language;
  final ValueChanged<String> setLanguage;

  const SpotAppController({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required this.language,
    required this.setLanguage,
    required super.child,
  });

  static SpotAppController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SpotAppController>();
  }

  @override
  bool updateShouldNotify(SpotAppController oldWidget) {
    return themeMode != oldWidget.themeMode || language != oldWidget.language;
  }
}

class SpotApp extends StatefulWidget {
  const SpotApp({super.key});

  @override
  State<SpotApp> createState() => _SpotAppState();
}

class _SpotAppState extends State<SpotApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _setLanguage(String lang) {
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    final obsidianDark = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF080B10),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E5FF),
        secondary: Color(0xFF00D2B4),
        surface: Color(0xFF10141C),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ).copyWith(
        bodyMedium: const TextStyle(color: Colors.white),
        bodySmall: const TextStyle(color: Color(0xFF8E9BAE)),
      ),
    );

    final sunlightLight = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F7FC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007A8C),
        secondary: Color(0xFF00B09B),
        surface: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF10141C),
        displayColor: const Color(0xFF10141C),
      ).copyWith(
        bodyMedium: const TextStyle(color: Color(0xFF10141C)),
        bodySmall: const TextStyle(color: Color(0xFF5A6678)),
      ),
    );

    return SpotAppController(
      themeMode: _themeMode,
      toggleTheme: _toggleTheme,
      language: _language,
      setLanguage: _setLanguage,
      child: MaterialApp(
        title: 'Spot Industrial Grid',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _BouncingScrollBehavior(),
        themeMode: _themeMode,
        theme: sunlightLight,
        darkTheme: obsidianDark,
        home: const MainSpotShell(),
      ),
    );
  }
}
