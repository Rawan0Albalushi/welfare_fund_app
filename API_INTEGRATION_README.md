# API Integration Documentation

This document describes the Laravel API integration implemented in the Student Welfare Fund App.

## Overview

The app now integrates with a Laravel backend API for authentication and student welfare fund applications. The integration uses Dio for HTTP requests, flutter_secure_storage for token management, and flutter_dotenv for configuration.

## Important: Two Separate Processes

The app handles two distinct processes that should NOT be mixed:

### 1. User Authentication (App Registration/Login)
- **Purpose**: Create user accounts to access the app
- **When**: Before using any app features
- **Data**: Phone, password, optional email/name
- **Result**: User can log in and access protected features
- **API**: `/api/v1/auth/*` endpoints

### 2. Student Welfare Fund Application
- **Purpose**: Apply for financial support from the welfare fund
- **When**: After logging in, when student wants to apply for support
- **Data**: Complete personal, academic, financial information + documents
- **Result**: Application submitted for review and approval
- **API**: `/api/v1/student-applications/*` endpoints

**Key Point**: These are completely separate processes. A user must first register/login to the app, then they can submit welfare fund applications.

## Dependencies Added

```yaml
dependencies:
  dio: ^5.4.0                    # HTTP client for API requests
  flutter_secure_storage: ^9.0.0 # Secure storage for auth tokens
  flutter_dotenv: ^5.1.0         # Environment variable management
```

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
API_BASE_URL=http://localhost:8000/api/v1
```

Update `pubspec.yaml` to include the .env file:

```yaml
flutter:
  assets:
    - .env
```

## API Endpoints

The app integrates with the following Laravel API endpoints:

### Authentication Endpoints (User Account Management)

- `POST /api/v1/auth/register` - User registration (for app login)
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/me` - Get current user profile
- `POST /api/v1/auth/logout` - User logout

### Student Application Endpoints (Welfare Fund Applications)

- `POST /api/v1/student-applications/submit` - Submit student application for welfare fund
- `GET /api/v1/student-applications/status/{studentId}` - Get application status
- `PUT /api/v1/student-applications/update/{studentId}` - Update application
- `GET /api/v1/student-applications/my-applications` - Get user's submitted applications

## Implementation Details

### 1. API Client (`lib/services/api_client.dart`)

The API client handles:
- Dio configuration with base URL from environment
- Automatic token injection in request headers
- 401 error handling (clears token on authentication failure)
- Secure token storage using flutter_secure_storage

```dart
// Initialize API client
await ApiClient().initialize();

// Set auth token
await ApiClient().setAuthToken(token);

// Check authentication status
bool isAuth = await ApiClient().isAuthenticated();
```

### 2. Auth Repository (`lib/services/auth_repository.dart`)

Handles all authentication operations:
- User registration
- User login
- Get current user profile
- User logout
- Error handling with Arabic error messages

```dart
final authRepo = AuthRepository();

// Register user
await authRepo.register(
  phone: '1234567890',
  password: 'password123',
  email: 'user@example.com',
  name: 'User Name'
);

// Login user
await authRepo.login(
  phone: '1234567890',
  password: 'password123'
);

// Logout user
await authRepo.logout();
```

### 3. Student Application Service (`lib/services/student_registration_service.dart`)

Handles student welfare fund applications with:
- Complete student information submission
- File upload for ID card images
- Application status checking
- Application updates
- User's application history

```dart
final studentService = StudentRegistrationService();

// Submit student application for welfare fund
await studentService.submitStudentApplication(
  fullName: 'Student Name',
  studentId: '12345',
  phone: '1234567890',
  university: 'University Name',
  college: 'College Name',
  major: 'Computer Science',
  academicYear: 'السنة الثالثة',
  gpa: 3.5,
  gender: 'ذكر',
  maritalStatus: 'أعزب',
  incomeLevel: 'منخفض',
  familySize: '1-3',
  email: 'student@example.com',
  idCardImagePath: '/path/to/image.jpg'
);

// Get application status
final status = await studentService.getApplicationStatus('12345');

// Get user's applications
final applications = await studentService.getUserApplications();
```

## Screen Integration

