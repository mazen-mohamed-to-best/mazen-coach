import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/local_db_service.dart';
import 'services/settings_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Future.wait([
    LocalDbService.instance.init(),
    SettingsService.instance.init(),
  ]);

  await ApiService.instance.loadConfig();

  runApp(
    const ProviderScope(
      child: ToBestApp(),
    ),
  );
}
