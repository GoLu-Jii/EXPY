import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

enum DividerStyle { single, double }

class AsciiDivider extends StatelessWidget {
  final DividerStyle style;
  final String? label;

  const AsciiDivider({
    super.key,
    this.style = DividerStyle.single,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final char = style == DividerStyle.double ? '═' : '─';
    if (label != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '$char$char$char $label $char$char$char',
          style: GoogleFonts.robotoMono(
            color: kAsh,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        char * 40,
        style: GoogleFonts.robotoMono(
          color: kBorder,
          fontSize: 11,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