### Login Screen (`lib/screens/login_screen.dart`)

- Updated to use phone number instead of email
- Integrated with AuthRepository for login
- Shows loading state during API calls
- Displays backend error messages
- Navigates to home screen on success

### Register Screen (`lib/screens/register_screen.dart`)

- Integrated with AuthRepository for registration
- Handles optional email field
- Shows loading state during API calls
- Displays backend error messages
- Navigates to home screen on success

### Student Application Screen (`lib/screens/student_registration_screen.dart`)

- Integrated with StudentRegistrationService
- Handles file upload for ID card images
- Submits complete student application for welfare fund
- Shows loading state during API calls
- Displays backend error messages

### Settings Screen (`lib/screens/settings_screen.dart`)

- Integrated logout functionality
- Calls AuthRepository.logout()
- Shows loading state during logout
- Navigates to login screen after logout
- Handles logout errors

## Error Handling

The implementation includes comprehensive error handling:

1. **Network Errors**: Connection timeout, receive timeout, connection errors
2. **Server Errors**: HTTP status codes with meaningful messages
3. **Validation Errors**: Laravel validation error extraction
4. **Arabic Error Messages**: All error messages are in Arabic for better UX

## Token Management

- Tokens are automatically stored in secure storage
- Tokens are automatically attached to all API requests
- Tokens are cleared on logout or 401 errors
- Authentication state is checked before making protected requests

## Usage Examples

### 1. User Authentication Flow

```dart
final authRepo = AuthRepository();

// Register new user account
await authRepo.register(
  phone: '1234567890',
  password: 'password123',
  email: 'user@example.com',
  name: 'User Name'
);

// Login user
await authRepo.login(
  phone: '1234567890',
  password: 'password123'
);

// Check if user is authenticated
bool isAuthenticated = await authRepo.isAuthenticated();
```

### 2. Student Application Flow (After Login)

```dart
final studentService = StudentRegistrationService();

// Submit welfare fund application
await studentService.submitStudentApplication(
  fullName: 'Student Name',
  studentId: '12345',
  phone: '1234567890',
  university: 'University Name',
  college: 'College Name',
  major: 'Computer Science',
  academicYear: 'السنة الثالثة',
  gpa: 3.5,
  gender: 'ذكر',
  maritalStatus: 'أعزب',
  incomeLevel: 'منخفض',
  familySize: '1-3',
  email: 'student@example.com',
  idCardImagePath: '/path/to/image.jpg'
);

// Check application status
final status = await studentService.getApplicationStatus('12345');

// Get user's applications
final applications = await studentService.getUserApplications();
```

### 3. Making Authenticated Requests

```dart
// The API client automatically handles token injection
final response = await ApiClient().dio.get('/protected-endpoint');
```

### 4. Handling API Errors

```dart
try {
  await authRepo.login(phone: '1234567890', password: 'password');
} catch (error) {
  // Error message is already in Arabic
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString()))
  );
}
```

## Security Features

1. **Secure Token Storage**: Uses flutter_secure_storage for encrypted token storage
2. **Automatic Token Management**: Tokens are automatically handled without manual intervention
3. **Error Handling**: Comprehensive error handling prevents app crashes
4. **Input Validation**: Client-side validation before API calls

## Future Enhancements

1. **Token Refresh**: Implement automatic token refresh before expiration
2. **Offline Support**: Cache data for offline usage
3. **Biometric Authentication**: Add biometric login support
4. **Push Notifications**: Integrate push notifications for registration status updates

## Testing

To test the API integration:

1. Start your Laravel backend server
2. Update the API_BASE_URL in .env file
3. Run the Flutter app
4. Test registration and login flows
5. Verify token storage and automatic injection

## Troubleshooting

### Common Issues

1. **Connection Errors**: Check if Laravel server is running and accessible
2. **Token Issues**: Clear app data or reinstall to reset stored tokens
3. **File Upload Errors**: Ensure proper file permissions and valid image formats
4. **Validation Errors**: Check Laravel validation rules match client-side validation

### Debug Mode

Enable debug logging in the API client for troubleshooting:

```dart
// Add to api_client.dart
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```
