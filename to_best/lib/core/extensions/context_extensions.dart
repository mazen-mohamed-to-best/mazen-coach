import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isArabic => AppLocalizations.of(this).isAr;
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  void showSnack(String message, {Color? backgroundColor, SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      action: action,
    ));
  }

  void showErrorSnack(String message) {
    showSnack(message, backgroundColor: Colors.red);
  }

  void showSuccessSnack(String message) {
    showSnack(message, backgroundColor: Colors.green);
  }

  Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? AppLocalizations.of(this).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: destructive ? Colors.red : colorScheme.primary,
            ),
            child: Text(confirmLabel ?? AppLocalizations.of(this).confirm),
          ),
        ],
      ),
    );
  }
}
