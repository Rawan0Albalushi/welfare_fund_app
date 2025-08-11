# Authentication Integration Documentation

This document describes the implementation of user registration and login integration in the Student Welfare Fund Flutter app using the Dio package.

## Overview

The authentication system has been implemented with the following features:
- User registration and login via REST API
- Token-based authentication with automatic header injection
- Secure token storage using SharedPreferences
- Comprehensive error handling and loading states
- Separation between app user registration and student welfare fund registration

## API Configuration

### Base URL
```
http://192.168.125.231:8000/api/v1
```

### Endpoints

#### Registration
- **URL**: `POST /auth/register`
- **Body**:
  ```json
  {
    "phone": "string (required)",
    "password": "string (required)",
    "password_confirmation": "string (required)",
    "name": "string (required)",
    "email": "string (optional)"
  }
  ```

#### Login
- **URL**: `POST /auth/login`
- **Body**:
  ```json
  {
    "phone": "string (required)",
    "password": "string (required)"
  }
  ```

#### Logout
- **URL**: `POST /auth/logout`
- **Headers**: `Authorization: Bearer {token}`

#### Get Current User
- **URL**: `GET /auth/me`
- **Headers**: `Authorization: Bearer {token}`

## Implementation Details

### 1. AuthService Class (`lib/services/auth_service.dart`)

The `AuthService` class is a singleton that handles all authentication-related API calls:

#### Key Features:
- **Singleton Pattern**: Ensures only one instance exists throughout the app
- **Dio Integration**: Uses Dio for HTTP requests with automatic token handling
- **Token Management**: Automatically stores and retrieves tokens from SharedPreferences
- **Interceptor Setup**: Automatically adds `Authorization: Bearer {token}` header to all requests
- **Error Handling**: Comprehensive error handling with Arabic error messages
- **Timeout Configuration**: 30-second timeout for connection and receive operations

#### Methods:
- `initialize()`: Sets up Dio with interceptors and base configuration
- `register()`: Handles user registration
- `login()`: Handles user login
- `logout()`: Handles user logout
- `getCurrentUser()`: Retrieves current user profile
- `isAuthenticated()`: Checks if user is authenticated
- `getToken()`: Retrieves stored authentication token

### 2. Token Storage

Tokens are stored securely using SharedPreferences:
- **Storage Key**: `auth_token`
- **Automatic Injection**: Tokens are automatically added to all API requests via Dio interceptors
- **Automatic Cleanup**: Tokens are automatically cleared on 401 (Unauthorized) responses

### 3. Error Handling

The system provides comprehensive error handling with Arabic error messages:

#### Error Types:
- **Validation Errors**: Laravel validation error messages
- **Server Errors**: HTTP status code errors
- **Connection Timeout**: 30-second timeout errors
- **Network Errors**: Connection failure errors
- **General Errors**: Unexpected error handling

### 4. Loading States

Both registration and login screens implement loading states:
- **Loading Indicators**: Show during API calls
- **Button States**: Disabled during loading
- **User Feedback**: Success/error messages via SnackBar

## Usage Examples

### Registration
```dart
final authService = AuthService();

try {
  final result = await authService.register(
    phone: '966501234567',
    password: 'password123',
    passwordConfirmation: 'password123',
    name: 'User Name',
    email: 'user@example.com',
  );
  
  // Handle success
  print('Registration successful: ${result}');
} catch (error) {
  // Handle error
  print('Registration failed: $error');
}
```

### Login
```dart
final authService = AuthService();

try {
  final result = await authService.login(
    phone: '966501234567',
    password: 'password123',
  );
  
  // Handle success
  print('Login successful: ${result}');
} catch (error) {
  // Handle error
  print('Login failed: $error');
}
```

### Check Authentication Status
```dart
final authService = AuthService();
final isAuthenticated = await authService.isAuthenticated();

if (isAuthenticated) {
  // User is logged in
  print('User is authenticated');
} else {
  // User is not logged in
  print('User is not authenticated');
}
```

## Integration with Screens

### Login Screen (`lib/screens/login_screen.dart`)
- Uses `AuthService` for login functionality
- Shows loading state during API calls
- Displays success/error messages
- Navigates to home screen on successful login

### Register Screen (`lib/screens/register_screen.dart`)
- Uses `AuthService` for registration functionality
- Validates password confirmation
- Shows loading state during API calls
- Displays success/error messages
- Navigates to home screen on successful registration

### Settings Screen (`lib/screens/settings_screen.dart`)
- Uses `AuthService` for logout functionality
- Clears user session on logout

## Dependencies

The following dependencies are required:

```yaml
dependencies:
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0  # For other secure storage needs
```

## Security Considerations

1. **Token Storage**: Tokens are stored in SharedPreferences (consider using flutter_secure_storage for production)
2. **Automatic Token Injection**: All requests automatically include the authentication token
3. **Token Cleanup**: Tokens are automatically cleared on authentication failures
4. **Error Handling**: Sensitive information is not exposed in error messages

## Testing

The authentication system includes basic tests:
- AuthService instantiation test
- Singleton pattern verification

Run tests with:
```bash
flutter test
```

## Troubleshooting

### Common Issues:

1. **Connection Timeout**: Ensure the API server is running and accessible
2. **401 Errors**: Check if the token is valid or has expired
3. **Validation Errors**: Verify that all required fields are provided
4. **Network Errors**: Check internet connectivity and API server status

### Debug Information:
- API base URL: `http://192.168.125.231:8000/api/v1`
- Connection timeout: 30 seconds
- Token storage key: `auth_token`

## Future Enhancements

1. **Token Refresh**: Implement automatic token refresh functionality
2. **Biometric Authentication**: Add fingerprint/face ID support
3. **Offline Support**: Implement offline authentication caching
4. **Multi-factor Authentication**: Add SMS/email verification
5. **Social Login**: Integrate Google, Facebook, or Apple login

## Notes

- The app user registration is separate from student welfare fund registration
- All error messages are in Arabic for better user experience
- The system handles both successful and failed authentication scenarios gracefully
- Loading states provide clear user feedback during API operations
