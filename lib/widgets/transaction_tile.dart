import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel tx;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
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
    final tx = widget.tx;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  tx.note != null && tx.note!.isNotEmpty
                      ? tx.note!
                      : '—',
                  style: GoogleFonts.robotoMono(color: kWhite, fontSize: 12),
                ),
              ),
              Text(
                '₹${_fmt.format(tx.amount)}',
                style: GoogleFonts.robotoMono(
                  color: kRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(tx.timestamp),
            style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10),
          ),
          const SizedBox(height: 4),
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _confirmDelete = true),
                child: Text(
                  '[DEL]',
                  style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
