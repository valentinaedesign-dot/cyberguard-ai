import 'package:flutter_test/flutter_test.dart';
import 'package:cyberguard_ai/main.dart';

void main() {
  testWidgets('CyberGuard AI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CyberGuardApp());
    expect(find.text('CyberGuard AI'), findsOneWidget);
  });
}
```

6. Appuie sur **Ctrl + S**

---

Regarde en bas — il doit maintenant afficher **0 problème** !

Ensuite dans le terminal tape :
```
flutter run -d chrome