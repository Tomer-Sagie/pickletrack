import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) {
  // AlertDialog builds its own semantic tree (title, content, action
  // buttons). Wrapping it in an outer `Semantics(label: '$title —
  // $message')` does NOT need `container: true` to be useful — but it
  // does cause screen readers to announce the title+message *twice*
  // (once from the wrapper's label, then again via the inner
  // `Text(title)` / `Text(message)`). Trust the dialog's built-in
  // semantic structure and let Material announce each piece once.
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
