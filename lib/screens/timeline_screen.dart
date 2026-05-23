import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/month_model.dart';
import '../theme.dart';
import '../widgets/ascii_divider.dart';
import 'dashboard_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<MonthModel> _months = [];
  Map<int, double> _spentMap = {};
  Map<int, double> _inHandMap = {};
  bool _loading = true;

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final months = await DbHelper.instance.getAllMonths();
    final spentMap = <int, double>{};
    final inHandMap = <int, double>{};
    for (final m in months) {
      final spent = await DbHelper.instance.getTotalSpentForMonth(m.id!);
      final savings = await DbHelper.instance.getNetSavingsForMonth(m.id!);
      final inHand = m.initialBalance - spent - savings;
      spentMap[m.id!] = spent;
      inHandMap[m.id!] = inHand;
    }
    setState(() {
      _months = months;
      _spentMap = spentMap;
      _inHandMap = inHandMap;
      _loading = false;
    });
  }

  Future<void> _showAddMonthDialog() async {
    final monthCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            backgroundColor: kBgColor,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: Text(
              '[ NEW MONTH ]',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 13),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: monthCtrl,
                  style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                  cursorColor: kWhite,
                  decoration: InputDecoration(
                    labelText: 'MONTH (MM-YYYY)',
                    hintText: 'e.g. 05-2026',
                    hintStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
                    labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balCtrl,
                  style: GoogleFonts.robotoMono(color: kWhite, fontSize: 13),
                  cursorColor: kWhite,
                  decoration: InputDecoration(
                    labelText: 'INITIAL BALANCE (₹)',
                    hintStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
                    labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 11),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: GoogleFonts.robotoMono(color: kRed, fontSize: 11),
                  ),
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
                  final my = monthCtrl.text.trim();
                  final balStr = balCtrl.text.trim();
                  // validate MM-YYYY
                  final re = RegExp(r'^\d{2}-\d{4}$');
                  if (!re.hasMatch(my)) {
                    setS(() => error = 'FORMAT: MM-YYYY');
                    return;
                  }
                  final bal = double.tryParse(balStr);
                  if (bal == null) {
                    setS(() => error = 'INVALID BALANCE');
                    return;
                  }
                  final model = MonthModel(monthYear: my, initialBalance: bal);
                  await DbHelper.instance.insertMonth(model);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                },
                child: Text('[CREATE]',
                    style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12)),
              ),
            ],
          );
        });
      },
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
        title: Text(
          'EXPY',
          style: GoogleFonts.robotoMono(
            color: kGreen,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _showAddMonthDialog,
            child: Text(
              '[+ NEW MONTH]',
              style: GoogleFonts.robotoMono(color: kGreen, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _loading
          ? const SizedBox.shrink()
          : _months.isEmpty
              ? Center(
                  child: Text(
                    '> NO MONTHS FOUND.\n  TAP [+ NEW MONTH] TO BEGIN.',
                    style: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _months.length,
                  itemBuilder: (ctx, i) {
                    final m = _months[i];
                    final spent = _spentMap[m.id] ?? 0;
                    final inHand = _inHandMap[m.id] ?? 0;
                    return InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DashboardScreen(month: m),
                          ),
                        );
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '> ',
                              style: GoogleFonts.robotoMono(
                                  color: kGreen, fontSize: 12),
                            ),
                            Text(
                              m.monthYear,
                              style: GoogleFonts.robotoMono(
                                color: kWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${_fmt.format(spent)} spent',
                                  style: GoogleFonts.robotoMono(
                                      color: kAsh, fontSize: 11),
                                ),
                                Text(
                                  '₹${_fmt.format(inHand)} in hand',
                                  style: GoogleFonts.robotoMono(
                                    color: inHand >= 0 ? kGreen : kRed,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
