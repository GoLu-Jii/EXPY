// lib/widgets/ledger_entry_tile.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/ledger_model.dart';
import '../theme.dart';

class LedgerEntryTile extends StatefulWidget {
  final LedgerModel entry;
  final String currentMonthYear;
  final VoidCallback onSettle;
  final VoidCallback onDelete;

  const LedgerEntryTile({
    super.key,
    required this.entry,
    required this.currentMonthYear,
    required this.onSettle,
    required this.onDelete,
  });

  @override
  State<LedgerEntryTile> createState() => _LedgerEntryTileState();
}

class _LedgerEntryTileState extends State<LedgerEntryTile> {
  bool _confirmDelete = false;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy  HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isGive = e.type == 'give';
    final amtColor = isGive ? kRed : kGreen;
    final isCarried = e.originalMonthYear != widget.currentMonthYear;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.entityName.toUpperCase(),
                  style: GoogleFonts.robotoMono(
                    color: kWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '₹${_fmt.format(e.amount)}',
                style: GoogleFonts.robotoMono(
                  color: amtColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (e.note != null && e.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              e.note!,
              style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatDate(e.timestamp),
                style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10),
              ),
              if (isCarried) ...[
                const SizedBox(width: 8),
                Text(
                  '[FROM ${e.originalMonthYear}]',
                  style: GoogleFonts.robotoMono(color: kGreen, fontSize: 10),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (_confirmDelete)
            Row(
              children: [
                Text(
                  'DELETE THIS ENTRY? ',
                  style: GoogleFonts.robotoMono(color: kRed, fontSize: 11),
                ),
                TextButton(
                  onPressed: widget.onDelete,
                  child: Text('[YES]',
                      style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
                ),
                TextButton(
                  onPressed: () => setState(() => _confirmDelete = false),
                  child: Text('[NO]',
                      style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onSettle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kGreen, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: Text(
                    '[SETTLE]',
                    style: GoogleFonts.robotoMono(color: kGreen, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _confirmDelete = true),
                  child: Text(
                    '[DEL]',
                    style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
