import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/month_model.dart';
import '../models/ledger_model.dart';
import '../theme.dart';
import '../widgets/ledger_entry_tile.dart';

class LedgerScreen extends StatefulWidget {
  final MonthModel month;
  final String type; // "give" or "take"

  const LedgerScreen({
    super.key,
    required this.month,
    required this.type,
  });

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<LedgerModel> _entries = [];
  bool _loading = true;

  final _dateFmt = DateFormat('dd MMM yyyy  HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all =
        await DbHelper.instance.getLedgerForMonth(widget.month.id!);
    setState(() {
      _entries = all.where((e) => e.type == widget.type).toList();
      _loading = false;
    });
  }

  Future<void> _showAddSheet() async {
    final entityCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl =
        TextEditingController(text: _dateFmt.format(DateTime.now()));
    String selectedType = widget.type;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[ ADD LEDGER ENTRY ]',
                style: GoogleFonts.robotoMono(
                  color: kGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: entityCtrl,
                autofocus: true,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                decoration: InputDecoration(
                  labelText: 'ENTITY NAME',
                  labelStyle:
                      GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'AMOUNT (₹)',
                  labelStyle:
                      GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                decoration: InputDecoration(
                  labelText: 'NOTE (optional)',
                  labelStyle:
                      GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'TYPE: ',
                    style:
                        GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                  ),
                  GestureDetector(
                    onTap: () => setS(() => selectedType = 'give'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedType == 'give' ? kRed : kBorder,
                          width: 1,
                        ),
                        color: selectedType == 'give'
                            ? kRed.withOpacity(0.1)
                            : kBgColor,
                      ),
                      child: Text(
                        'TO GIVE',
                        style: GoogleFonts.robotoMono(
                          color:
                              selectedType == 'give' ? kRed : kAsh,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setS(() => selectedType = 'take'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              selectedType == 'take' ? kGreen : kBorder,
                          width: 1,
                        ),
                        color: selectedType == 'take'
                            ? kGreen.withOpacity(0.1)
                            : kBgColor,
                      ),
                      child: Text(
                        'TO TAKE',
                        style: GoogleFonts.robotoMono(
                          color:
                              selectedType == 'take' ? kGreen : kAsh,
                          fontSize: 11,
                        ),
                      ),
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
                  labelStyle:
                      GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: GoogleFonts.robotoMono(color: kRed, fontSize: 11),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '[CANCEL]',
                      style: GoogleFonts.robotoMono(
                          color: kAsh, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final entity = entityCtrl.text.trim();
                      final amt =
                          double.tryParse(amtCtrl.text.trim());
                      if (entity.isEmpty) {
                        setS(() => error = 'ENTITY NAME REQUIRED');
                        return;
                      }
                      if (amt == null || amt <= 0) {
                        setS(() => error = 'INVALID AMOUNT');
                        return;
                      }
                      DateTime ts = DateTime.now();
                      try {
                        ts = _dateFmt.parse(dateCtrl.text.trim());
                      } catch (_) {}
                      await DbHelper.instance.insertLedger(
                        LedgerModel(
                          monthId: widget.month.id!,
                          entityName: entity,
                          amount: amt,
                          type: selectedType,
                          originalMonthYear: widget.month.monthYear,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                          timestamp: ts.toIso8601String(),
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                    },
                    child: Text(
                      '[ADD]',
                      style: GoogleFonts.robotoMono(
                          color: kGreen, fontSize: 12),
                    ),
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
    final label = widget.type == 'give' ? 'TO GIVE' : 'TO TAKE';

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '[BACK]',
            style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          '[ $label ]',
          style: GoogleFonts.robotoMono(
            color: kWhite,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: _loading
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Text(
                    '─' * 36,
                    style: GoogleFonts.robotoMono(
                        color: kBorder, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '> NO ENTRIES FOR THIS MONTH.',
                            style: GoogleFonts.robotoMono(
                                color: kAsh, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _entries.length,
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            return LedgerEntryTile(
                              entry: e,
                              currentMonthYear: widget.month.monthYear,
                              onSettle: () async {
                                await DbHelper.instance
                                    .settleLedger(e.id!);
                                await _load();
                              },
                              onDelete: () async {
                                await DbHelper.instance
                                    .deleteLedger(e.id!);
                                await _load();
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: _showAddSheet,
                    child: const Text('[+ ADD]'),
                  ),
                ),
              ],
            ),
    );
  }
}
