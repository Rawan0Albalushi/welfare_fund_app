import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../constants/app_colors.dart';
import '../responsive/responsive_layout.dart';
import 'web_header.dart';
import 'web_sidebar.dart';

/// Scaffold مخصص للويب مع header و responsive layout
class WebScaffold extends StatefulWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onNavigationChanged;
  final Widget? floatingActionButton;
  final bool showBackButton;
  
  const WebScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onNavigationChanged,
    this.floatingActionButton,
    this.showBackButton = false,
  });
  
  @override
  State<WebScaffold> createState() => _WebScaffoldState();
}

class _WebScaffoldState extends State<WebScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    // إذا لم يكن ويب، أرجع الـ body مباشرة
    if (!kIsWeb) {
      return widget.body;
    }
    
    final info = ResponsiveLayout.getResponsiveInfo(context);
    
    // Desktop & Tablet: Header + Content
    if (info.isDesktop || info.isTablet) {
      return _buildHeaderLayout(info);
    }
    
    // Mobile Web: Drawer + AppBar
    return _buildMobileWebLayout(info);
  }
  
  Widget _buildHeaderLayout(ResponsiveInfo info) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Navigation
          WebHeader(
            selectedIndex: widget.selectedIndex,
            onItemSelected: widget.onNavigationChanged,
          ),
          
          // Main Content
          Expanded(
            child: widget.body,
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
  
  Widget _buildMobileWebLayout(ResponsiveInfo info) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: const Icon(Icons.menu_rounded),
          color: AppColors.textPrimary,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.volunteer_activism,
                color: AppColors.surface,
                size: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: WebSidebar(
          selectedIndex: widget.selectedIndex,
          onItemSelected: (index) {
            Navigator.pop(context);
            widget.onNavigationChanged(index);
          },
        ),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
