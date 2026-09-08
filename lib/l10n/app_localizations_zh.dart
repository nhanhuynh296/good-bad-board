// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get about => '关于';

  @override
  String get add => '添加';

  @override
  String get add_player => '添加球员';

  @override
  String get anonymised_player => '已删除球员';

  @override
  String get app_name => '羽毛球比赛生成器';

  @override
  String get are_you_sure_you_want_to_delete_this_player => '确定删除此球员吗？';

  @override
  String get are_you_sure_you_want_to_exit => '确定退出吗？';

  @override
  String get auto_game => '自动比赛';

  @override
  String auto_game_status(String status) {
    return '自动比赛生成：$status';
  }

  @override
  String get break_ => '休息';

  @override
  String get cancel => '取消';

  @override
  String get coming_soon => '即将推出';

  @override
  String get court_background => '球场背景';

  @override
  String court_n(int n) {
    return '球场$n';
  }

  @override
  String get delete => '删除';

  @override
  String get done => '完成';

  @override
  String get elo => '等级分';

  @override
  String get email => '邮箱';

  @override
  String get first_name => '名字';

  @override
  String get game_based => '计分制';

  @override
  String get game_duration => '比赛时长';

  @override
  String get game_history => '比赛历史';

  @override
  String get game_is_currently_running => '比赛进行中...';

  @override
  String game_number(int n) {
    return '第$n场比赛';
  }

  @override
  String get game_type => '比赛类型';

  @override
  String get games_history => '比赛历史';

  @override
  String get generate_game => '生成比赛';

  @override
  String get generate_some_game_to_start => '生成比赛以开始';

  @override
  String get history => 'History';

  @override
  String get id => 'ID';

  @override
  String get language => '语言';

  @override
  String get language_name => '简体中文';

  @override
  String get last_name => '姓氏';

  @override
  String get make_game => '创建比赛';

  @override
  String get most_games_played => '参赛最多';

  @override
  String get most_sessions_attended => '出席最多';

  @override
  String n_court(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个球场',
      one: '1个球场',
      zero: '无球场',
    );
    return '$_temp0';
  }

  @override
  String get off => '关闭';

  @override
  String get ok => '确定';

  @override
  String get on => '开启';

  @override
  String player_deleted(String id) {
    return '球员$id已删除';
  }

  @override
  String get player_register => '球员注册';

  @override
  String get player_statistic => '球员统计';

  @override
  String get regenerate => '重新生成';

  @override
  String get regenerate_game => '重新生成比赛';

  @override
  String get reset => '重置';

  @override
  String get save => '保存';

  @override
  String get settings => '设置';

  @override
  String get sign_in_id => '登录ID';

  @override
  String skill_gap_n(num gap) {
    return '水平差距：$gap';
  }

  @override
  String get the_beginning => '开始';

  @override
  String get time_based => '计时制';

  @override
  String get time_remaining => '剩余时间';

  @override
  String get to_current_session => 'To current session';

  @override
  String get today => '今天';

  @override
  String get update => '更新';
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class AppLocalizationsZhHk extends AppLocalizationsZh {
  AppLocalizationsZhHk() : super('zh_HK');

  @override
  String get about => '關於';

  @override
  String get add => '添加';

  @override
  String get add_player => '添加球員';

  @override
  String get anonymised_player => '已刪除球員';

  @override
  String get app_name => '羽毛球比賽生成器';

  @override
  String get are_you_sure_you_want_to_delete_this_player => '確定刪除此球員？';

  @override
  String get are_you_sure_you_want_to_exit => '確定退出？';

  @override
  String get auto_game => '自動比賽';

  @override
  String auto_game_status(String status) {
    return '自動比賽生成：$status';
  }

  @override
  String get break_ => '休息';

  @override
  String get cancel => '取消';

  @override
  String get coming_soon => '即將推出';

  @override
  String get court_background => '球場背景';

  @override
  String court_n(int n) {
    return '球場$n';
  }

  @override
  String get delete => '刪除';

  @override
  String get done => '完成';

  @override
  String get elo => '等級分';

  @override
  String get email => '電郵';

  @override
  String get first_name => '名字';

  @override
  String get game_based => '計分制';

  @override
  String get game_duration => '比賽時長';

  @override
  String get game_history => '比賽歷史';

  @override
  String get game_is_currently_running => '比賽進行中...';

  @override
  String game_number(int n) {
    return '第$n場比賽';
  }

  @override
  String get game_type => '比賽類型';

  @override
  String get games_history => '比賽歷史';

  @override
  String get generate_game => '生成比賽';

  @override
  String get generate_some_game_to_start => '生成比賽以開始';

  @override
  String get id => 'ID';

  @override
  String get language => '語言';

  @override
  String get language_name => '繁體中文';

  @override
  String get last_name => '姓氏';

  @override
  String get make_game => '創建比賽';

  @override
  String get most_games_played => '參賽最多';

  @override
  String get most_sessions_attended => '出席最多';

  @override
  String n_court(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個球場',
      one: '1個球場',
      zero: '無球場',
    );
    return '$_temp0';
  }

  @override
  String get off => '關閉';

  @override
  String get ok => '確定';

  @override
  String get on => '開啟';

  @override
  String player_deleted(String id) {
    return '球員$id已刪除';
  }

  @override
  String get player_register => '球員註冊';

  @override
  String get player_statistic => '球員統計';

  @override
  String get regenerate => '重新生成';

  @override
  String get regenerate_game => '重新生成比賽';

  @override
  String get reset => '重置';

  @override
  String get save => '保存';

  @override
  String get settings => '設定';

  @override
  String get sign_in_id => '登入ID';

  @override
  String skill_gap_n(num gap) {
    return '水平差距：$gap';
  }

  @override
  String get the_beginning => '開始';

  @override
  String get time_based => '計時制';

  @override
  String get time_remaining => '剩餘時間';

  @override
  String get today => '今日';

  @override
  String get update => '更新';
}
