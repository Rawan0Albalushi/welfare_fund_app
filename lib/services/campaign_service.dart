import 'package:dio/dio.dart';
import '../models/campaign.dart';
import 'api_client.dart';

class CampaignService {
  final ApiClient _apiClient = ApiClient();

  // Helper method to parse double values from API
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // ===== STUDENT SUPPORT PROGRAMS (البرامج الموجودة) =====

  // Get all student support programs
  Future<List<Campaign>> getStudentPrograms() async {
    try {
      print('CampaignService: Fetching student programs from API...');
      
      // Try multiple possible endpoints
      List<String> endpoints = [
        '/v1/programs',
        '/programs',
        '/api/v1/programs',
        '/api/programs',
        '/v1/programs/support',
        '/programs/support'
      ];
      
      DioException? lastError;
      
      for (String endpoint in endpoints) {
                 try {
           print('CampaignService: Trying endpoint: $endpoint');
           final response = await _apiClient.dio.get(endpoint);
           
           print('CampaignService: Student Programs API Response status: ${response.statusCode}');
           print('CampaignService: Full URL: ${_apiClient.dio.options.baseUrl}$endpoint');
           print('CampaignService: Response data length: ${response.data.toString().length}');
          
          if (response.statusCode == 200) {
            final List<dynamic> programsData = response.data['data'] ?? response.data;
            
            // Debug: Print first program data types
            if (programsData.isNotEmpty) {
              final firstProgram = programsData.first;
              print('CampaignService: First student program goal_amount type: ${firstProgram['goal_amount'].runtimeType}');
              print('CampaignService: First student program raised_amount type: ${firstProgram['raised_amount'].runtimeType}');
            }
            
            final List<Campaign> programs = programsData.map((program) {
              return Campaign(
                id: program['id']?.toString() ?? '',
                title: program['title'] ?? program['name'] ?? '',
                description: program['description'] ?? '',
                imageUrl: program['image_url'] ?? program['image'] ?? '',
                targetAmount: _parseDouble(program['goal_amount'] ?? program['target_amount'] ?? 0),
                currentAmount: _parseDouble(program['raised_amount'] ?? program['current_amount'] ?? 0),
                startDate: DateTime.parse(program['created_at'] ?? DateTime.now().toIso8601String()),
                endDate: DateTime.parse(program['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
                isActive: program['status'] == 'active' || program['is_active'] == true,
                category: program['category']?['name'] ?? program['category_name'] ?? '',
                donorCount: program['donor_count'] ?? program['donors_count'] ?? 0,
                type: 'student_program', // Mark as student program
              );
            }).toList();
            
                         print('CampaignService: Successfully parsed ${programs.length} student programs from endpoint: $endpoint');
             print('CampaignService: Student program IDs: ${programs.map((p) => p.id).toList()}');
             print('CampaignService: Student program titles: ${programs.map((p) => p.title).toList()}');
             return programs;
          }
        } catch (error) {
          print('CampaignService: Failed to fetch from endpoint $endpoint: $error');
          if (error is DioException) {
            lastError = error;
          }
          continue; // Try next endpoint
        }
      }
      
      // If all endpoints failed, return empty list instead of throwing
      print('CampaignService: All endpoints failed for student programs, returning empty list');
      return [];
      
    } catch (error) {
      print('CampaignService: Error fetching student programs: $error');
      if (error is DioException) {
        print('CampaignService: DioException details: ${error.message}');
        print('CampaignService: Response data: ${error.response?.data}');
      }
      return []; // Return empty list instead of rethrowing
    }
  }

  // Get student program details by ID
  Future<Campaign?> getStudentProgramDetails(String programId) async {
    try {
      print('CampaignService: Fetching student program details for ID: $programId');
      final response = await _apiClient.dio.get('/v1/programs/$programId');
      
      print('CampaignService: Student Program details API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final program = response.data['data'] ?? response.data;
        return Campaign(
          id: program['id']?.toString() ?? '',
          title: program['title'] ?? program['name'] ?? '',
          description: program['description'] ?? '',
          imageUrl: program['image_url'] ?? program['image'] ?? '',
          targetAmount: _parseDouble(program['goal_amount'] ?? program['target_amount'] ?? 0),
          currentAmount: _parseDouble(program['raised_amount'] ?? program['current_amount'] ?? 0),
          startDate: DateTime.parse(program['created_at'] ?? DateTime.now().toIso8601String()),
          endDate: DateTime.parse(program['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
          isActive: program['status'] == 'active' || program['is_active'] == true,
          category: program['category']?['name'] ?? program['category_name'] ?? '',
          donorCount: program['donor_count'] ?? program['donors_count'] ?? 0,
          type: 'student_program', // Mark as student program
        );
      } else {
        throw Exception('Failed to fetch student program details: ${response.statusCode}');
      }
    } catch (error) {
      print('CampaignService: Error fetching student program details: $error');
      return null; // Return null instead of rethrowing
    }
  }

  // ===== CHARITY CAMPAIGNS (الحملات الجديدة) =====

  // Get all charity campaigns
  Future<List<Campaign>> getCharityCampaigns() async {
    try {
      print('CampaignService: Fetching charity campaigns from API...');
      
      // Try multiple possible endpoints
      List<String> endpoints = [
        '/v1/campaigns',
        '/campaigns',
        '/api/v1/campaigns',
        '/api/campaigns',
        '/v1/charity-campaigns',
        '/charity-campaigns'
      ];
      
      DioException? lastError;
      
      for (String endpoint in endpoints) {
                 try {
           print('CampaignService: Trying endpoint: $endpoint');
           final response = await _apiClient.dio.get(endpoint);
           
           print('CampaignService: Charity Campaigns API Response status: ${response.statusCode}');
           print('CampaignService: Full URL: ${_apiClient.dio.options.baseUrl}$endpoint');
           print('CampaignService: Response data length: ${response.data.toString().length}');
          
          if (response.statusCode == 200) {
            final List<dynamic> campaignsData = response.data['data'] ?? response.data;
            
            final List<Campaign> campaigns = campaignsData.map((campaign) {
              return Campaign(
                id: campaign['id']?.toString() ?? '',
                title: campaign['title'] ?? campaign['name'] ?? '',
                description: campaign['description'] ?? '',
                imageUrl: campaign['image_url'] ?? campaign['image'] ?? '',
                targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
                currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
                startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
                endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
                isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
                category: campaign['category']?['name'] ?? campaign['category_name'] ?? '',
                donorCount: campaign['donor_count'] ?? campaign['donors_count'] ?? 0,
                type: 'charity_campaign', // Mark as charity campaign
                isUrgentFlag: campaign['is_urgent'] ?? false,
                isFeatured: campaign['is_featured'] ?? false,
              );
            }).toList();
            
                         print('CampaignService: Successfully parsed ${campaigns.length} charity campaigns from endpoint: $endpoint');
             print('CampaignService: Charity campaign IDs: ${campaigns.map((c) => c.id).toList()}');
             print('CampaignService: Charity campaign titles: ${campaigns.map((c) => c.title).toList()}');
             return campaigns;
          }
        } catch (error) {
          print('CampaignService: Failed to fetch from endpoint $endpoint: $error');
          if (error is DioException) {
            lastError = error;
          }
          continue; // Try next endpoint
        }
      }
      
      // If all endpoints failed, return empty list instead of throwing
      print('CampaignService: All endpoints failed for charity campaigns, returning empty list');
      return [];
      
    } catch (error) {
      print('CampaignService: Error fetching charity campaigns: $error');
      if (error is DioException) {
        print('CampaignService: DioException details: ${error.message}');
        print('CampaignService: Response data: ${error.response?.data}');
      }
      return []; // Return empty list instead of rethrowing
    }
  }

  // Get urgent campaigns
  Future<List<Campaign>> getUrgentCampaigns() async {
    try {
      print('CampaignService: Fetching urgent campaigns from API...');
      final response = await _apiClient.dio.get('/v1/campaigns/urgent');
      
      print('CampaignService: Urgent Campaigns API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsData = response.data['data'] ?? response.data;
        
        final List<Campaign> campaigns = campaignsData.map((campaign) {
          return Campaign(
            id: campaign['id']?.toString() ?? '',
            title: campaign['title'] ?? campaign['name'] ?? '',
            description: campaign['description'] ?? '',
            imageUrl: campaign['image_url'] ?? campaign['image'] ?? '',
            targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
            currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
            startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
            isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
            category: campaign['category']?['name'] ?? campaign['category_name'] ?? '',
            donorCount: campaign['donor_count'] ?? campaign['donors_count'] ?? 0,
            type: 'charity_campaign',
            isUrgentFlag: true,
            isFeatured: campaign['is_featured'] ?? false,
          );
        }).toList();
        
        print('CampaignService: Successfully parsed ${campaigns.length} urgent campaigns');
        return campaigns;
      } else {
        throw Exception('Failed to fetch urgent campaigns: ${response.statusCode}');
      }
    } catch (error) {
      print('CampaignService: Error fetching urgent campaigns: $error');
      return []; // Return empty list instead of rethrowing
    }
  }

  // Get featured campaigns
  Future<List<Campaign>> getFeaturedCampaigns() async {
    try {
      print('CampaignService: Fetching featured campaigns from API...');
      final response = await _apiClient.dio.get('/v1/campaigns/featured');
      
      print('CampaignService: Featured Campaigns API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsData = response.data['data'] ?? response.data;
        
        final List<Campaign> campaigns = campaignsData.map((campaign) {
          return Campaign(
            id: campaign['id']?.toString() ?? '',
            title: campaign['title'] ?? campaign['name'] ?? '',
            description: campaign['description'] ?? '',
            imageUrl: campaign['image_url'] ?? campaign['image'] ?? '',
            targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
            currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
            startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
            isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
            category: campaign['category']?['name'] ?? campaign['category_name'] ?? '',
            donorCount: campaign['donor_count'] ?? campaign['donors_count'] ?? 0,
            type: 'charity_campaign',
            isUrgentFlag: campaign['is_urgent'] ?? false,
            isFeatured: true,
          );
        }).toList();
        
        print('CampaignService: Successfully parsed ${campaigns.length} featured campaigns');
        return campaigns;
      } else {
        throw Exception('Failed to fetch featured campaigns: ${response.statusCode}');
      }
    } catch (error) {
      print('CampaignService: Error fetching featured campaigns: $error');
      return []; // Return empty list instead of rethrowing
    }
  }

  // Get charity campaign details by ID
  Future<Campaign?> getCharityCampaignDetails(String campaignId) async {
    try {
      print('CampaignService: Fetching charity campaign details for ID: $campaignId');
      final response = await _apiClient.dio.get('/v1/campaigns/$campaignId');
      
      print('CampaignService: Charity Campaign details API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final campaign = response.data['data'] ?? response.data;
        return Campaign(
          id: campaign['id']?.toString() ?? '',
          title: campaign['title'] ?? campaign['name'] ?? '',
          description: campaign['description'] ?? '',
          imageUrl: campaign['image_url'] ?? campaign['image'] ?? '',
          targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
          currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
          startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
          endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
          isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
          category: campaign['category']?['name'] ?? campaign['category_name'] ?? '',
          donorCount: campaign['donor_count'] ?? campaign['donors_count'] ?? 0,
          type: 'charity_campaign',
          isUrgentFlag: campaign['is_urgent'] ?? false,
          isFeatured: campaign['is_featured'] ?? false,
        );
      } else {
        throw Exception('Failed to fetch charity campaign details: ${response.statusCode}');
      }
    } catch (error) {
      print('CampaignService: Error fetching charity campaign details: $error');
      return null; // Return null instead of rethrowing
    }
  }

  // ===== CATEGORIES (فئات البرامج) =====

  // Get program categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      print('CampaignService: Fetching categories from API...');
      final response = await _apiClient.dio.get('/v1/categories');
      
      print('CampaignService: Categories API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = response.data['data'] ?? response.data;
        return categoriesData.map((category) => {
          'id': category['id'],
          'name': category['name'],
          'description': category['description'] ?? '',
        }).toList();
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (error) {
      print('CampaignService: Error fetching categories: $error');
      return []; // Return empty list instead of rethrowing
    }
  }

  // ===== UNIFIED DONATION SYSTEM (نظام التبرعات الموحد) =====

  // Create donation (for both programs and campaigns)
  Future<Map<String, dynamic>> createDonation({
    required String itemId,
    required String itemType, // 'program' or 'campaign'
    required double amount,
    String? donorName,
    String? donorPhone,
    String? donorEmail,
    String? message,
  }) async {
    try {
      print('CampaignService: Creating donation for $itemType: $itemId, amount: $amount');
      
      final donationData = {
        'item_id': itemId,
        'item_type': itemType, // Specify if it's for program or campaign
        'amount': amount,
        if (donorName != null) 'donor_name': donorName,
        if (donorPhone != null) 'donor_phone': donorPhone,
        if (donorEmail != null) 'donor_email': donorEmail,
        if (message != null) 'message': message,
      };
      
      print('CampaignService: Donation data: $donationData');
      
      final response = await _apiClient.dio.post('/v1/donations', data: donationData);
      
      print('CampaignService: Donation API Response: ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception('Failed to create donation: ${response.statusCode}');
      }
    } catch (error) {
      print('CampaignService: Error creating donation: $error');
      if (error is DioException) {
        print('CampaignService: DioException details: ${error.message}');
        print('CampaignService: Response data: ${error.response?.data}');
      }
      rethrow;
    }
  }

  // Get quick donation amounts
  Future<List<double>> getQuickDonationAmounts() async {
    try {
      print('CampaignService: Fetching quick donation amounts...');
      final response = await _apiClient.dio.get('/v1/donations/quick-amounts');
      
      print('CampaignService: Quick amounts API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> amountsData = response.data['data'] ?? response.data;
        return amountsData.map((amount) => (amount as num).toDouble()).toList();
      } else {
        // Fallback to default amounts if API fails
        print('CampaignService: Using fallback quick amounts');
        return [10.0, 25.0, 50.0, 100.0, 200.0, 500.0];
      }
    } catch (error) {
      print('CampaignService: Error fetching quick amounts, using fallback: $error');
      // Fallback to default amounts
      return [10.0, 25.0, 50.0, 100.0, 200.0, 500.0];
    }
  }

  // ===== LEGACY METHODS (for backward compatibility) =====

  // Legacy method - now calls getStudentPrograms
  @Deprecated('Use getStudentPrograms() instead')
  Future<List<Campaign>> getPrograms() async {
    return getStudentPrograms();
  }

  // Legacy method - now calls getStudentProgramDetails
  @Deprecated('Use getStudentProgramDetails() instead')
  Future<Campaign?> getProgramDetails(String programId) async {
    return getStudentProgramDetails(programId);
  }
}
