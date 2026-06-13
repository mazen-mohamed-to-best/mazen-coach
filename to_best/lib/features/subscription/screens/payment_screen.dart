import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String planId;
  const PaymentScreen({super.key, required this.planId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _selectedDuration = 1;
  String _promoCode = '';
  double _discount = 0;
  bool _promoLoading = false;
  bool _submitting = false;
  String? _promoMsg;
  String? _imageBase64;
  final _promoCtrl = TextEditingController();

  final Map<int, double> _durationDiscounts = {1: 0, 2: 0.05, 3: 0.1, 6: 0.15, 12: 0.2};

  double get _basePrice => widget.planId == 'full' ? 200 : 100;

  double get _totalPrice {
    final months = _selectedDuration;
    final durDiscount = _durationDiscounts[months] ?? 0;
    final afterDuration = _basePrice * months * (1 - durDiscount);
    return afterDuration * (1 - _discount / 100);
  }

  Future<void> _applyPromo() async {
    if (_promoCtrl.text.isEmpty) return;
    setState(() { _promoLoading = true; _promoMsg = null; });
    final result = await ApiService.instance.checkPromo(_promoCtrl.text.trim().toUpperCase());
    setState(() {
      _promoLoading = false;
      if (result?['ok'] == true && result?['discount'] != null) {
        _discount = (result!['discount'] as num).toDouble();
        _promoCode = _promoCtrl.text.trim().toUpperCase();
        _promoMsg = '✓ تم تطبيق خصم ${_discount.toInt()}%';
      } else {
        _promoMsg = '✗ كود غير صحيح أو منتهي';
        _discount = 0;
        _promoCode = '';
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _submit() async {
    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى رفع إيصال التحويل')));
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _submitting = true);

    final data = {
      'subscriptionType': widget.planId,
      'subscriptionDuration': _selectedDuration,
      'amount': _totalPrice,
      'promoCode': _promoCode,
      'discount': _discount,
      'imageData': _imageBase64,
      'createdAt': DateTime.now().toIso8601String(),
      'name': user.name,
      'email': user.email,
    };

    final result = await ApiService.instance.saveSubscriptionRequest(user.uid, data);

    if (mounted) {
      setState(() => _submitting = false);
      if (result?['ok'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('تم إرسال الطلب ✓'),
            content: const Text('تم استلام طلب اشتراكك وسيتم مراجعته من قِبل المدرب قريباً.'),
            actions: [
              ElevatedButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: const Text('رجوع'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['err']?.toString() ?? 'حدث خطأ'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscribeNow)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Text(widget.planId == 'full' ? '⭐ اشتراك كامل' : '✨ اشتراك خفيف',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),

            // Duration selector
            Text(l10n.subscriptionDuration, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.subDurations.map((d) {
                final isSelected = _selectedDuration == d;
                final durDisc = (_durationDiscounts[d] ?? 0) * 100;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$d ${l10n.month}', style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.w700 : null,
                        )),
                        if (durDisc > 0)
                          Text('وفر ${durDisc.toInt()}%', style: TextStyle(
                            color: isSelected ? Colors.white70 : AppColors.success,
                            fontSize: 10,
                          )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Price summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('السعر الأساسي', style: theme.textTheme.bodyMedium),
                      Text('${(_basePrice * _selectedDuration).toStringAsFixed(0)} ريال', style: theme.textTheme.bodyMedium),
                    ]),
                    if ((_durationDiscounts[_selectedDuration] ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('خصم المدة', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success)),
                        Text('-${((_durationDiscounts[_selectedDuration] ?? 0) * 100).toInt()}%', style: const TextStyle(color: AppColors.success)),
                      ]),
                    ],
                    if (_discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('كود الخصم', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success)),
                        Text('-${_discount.toInt()}%', style: const TextStyle(color: AppColors.success)),
                      ]),
                    ],
                    const Divider(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(l10n.total, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${_totalPrice.toStringAsFixed(0)} ريال',
                          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Promo code
            Text(l10n.promoCode, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                controller: _promoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: 'أدخل كود الخصم', isDense: true),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _promoLoading ? null : _applyPromo,
                child: _promoLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.applyCode),
              ),
            ]),
            if (_promoMsg != null) ...[
              const SizedBox(height: 4),
              Text(_promoMsg!, style: TextStyle(color: _discount > 0 ? AppColors.success : AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),

            // Transfer proof
            Text(l10n.uploadProof, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover, width: double.infinity),
                      )
                    : Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 40),
                          const SizedBox(height: 8),
                          Text('اضغط لرفع إيصال التحويل', style: theme.textTheme.bodySmall),
                        ],
                      )),
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.submitRequest, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
