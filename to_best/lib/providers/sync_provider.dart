import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier() : super(SyncStatus.idle) {
    SyncService.instance.setStatusCallback((status) {
      state = status;
    });
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncStatus>(
  (ref) => SyncNotifier(),
);
