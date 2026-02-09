import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../constants/app_constants.dart';

/// أنواع الشاشات المختلفة
enum ScreenType { mobile, tablet, desktop }

/// كلاس للحصول على معلومات الشاشة
class ResponsiveInfo {
  final double screenWidth;
  final double screenHeight;
  final ScreenType screenType;
  final bool isWeb;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  
  ResponsiveInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.screenType,
  }) : isWeb = kIsWeb,
       isMobile = screenType == ScreenType.mobile,
       isTablet = screenType == ScreenType.tablet,
       isDesktop = screenType == ScreenType.desktop;
  
  /// الحصول على عدد الأعمدة للشبكة
  int get gridColumns {
    if (isDesktop) return 3;
    if (isTablet) return 2;
    return 1;
  }
  
  /// الحصول على عرض المحتوى الأقصى
  double get maxContentWidth {
    if (isDesktop) return 1400;
    if (isTablet) return 900;
    return screenWidth;
  }
  
  /// الحصول على padding مناسب
  double get horizontalPadding {
    if (isDesktop) return 48;
    if (isTablet) return 32;
    return AppConstants.largePadding;
  }
  
  /// عرض sidebar للديسكتوب
  double get sidebarWidth => 280;
  
  /// هل يظهر sidebar؟
  bool get showSidebar => isWeb && isDesktop;
  
  /// هل يظهر app bar مع drawer؟
  bool get showDrawer => isWeb && !isDesktop;
}

/// Widget للتخطيط المتجاوب
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = getResponsiveInfo(context);
        
        if (info.isDesktop && desktop != null) {
          return desktop!;
        }
        if (info.isTablet && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
  
  /// الحصول على معلومات الشاشة من context
  static ResponsiveInfo getResponsiveInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    ScreenType screenType;
    if (width >= AppConstants.desktopBreakpoint) {
      screenType = ScreenType.desktop;
    } else if (width >= AppConstants.tabletBreakpoint) {
      screenType = ScreenType.tablet;
    } else {
      screenType = ScreenType.mobile;
    }
    
    return ResponsiveInfo(
      screenWidth: width,
      screenHeight: height,
      screenType: screenType,
    );
  }
}

/// Widget لتوسيط المحتوى مع عرض أقصى
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final info = ResponsiveLayout.getResponsiveInfo(context);
    final effectiveMaxWidth = maxWidth ?? info.maxContentWidth;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: info.horizontalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

