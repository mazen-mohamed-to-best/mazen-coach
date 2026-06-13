import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _urlCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _testing = false;
  String? _result;
  bool _ok = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.connection)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إعداد الاتصال بـ Google Apps Script', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('أدخل رابط WebApp ومفتاح الأمان الخاصين بالنظام', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.webAppUrl,
                        prefixIcon: const Icon(Icons.link),
                        hintText: 'https://script.google.com/macros/s/...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _secretCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.secretKey,
                        prefixIcon: const Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_result != null) ...[
                      Row(
                        children: [
                          Icon(_ok ? Icons.check_circle : Icons.error_outline,
                              color: _ok ? AppColors.success : AppColors.error),
                          const SizedBox(width: 8),
                          Text(_result!, style: TextStyle(color: _ok ? AppColors.success : AppColors.error)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _testing ? null : _test,
                        child: _testing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(l10n.testConnection),
                      ),
                    ),
                    if (_ok) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/auth/login'),
                          child: Text(l10n.backToLogin),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _test() async {
    setState(() { _testing = true; _result = null; _ok = false; });
    await ApiService.instance.saveConfig(
      _urlCtrl.text.trim(),
      _secretCtrl.text.trim(),
    );
    final result = await ApiService.instance.testConnection();
    setState(() {
      _testing = false;
      _ok = result?['ok'] == true;
      _result = _ok ? context.l10n.connOK : context.l10n.connFail;
    });
  }
}
