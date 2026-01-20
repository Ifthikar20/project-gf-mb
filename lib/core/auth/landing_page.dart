import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _agreedToTerms = false;
  
  // Video controller
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // Purple theme color
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFA78BFA);

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/images/main-video.mp4');
    try {
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0); // Muted background video
      _videoController.play();
      setState(() => _isVideoInitialized = true);
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Terms of Service

Last updated: January 2026

1. Acceptance of Terms
By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.

2. Use License
Permission is granted to temporarily download one copy of the materials for personal, non-commercial transitory viewing only.

3. Disclaimer
The materials on this application are provided on an 'as is' basis. We make no warranties, expressed or implied.

4. Limitations
In no event shall we or our suppliers be liable for any damages arising out of the use or inability to use the materials.

5. Revisions
We may revise these terms of service at any time without notice.

For questions about these terms, please contact support.''',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primaryPurple)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Privacy Policy

Last updated: January 2026

1. Information We Collect
We collect information you provide directly to us, such as when you create an account.

2. How We Use Your Information
We use the information we collect to provide, maintain, and improve our services.

3. Information Sharing
We do not share your personal information with third parties except as described in this policy.

4. Data Security
We take reasonable measures to help protect your personal information.

5. Your Choices
You may update, correct, or delete your account information at any time.

6. Contact Us
If you have any questions about this Privacy Policy, please contact us.''',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primaryPurple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== FULLSCREEN VIDEO BACKGROUND =====
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: const Color(0xFF0A0A0A)),
          
          // ===== LIGHT OVERLAY FOR TOP (keeps video visible) =====
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2), // Light at top - video visible
                  Colors.black.withOpacity(0.3), // Still light
                  Colors.black.withOpacity(0.85), // Darker at bottom for buttons
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // ===== CONTENT =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Centered Logo
                  Image.asset(
                    'assets/images/logo-main.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Welcome text
                  Text(
                    'Welcome to\nGreat Feel.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // Terms & Conditions checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                          activeColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: lightPurple,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _showTermsDialog,
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: lightPurple,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _showPrivacyDialog,
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign up button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _agreedToTerms
                          ? () => context.push('/register')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        disabledBackgroundColor: primaryPurple.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign up free',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Log in button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _agreedToTerms
                          ? () => context.push('/login')
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: _agreedToTerms 
                              ? Colors.white.withOpacity(0.6) 
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        'Log in',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _agreedToTerms 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
