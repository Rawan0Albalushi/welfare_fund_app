import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  // Initialize auth state
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if user is authenticated
      final isLoggedIn = await _authService.isAuthenticated();
      print('AuthProvider: Checking authentication status. isLoggedIn: $isLoggedIn');
      
      if (isLoggedIn) {
        await _loadUserProfile();
      } else {
        _isAuthenticated = false;
        _userProfile = null;
        print('AuthProvider: User not authenticated');
      }
    } catch (error) {
      print('Error initializing auth provider: $error');
      _isAuthenticated = false;
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Initialization complete. isAuthenticated: $_isAuthenticated');
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUser();
      print('AuthProvider: Raw profile data: $profile');
      print('AuthProvider: Profile keys: ${profile.keys}');
      
      // Handle different response structures
      if (profile['data'] != null) {
        _userProfile = profile['data'];
        print('AuthProvider: Using profile.data: ${_userProfile}');
      } else {
        _userProfile = profile;
        print('AuthProvider: Using profile directly: ${_userProfile}');
      }
      
      _isAuthenticated = true;
      print('AuthProvider: User profile loaded successfully. isAuthenticated: $_isAuthenticated');
      print('AuthProvider: Final userProfile keys: ${_userProfile?.keys}');
    } catch (error) {
      print('Error loading user profile: $error');
      _isAuthenticated = false;
      _userProfile = null;
    }
  }

  // Login user
  Future<bool> login(String phone, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.login(phone: phone, password: password);
      print('AuthProvider: Login response received: ${response.keys}');
      
      if (response['data'] != null || response['token'] != null) {
        await _loadUserProfile();
        print('AuthProvider: Login successful. isAuthenticated: $_isAuthenticated');
        return true;
      }
      print('AuthProvider: Login failed - no data or token in response');
      return false;
    } catch (error) {
      print('Error during login: $error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      print('AuthProvider: Starting logout process...');
      _isLoading = true;
      notifyListeners();

      await _authService.logout();
      
      // Clear local state
      _isAuthenticated = false;
      _userProfile = null;
      print('AuthProvider: Logout successful. isAuthenticated: $_isAuthenticated');
    } catch (error) {
      print('Error during logout: $error');
      // Even if logout fails on server, clear local state
      _isAuthenticated = false;
      _userProfile = null;
      print('AuthProvider: Logout completed with error. isAuthenticated: $_isAuthenticated');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Logout process completed, notifying listeners');
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (_isAuthenticated) {
      await _loadUserProfile();
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final updatedProfile = await _authService.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );
      
      // Handle different response structures (same as _loadUserProfile)
      if (updatedProfile['data'] != null) {
        _userProfile = updatedProfile['data'];
      } else {
        _userProfile = updatedProfile;
      }
      
      notifyListeners();
    } catch (error) {
      print('Error updating profile: $error');
      rethrow;
    }
  }

  // Check authentication status
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isAuthenticated();
      if (isLoggedIn && !_isAuthenticated) {
        await _loadUserProfile();
      } else if (!isLoggedIn && _isAuthenticated) {
        _isAuthenticated = false;
        _userProfile = null;
      }
      notifyListeners();
    } catch (error) {
      print('Error checking auth status: $error');
    }
  }
}
