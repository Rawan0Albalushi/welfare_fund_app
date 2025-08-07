import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../widgets/common/campaign_card.dart';
import '../models/campaign.dart';
import 'quick_donate_amount_screen.dart';
import 'gift_donation_screen.dart';
import 'my_donations_screen.dart';
import 'campaign_donation_screen.dart';
import 'student_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Campaign> _campaigns = [];
  List<Campaign> _allCampaigns = []; // جميع الحملات الأصلية
  int _currentIndex = 0; // Home tab is active (الرئيسية في index 0)
  String _selectedFilter = 'الكل'; // Track selected filter

  @override
  void initState() {
    super.initState();
    _loadSampleCampaigns();
  }

  void _loadSampleCampaigns() {
    _campaigns = [
      Campaign(
        id: '1',
        title: 'مساعدة كبار السن',
        description: 'مساعدة كبار السن في الحصول على الرعاية الصحية والاحتياجات الأساسية',
        imageUrl: '',
        targetAmount: 50000,
        currentAmount: 35000,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 60)),
        isActive: true,
        category: 'الإعانة الشهرية',
        donorCount: 245,
      ),
      Campaign(
        id: '2',
        title: 'مساعدة الأسر المحتاجة',
        description: 'توفير الغذاء والملابس للأسر المحتاجة في المجتمع',
        imageUrl: '',
        targetAmount: 25000,
        currentAmount: 18000,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        isActive: true,
        category: 'السكن والنقل',
        donorCount: 189,
      ),
      Campaign(
        id: '3',
        title: 'تعليم الأطفال',
        description: 'توفير التعليم والكتب الدراسية للأطفال المحتاجين',
        imageUrl: '',
        targetAmount: 75000,
        currentAmount: 42000,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        category: 'فرص التعليم',
        donorCount: 312,
      ),
      Campaign(
        id: '4',
        title: 'توفير أجهزة لطلاب الجامعات',
        description: 'شراء أجهزة كمبيوتر محمول للطلاب ذوي الدخل المحدود لدعم دراستهم.',
        imageUrl: '',
        targetAmount: 40000,
        currentAmount: 12000,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 50)),
        isActive: true,
        category: 'شراء أجهزة',
        donorCount: 98,
      ),
      Campaign(
        id: '5',
        title: 'دعم رسوم اختبارات الطلاب',
        description: 'المساهمة في دفع رسوم اختبارات نهاية العام للطلاب المحتاجين.',
        imageUrl: '',
        targetAmount: 20000,
        currentAmount: 5000,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        isActive: true,
        category: 'رسوم الاختبارات',
        donorCount: 54,
      ),
    ];
    _allCampaigns = List.from(_campaigns); // حفظ نسخة من جميع الحملات
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQuickDonate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuickDonateAmountScreen(),
      ),
    );
  }

  void _onGiftDonation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GiftDonationScreen(),
      ),
    );
  }

  void _onMyDonations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyDonationsScreen(),
      ),
    );
  }

  void _onRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentRegistrationScreen(),
      ),
    );
  }

  void _onCampaignTap(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignDonationScreen(campaign: campaign),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Modern Compact Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    // Compact Header Row
                    Row(
                      children: [
                        // Profile icon with notification badge
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.surface,
                                size: 18,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Welcome text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً بك',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.surface.withOpacity(0.8),
                                ),
                              ),
                              const Text(
                                'تبرع معنا',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Heart icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppColors.surface,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    // Modern Search Bar with glassmorphism effect
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن الجمعيات الخيرية...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: AppColors.secondary,
                              size: 16,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.smallPadding,
                            vertical: AppConstants.smallPadding,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Icons Row - Modern, outside any card
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      children: [
                        Expanded(
                          child:                         _buildModernCircleFeature(
                          icon: Icons.favorite,
                          label: 'التبرع السريع',
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          onTap: _onQuickDonate,
                        ),
                        ),
                        Expanded(
                          child:                         _buildModernCircleFeature(
                          icon: Icons.card_giftcard,
                          label: 'اهداء التبرع',
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight],
                          ),
                          onTap: _onGiftDonation,
                        ),
                        ),
                        Expanded(
                          child:                         _buildModernCircleFeature(
                          icon: Icons.history,
                          label: 'تبرعاتي',
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.secondaryLight],
                          ),
                          onTap: _onMyDonations,
                        ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                                     // Modern Student Help Banner - Image Background with Gradient Overlay
                   Container(
                     width: double.infinity,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: AppColors.primary.withOpacity(0.25),
                           blurRadius: 15,
                           offset: const Offset(0, 8),
                         ),
                       ],
                     ),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(20),
                       child: Stack(
                         children: [
                           // Background Image
                           Container(
                             width: double.infinity,
                             height: 200,
                             decoration: const BoxDecoration(
                               image: DecorationImage(
                                 image: NetworkImage(
                                   'https://images.pexels.com/photos/5905708/pexels-photo-5905708.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                                 ),
                                 fit: BoxFit.cover,
                               ),
                             ),
                           ),
                           // Gradient Overlay for better text readability
                           Container(
                             width: double.infinity,
                             height: 200,
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [
                                   AppColors.primary.withOpacity(0.7),
                                   AppColors.secondary.withOpacity(0.6),
                                   Colors.black.withOpacity(0.4),
                                 ],
                               ),
                             ),
                           ),
                           // Centered Content
                           SizedBox(
                             width: double.infinity,
                             height: 200,
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 Text(
                                   'قدّم طلبك وابدأ رحلتك بثقة',
                                   style: AppTextStyles.titleLarge.copyWith(
                                     fontWeight: FontWeight.bold,
                                     color: Colors.white,
                                     height: 1.2,
                                     shadows: [
                                       Shadow(
                                         color: Colors.black.withOpacity(0.3),
                                         blurRadius: 8,
                                         offset: Offset(0, 2),
                                       ),
                                     ],
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: 8),
                                 Text(
                                   'نحن هنا لنمكِّنك من مواصلة تعليمك',
                                   style: AppTextStyles.bodyMedium.copyWith(
                                     color: Colors.white.withOpacity(0.95),
                                     shadows: [
                                       Shadow(
                                         color: Colors.black.withOpacity(0.2),
                                         blurRadius: 6,
                                         offset: Offset(0, 1),
                                       ),
                                     ],
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: 18),
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 32),
                                   child: Container(
                                     width: double.infinity,
                                     height: 48,
                                     decoration: BoxDecoration(
                                       color: Colors.white,
                                       borderRadius: BorderRadius.circular(12),
                                       boxShadow: [
                                         BoxShadow(
                                           color: Colors.black.withOpacity(0.15),
                                           blurRadius: 8,
                                           offset: const Offset(0, 4),
                                         ),
                                       ],
                                     ),
                                     child: Material(
                                       color: Colors.transparent,
                                       child: InkWell(
                                         onTap: _onRegister,
                                         borderRadius: BorderRadius.circular(12),
                                         child: Center(
                                           child: Row(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               Icon(
                                                 Icons.edit_note,
                                                 color: AppColors.primary,
                                                 size: 20,
                                               ),
                                               const SizedBox(width: 8),
                                               Text(
                                                 'سجل الآن',
                                                 style: AppTextStyles.buttonMedium.copyWith(
                                                   color: AppColors.primary,
                                                   fontWeight: FontWeight.w600,
                                                   fontSize: 15,
                                                   shadows: [
                                                     Shadow(
                                                       color: Colors.black.withOpacity(0.08),
                                                       blurRadius: 2,
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       ),
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                  
                  const SizedBox(height: AppConstants.extraLargePadding),
                  
                  // Campaigns Section
                  const Text(
                    'كن أملًا لطالب محتاج',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Modern Filters
                  Container(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        _buildFilterChip('الكل', _selectedFilter == 'الكل'),
                        const SizedBox(width: 12),
                        _buildFilterChip('فرص التعليم', _selectedFilter == 'فرص التعليم'),
                        const SizedBox(width: 12),
                        _buildFilterChip('السكن والنقل', _selectedFilter == 'السكن والنقل'),
                        const SizedBox(width: 12),
                        _buildFilterChip('الإعانة الشهرية', _selectedFilter == 'الإعانة الشهرية'),
                        const SizedBox(width: 12),
                        _buildFilterChip('شراء أجهزة', _selectedFilter == 'شراء أجهزة'),
                        const SizedBox(width: 12),
                        _buildFilterChip('رسوم الاختبارات', _selectedFilter == 'رسوم الاختبارات'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  if (_campaigns.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.extraLargePadding),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.campaign,
                              size: AppConstants.extraLargeIconSize,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              'لا توجد حملات نشطة في الوقت الحالي',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._campaigns.map((campaign) => CampaignCard(
                      campaign: campaign,
                      onTap: () => _onCampaignTap(campaign),
                    )),
                    
                    const SizedBox(height: AppConstants.extraLargePadding),
                    
                    // Recent Donations Section
                    const Text(
                      'التبرعات الأخيرة',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    // Recent Donations List
                    Container(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 280,
                                child: _buildRecentDonationCard(
                                  donorName: 'فاعل خير',
                                  amount: 500,
                                                                     campaignTitle: 'الإعانة الشهرية',
                                  timeAgo: 'منذ ساعتين',
                                  isAnonymous: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 280,
                                child: _buildRecentDonationCard(
                                  donorName: 'فاعل خير',
                                  amount: 1000,
                                                                     campaignTitle: 'فرص التعليم',
                                  timeAgo: 'منذ 3 ساعات',
                                  isAnonymous: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 280,
                                child: _buildRecentDonationCard(
                                  donorName: 'فاعل خير',
                                  amount: 750,
                                                                     campaignTitle: 'السكن والنقل',
                                  timeAgo: 'منذ 5 ساعات',
                                  isAnonymous: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 280,
                                child: _buildRecentDonationCard(
                                  donorName: 'فاعل خير',
                                  amount: 1200,
                                                                     campaignTitle: 'شراء أجهزة',
                                  timeAgo: 'منذ 6 ساعات',
                                  isAnonymous: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 280,
                                child: _buildRecentDonationCard(
                                  donorName: 'فاعل خير',
                                  amount: 300,
                                                                     campaignTitle: 'رسوم الاختبارات',
                                  timeAgo: 'منذ 7 ساعات',
                                  isAnonymous: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 280,
                                child: _buildRecentDonationCard(
                                  donorName: 'فاعل خير',
                                  amount: 800,
                                                                     campaignTitle: 'فرص التعليم',
                                  timeAgo: 'منذ 8 ساعات',
                                  isAnonymous: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'تبرعاتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  Widget _buildModernCircleFeature({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    bool isCurrentlySelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: false, // Remove checkmark
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
          if (label == 'الكل') {
            _campaigns = _allCampaigns;
          } else {
            _campaigns = _allCampaigns.where((campaign) => campaign.category == label).toList();
          }
        });
      },
      selectedColor: AppColors.surface, // Keep background white
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isCurrentlySelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isCurrentlySelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isCurrentlySelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
          width: isCurrentlySelected ? 2 : 1, // Thicker border for selected
        ),
      ),
    );
  }

  Widget _buildRecentDonationCard({
    required String donorName,
    required double amount,
    required String campaignTitle,
    required String timeAgo,
    required bool isAnonymous,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Donor name and time
          Row(
            children: [
              Expanded(
                child: Text(
                  donorName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 10,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    timeAgo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Campaign title
          Text(
            campaignTitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Amount with icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${amount.toStringAsFixed(0)} ريال',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          
          // Motivational message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volunteer_activism,
                  size: 10,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'ساعد في تحقيق الأمل',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}