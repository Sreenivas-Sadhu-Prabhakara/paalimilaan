import 'package:flutter/material.dart';

void main() => runApp(const PaalimilaanApp());

/// Paalimilaan — per-shift cash handover variance, attributed to the staff on
/// duty. Mirrors the Go journal service.
class PaalimilaanApp extends StatelessWidget {
  const PaalimilaanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Paalimilaan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF8E5A3E), useMaterial3: true),
        home: const HomePage(),
      );
}

class Shift {
  final String staff;
  final double openingFloat, shiftSales, countedCash;
  Shift(this.staff, this.openingFloat, this.shiftSales, this.countedCash);
  double get variance => countedCash - (openingFloat + shiftSales);
}

/// perStaff accumulates variance by staff member.
Map<String, double> perStaff(List<Shift> shifts) {
  final out = <String, double>{};
  for (final s in shifts) {
    out[s.staff] = (out[s.staff] ?? 0) + s.variance;
  }
  return out;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _shifts = <Shift>[];
  final _staff = TextEditingController();
  final _float = TextEditingController(text: '1000');
  final _sales = TextEditingController();
  final _counted = TextEditingController();

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _add() {
    if (_staff.text.trim().isEmpty) return;
    setState(() {
      _shifts.insert(0, Shift(_staff.text.trim(), _n(_float), _n(_sales), _n(_counted)));
      _sales.clear();
      _counted.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = perStaff(_shifts);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paalimilaan · shift variance'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _staff, decoration: const InputDecoration(labelText: 'Staff on duty', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            SizedBox(width: 100, child: TextField(controller: _float, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Float ₹', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _sales, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Shift sales ₹', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _counted, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Counted cash ₹', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _add, child: const Text('Log')),
          ]),
        ])),
        if (staff.isNotEmpty) ...[
          const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('By staff', style: TextStyle(fontWeight: FontWeight.w600)))),
          for (final e in staff.entries)
            ListTile(
              dense: true,
              title: Text(e.key),
              trailing: Text('₹${e.value.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: e.value < 0 ? Colors.red : Colors.green)),
            ),
          const Divider(),
        ],
        Expanded(child: ListView.builder(
          itemCount: _shifts.length,
          itemBuilder: (_, i) {
            final s = _shifts[i];
            return ListTile(
              dense: true,
              title: Text('${s.staff} · sales ₹${s.shiftSales.toStringAsFixed(0)}'),
              trailing: Text('${s.variance >= 0 ? '+' : ''}₹${s.variance.toStringAsFixed(2)}',
                  style: TextStyle(color: s.variance < 0 ? Colors.red : Colors.green)),
            );
          },
        )),
      ]),
    );
  }
}
