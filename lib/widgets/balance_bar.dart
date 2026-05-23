import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class BalanceBar extends StatelessWidget {
  final double percent; // 0.0 to 1.0+
  final int totalBars;

  const BalanceBar({
    super.key,
    required this.percent,
    this.totalBars = 20,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final filled = (clamped * totalBars).round();
    final empty = totalBars - filled;
    final barColor = percent > 0.9 ? kRed : (percent > 0.7 ? Colors.yellow : kGreen);
    final bar = '█' * filled + '░' * empty;
    final pct = (percent * 100).round();

    return Text(
      '[$bar]  $pct% used',
      style: GoogleFonts.robotoMono(
        color: barColor,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}
