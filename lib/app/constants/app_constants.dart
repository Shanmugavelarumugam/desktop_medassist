abstract class AppConstants {
  AppConstants._();

  static const String appName = 'MedAssist';
  static const String appVersion = '2.0.0';

  static const int defaultPageSize = 20;
  static const List<int> pageSizeOptions = [10, 20, 50, 100];

  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;
  static const double topbarHeight = 70;

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);
}
