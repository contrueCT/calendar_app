# 日历 (Calendar App)

一个基于 Flutter 开发的功能完善、现代化的日历应用，支持 Android 平台。

## 🌟 项目概述

本项目采用 **MVVM (Model-View-ViewModel)** 架构模式开发，旨在提供一个流畅、易用且功能强大的日程管理工具。它不仅支持基础的日程增删改查，还深度集成了农历、节气、iCalendar 标准支持以及网络订阅功能。

## ✨ 核心功能

- **📅 多视图展示**:
  - **月视图**: 基于 `table_calendar` 定制，支持农历显示、节气节日标注及事件标记。
  - **周视图**: 自定义时间轴布局，直观展示一周内的日程安排。
  - **日视图**: 24 小时详细时间轴，支持点击空白区域快速创建事件。
- **📝 事件管理**:
  - 支持全天事件、重复事件（符合 RFC 5545 RRULE 标准）。
  - 自定义事件颜色、地点、描述及多个提醒设置。
  - 智能冲突检测与重复事件实例缓存优化。
- **🌙 农历与节日**:
  - 完整集成农历日期、二十四节气及中国传统节日。
  - 优先级智能显示（节气 > 节日 > 农历日期）。
- **🔗 iCalendar 集成**:
  - **导入/导出**: 支持 `.ics` 文件的本地导入与导出，方便数据迁移。
  - **网络订阅**: 支持通过 URL 订阅远程日历（如 Google Calendar, Apple Calendar 等），支持自动同步。
- **🔔 智能提醒**:
  - 基于 `flutter_local_notifications` 实现精确定时提醒。
  - 支持多种提醒策略（事件发生时、提前 5/15/30 分钟、1 小时、1 天等）。
- **🚀 性能优化**:
  - **预加载机制**: 自动预加载前后月份数据，确保滑动切换时零延迟。
  - **静默更新**: 后台异步加载数据，UI 实时响应，消除加载闪烁感。
  - **Material 3**: 采用最新的 Material 3 设计语言，支持现代化的动画效果。

## 🏗️ 技术架构

项目严格遵循 MVVM 架构，确保代码的可维护性和可扩展性：

- **View**: 负责 UI 展示，使用 `Provider` 监听 `ViewModel` 的状态变化。
- **ViewModel**: 处理业务逻辑，封装数据请求，通过 `notifyListeners()` 通知 UI 更新。
- **Repository**: 数据访问抽象层，统一管理本地数据库和远程 API。
- **Model**: 纯数据模型定义，包含 JSON 序列化与反序列化逻辑。
- **Service**: 独立的功能服务（如通知服务、iCalendar 解析服务、农历服务等）。

## 🛠️ 技术栈

- **核心框架**: Flutter 3.24+ / Dart 3.5+
- **状态管理**: `provider`
- **本地存储**: `sqflite` (SQLite), `shared_preferences`
- **网络请求**: `dio`
- **日期处理**: `intl`, `timezone`, `lunar`
- **解析工具**: `icalendar_parser`
- **通知系统**: `flutter_local_notifications`
- **UI 组件**: `table_calendar`, `flutter_colorpicker`
- **其他工具**: `uuid`, `share_plus`, `app_settings`

## 📂 项目结构

```text
lib/
├── main.dart                # 应用入口
├── app.dart                 # MaterialApp 配置与路由管理
├── config/                  # 配置文件 (主题、路由)
├── core/                    # 核心模块 (常量、工具类、单例服务)
├── data/                    # 数据层 (模型、仓库、数据源)
├── viewmodels/              # ViewModel 层 (业务逻辑与状态)
└── views/                   # View 层 (页面与组件)
    ├── screens/             # 独立页面
    └── widgets/             # 可复用组件
```

## 🚀 快速开始

### 环境要求

- Flutter SDK: `^3.10.4`
- Android SDK: API 21+

### 运行步骤

1. 克隆项目到本地。
2. 在根目录执行 `flutter pub get` 安装依赖。
3. 连接 Android 设备或启动模拟器。
4. 执行 `flutter run` 启动应用。

### 构建 APK

执行以下命令生成发布版 APK：

```bash
flutter build apk --release
```

产物路径: `build/app/outputs/flutter-apk/app-release.apk`

## 📈 开发进度

- [x] 阶段一：项目初始化与基础架构
- [x] 阶段二：数据层实现 (SQLite & Models)
- [x] 阶段三：日历核心视图 (月/周/日)
- [x] 阶段四：日程管理功能 (CRUD & RRULE)
- [x] 阶段五：提醒通知系统
- [x] 阶段六：iCalendar 导入导出与网络订阅
- [x] 阶段七：UI/UX 优化与性能调优

---
