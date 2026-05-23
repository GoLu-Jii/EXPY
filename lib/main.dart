import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'database/db_helper.dart';
import 'screens/timeline_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    systemNavigationBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
  ));
  await DbHelper.instance.database;
  await DbHelper.instance.cleanOldData();
  runApp(const ExpyApp());
}

class ExpyApp extends StatelessWidget {
  const ExpyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXPY',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _loading = true;
  bool _hasMonths = false;

  @override
  void initState() {
    super.initState();
    _checkMonths();
  }

  Future<void> _checkMonths() async {
    final months = await DbHelper.instance.getAllMonths();
    setState(() {
      _hasMonths = months.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBgColor,
        body: Center(
          child: SizedBox.shrink(),
        ),
      );
    }
    if (!_hasMonths) {
      return WelcomeScreen(onBegin: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TimelineScreen()),
        );
      });
    }
    return const TimelineScreen();
  }
}

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onBegin;
  const WelcomeScreen({super.key, required this.onBegin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '> EXPY v1.0',
                style: GoogleFonts.robotoMono(
                  color: kGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '  TRACK OR FORGET.',
                style: GoogleFonts.robotoMono(
                  color: kAsh,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: onBegin,
                child: const Text('[ BEGIN ]'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
