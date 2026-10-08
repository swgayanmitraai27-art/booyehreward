import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ff_brand_elements.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  final AppState appState;

  const AuthScreen({super.key, required this.appState});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPassController = TextEditingController();
  bool _loginPassObscure = true;
  bool _isLoginLoading = false;
  String? _loginError;

  // Signup Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPassController = TextEditingController();
  final _ignController = TextEditingController();
  final _uidController = TextEditingController();
  final _levelController = TextEditingController(text: '45');
  final _referralCodeController = TextEditingController();
  bool _signupPassObscure = true;
  bool _isSignupLoading = false;
  String? _signupError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPassController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _signupEmailController.dispose();
    _signupPassController.dispose();
    _ignController.dispose();
    _uidController.dispose();
    _levelController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  // --- LOGIN FUNCTION ---
  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final pass = _loginPassController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _loginError = 'Please enter both Email and Password.');
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _loginError = null;
    });

    try {
      final authResult = await AuthService.login(
        email: email,
        password: pass,
      );

      if (authResult.success && authResult.user != null) {
        widget.appState.setUser(authResult.user!);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
        );
      } else {
        setState(() {
          _isLoginLoading = false;
          _loginError = authResult.errorMessage ?? 'Invalid email or password. Please check or Register a new account.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoginLoading = false;
        _loginError = 'Login error: $e';
      });
    }
  }

  // --- SIGN UP FUNCTION ---
  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _signupEmailController.text.trim();
    final pass = _signupPassController.text.trim();
    final ign = _ignController.text.trim();
    final uid = _uidController.text.trim();
    final level = int.tryParse(_levelController.text.trim()) ?? 0;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || pass.isEmpty || ign.isEmpty || uid.isEmpty) {
      setState(() => _signupError = 'Please fill all mandatory fields!');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _signupError = 'Please enter a valid email address.');
      return;
    }

    if (pass.length < 6) {
      setState(() => _signupError = 'Password must be at least 6 characters long.');
      return;
    }

    if (phone.length < 10) {
      setState(() => _signupError = 'Please enter a valid 10-digit WhatsApp phone number.');
      return;
    }

    // STRICT LEVEL 40+ ANTI-HACK CHECK
    if (level < 40) {
      setState(() => _signupError = 'Anti-Hack Rule: Free Fire Level must be minimum 40+ to join tournaments.');
      return;
    }

    setState(() {
      _isSignupLoading = true;
      _signupError = null;
    });

    try {
      final authResult = await AuthService.signUp(
        name: name,
        phone: phone,
        email: email,
        password: pass,
        inGameName: ign,
        inGameUid: uid,
        inGameLevel: level,
      );

      if (authResult.success && authResult.user != null) {
        widget.appState.setUser(authResult.user!);

        // Apply referral code if provided
        final refCode = _referralCodeController.text.trim();
        if (refCode.isNotEmpty) {
          await widget.appState.applyReferralCode(refCode);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(refCode.isNotEmpty
                ? '🎉 Account Created! 5 🟡 Signup + 10 🎁 Referral Bonus Coins Credited!'
                : '🎉 Account Created! Welcome bonus 5 🟡 Ad Coins credited!'),
            backgroundColor: AppTheme.winningGreen,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
        );
      } else {
        setState(() {
          _isSignupLoading = false;
          _signupError = authResult.errorMessage ?? 'Sign up failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isSignupLoading = false;
        _signupError = 'Sign up error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A), // Sleek gaming dark background
      body: Stack(
        children: [
          // Background ambient glowing circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryAmber.withAlpha(40),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withAlpha(40),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Logo & Branding
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          border: Border.all(color: AppTheme.primaryAmber, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAmber.withAlpha(80),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'imgasest/app logo .png',
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.sports_esports, size: 40, color: AppTheme.primaryAmber),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('BOOYAH ', style: AppTheme.gamingTitle(fontSize: 22, color: Colors.white)),
                          Text('REWARDS', style: AppTheme.gamingTitle(fontSize: 22, color: AppTheme.primaryAmber)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'Official Esports Platform for',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                          FreeFireLogoInline(height: 14, width: 90),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Tabs: Login vs Register
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.black,
                          unselectedLabelColor: const Color(0xFF94A3B8),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          tabs: const [
                            Tab(text: '🔑 LOGIN'),
                            Tab(text: '📝 REGISTER'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tab Views
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLoginTab(),
                            _buildSignupTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIN TAB VIEW ---
  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loginError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loginError!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          _buildInputField(
            controller: _loginEmailController,
            label: 'Email Address',
            hint: 'name@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          _buildInputField(
            controller: _loginPassController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _loginPassObscure,
            suffixIcon: IconButton(
              icon: Icon(
                _loginPassObscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _loginPassObscure = !_loginPassObscure),
            ),
          ),
          const SizedBox(height: 20),

          // Login Button
          ElevatedButton(
            onPressed: _isLoginLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: _isLoginLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                : Text('ENTER ARENA & PLAY', style: AppTheme.gamingTitle(fontSize: 14, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- SIGN UP TAB VIEW ---
  Widget _buildSignupTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_signupError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _signupError!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          _buildInputField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Aman Sharma',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 10),

          _buildInputField(
            controller: _phoneController,
            label: 'WhatsApp Phone Number',
            hint: '9876543210 (For Payouts)',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),

          _buildInputField(
            controller: _signupEmailController,
            label: 'Email Address',
            hint: 'player@gmail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),

          _buildInputField(
            controller: _signupPassController,
            label: 'Password',
            hint: 'Min 6 characters',
            icon: Icons.lock_outline,
            obscureText: _signupPassObscure,
            suffixIcon: IconButton(
              icon: Icon(
                _signupPassObscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _signupPassObscure = !_signupPassObscure),
            ),
          ),
          const SizedBox(height: 10),

          // Free Fire Specific Details (IGN, UID, Level 40+)
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _ignController,
                  label: 'FF In-Game Name',
                  hint: '⚡BOOYAH⚡',
                  icon: Icons.sports_esports_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  controller: _uidController,
                  label: 'Free Fire UID',
                  hint: '284719284',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildInputField(
            controller: _levelController,
            label: 'Free Fire Level (Min 40+ Anti-Hack)',
            hint: '40+',
            icon: Icons.shield_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _isSignupLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.winningGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: _isSignupLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('CREATE FREE ACCOUNT (+5 🟡 COINS)', style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              prefixIcon: Icon(icon, color: AppTheme.primaryAmber, size: 18),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
