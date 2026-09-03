import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static late final PackageInfo _packageInfo;
  static late final String licenseText;

  /// Directory where user data should be stored.
  /// The data here is supposed to persist across application launches.
  static late final String userDir;

  /// Directory where temporary data should be stored.
  /// The data here may be cleared by the system in the next application launch.
  static late final String tmpDir;

  /// Directory where cache data should be stored.
  /// The data here may be cleared by the system at any time.
  static late final String cacheDir;

  /// Directory where database files should be stored.
  /// The data here is supposed to persist across application launches.
  /// In contrast to [userDir], this directory is not supposed to be accessed
  /// by the user directly.
  static late final String dbDir;

  /// Directory where app configuration files should be put.
  /// The field may be empty for some platforms.
  static late final String cfgDir;

  static String? _lastUserDir;

  /// Name of the application.
  /// Do not forget `AppInfo.initialize()` beforehand.
  static String get name => _packageInfo.appName;

  /// Version of the application.
  /// DO not forget `AppInfo.initialize()` beforehand.
  static String get version => _packageInfo.version;

  /// Field to remember the last used user directory across the app.
  /// It falls back to [userDir] if no last user directory is set.
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
