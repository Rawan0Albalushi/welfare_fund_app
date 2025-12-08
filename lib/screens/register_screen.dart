import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _formAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isEmailOptional = true;
  
  // Auth Service
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _formAnimationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // App Bar - With Gradient Background
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  centerTitle: true,
                  iconTheme: const IconThemeData(color: AppColors.surface),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.surface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'create_new_account'.tr(),
                    style: AppTextStyles.appBarTitleDark,
                  ),
                  actions: const [],
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.modernGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),

                // Register Form
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),

                      // Register Form
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.modernGradient,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'register'.tr(),
                                      style: AppTextStyles.headlineSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                 // Name Field
                                 _buildTextField(
                                   controller: _nameController,
                                   label: 'full_name'.tr(),
                                   hint: 'full_name'.tr(),
                                   icon: Icons.person_outline,
                                   keyboardType: TextInputType.name,
                                   validator: (value) {
                                     if (value == null || value.isEmpty) {
                                       return 'required_field'.tr();
                                     }
                                     if (value.trim().length < 2) {
                                       return 'required_field'.tr();
                                     }
                                     return null;
                                   },
                                 ),
                                 const SizedBox(height: 20),

                                 // Phone Field
                                 _buildTextField(
                                  controller: _phoneController,
                                  label: 'phone_number'.tr(),
                                  hint: 'phone_number'.tr(),
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'required_field'.tr();
                                    }
                                    if (value.length != 8) {
                                      return 'required_field'.tr();
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Email Field (Optional)
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'email'.tr(),
                                  hint: 'email'.tr(),
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  isOptional: true,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value)) {
                                        return 'invalid_email'.tr();
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'password'.tr(),
                                  hint: 'password'.tr(),
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'required_field'.tr();
                                    }
                                    if (value.length < 6) {
                                      return 'password_too_short'.tr();
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Confirm Password Field
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  label: 'confirm_password'.tr(),
                                  hint: 'confirm_password'.tr(),
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isConfirmPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'required_field'.tr();
                                    }
                                    if (value != _passwordController.text) {
                                      return 'passwords_do_not_match'.tr();
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),

                                // Terms and Conditions
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isEmailOptional, // This will be used for terms acceptance
                                      onChanged: (value) {
                                        setState(() {
                                          _isEmailOptional = value!;
                                        });
                                      },
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'terms_conditions'.tr(),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Register Button
                                _buildRegisterButton(),
                                const SizedBox(height: 25),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: AppColors.surfaceVariant,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or'.tr(),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: AppColors.surfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),

                                // Login Button
                                _buildLoginButton(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool isOptional = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.labelLarge,
            ),
            if (isOptional) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'optional'.tr(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !(isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        } else {
                          _isPasswordVisible = !_isPasswordVisible;
                        }
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.surfaceVariant,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.surfaceVariant,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.modernGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _handleRegister,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.surface,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.person_add,
                    color: AppColors.surface,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isLoading ? 'loading'.tr() : 'register'.tr(),
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.login,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'already_have_account'.tr(),
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (!_isEmailOptional) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'required_field'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      HapticFeedback.lightImpact();

      try {
                 // Call register API
         await _authService.register(
           phone: _phoneController.text.trim(),
           password: _passwordController.text,
           passwordConfirmation: _confirmPasswordController.text,
           email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
           name: _nameController.text.trim(),
         );

        setState(() {
          _isLoading = false;
        });

        // Show success message and navigate to home
        if (mounted) {
          // تأكيد تسجيل الدخول تلقائياً عبر مزود الحالة بعد نجاح التسجيل
          try {
            await context.read<AuthProvider>().checkAuthStatus();
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'registration_successful'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }
}

