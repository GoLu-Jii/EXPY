import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/month_model.dart';
import '../models/class_model.dart';
import '../models/ledger_model.dart';
import '../models/savings_model.dart';
import '../theme.dart';
import '../widgets/ascii_divider.dart';
import '../widgets/balance_bar.dart';
import '../widgets/ledger_entry_tile.dart';
import 'class_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final MonthModel month;
  const DashboardScreen({super.key, required this.month});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MonthModel _month;
  double _totalSpent = 0;
  double _savingsNet = 0;
  List<ClassModel> _classes = [];
  List<LedgerModel> _ledger = [];
  List<SavingsModel> _savings = [];

  bool _classesExpanded = true;
  bool _giveExpanded = true;
  bool _takeExpanded = true;
  bool _savingsExpanded = true;

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy  HH:mm');

  @override
  void initState() {
    super.initState();
    _month = widget.month;
    _init();
  }

  Future<void> _init() async {
    await DbHelper.instance.carryForwardUnsettledLedger(
      _month.id!,
      _month.monthYear,
    );
    await _load();
  }

  Future<void> _load() async {
    final spent = await DbHelper.instance.getTotalSpentForMonth(_month.id!);
    final savingsNet = await DbHelper.instance.getNetSavingsForMonth(_month.id!);
    final classes = await DbHelper.instance.getClassesForMonth(_month.id!);
    final ledger = await DbHelper.instance.getLedgerForMonth(_month.id!);
    final savings = await DbHelper.instance.getSavingsForMonth(_month.id!);
    setState(() {
      _totalSpent = spent;
      _savingsNet = savingsNet;
      _classes = classes;
      _ledger = ledger;
      _savings = savings;
    });
  }

  double get _inHand => _month.initialBalance - _totalSpent - _savingsNet;

  List<LedgerModel> get _giveEntries =>
      _ledger.where((e) => e.type == 'give').toList();

  List<LedgerModel> get _takeEntries =>
      _ledger.where((e) => e.type == 'take').toList();

  // ─── DIALOGS ──────────────────────────────────────────────────────────────

  Future<void> _showAddClassDialog() async {
    final ctrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: kBgColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            '[ ADD CLASS ]',
            style: GoogleFonts.robotoMono(color: kGreen, fontSize: 13),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                decoration: InputDecoration(
                  labelText: 'CLASS NAME',
                  labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('[CANCEL]',
                  style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) {
                  setS(() => error = 'NAME REQUIRED');
                  return;
                }
                await DbHelper.instance.insertClass(
                    ClassModel(monthId: _month.id!, className: name));
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: Text('[ADD]',
                  style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showAddLedgerSheet({required String type}) async {
    final entityCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
        text: _dateFmt.format(DateTime.now()));
    String selectedType = type;
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
                    color: kGreen, fontSize: 13, fontWeight: FontWeight.bold),
              ),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                  Text('TYPE: ',
                      style:
                          GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
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
                      child: Text('TO GIVE',
                          style: GoogleFonts.robotoMono(
                              color:
                                  selectedType == 'give' ? kRed : kAsh,
                              fontSize: 11)),
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
                          color: selectedType == 'take' ? kGreen : kBorder,
                          width: 1,
                        ),
                        color: selectedType == 'take'
                            ? kGreen.withOpacity(0.1)
                            : kBgColor,
                      ),
                      child: Text('TO TAKE',
                          style: GoogleFonts.robotoMono(
                              color:
                                  selectedType == 'take' ? kGreen : kAsh,
                              fontSize: 11)),
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
                Text(error!,
                    style:
                        GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.robotoMono(
                            color: kAsh, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final entity = entityCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim());
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
                      await DbHelper.instance.insertLedger(LedgerModel(
                        monthId: _month.id!,
                        entityName: entity,
                        amount: amt,
                        type: selectedType,
                        originalMonthYear: _month.monthYear,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                        timestamp: ts.toIso8601String(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                    },
                    child: Text('[ADD]',
                        style: GoogleFonts.robotoMono(
                            color: kGreen, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showAddSavingsSheet() async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
        text: _dateFmt.format(DateTime.now()));
    String selectedType = 'deposit';
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
                '[ ADD SAVINGS ENTRY ]',
                style: GoogleFonts.robotoMono(
                    color: kGreen, fontSize: 13, fontWeight: FontWeight.bold),
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
                  Text('TYPE: ',
                      style:
                          GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                  GestureDetector(
                    onTap: () => setS(() => selectedType = 'deposit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedType == 'deposit'
                              ? kGreen
                              : kBorder,
                          width: 1,
                        ),
                        color: selectedType == 'deposit'
                            ? kGreen.withOpacity(0.1)
                            : kBgColor,
                      ),
                      child: Text('DEPOSIT',
                          style: GoogleFonts.robotoMono(
                              color: selectedType == 'deposit'
                                  ? kGreen
                                  : kAsh,
                              fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setS(() => selectedType = 'withdraw'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedType == 'withdraw'
                              ? kRed
                              : kBorder,
                          width: 1,
                        ),
                        color: selectedType == 'withdraw'
                            ? kRed.withOpacity(0.1)
                            : kBgColor,
                      ),
                      child: Text('WITHDRAW',
                          style: GoogleFonts.robotoMono(
                              color: selectedType == 'withdraw'
                                  ? kRed
                                  : kAsh,
                              fontSize: 11)),
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
                Text(error!,
                    style:
                        GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.robotoMono(
                            color: kAsh, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amtCtrl.text.trim());
                      if (amt == null || amt <= 0) {
                        setS(() => error = 'INVALID AMOUNT');
                        return;
                      }
                      DateTime ts = DateTime.now();
                      try {
                        ts = _dateFmt.parse(dateCtrl.text.trim());
                      } catch (_) {}
                      await DbHelper.instance.insertSavings(SavingsModel(
                        monthId: _month.id!,
                        amount: amt,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                        type: selectedType,
                        timestamp: ts.toIso8601String(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                    },
                    child: Text('[ADD]',
                        style: GoogleFonts.robotoMono(
                            color: kGreen, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String label, bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: kBgColor,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              expanded ? '▼ ' : '▶ ',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12),
            ),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                color: kWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final inHand = _inHand;
    final pct = _month.initialBalance > 0
        ? (_totalSpent + _savingsNet) / _month.initialBalance
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '═' * 36,
            style: GoogleFonts.robotoMono(color: kBorder, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '  ${_month.monthYear}',
            style: GoogleFonts.robotoMono(
              color: kGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '═' * 36,
            style: GoogleFonts.robotoMono(color: kBorder, fontSize: 11),
          ),
          const SizedBox(height: 8),
          _balRow('INITIAL ', _month.initialBalance, kWhite),
          _balRow('SPENT   ', _totalSpent, kRed),
          _balRow('SAVINGS ', _savingsNet, kAsh),
          _balRow('IN HAND ', inHand, inHand >= 0 ? kGreen : kRed),
          const SizedBox(height: 8),
          BalanceBar(percent: pct),
          const SizedBox(height: 8),
          Text(
            '═' * 36,
            style: GoogleFonts.robotoMono(color: kBorder, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _balRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '  $label',
            style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
          ),
          Text(
            '₹${_fmt.format(value)}',
            style: GoogleFonts.robotoMono(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
          _month.monthYear,
          style: GoogleFonts.robotoMono(
            color: kGreen,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _buildHeader(),

          // ─── CLASSES ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  '[ CLASSES ]',
                  _classesExpanded,
                  () => setState(
                      () => _classesExpanded = !_classesExpanded),
                ),
                if (_classesExpanded) ...[
                  ..._classes.map((c) => _classTile(c)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _showAddClassDialog,
                    child: const Text('[+ ADD CLASS]'),
                  ),
                  const SizedBox(height: 16),
                ],
                const AsciiDivider(),
              ],
            ),
          ),

          // ─── TO GIVE ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  '[ TO GIVE ]',
                  _giveExpanded,
                  () => setState(() => _giveExpanded = !_giveExpanded),
                ),
                if (_giveExpanded) ...[
                  if (_giveEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '  > NO ENTRIES',
                        style: GoogleFonts.robotoMono(
                            color: kAsh, fontSize: 11),
                      ),
                    ),
                  ..._giveEntries.map((e) => LedgerEntryTile(
                        entry: e,
                        currentMonthYear: _month.monthYear,
                        onSettle: () async {
                          await DbHelper.instance.settleLedger(e.id!);
                          await _load();
                        },
                        onDelete: () async {
                          await DbHelper.instance.deleteLedger(e.id!);
                          await _load();
                        },
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        _showAddLedgerSheet(type: 'give'),
                    child: const Text('[+ ADD]'),
                  ),
                  const SizedBox(height: 16),
                ],
                const AsciiDivider(),
              ],
            ),
          ),

          // ─── TO TAKE ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  '[ TO TAKE ]',
                  _takeExpanded,
                  () => setState(() => _takeExpanded = !_takeExpanded),
                ),
                if (_takeExpanded) ...[
                  if (_takeEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '  > NO ENTRIES',
                        style: GoogleFonts.robotoMono(
                            color: kAsh, fontSize: 11),
                      ),
                    ),
                  ..._takeEntries.map((e) => LedgerEntryTile(
                        entry: e,
                        currentMonthYear: _month.monthYear,
                        onSettle: () async {
                          await DbHelper.instance.settleLedger(e.id!);
                          await _load();
                        },
                        onDelete: () async {
                          await DbHelper.instance.deleteLedger(e.id!);
                          await _load();
                        },
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        _showAddLedgerSheet(type: 'take'),
                    child: const Text('[+ ADD]'),
                  ),
                  const SizedBox(height: 16),
                ],
                const AsciiDivider(),
              ],
            ),
          ),

          // ─── SAVINGS ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  '[ SAVINGS ]',
                  _savingsExpanded,
                  () => setState(
                      () => _savingsExpanded = !_savingsExpanded),
                ),
                if (_savingsExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '  NET SAVED: ₹${_fmt.format(_savingsNet)}',
                      style: GoogleFonts.robotoMono(
                        color: _savingsNet >= 0 ? kGreen : kRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_savings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '  > NO ENTRIES',
                        style: GoogleFonts.robotoMono(
                            color: kAsh, fontSize: 11),
                      ),
                    ),
                  ..._savings.map((s) => _savingsTile(s)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _showAddSavingsSheet,
                    child: const Text('[+ ADD]'),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _classTile(ClassModel c) {
    return FutureBuilder<double>(
      future: DbHelper.instance.getTotalSpentForClass(c.id!),
      builder: (ctx, snap) {
        final total = snap.data ?? 0;
        return InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ClassDetailScreen(classModel: c, month: _month),
              ),
            );
            await _load();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: kBorder, width: 1),
            ),
            child: Row(
              children: [
                Text(
                  '  ${c.className}',
                  style: GoogleFonts.robotoMono(
                      color: kWhite, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '₹${_fmt.format(total)}',
                  style: GoogleFonts.robotoMono(
                    color: kRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '>',
                  style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _savingsTile(SavingsModel s) {
    final isDeposit = s.type == 'deposit';
    final color = isDeposit ? kGreen : kRed;
    String _formatDate(String iso) {
      try {
        return _dateFmt.format(DateTime.parse(iso));
      } catch (_) {
        return iso;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Row(
        children: [
          Text(
            isDeposit ? 'deposit' : 'withdraw',
            style: GoogleFonts.robotoMono(color: color, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${_fmt.format(s.amount)}',
            style: GoogleFonts.robotoMono(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (s.note != null && s.note!.isNotEmpty)
                Text(s.note!,
                    style: GoogleFonts.robotoMono(
                        color: kAsh, fontSize: 10)),
              Text(
                _formatDate(s.timestamp),
                style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
