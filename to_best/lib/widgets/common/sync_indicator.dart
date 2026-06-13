import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncNotifierProvider);
    return _buildDot(status);
  }

  Widget _buildDot(SyncStatus status) {
    Color color;
    Widget icon;

    switch (status) {
      case SyncStatus.syncing:
        color = Colors.blue;
        icon = const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
        break;
      case SyncStatus.ok:
        color = Colors.green;
        icon = const Icon(Icons.check, size: 10, color: Colors.white);
        break;
      case SyncStatus.error:
        color = Colors.red;
        icon = const Icon(Icons.error_outline, size: 10, color: Colors.white);
        break;
      case SyncStatus.offline:
        color = Colors.orange;
        icon = const Icon(Icons.wifi_off, size: 10, color: Colors.white);
        break;
      case SyncStatus.idle:
        color = Colors.grey;
        icon = const Icon(Icons.cloud_outlined, size: 10, color: Colors.white);
        break;
    }

    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: icon),
    );
  }
}
