// lib/screens/dashboard_screen.dart

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
    _load();
  }

  Future<void> _load() async {
    final spent = await DbHelper.instance.getTotalSpentForMonth(_month.id!);
    final savingsNet = await DbHelper.instance.getNetSavingsForMonth(_month.id!);
    final classes = await DbHelper.instance.getClassesForMonth(_month.id!);
    final ledger = await DbHelper.instance.getLedgerForMonth(_month.id!);
    final savings = await DbHelper.instance.getSavingsForMonth(_month.id!);
    // Refresh month to pick up any balance edits
    final refreshed = await DbHelper.instance.getMonth(_month.monthYear);
    setState(() {
      if (refreshed != null) _month = refreshed;
      _totalSpent = spent;
      _savingsNet = savingsNet;
      _classes = classes;
      _ledger = ledger;
      _savings = savings;
    });
  }

  double get _inHand => _month.initialBalance - _totalSpent - _savingsNet;
  List<LedgerModel> get _giveEntries => _ledger.where((e) => e.type == 'give').toList();
  List<LedgerModel> get _takeEntries => _ledger.where((e) => e.type == 'take').toList();

  // ─── EDIT INITIAL BALANCE ─────────────────────────────────────────────────

  Future<void> _showEditBalanceDialog() async {
    final ctrl = TextEditingController(text: _month.initialBalance.toString());
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: kBgColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('[ EDIT INITIAL BALANCE ]',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                cursorColor: kWhite,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'NEW BALANCE (₹)',
                  labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('[CANCEL]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () async {
                final val = double.tryParse(ctrl.text.trim());
                if (val == null || val < 0) {
                  setS(() => error = 'INVALID AMOUNT');
                  return;
                }
                await DbHelper.instance.updateMonthBalance(_month.id!, val);
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: Text('[SAVE]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
            ),
          ],
        );
      }),
    );
  }

  // ─── ADD / EDIT CLASS ─────────────────────────────────────────────────────

  Future<void> _showAddClassDialog() async {
    final ctrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: kBgColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('[ ADD CLASS ]',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 13)),
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
                Text(error!, style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('[CANCEL]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) { setS(() => error = 'NAME REQUIRED'); return; }
                await DbHelper.instance.insertClass(ClassModel(monthId: _month.id!, className: name));
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: Text('[ADD]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showEditClassDialog(ClassModel c) async {
    final ctrl = TextEditingController(text: c.className);
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: kBgColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('[ EDIT CLASS ]',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 13)),
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
                Text(error!, style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('[CANCEL]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) { setS(() => error = 'NAME REQUIRED'); return; }
                await DbHelper.instance.updateClassName(c.id!, name);
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: Text('[SAVE]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
            ),
          ],
        );
      }),
    );
  }

  // ─── ADD / EDIT LEDGER ────────────────────────────────────────────────────

  Future<void> _showAddLedgerSheet({required String type}) async {
    final entityCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: _dateFmt.format(DateTime.now()));
    String selectedType = type;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[ ADD LEDGER ENTRY ]',
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
                      await DbHelper.instance.insertLedger(LedgerModel(
                        monthId: _month.id!,
                        entityName: entity,
                        amount: amt,
                        type: selectedType,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        timestamp: ts.toIso8601String(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                    },
                    child: Text('[ADD]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── ADD / EDIT SAVINGS ───────────────────────────────────────────────────

  Future<void> _showAddSavingsSheet() async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: _dateFmt.format(DateTime.now()));
    String selectedType = 'deposit';
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: _savingsForm(
            title: '[ ADD SAVINGS ENTRY ]',
            amtCtrl: amtCtrl,
            noteCtrl: noteCtrl,
            dateCtrl: dateCtrl,
            selectedType: selectedType,
            error: error,
            onTypeChange: (t) => setS(() => selectedType = t),
            onCancel: () => Navigator.pop(ctx),
            onSave: () async {
              final amt = double.tryParse(amtCtrl.text.trim());
              if (amt == null || amt <= 0) { setS(() => error = 'INVALID AMOUNT'); return; }
              DateTime ts = DateTime.now();
              try { ts = _dateFmt.parse(dateCtrl.text.trim()); } catch (_) {}
              await DbHelper.instance.insertSavings(SavingsModel(
                monthId: _month.id!,
                amount: amt,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                type: selectedType,
                timestamp: ts.toIso8601String(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            },
          ),
        );
      }),
    );
  }

  Future<void> _showEditSavingsSheet(SavingsModel s) async {
    final amtCtrl = TextEditingController(text: s.amount.toString());
    final noteCtrl = TextEditingController(text: s.note ?? '');
    final dateCtrl = TextEditingController(
        text: _dateFmt.format(DateTime.tryParse(s.timestamp) ?? DateTime.now()));
    String selectedType = s.type;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: _savingsForm(
            title: '[ EDIT SAVINGS ENTRY ]',
            amtCtrl: amtCtrl,
            noteCtrl: noteCtrl,
            dateCtrl: dateCtrl,
            selectedType: selectedType,
            error: error,
            onTypeChange: (t) => setS(() => selectedType = t),
            onCancel: () => Navigator.pop(ctx),
            onSave: () async {
              final amt = double.tryParse(amtCtrl.text.trim());
              if (amt == null || amt <= 0) { setS(() => error = 'INVALID AMOUNT'); return; }
              DateTime ts = DateTime.now();
              try { ts = _dateFmt.parse(dateCtrl.text.trim()); } catch (_) {}
              await DbHelper.instance.updateSavings(
                s.id!, amt,
                noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                selectedType,
                ts.toIso8601String(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            },
          ),
        );
      }),
    );
  }

  Widget _savingsForm({
    required String title,
    required TextEditingController amtCtrl,
    required TextEditingController noteCtrl,
    required TextEditingController dateCtrl,
    required String selectedType,
    required String? error,
    required void Function(String) onTypeChange,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.robotoMono(color: kGreen, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: amtCtrl,
          autofocus: true,
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
              onTap: () => onTypeChange('deposit'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: selectedType == 'deposit' ? kGreen : kBorder, width: 1),
                  color: selectedType == 'deposit' ? kGreen.withOpacity(0.1) : kBgColor,
                ),
                child: Text('DEPOSIT',
                    style: GoogleFonts.robotoMono(color: selectedType == 'deposit' ? kGreen : kAsh, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onTypeChange('withdraw'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: selectedType == 'withdraw' ? kRed : kBorder, width: 1),
                  color: selectedType == 'withdraw' ? kRed.withOpacity(0.1) : kBgColor,
                ),
                child: Text('WITHDRAW',
                    style: GoogleFonts.robotoMono(color: selectedType == 'withdraw' ? kRed : kAsh, fontSize: 11)),
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
          Text(error, style: GoogleFonts.robotoMono(color: kRed, fontSize: 11)),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text('[CANCEL]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onSave,
              child: Text('[SAVE]', style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  // ─── UI HELPERS ───────────────────────────────────────────────────────────

  Widget _sectionHeader(String label, bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: kBgColor,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(expanded ? '▼ ' : '▶ ',
                style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
            Text(label,
                style: GoogleFonts.robotoMono(
                    color: kWhite, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
          Text('═' * 36, style: GoogleFonts.robotoMono(color: kBorder, fontSize: 11)),
          const SizedBox(height: 4),
          Text('  ${_month.monthYear}',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('═' * 36, style: GoogleFonts.robotoMono(color: kBorder, fontSize: 11)),
          const SizedBox(height: 8),
          // INITIAL row with edit button
          Row(
            children: [
              Text('  INITIAL ', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
              Text('₹${_fmt.format(_month.initialBalance)}',
                  style: GoogleFonts.robotoMono(color: kWhite, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showEditBalanceDialog,
                child: Text('[EDIT]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10)),
              ),
            ],
          ),
          _balRow('SPENT   ', _totalSpent, kRed),
          _balRow('SAVINGS ', _savingsNet, kAsh),
          _balRow('IN HAND ', inHand, inHand >= 0 ? kGreen : kRed),
          const SizedBox(height: 8),
          BalanceBar(percent: pct),
          const SizedBox(height: 8),
          Text('═' * 36, style: GoogleFonts.robotoMono(color: kBorder, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _balRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('  $label', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12)),
          Text('₹${_fmt.format(value)}',
              style: GoogleFonts.robotoMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

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
          child: Text('[BACK]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
        ),
        leadingWidth: 80,
        title: Text(_month.monthYear,
            style: GoogleFonts.robotoMono(color: kGreen, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _buildHeader(),

          // ─── CLASSES ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('[ CLASSES ]', _classesExpanded,
                    () => setState(() => _classesExpanded = !_classesExpanded)),
                if (_classesExpanded) ...[
                  ..._classes.map((c) => _classTile(c)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _showAddClassDialog, child: const Text('[+ ADD CLASS]')),
                  const SizedBox(height: 16),
                ],
                const AsciiDivider(),
              ],
            ),
          ),

          // ─── TO GIVE ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('[ TO GIVE ]', _giveExpanded,
                    () => setState(() => _giveExpanded = !_giveExpanded)),
                if (_giveExpanded) ...[
                  if (_giveEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('  > NO ENTRIES', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                    ),
                  ..._giveEntries.map((e) => LedgerEntryTile(
                        entry: e,
                        onDelete: () async {
                          await DbHelper.instance.deleteLedger(e.id!);
                          await _load();
                        },
                        onEdit: (entity, amt, type, note, ts) async {
                          await DbHelper.instance.updateLedger(e.id!, entity, amt, type, note, ts);
                          await _load();
                        },
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: () => _showAddLedgerSheet(type: 'give'),
                      child: const Text('[+ ADD]')),
                  const SizedBox(height: 16),
                ],
                const AsciiDivider(),
              ],
            ),
          ),

          // ─── TO TAKE ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('[ TO TAKE ]', _takeExpanded,
                    () => setState(() => _takeExpanded = !_takeExpanded)),
                if (_takeExpanded) ...[
                  if (_takeEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('  > NO ENTRIES', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                    ),
                  ..._takeEntries.map((e) => LedgerEntryTile(
                        entry: e,
                        onDelete: () async {
                          await DbHelper.instance.deleteLedger(e.id!);
                          await _load();
                        },
                        onEdit: (entity, amt, type, note, ts) async {
                          await DbHelper.instance.updateLedger(e.id!, entity, amt, type, note, ts);
                          await _load();
                        },
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: () => _showAddLedgerSheet(type: 'take'),
                      child: const Text('[+ ADD]')),
                  const SizedBox(height: 16),
                ],
                const AsciiDivider(),
              ],
            ),
          ),

          // ─── SAVINGS ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('[ SAVINGS ]', _savingsExpanded,
                    () => setState(() => _savingsExpanded = !_savingsExpanded)),
                if (_savingsExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '  NET SAVED: ₹${_fmt.format(_savingsNet)}',
                      style: GoogleFonts.robotoMono(
                          color: _savingsNet >= 0 ? kGreen : kRed,
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_savings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('  > NO ENTRIES', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 11)),
                    ),
                  ..._savings.map((s) => _savingsTile(s)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _showAddSavingsSheet, child: const Text('[+ ADD]')),
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
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(border: Border.all(color: kBorder, width: 1)),
          child: Row(
            children: [
              // Tap name area → go to class detail
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ClassDetailScreen(classModel: c, month: _month)),
                    );
                    await _load();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text('  ${c.className}',
                        style: GoogleFonts.robotoMono(color: kWhite, fontSize: 12)),
                  ),
                ),
              ),
              Text('₹${_fmt.format(total)}',
                  style: GoogleFonts.robotoMono(color: kRed, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              // Edit class name
              GestureDetector(
                onTap: () => _showEditClassDialog(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text('[EDIT]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _savingsTile(SavingsModel s) {
    final isDeposit = s.type == 'deposit';
    final color = isDeposit ? kGreen : kRed;
    String formatDate(String iso) {
      try { return _dateFmt.format(DateTime.parse(iso)); } catch (_) { return iso; }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: kBorder, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isDeposit ? 'deposit' : 'withdraw',
                  style: GoogleFonts.robotoMono(color: color, fontSize: 11)),
              const SizedBox(width: 8),
              Text('₹${_fmt.format(s.amount)}',
                  style: GoogleFonts.robotoMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (s.note != null && s.note!.isNotEmpty)
                Text(s.note!, style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(formatDate(s.timestamp), style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showEditSavingsSheet(s),
                child: Text('[EDIT]', style: GoogleFonts.robotoMono(color: kAsh, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
