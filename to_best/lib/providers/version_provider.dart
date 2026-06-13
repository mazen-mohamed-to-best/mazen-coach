import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/version_model.dart';
import '../services/version_check_service.dart';

class VersionNotifier extends StateNotifier<VersionState> {
  VersionNotifier() : super(const VersionState.loading()) {
    _check();
  }

  Future<void> _check() async {
    state = const VersionState.loading();
    final result = await VersionCheckService.instance.checkVersion();
    state = result;
  }

  Future<void> refresh() => _check();

  Future<void> skipUpdate() async {
    await VersionCheckService.instance.skipCurrentUpdate();
    state = VersionState(
      status: UpdateStatus.upToDate,
      info: state.info,
      currentBuild: state.currentBuild,
      currentVersionName: state.currentVersionName,
    );
  }
}

final versionProvider =
    StateNotifierProvider<VersionNotifier, VersionState>((ref) => VersionNotifier());
