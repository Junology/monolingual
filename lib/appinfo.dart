import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static late final PackageInfo _packageInfo;
  static late final String licenseText;
  static late final String userDir;
  static late final String tmpDir;
  static late final String cacheDir;
  static late final String dbDir;
  static late final String cfgDir;
  static String? _lastUserDir;

  /// Name of the application.
  /// Do not forget `AppInfo.initialize()` beforehand.
  static String get name => _packageInfo.appName;

  /// Version of the application.
  /// DO not forget `AppInfo.initialize()` beforehand.
  static String get version => _packageInfo.version;

  static String get lastUserDir => _lastUserDir ?? userDir;
  static set lastUserDir(String dir) => _lastUserDir = dir;

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    _packageInfo = await PackageInfo.fromPlatform();
    licenseText = await rootBundle.loadString('LICENSE');
    userDir = await getApplicationDocumentsDirectory().then((d) => d.path);
    tmpDir = join(await getTemporaryDirectory().then((d) => d.path), name);
    // Ensure the temporary directory exists
    final tmpDirectory = Directory(tmpDir);
    if (!tmpDirectory.existsSync()) {
      tmpDirectory.createSync();
    }
    cacheDir = await getApplicationCacheDirectory().then((d) => d.path);
    // Get directory for database
    // We need to prepare this fallback since `getLibraryDirectory()` is implemented in limited platforms, e.g., iOS.
    late Directory dbDir;
    try {
      dbDir = await getLibraryDirectory();
    } catch (_) {
      dbDir = await getApplicationSupportDirectory();
    }
    AppInfo.dbDir = dbDir.path;
    // Get the directory for config files
    // In Linux, it is given by `$XDG_CONFIG_HOME/(appname)`
    if (Platform.isLinux && Platform.environment['XDG_CONFIG_HOME'] != null) {
      final Directory dir = Directory(
        join(Platform.environment['XDG_CONFIG_HOME']!, AppInfo.name),
      );
      if (dir.existsSync()) {
        cfgDir = dir.path;
      } else {
        cfgDir = '';
      }
    } else {
      cfgDir = '';
    }
  }
}
