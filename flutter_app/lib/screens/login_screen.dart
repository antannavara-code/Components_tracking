import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _error = '';

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final result = await context.read<AuthProvider>().demoLogin();

    if (result != null && mounted) {
      setState(() {
        _error = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> gradientColors = isDark
        ? const [Color(0xFF0D1B3E), Color(0xFF1A237E), Color(0xFF283593)]
        : const [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF3F51B5)];

    final scaffoldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: BoxDecoration(gradient: scaffoldGradient)),
          Image.asset(
            'assets/images/factory_background.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.45),
          ),
          Container(color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.30)),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Consumer<ThemeProvider>(
                      builder: (context, theme, _) => IconButton(
                        icon: Icon(
                          theme.isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        tooltip: theme.isDark ? 'Light theme' : 'Dark theme',
                        onPressed: () =>
                            context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        _buildLogo(),
                        const SizedBox(height: 24),
                        const Text(
                          'FWD Asset Tracker',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Component Management System',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildFeatureRow(),
                        const SizedBox(height: 36),
                        if (_error.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.red.shade700),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _handleDemoLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1565C0)),
                                  )
                                : const Icon(Icons.lock, size: 20),
                            label: const Text('Login',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to enter the app',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'v1.0.1  •  Fully offline',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Image.asset(
        'assets/images/fwd_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildFeatureRow() {
    const features = [
      (Icons.inventory_2, 'Asset\nTracking'),
      (Icons.qr_code_scanner, 'QR\nScanning'),
      (Icons.print, 'Label\nPrinting'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.map((f) {
        return Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(f.$1, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                f.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
