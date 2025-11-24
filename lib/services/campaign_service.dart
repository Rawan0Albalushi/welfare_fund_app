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
      final normalized = _normalizeNumberString(value);
      if (normalized.isEmpty) return 0.0;
      return double.tryParse(normalized) ?? 0.0;
    }
    return 0.0;
  }

  String _normalizeNumberString(String value) {
    const arabicToEnglishDigits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    final buffer = StringBuffer();
    for (final codePoint in value.trim().runes) {
      final char = String.fromCharCode(codePoint);
      if (arabicToEnglishDigits.containsKey(char)) {
        buffer.write(arabicToEnglishDigits[char]);
      } else if (char == ',' || char == '٬') {
        // Skip thousands separators
        continue;
      } else if (char == '.' || char == '٫') {
        buffer.write('.');
      } else if (char == '-' && buffer.isEmpty) {
        buffer.write('-');
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        buffer.write(char);
      }
      // Ignore any other characters (like currency symbols or spaces)
    }
    return buffer.toString();
  }

  // ===== STUDENT SUPPORT PROGRAMS (البرامج الموجودة) =====

  // Get all student support programs
  Future<List<Campaign>> getStudentPrograms() async {
    try {
      print('CampaignService: Fetching student programs from API...');
      
      // Try multiple possible endpoints
      List<String> endpoints = [
        '/programs',
        '/programs/support',
        '/student-programs',
      ];
      
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
              // Debug: Print image fields for debugging
              if (programsData.indexOf(program) == 0) {
                print('CampaignService: First program image fields:');
                print('  - image_url: ${program['image_url']}');
                print('  - image: ${program['image']}');
                print('  - photo: ${program['photo']}');
                print('  - photo_url: ${program['photo_url']}');
                print('  - banner: ${program['banner']}');
                print('  - banner_url: ${program['banner_url']}');
              }
              
              // Try multiple possible image field names
              final imageUrl = program['image_url'] ?? 
                              program['image'] ?? 
                              program['photo'] ?? 
                              program['photo_url'] ?? 
                              program['banner'] ?? 
                              program['banner_url'] ?? 
                              program['imageUrl'] ?? 
                              '';
              
              // 🔍 DEBUG: Print image URL for first program
              if (programsData.indexOf(program) == 0) {
                print('═══════════════════════════════════════════════════════════');
                print('📦 CampaignService: Processing FIRST student program');
                print('📋 Program ID: ${program['id']}');
                print('📋 Program title: ${program['title'] ?? program['title_ar'] ?? program['name']}');
                print('🔍 Raw image fields from backend:');
                print('   - image_url: "${program['image_url']}"');
                print('   - image: "${program['image']}"');
                print('   - photo: "${program['photo']}"');
                print('   - photo_url: "${program['photo_url']}"');
                print('   - banner: "${program['banner']}"');
                print('   - banner_url: "${program['banner_url']}"');
                print('✅ Final selected imageUrl: "$imageUrl"');
                print('📏 imageUrl length: ${imageUrl.length}');
                print('📏 imageUrl startsWith(/): ${imageUrl.startsWith('/')}');
                print('📏 imageUrl startsWith(http): ${imageUrl.startsWith('http')}');
                print('═══════════════════════════════════════════════════════════');
              }
              
              final categoryName = program['category']?['name'] ?? program['category_name'] ?? '';
              final categoryNameAr = program['category']?['name_ar'] ?? program['category_name_ar'] ?? categoryName;
              final categoryNameEn = program['category']?['name_en'] ?? program['category_name_en'] ?? categoryName;
              
              return Campaign(
                id: program['id']?.toString() ?? '',
                title: program['title'] ?? program['title_ar'] ?? program['title_en'] ?? program['name'] ?? '',
                titleAr: program['title_ar'] ?? program['title'] ?? '',
                titleEn: program['title_en'] ?? program['title'] ?? '',
                description: program['description'] ?? program['description_ar'] ?? program['description_en'] ?? '',
                descriptionAr: program['description_ar'] ?? program['description'] ?? '',
                descriptionEn: program['description_en'] ?? program['description'] ?? '',
                imageUrl: imageUrl,
                targetAmount: _parseDouble(program['goal_amount'] ?? program['target_amount'] ?? 0),
                currentAmount: _parseDouble(program['raised_amount'] ?? program['current_amount'] ?? 0),
                startDate: DateTime.parse(program['created_at'] ?? DateTime.now().toIso8601String()),
                endDate: DateTime.parse(program['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
                isActive: program['status'] == 'active' || program['is_active'] == true,
                category: categoryName,
                categoryAr: categoryNameAr,
                categoryEn: categoryNameEn,
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
      final response = await _apiClient.dio.get('/programs/$programId');
      
      print('CampaignService: Student Program details API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final program = response.data['data'] ?? response.data;
        
        // Debug: Print image fields
        print('CampaignService: Program details image fields:');
        print('  - image_url: ${program['image_url']}');
        print('  - image: ${program['image']}');
        print('  - photo: ${program['photo']}');
        print('  - photo_url: ${program['photo_url']}');
        print('  - banner: ${program['banner']}');
        print('  - banner_url: ${program['banner_url']}');
        
        // Try multiple possible image field names
        final imageUrl = program['image_url'] ?? 
                        program['image'] ?? 
                        program['photo'] ?? 
                        program['photo_url'] ?? 
                        program['banner'] ?? 
                        program['banner_url'] ?? 
                        program['imageUrl'] ?? 
                        '';
        
        final categoryName = program['category']?['name'] ?? program['category_name'] ?? '';
        final categoryNameAr = program['category']?['name_ar'] ?? program['category_name_ar'] ?? categoryName;
        final categoryNameEn = program['category']?['name_en'] ?? program['category_name_en'] ?? categoryName;
        
        return Campaign(
          id: program['id']?.toString() ?? '',
          title: program['title'] ?? program['title_ar'] ?? program['title_en'] ?? program['name'] ?? '',
          titleAr: program['title_ar'] ?? program['title'] ?? '',
          titleEn: program['title_en'] ?? program['title'] ?? '',
          description: program['description'] ?? program['description_ar'] ?? program['description_en'] ?? '',
          descriptionAr: program['description_ar'] ?? program['description'] ?? '',
          descriptionEn: program['description_en'] ?? program['description'] ?? '',
          imageUrl: imageUrl,
          targetAmount: _parseDouble(program['goal_amount'] ?? program['target_amount'] ?? 0),
          currentAmount: _parseDouble(program['raised_amount'] ?? program['current_amount'] ?? 0),
          startDate: DateTime.parse(program['created_at'] ?? DateTime.now().toIso8601String()),
          endDate: DateTime.parse(program['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
          isActive: program['status'] == 'active' || program['is_active'] == true,
          category: categoryName,
          categoryAr: categoryNameAr,
          categoryEn: categoryNameEn,
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
        '/campaigns',
        '/charity-campaigns',
      ];
      
      for (String endpoint in endpoints) {
                 try {
           print('CampaignService: Trying endpoint: $endpoint');
           
           // Try to fetch all campaigns with pagination
           List<Campaign> allCampaigns = [];
           int currentPage = 1;
           const int limit = 100; // Fetch 100 campaigns per page
           bool hasMorePages = true;
           
           while (hasMorePages) {
             try {
               // Build query parameters
              final queryParams = <String, dynamic>{
                'page': currentPage.toString(),
                'limit': limit.toString(),
                'per_page': limit.toString(),
              };
               
               print('CampaignService: Fetching page $currentPage with limit $limit from endpoint: $endpoint');
              final response = await _apiClient.dio.get(
                endpoint,
                queryParameters: queryParams,
              );
               
               print('CampaignService: Charity Campaigns API Response status: ${response.statusCode}');
               print('CampaignService: Full URL: ${_apiClient.dio.options.baseUrl}$endpoint?page=$currentPage&limit=$limit');
               
               if (response.statusCode == 200) {
                final dynamic responseData = response.data;
                List<dynamic> pageCampaigns = [];
                if (responseData is Map<String, dynamic>) {
                  final dynamic nestedData = responseData['data'];
                  if (nestedData is List) {
                    pageCampaigns = List<dynamic>.from(nestedData);
                  }
                } else if (responseData is List) {
                  pageCampaigns = List<dynamic>.from(responseData);
                }
                 
                 if (pageCampaigns.isEmpty) {
                   print('CampaignService: No campaigns returned on page $currentPage, stopping pagination');
                   hasMorePages = false;
                   break;
                 }
                 
                 final List<Campaign> parsedCampaigns = pageCampaigns.map((campaign) {
                   // Debug: Print image fields for debugging
                   if (pageCampaigns.indexOf(campaign) == 0 && currentPage == 1) {
                     print('CampaignService: First charity campaign image fields:');
                     print('  - image_url: ${campaign['image_url']}');
                     print('  - image: ${campaign['image']}');
                     print('  - photo: ${campaign['photo']}');
                     print('  - photo_url: ${campaign['photo_url']}');
                     print('  - banner: ${campaign['banner']}');
                     print('  - banner_url: ${campaign['banner_url']}');
                   }
                   
                   // Try multiple possible image field names
                   final imageUrl = campaign['image_url'] ?? 
                                   campaign['image'] ?? 
                                   campaign['photo'] ?? 
                                   campaign['photo_url'] ?? 
                                   campaign['banner'] ?? 
                                   campaign['banner_url'] ?? 
                                   campaign['imageUrl'] ?? 
                                   '';
                   
                   final categoryName = campaign['category']?['name'] ?? campaign['category_name'] ?? '';
                   final categoryNameAr = campaign['category']?['name_ar'] ?? campaign['category_name_ar'] ?? categoryName;
                   final categoryNameEn = campaign['category']?['name_en'] ?? campaign['category_name_en'] ?? categoryName;
                   
                   return Campaign(
                     id: campaign['id']?.toString() ?? '',
                     title: campaign['title'] ?? campaign['title_ar'] ?? campaign['title_en'] ?? campaign['name'] ?? '',
                     titleAr: campaign['title_ar'] ?? campaign['title'] ?? '',
                     titleEn: campaign['title_en'] ?? campaign['title'] ?? '',
                     description: campaign['description'] ?? campaign['description_ar'] ?? campaign['description_en'] ?? '',
                     descriptionAr: campaign['description_ar'] ?? campaign['description'] ?? '',
                     descriptionEn: campaign['description_en'] ?? campaign['description'] ?? '',
                     imageUrl: imageUrl,
                     targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
                     currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
                     startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
                     endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
                     isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
                     category: categoryName,
                     categoryAr: categoryNameAr,
                     categoryEn: categoryNameEn,
                     impactDescription: campaign['impact_description'] as String?,
                     impactDescriptionAr: campaign['impact_description_ar'] as String?,
                     impactDescriptionEn: campaign['impact_description_en'] as String?,
                     donorCount: campaign['donor_count'] ?? campaign['donors_count'] ?? 0,
                     type: 'charity_campaign', // Mark as charity campaign
                     isUrgentFlag: campaign['is_urgent'] ?? false,
                     isFeatured: campaign['is_featured'] ?? false,
                   );
                 }).toList();
                 
                 allCampaigns.addAll(parsedCampaigns);
                 print('CampaignService: Added ${parsedCampaigns.length} campaigns from page $currentPage. Total so far: ${allCampaigns.length}');
                 
                 // Check if we got less than the limit, which means this is the last page
                 if (parsedCampaigns.length < limit) {
                   print('CampaignService: Got ${parsedCampaigns.length} campaigns (less than limit $limit), this is the last page');
                   hasMorePages = false;
                 } else {
                   currentPage++;
                 }
               } else {
                 print('CampaignService: Unexpected status code: ${response.statusCode}');
                 hasMorePages = false;
                 break;
               }
             } catch (pageError) {
               print('CampaignService: Error fetching page $currentPage: $pageError');
               hasMorePages = false;
               break;
             }
           }
           
           if (allCampaigns.isNotEmpty) {
             print('CampaignService: Successfully parsed ${allCampaigns.length} charity campaigns from endpoint: $endpoint');
             print('CampaignService: Charity campaign IDs: ${allCampaigns.map((c) => c.id).toList()}');
             print('CampaignService: Charity campaign titles: ${allCampaigns.map((c) => c.title).toList()}');
             return allCampaigns;
           }
         } catch (error) {
           print('CampaignService: Failed to fetch from endpoint $endpoint: $error');
           // If pagination fails, try without pagination as fallback
           try {
             print('CampaignService: Trying endpoint $endpoint without pagination as fallback...');
            final response = await _apiClient.dio.get(
              endpoint,
              queryParameters: const {
                'limit': 500,
                'per_page': 500,
              },
            );
             
             if (response.statusCode == 200) {
              final dynamic responseData = response.data;
              List<dynamic> campaignsData = [];
              if (responseData is Map<String, dynamic>) {
                final dynamic nestedData = responseData['data'];
                if (nestedData is List) {
                  campaignsData = List<dynamic>.from(nestedData);
                }
              } else if (responseData is List) {
                campaignsData = List<dynamic>.from(responseData);
              }
              
              if (campaignsData.isNotEmpty) {
                final List<Campaign> campaigns = campaignsData.map((campaign) {
                   final imageUrl = campaign['image_url'] ?? 
                                   campaign['image'] ?? 
                                   campaign['photo'] ?? 
                                   campaign['photo_url'] ?? 
                                   campaign['banner'] ?? 
                                   campaign['banner_url'] ?? 
                                   campaign['imageUrl'] ?? 
                                   '';
                   
                   final categoryName = campaign['category']?['name'] ?? campaign['category_name'] ?? '';
                   final categoryNameAr = campaign['category']?['name_ar'] ?? campaign['category_name_ar'] ?? categoryName;
                   final categoryNameEn = campaign['category']?['name_en'] ?? campaign['category_name_en'] ?? categoryName;
                   
                   return Campaign(
                     id: campaign['id']?.toString() ?? '',
                     title: campaign['title'] ?? campaign['title_ar'] ?? campaign['title_en'] ?? campaign['name'] ?? '',
                     titleAr: campaign['title_ar'] ?? campaign['title'] ?? '',
                     titleEn: campaign['title_en'] ?? campaign['title'] ?? '',
                     description: campaign['description'] ?? campaign['description_ar'] ?? campaign['description_en'] ?? '',
                     descriptionAr: campaign['description_ar'] ?? campaign['description'] ?? '',
                     descriptionEn: campaign['description_en'] ?? campaign['description'] ?? '',
                     imageUrl: imageUrl,
                     targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
                     currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
                     startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
                     endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
                     isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
                     category: categoryName,
                     categoryAr: categoryNameAr,
                     categoryEn: categoryNameEn,
                     impactDescription: campaign['impact_description'] as String?,
                     impactDescriptionAr: campaign['impact_description_ar'] as String?,
                     impactDescriptionEn: campaign['impact_description_en'] as String?,
                     donorCount: campaign['donor_count'] ?? campaign['donors_count'] ?? 0,
                     type: 'charity_campaign',
                     isUrgentFlag: campaign['is_urgent'] ?? false,
                     isFeatured: campaign['is_featured'] ?? false,
                   );
                 }).toList();
                 
                 print('CampaignService: Successfully parsed ${campaigns.length} charity campaigns from endpoint: $endpoint (fallback, no pagination)');
                 return campaigns;
               }
             }
           } catch (fallbackError) {
             print('CampaignService: Fallback also failed for endpoint $endpoint: $fallbackError');
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
      final response = await _apiClient.dio.get('/campaigns/urgent');
      
      print('CampaignService: Urgent Campaigns API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsData = response.data['data'] ?? response.data;
        
        final List<Campaign> campaigns = campaignsData.map((campaign) {
          // Try multiple possible image field names
          final imageUrl = campaign['image_url'] ?? 
                          campaign['image'] ?? 
                          campaign['photo'] ?? 
                          campaign['photo_url'] ?? 
                          campaign['banner'] ?? 
                          campaign['banner_url'] ?? 
                          campaign['imageUrl'] ?? 
                          '';
          
          final categoryName = campaign['category']?['name'] ?? campaign['category_name'] ?? '';
          final categoryNameAr = campaign['category']?['name_ar'] ?? campaign['category_name_ar'] ?? categoryName;
          final categoryNameEn = campaign['category']?['name_en'] ?? campaign['category_name_en'] ?? categoryName;
          
          return Campaign(
            id: campaign['id']?.toString() ?? '',
            title: campaign['title'] ?? campaign['title_ar'] ?? campaign['title_en'] ?? campaign['name'] ?? '',
            titleAr: campaign['title_ar'] ?? campaign['title'] ?? '',
            titleEn: campaign['title_en'] ?? campaign['title'] ?? '',
            description: campaign['description'] ?? campaign['description_ar'] ?? campaign['description_en'] ?? '',
            descriptionAr: campaign['description_ar'] ?? campaign['description'] ?? '',
            descriptionEn: campaign['description_en'] ?? campaign['description'] ?? '',
            imageUrl: imageUrl,
            targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
            currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
            startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
            isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
            category: categoryName,
            categoryAr: categoryNameAr,
            categoryEn: categoryNameEn,
            impactDescription: campaign['impact_description'] as String?,
            impactDescriptionAr: campaign['impact_description_ar'] as String?,
            impactDescriptionEn: campaign['impact_description_en'] as String?,
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
      final response = await _apiClient.dio.get('/campaigns/featured');
      
      print('CampaignService: Featured Campaigns API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsData = response.data['data'] ?? response.data;
        
        final List<Campaign> campaigns = campaignsData.map((campaign) {
          // Try multiple possible image field names
          final imageUrl = campaign['image_url'] ?? 
                          campaign['image'] ?? 
                          campaign['photo'] ?? 
                          campaign['photo_url'] ?? 
                          campaign['banner'] ?? 
                          campaign['banner_url'] ?? 
                          campaign['imageUrl'] ?? 
                          '';
          
          final categoryName = campaign['category']?['name'] ?? campaign['category_name'] ?? '';
          final categoryNameAr = campaign['category']?['name_ar'] ?? campaign['category_name_ar'] ?? categoryName;
          final categoryNameEn = campaign['category']?['name_en'] ?? campaign['category_name_en'] ?? categoryName;
          
          return Campaign(
            id: campaign['id']?.toString() ?? '',
            title: campaign['title'] ?? campaign['title_ar'] ?? campaign['title_en'] ?? campaign['name'] ?? '',
            titleAr: campaign['title_ar'] ?? campaign['title'] ?? '',
            titleEn: campaign['title_en'] ?? campaign['title'] ?? '',
            description: campaign['description'] ?? campaign['description_ar'] ?? campaign['description_en'] ?? '',
            descriptionAr: campaign['description_ar'] ?? campaign['description'] ?? '',
            descriptionEn: campaign['description_en'] ?? campaign['description'] ?? '',
            imageUrl: imageUrl,
            targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
            currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
            startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
            isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
            category: categoryName,
            categoryAr: categoryNameAr,
            categoryEn: categoryNameEn,
            impactDescription: campaign['impact_description'] as String?,
            impactDescriptionAr: campaign['impact_description_ar'] as String?,
            impactDescriptionEn: campaign['impact_description_en'] as String?,
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
      final response = await _apiClient.dio.get('/campaigns/$campaignId');
      
      print('CampaignService: Charity Campaign details API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final campaign = response.data['data'] ?? response.data;
        
        // Debug: Print image fields
        print('CampaignService: Charity campaign details image fields:');
        print('  - image_url: ${campaign['image_url']}');
        print('  - image: ${campaign['image']}');
        print('  - photo: ${campaign['photo']}');
        print('  - photo_url: ${campaign['photo_url']}');
        print('  - banner: ${campaign['banner']}');
        print('  - banner_url: ${campaign['banner_url']}');
        
        // Try multiple possible image field names
        final imageUrl = campaign['image_url'] ?? 
                        campaign['image'] ?? 
                        campaign['photo'] ?? 
                        campaign['photo_url'] ?? 
                        campaign['banner'] ?? 
                        campaign['banner_url'] ?? 
                        campaign['imageUrl'] ?? 
                        '';
        
        final categoryName = campaign['category']?['name'] ?? campaign['category_name'] ?? '';
        final categoryNameAr = campaign['category']?['name_ar'] ?? campaign['category_name_ar'] ?? categoryName;
        final categoryNameEn = campaign['category']?['name_en'] ?? campaign['category_name_en'] ?? categoryName;
        
        return Campaign(
          id: campaign['id']?.toString() ?? '',
          title: campaign['title'] ?? campaign['title_ar'] ?? campaign['title_en'] ?? campaign['name'] ?? '',
          titleAr: campaign['title_ar'] ?? campaign['title'] ?? '',
          titleEn: campaign['title_en'] ?? campaign['title'] ?? '',
          description: campaign['description'] ?? campaign['description_ar'] ?? campaign['description_en'] ?? '',
          descriptionAr: campaign['description_ar'] ?? campaign['description'] ?? '',
          descriptionEn: campaign['description_en'] ?? campaign['description'] ?? '',
          imageUrl: imageUrl,
          targetAmount: _parseDouble(campaign['goal_amount'] ?? campaign['target_amount'] ?? 0),
          currentAmount: _parseDouble(campaign['raised_amount'] ?? campaign['current_amount'] ?? 0),
          startDate: DateTime.parse(campaign['created_at'] ?? DateTime.now().toIso8601String()),
          endDate: DateTime.parse(campaign['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
          isActive: campaign['status'] == 'active' || campaign['is_active'] == true,
          category: categoryName,
          categoryAr: categoryNameAr,
          categoryEn: categoryNameEn,
          impactDescription: campaign['impact_description'] as String?,
          impactDescriptionAr: campaign['impact_description_ar'] as String?,
          impactDescriptionEn: campaign['impact_description_en'] as String?,
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
      final response = await _apiClient.dio.get('/categories');
      
      print('CampaignService: Categories API Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = response.data['data'] ?? response.data;
        return categoriesData.map((category) => {
          'id': category['id'],
          'name': category['name'],
          'name_ar': category['name_ar'] ?? category['name'],
          'name_en': category['name_en'] ?? category['name'],
          'description': category['description'] ?? '',
          'status': category['status'] ?? 'active',
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
      
      final response = await _apiClient.dio.post('/donations', data: donationData);
      
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
      final response = await _apiClient.dio.get('/donations/quick-amounts');
      
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
