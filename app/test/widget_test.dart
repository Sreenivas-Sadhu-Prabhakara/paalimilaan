import 'package:flutter_test/flutter_test.dart';

import 'package:paalimilaan_app/main.dart';

void main() {
  test('variance and per-staff accumulation', () {
    final s1 = Shift('Ravi', 1000, 4000, 4950); // -50
    final s2 = Shift('Ravi', 1000, 3000, 3990); // -10
    expect(s1.variance, closeTo(-50, 1e-9));
    final agg = perStaff([s1, s2]);
    expect(agg['Ravi'], closeTo(-60, 1e-9));
  });

  testWidgets('renders the shift form', (tester) async {
    await tester.pumpWidget(const PaalimilaanApp());
    expect(find.text('Staff on duty'), findsOneWidget);
  });
}
