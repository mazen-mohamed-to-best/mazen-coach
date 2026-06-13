class VersionInfo {
  final int minBuild;
  final int latestBuild;
  final String latestVersionName;
  final String downloadUrl;
  final String notesAr;
  final String notesEn;
  final bool isSupported;

  const VersionInfo({
    required this.minBuild,
    required this.latestBuild,
    required this.latestVersionName,
    required this.downloadUrl,
    required this.notesAr,
    required this.notesEn,
    required this.isSupported,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
    minBuild:          _parseInt(json['minBuild'])     ?? 1,
    latestBuild:       _parseInt(json['latestBuild'])  ?? 1,
    latestVersionName: json['latestVersionName']?.toString() ?? '1.0.0',
    downloadUrl:       json['downloadUrl']?.toString() ?? '',
    notesAr:           json['notesAr']?.toString()     ?? '',
    notesEn:           json['notesEn']?.toString()     ?? '',
    isSupported:       _parseBool(json['isSupported']),
  );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Handles bool, "true"/"false" strings, 1/0 integers
  static bool _parseBool(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is int) return v != 0;
    final s = v.toString().toLowerCase().trim();
    return s != 'false' && s != '0' && s != 'no';
  }
}

enum UpdateStatus {
  upToDate,
  optional,
  forced,
  unsupported,
  unknown,
}

class VersionState {
  final UpdateStatus status;
  final VersionInfo? info;
  final int currentBuild;
  final String currentVersionName;
  final bool isLoading;
  final String? error;

  const VersionState({
    required this.status,
    this.info,
    this.currentBuild = 0,
    this.currentVersionName = '',
    this.isLoading = false,
    this.error,
  });

  const VersionState.loading()
      : status = UpdateStatus.unknown,
        info = null,
        currentBuild = 0,
        currentVersionName = '',
        isLoading = true,
        error = null;

  const VersionState.unknown()
      : status = UpdateStatus.unknown,
        info = null,
        currentBuild = 0,
        currentVersionName = '',
        isLoading = false,
        error = null;

  bool get isBlocked =>
      status == UpdateStatus.forced || status == UpdateStatus.unsupported;

  bool get hasUpdate =>
      status == UpdateStatus.optional || status == UpdateStatus.forced || status == UpdateStatus.unsupported;
}
