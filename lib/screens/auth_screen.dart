import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
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
  final _loginIdentController = TextEditingController();
  final _loginPassController = TextEditingController();
  bool _loginPassVisible = false;
  bool _isLoginLoading = false;

  // Signup Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _signupPassController = TextEditingController();
  final _ignController = TextEditingController();
  final _uidController = TextEditingController();
  final _referralController = TextEditingController();
  bool _signupPassVisible = false;
  bool _isSignupLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentController.dispose();
    _loginPassController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _signupPassController.dispose();
    _ignController.dispose();
    _uidController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final ident = _loginIdentController.text.trim();
    final pass = _loginPassController.text.trim();

    if (ident.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया ईमेल/फ़ोन और पासवर्ड दर्ज करें!')),
      );
      return;
    }

    setState(() => _isLoginLoading = true);
    final res = await widget.appState.loginUser(identifier: ident, password: pass);
    if (!mounted) return;
    setState(() => _isLoginLoading = false);

    if (res['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.errorRed, content: Text(res['message'] ?? 'लॉगिन विफल रहा!')),
      );
    }
  }

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pass = _signupPassController.text.trim();
    final ign = _ignController.text.trim();
    final uid = _uidController.text.trim();
    final ref = _referralController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया नाम, मोबाइल, ईमेल और पासवर्ड भरें!')),
      );
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('पासवर्ड कम से कम 6 अक्षरों का होना चाहिए!')),
      );
      return;
    }

    setState(() => _isSignupLoading = true);
    final res = await widget.appState.signupUser(
      name: name,
      phone: phone,
      email: email,
      password: pass,
      inGameName: ign,
      inGameId: uid,
      referralCode: ref,
    );
    if (!mounted) return;
    setState(() => _isSignupLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.successGreen, content: Text(res['message'] ?? 'खाता बन गया!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.errorRed, content: Text(res['message'] ?? 'साइन-अप विफल रहा!')),
      );
    }
  }

  void _guestLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Hero Logo
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.35), blurRadius: 16),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: Image.asset(
                      'assets/imgasest/booyah_hero_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 50, color: AppTheme.primaryGold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'BOOYAH REWARDS',
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppTheme.primaryGold,
                ),
              ),
              Text(
                'India Ka Apna Esports Platform',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.cyanAccent,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 20),

              // Tab Bar (Login vs Signup)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryGold,
                  indicatorWeight: 3,
                  labelColor: AppTheme.primaryGold,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: '🔑 लॉगिन (LOGIN)'),
                    Tab(text: '📝 नया खाता (SIGNUP)'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tab Bar Views
              SizedBox(
                height: 440,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: LOGIN
                    _buildLoginForm(),

                    // TAB 2: SIGNUP
                    _buildSignupForm(),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Guest Access Link
              TextButton(
                onPressed: _guestLogin,
                child: const Text(
                  'बिना पासवर्ड गेस्ट रूप में खेलें ➜',
                  style: TextStyle(color: Colors.white54, fontSize: 13, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ईमेल आईडी या मोबाइल नंबर:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: _loginIdentController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'example@gmail.com या 9876543210',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.person, color: AppTheme.primaryGold, size: 20),
              filled: true,
              fillColor: AppTheme.bgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          const Text('पासवर्ड:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: _loginPassController,
            obscureText: !_loginPassVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'अपना पासवर्ड दर्ज करें',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGold, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_loginPassVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54, size: 20),
                onPressed: () => setState(() => _loginPassVisible = !_loginPassVisible),
              ),
              filled: true,
              fillColor: AppTheme.bgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.bgDark,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoginLoading ? null : _handleLogin,
            child: _isLoginLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('लॉगिन करें ➜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField('पूरा नाम (Full Name):', _nameController, 'e.g. Rahul Sharma', Icons.badge),
          const SizedBox(height: 10),

          _buildField('व्हाट्सएप मोबाइल नंबर:', _phoneController, '10-अंकों का नंबर', Icons.phone, keyboard: TextInputType.phone),
          const SizedBox(height: 10),

          _buildField('ईमेल आईडी:', _emailController, 'rahul@gmail.com', Icons.email, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 10),

          // Password
          const Text('पासवर्ड बनाएं (कम से कम 6 अक्षर):', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
          const SizedBox(height: 4),
          TextField(
            controller: _signupPassController,
            obscureText: !_signupPassVisible,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'मजबूत पासवर्ड दर्ज करें',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGold, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_signupPassVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54, size: 18),
                onPressed: () => setState(() => _signupPassVisible = !_signupPassVisible),
              ),
              filled: true,
              fillColor: AppTheme.bgCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),

          _buildField('फ्री फायर इन-गेम नाम (IGN):', _ignController, 'e.g. RASTAR_99', Icons.sports_esports),
          const SizedBox(height: 10),

          _buildField('फ्री फायर UID (Game UID):', _uidController, 'e.g. 2938472918', Icons.tag, keyboard: TextInputType.number),
          const SizedBox(height: 10),

          _buildField('रेफरल कोड (वैकल्पिक - +10 कॉइन्स बोनस):', _referralController, '6-अंकों का रेफरल कोड (यदि है)', Icons.card_giftcard),
          const SizedBox(height: 18),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.bgDark,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSignupLoading ? null : _handleSignup,
            child: _isSignupLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('खाता बनाएं और 30 कॉइन्स पाएं ➜', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            prefixIcon: Icon(icon, color: AppTheme.primaryGold, size: 18),
            filled: true,
            fillColor: AppTheme.bgCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
