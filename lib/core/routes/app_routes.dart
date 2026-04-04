import 'package:flutter/material.dart';

import '../../screens/loading_page.dart';
import '../../screens/main_screen.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/account/create_account_page.dart';
import '../../features/account/subscription_page.dart';
import '../../features/account/account_page.dart';
import '../../features/settings/setting_page.dart';
import '../../features/scan/detail_page.dart';
import '../../features/news/news_detail_page.dart';
import '../../features/account/login_page.dart'; 

// นำเข้าไฟล์หน้าจอเพิ่มเติม
import '../../features/settings/tos_page.dart';
import '../../features/settings/faq_page.dart';
import '../../features/settings/contact_us_page.dart';

class AppRoutes {
  static const String loading = '/'; 
  static const String main = '/main'; 
  
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String account = '/account';
  static const String createAccount = '/create_account';
  static const String subscription = '/subscription';
  static const String scanResult = '/scan_result';
  static const String newsDetail = '/news_detail';
  
  // เส้นทางหน้าจอเพิ่มเติม
  static const String tos = '/tos';
  static const String faq = '/faq';
  static const String contact = '/contact';
  static const String login = '/login';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      loading: (context) => const LoadingPage(),
      main: (context) => const MainScreen(),
      notifications: (context) => const NotificationsPage(),
      settings: (context) => const SettingPage(),
      account: (context) => const AccountPage(),
      createAccount: (context) => const CreateAccountPage(),
      subscription: (context) => const SubscriptionPage(),
      scanResult: (context) => const DetailPage(),
      newsDetail: (context) => const NewsDetailPage(),
      
      // การจับคู่เส้นทางหน้าจอเพิ่มเติม
      tos: (context) => const TosPage(),
      faq: (context) => const FaqPage(),
      contact: (context) => const ContactUsPage(),
      login: (context) => const LoginPage(),
    };
  }
}