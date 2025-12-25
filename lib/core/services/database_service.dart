import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';

/// 数据库服务 - 统一管理数据库初始化和访问
class DatabaseService {
  static DatabaseService? _instance;
  final DatabaseHelper _dbHelper;
  final SharedPrefsHelper _prefsHelper;

  DatabaseService._internal()
    : _dbHelper = DatabaseHelper(),
      _prefsHelper = SharedPrefsHelper();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  /// 获取数据库助手
  DatabaseHelper get dbHelper => _dbHelper;

  /// 获取SharedPreferences助手
  SharedPrefsHelper get prefsHelper => _prefsHelper;

  /// 初始化服务
  Future<void> initialize() async {
    // 初始化SharedPreferences
    await _prefsHelper.init();

    // 初始化数据库（首次访问时会自动创建）
    await _dbHelper.database;
  }

  /// 关闭服务
  Future<void> close() async {
    await _dbHelper.close();
  }

  /// 重置所有数据
  Future<void> resetAllData() async {
    await _dbHelper.clearAllData();
    await _prefsHelper.clear();
    await _prefsHelper.init();
  }
}
