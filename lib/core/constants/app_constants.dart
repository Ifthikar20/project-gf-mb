class AppConstants {
  // Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String audioPath = 'assets/audio/';
  static const String videosPath = 'assets/videos/';
  
  // Audio Files
  static const String oceanWavesAudio = '${audioPath}ocean_waves.mp3';
  static const String rainAudio = '${audioPath}rain.mp3';
  static const String forestAudio = '${audioPath}forest.mp3';
  static const String birdsAudio = '${audioPath}birds.mp3';
  static const String campfireAudio = '${audioPath}campfire.mp3';
  static const String windChimesAudio = '${audioPath}wind_chimes.mp3';
  static const String riverAudio = '${audioPath}river.mp3';
  static const String thunderstormAudio = '${audioPath}thunderstorm.mp3';
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border Radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  
  // Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Meditation Timer Presets (in minutes)
  static const List<int> meditationTimers = [5, 10, 15, 20, 30];
  
  // Wellness Goal Categories
  static const List<String> goalCategories = [
    'Mindfulness',
    'Exercise',
    'Nutrition',
    'Sleep',
    'Meditation',
    'Reading',
    'Hydration',
    'Social',
    'Other',
  ];
  
  // Video Categories
  static const List<String> videoCategories = [
    'All',
    'Yoga',
    'Breathing',
    'Exercises',
    'Mindfulness',
    'Sleep',
  ];
}
