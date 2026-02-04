import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/typography.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/services/sample_data_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  final SampleDataService _sampleDataService = SampleDataService();

  int _currentPage = 0;
  bool _isGeneratingData = false;

  final List<OnboardingContent> _slides = [
    OnboardingContent(
      title: 'Welcome to Yepsy',
      description:
          'Your private, secure companion for tracking health, mood, and meals.',
      imagePath: 'assets/images/yepsy.png',
      color: const Color(0xFFFF80AB), // Pink accent
    ),
    OnboardingContent(
      title: 'Track Your Cycle',
      description:
          'Log symptoms and get smart insights into your cycle patterns.',
      imagePath: 'assets/images/raincheck.png',
      color: const Color(0xFF9575CD), // Purple accent
    ),
    OnboardingContent(
      title: 'Monitor Sleep & Vitality',
      description:
          'Understand your rest patterns and how they relate to your overall wellbeing.',
      imagePath: 'assets/images/sleep.png',
      color: const Color(0xFF64B5F6), // Blue accent
    ),
    OnboardingContent(
      title: 'Privacy First',
      description:
          'Everything is encrypted on your device. Only you can see your data.',
      icon: Icons.security_outlined,
      color: const Color(0xFF4DB6AC), // Teal accent
    ),
  ];

  Future<void> _onFinish() async {
    setState(() => _isGeneratingData = true);

    // Generate sample data
    await _sampleDataService.generateSampleData();

    // Mark as completed
    await _onboardingService.completeOnboarding();

    if (mounted) {
      context.go('/calendar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (slide.imagePath != null)
                      Image.asset(
                        slide.imagePath!,
                        height: 200,
                        fit: BoxFit.contain,
                      )
                    else if (slide.icon != null)
                      Icon(
                        slide.icon!,
                        size: 150,
                        color: slide.color,
                      ),
                    const SizedBox(height: 60),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayTextTheme.headlineMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      slide.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayTextTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Navigation controls
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _slides[_currentPage].color
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGeneratingData
                        ? null
                        : () {
                            if (_currentPage == _slides.length - 1) {
                              _onFinish();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slides[_currentPage].color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isGeneratingData
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentPage == _slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
}

class OnboardingContent {
  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    this.imagePath,
    this.icon,
    required this.color,
  });
}
