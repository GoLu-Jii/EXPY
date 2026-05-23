import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/class_model.dart';
import '../models/month_model.dart';
import '../models/transaction_model.dart';
import '../theme.dart';
import '../widgets/ascii_divider.dart';
import '../widgets/transaction_tile.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;
  final MonthModel month;

  const ClassDetailScreen({
    super.key,
    required this.classModel,
    required this.month,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  List<TransactionModel> _transactions = [];
  double _total = 0;
  bool _loading = true;

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy  HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txs = await DbHelper.instance
        .getTransactionsForClass(widget.classModel.id!);
    final total =
        await DbHelper.instance.getTotalSpentForClass(widget.classModel.id!);
    setState(() {
      _transactions = txs;
      _total = total;
      _loading = false;
    });
  }

  Future<void> _showAddSheet() async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl =
        TextEditingController(text: _dateFmt.format(DateTime.now()));
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
                '[ ADD TRANSACTION ]',
                style: GoogleFonts.robotoMono(
                  color: kGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amtCtrl,
                autofocus: true,
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
                      style:
                          GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final amt =
                          double.tryParse(amtCtrl.text.trim());
                      if (amt == null || amt <= 0) {
                        setS(() => error = 'INVALID AMOUNT');
                        return;
                      }
                      DateTime ts = DateTime.now();
                      try {
                        ts = _dateFmt.parse(dateCtrl.text.trim());
                      } catch (_) {}
                      await DbHelper.instance.insertTransaction(
                        TransactionModel(
                          classId: widget.classModel.id!,
                          amount: amt,
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
          widget.classModel.className.toUpperCase(),
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
                      horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '═' * 36,
                        style: GoogleFonts.robotoMono(
                            color: kBorder, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.classModel.className.toUpperCase(),
                            style: GoogleFonts.robotoMono(
                              color: kWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '₹${_fmt.format(_total)}',
                            style: GoogleFonts.robotoMono(
                              color: kRed,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '═' * 36,
                        style: GoogleFonts.robotoMono(
                            color: kBorder, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '> NO TRANSACTIONS YET.',
                            style: GoogleFonts.robotoMono(
                                color: kAsh, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          itemBuilder: (ctx, i) {
                            final tx = _transactions[i];
                            return TransactionTile(
                              tx: tx,
                              onDelete: () async {
                                await DbHelper.instance
                                    .deleteTransaction(tx.id!);
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
                    child: const Text('[+ ADD TRANSACTION]'),
                  ),
                ),
              ],
            ),
    );
  }
}
