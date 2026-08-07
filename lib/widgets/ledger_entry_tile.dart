// lib/widgets/ledger_entry_tile.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/ledger_model.dart';
import '../theme.dart';

class LedgerEntryTile extends StatefulWidget {
  final LedgerModel entry;
  final VoidCallback onDelete;
  final Future<void> Function(String entityName, double amount, String type, String? note, String timestamp) onEdit;

  const LedgerEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<LedgerEntryTile> createState() => _LedgerEntryTileState();
}

class _LedgerEntryTileState extends State<LedgerEntryTile> {
  bool _confirmDelete = false;
  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy  HH:mm');

  String _formatDate(String iso) {
    try {
      return _dateFmt.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _showEditSheet() async {
    final e = widget.entry;
    final entityCtrl = TextEditingController(text: e.entityName);
    final amtCtrl = TextEditingController(text: e.amount.toString());
    final noteCtrl = TextEditingController(text: e.note ?? '');
    final dateCtrl = TextEditingController(text: _formatDate(e.timestamp));
    String selectedType = e.type;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[ EDIT LEDGER ENTRY ]',
                  style: GoogleFonts.robotoMono(color: kGreen, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: entityCtrl,
                autofocus: true,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                decoration: InputDecoration(
                  labelText: 'ENTITY NAME',
                  labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'AMOUNT (₹)',
                  labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                decoration: InputDecoration(
                  labelText: 'NOTE (optional)',
                  labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('TYPE: ', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                  GestureDetector(
                    onTap: () => setS(() => selectedType = 'give'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedType == 'give' ? kRed : kBorder, width: 1),
                        color: selectedType == 'give' ? kRed.withOpacity(0.1) : kBgColor,
                      ),
                      child: Text('TO GIVE',
                          style: GoogleFonts.robotoMono(color: selectedType == 'give' ? kRed : kAsh, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setS(() => selectedType = 'take'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedType == 'take' ? kGreen : kBorder, width: 1),
                        color: selectedType == 'take' ? kGreen.withOpacity(0.1) : kBgColor,
                      ),
                      child: Text('TO TAKE',
                          style: GoogleFonts.robotoMono(color: selectedType == 'take' ? kGreen : kAsh, fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                decoration: InputDecoration(
                  labelText: 'DATE',
                  labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('[CANCEL]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final entity = entityCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim());
                      if (entity.isEmpty) { setS(() => error = 'ENTITY NAME REQUIRED'); return; }
                      if (amt == null || amt <= 0) { setS(() => error = 'INVALID AMOUNT'); return; }
                      DateTime ts = DateTime.now();
                      try { ts = _dateFmt.parse(dateCtrl.text.trim()); } catch (_) {}
                      await widget.onEdit(
                        entity, amt, selectedType,
                        noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        ts.toIso8601String(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text('[SAVE]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isGive = e.type == 'give';
    final amtColor = isGive ? kRed : kGreen;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: kBorder, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.entityName.toUpperCase(),
                  style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '₹${_fmt.format(e.amount)}',
                style: GoogleFonts.robotoMono(color: amtColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (e.note != null && e.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(e.note!, style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
          ],
          const SizedBox(height: 4),
          Text(_formatDate(e.timestamp), style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10)),
          const SizedBox(height: 8),
          if (_confirmDelete)
            Row(
              children: [
                Text('DELETE THIS ENTRY? ', style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
                TextButton(
                  onPressed: widget.onDelete,
                  child: Text('[YES]', style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
                ),
                TextButton(
                  onPressed: () => setState(() => _confirmDelete = false),
                  child: Text('[NO]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                ),
              ],
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: _showEditSheet,
                  child: Text('[EDIT]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _confirmDelete = true),
                  child: Text('[DEL]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
