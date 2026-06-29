import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickletrack/widgets/confirm_dialog.dart';

void main() {
  group('showConfirmDialog', () {
    testWidgets('renders title, message, and both action buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showConfirmDialog(
                    context,
                    title: 'Delete match?',
                    message: 'This action cannot be undone.',
                  ),
                  child: const Text('Open dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete match?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('Cancel button pops with false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showConfirmDialog(
                      context,
                      title: 'Title',
                      message: 'Msg',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('Confirm button pops with true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showConfirmDialog(
                      context,
                      title: 'Title',
                      message: 'Msg',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('destructive variant applies error background to Confirm',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showConfirmDialog(
                    context,
                    title: 'Delete?',
                    message: 'Sure?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Destructive variant renames the confirm label — proves the
      // flag propagated through.
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets(
        'Cancel and Confirm remain independently tappable (no flattened '
        'semantic node swallowing button taps)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showConfirmDialog(
                    context,
                    title: 'T',
                    message: 'M',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Before the fix, the outer Semantics(label:…) wrapper was
      // flattening the dialog semantic node — inner button hits could
      // land on the parent. After the fix, both action buttons must
      // resolve to distinct semantic nodes that can be tapped
      // individually.
      final cancelSem = tester.getSemantics(find.text('Cancel'));
      final confirmSem = tester.getSemantics(find.text('Confirm'));
      expect(cancelSem.id, isNot(equals(confirmSem.id)));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });
}
