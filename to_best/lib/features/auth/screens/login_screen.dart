import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/settings_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  // Setup state
  bool _showSetup = false;
  final _urlCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  void _checkSetup() {
    final s = SettingsService.instance;
    if (s.webAppUrl.isEmpty || s.secretKey.isEmpty) {
      setState(() => _showSetup = true);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final err = await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (mounted) {
      setState(() { _loading = false; _errorMsg = err; });
      if (err == null) context.go('/home');
    }
  }

  Future<void> _saveConfig() async {
    if (_urlCtrl.text.trim().isEmpty || _secretCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'يرجى إدخال رابط WebApp ومفتاح الأمان');
      return;
    }
    await ApiService.instance.saveConfig(
      _urlCtrl.text.trim(),
      _secretCtrl.text.trim(),
    );
    final result = await ApiService.instance.testConnection();
    if (mounted) {
      if (result?['ok'] == true) {
        setState(() { _showSetup = false; _errorMsg = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.connOK), backgroundColor: AppColors.success),
        );
      } else {
        setState(() => _errorMsg = context.l10n.connFail);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w700,
                  )),
              Text(l10n.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 40),

              if (_showSetup) ...[
                _buildSetupCard(l10n, theme),
              ] else ...[
                _buildLoginForm(l10n, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.connection, style: theme.textTheme.titleMedium),
              ],
            ),
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
            if (_errorMsg != null)
              Text(_errorMsg!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveConfig,
                child: Text(l10n.testConnection),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppLocalizations l10n, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) => v?.isEmpty == true ? l10n.email : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => v?.isEmpty == true ? l10n.password : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => _showForgotPassword(),
              child: Text(l10n.forgotPassword),
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(_errorMsg!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.loginBtn, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('أو', style: theme.textTheme.bodySmall),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showGuestLogin(),
            icon: const Icon(Icons.person_outline),
            label: Text(l10n.guestLogin),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/auth/register'),
            child: RichText(
              text: TextSpan(
                text: 'ليس لديك حساب؟ ',
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: l10n.register,
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showSetup = true),
            icon: const Icon(Icons.settings, size: 16),
            label: Text(l10n.connection),
            style: TextButton.styleFrom(foregroundColor: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.forgotPassword, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: context.l10n.email),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await ApiService.instance.forgotPassword(emailCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال رمز إعادة التعيين إلى بريدك')),
                    );
                  }
                },
                child: Text(context.l10n.resetPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuestLogin() {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.guestLogin, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: context.l10n.guestCode),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final err = await ref.read(authProvider.notifier).guestLogin(codeCtrl.text.trim());
                  if (mounted && err == null) context.go('/home');
                  if (mounted && err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: AppColors.error),
                    );
                  }
                },
                child: Text(context.l10n.loginBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
