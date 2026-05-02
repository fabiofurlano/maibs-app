import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feed_screen.dart';
import 'screens/quiet_room.dart';
import 'screens/decide_screen.dart';
import 'screens/agents_screen.dart';
import 'services/agui_client.dart';
import 'services/audio_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final server = prefs.getString('server') ?? 'localhost';
  final port = prefs.getInt('port') ?? 8432;

  runApp(MAIBSApp(
    serverHost: server,
    serverPort: port,
  ));
}

class MAIBSApp extends StatefulWidget {
  final String serverHost;
  final int serverPort;

  const MAIBSApp({
    super.key,
    required this.serverHost,
    required this.serverPort,
  });

  @override
  State<MAIBSApp> createState() => _MAIBSAppState();
}

class _MAIBSAppState extends State<MAIBSApp> {
  final AguiClient _client = AguiClient();
  final CompanionAudio _audio = CompanionAudio();
  int _selectedIndex = 0;

  static const Color _accentGold = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    _client.connect(widget.serverHost, widget.serverPort);
    _audio.configure('http://${widget.serverHost}:${widget.serverPort}');
  }

  @override
  void dispose() {
    _client.disconnect();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAIBS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentGold,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF080810),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Sora',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Sora',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 13,
            height: 1.5,
            color: Color(0xFFB0B0C0),
          ),
          labelSmall: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 11,
            letterSpacing: 0.5,
            color: Color(0xFF707088),
          ),
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF080810),
                Color(0xFF0A0A18),
                Color(0xFF0D0D20),
                Color(0xFF080810),
              ],
            ),
          ),
          child: _buildScreen(),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00080810),
            Color(0xFF080810),
          ],
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0D0D18),
        selectedItemColor: _accentGold,
        unselectedItemColor: Colors.white38,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Quiet Room',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_outlined),
            label: 'Decide',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dns_outlined),
            label: 'Agents',
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return FeedScreen(client: _client, audio: _audio);
      case 1:
        return QuietRoom(client: _client, audio: _audio);
      case 2:
        return DecideScreen(client: _client);
      case 3:
        return AgentsScreen(client: _client);
      default:
        return FeedScreen(client: _client, audio: _audio);
    }
  }
}
