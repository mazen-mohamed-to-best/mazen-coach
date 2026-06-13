import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/version_model.dart';
import 'api_service.dart';

class VersionCheckService {
  VersionCheckService._();
  static final VersionCheckService instance = VersionCheckService._();

  static const _prefSkipBuild  = 'skip_update_build';
  static const _prefCacheJson  = 'version_cache_json';
  static const _prefCacheTs    = 'version_cache_ts';
  static const _cacheTtlMs     = 6 * 60 * 60 * 1000; // 6 hours

  PackageInfo? _packageInfo;

  Future<PackageInfo> _getPackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  Future<int> get currentBuildNumber async {
    final info = await _getPackageInfo();
    return int.tryParse(info.buildNumber) ?? 1;
  }

  Future<String> get currentVersionName async {
    final info = await _getPackageInfo();
    return info.version;
  }

  // ── Public API ─────────────────────────────────────────────

  Future<VersionState> checkVersion() async {
    final prefs   = await SharedPreferences.getInstance();
    final build   = await currentBuildNumber;
    final vName   = await currentVersionName;

    // Try to serve from cache first (valid for 6h)
    VersionInfo? info = _loadCache(prefs);

    if (info == null) {
      // Fetch from server
      try {
        final result = await ApiService.instance.checkVersion(build);
        if (result != null) {
          info = VersionInfo.fromJson(result);
          _saveCache(prefs, info);
        }
      } catch (_) {}
    }

    if (info == null) {
      // No server response and no cache — allow through silently
      return const VersionState.unknown();
    }

    final status = _resolveStatus(info, build, prefs);

    return VersionState(
      status: status,
      info: info,
      currentBuild: build,
      currentVersionName: vName,
    );
  }

  Future<void> skipCurrentUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final info  = _loadCache(prefs);
    if (info != null) {
      await prefs.setInt(_prefSkipBuild, info.latestBuild);
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefCacheJson);
    await prefs.remove(_prefCacheTs);
    await prefs.remove(_prefSkipBuild);
  }

  // ── Helpers ────────────────────────────────────────────────

  VersionInfo? _loadCache(SharedPreferences prefs) {
    final ts = prefs.getInt(_prefCacheTs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - ts > _cacheTtlMs) return null;

    final json = prefs.getString(_prefCacheJson);
    if (json == null) return null;
    try {
      return VersionInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _saveCache(SharedPreferences prefs, VersionInfo info) {
    prefs.setString(_prefCacheJson, jsonEncode({
      'minBuild':          info.minBuild,
      'latestBuild':       info.latestBuild,
      'latestVersionName': info.latestVersionName,
      'downloadUrl':       info.downloadUrl,
      'notesAr':           info.notesAr,
      'notesEn':           info.notesEn,
      'isSupported':       info.isSupported,
    }));
    prefs.setInt(_prefCacheTs, DateTime.now().millisecondsSinceEpoch);
  }

  UpdateStatus _resolveStatus(VersionInfo info, int build, SharedPreferences prefs) {
    // Explicit unsupported flag from server
    if (!info.isSupported) return UpdateStatus.unsupported;

    // Build is below minimum required build → forced update
    if (build < info.minBuild) return UpdateStatus.forced;

    // Optional update available (unless user skipped this version)
    if (build < info.latestBuild) {
      final skippedBuild = prefs.getInt(_prefSkipBuild) ?? 0;
      if (skippedBuild >= info.latestBuild) return UpdateStatus.upToDate;
      return UpdateStatus.optional;
    }

    return UpdateStatus.upToDate;
  }
}
