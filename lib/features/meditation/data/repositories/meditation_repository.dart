import 'package:flutter/material.dart';
import '../../domain/entities/meditation_audio.dart';
import '../../domain/entities/meditation_type.dart';

class MeditationRepository {
  // Meditation Types - main categories for the home screen
  List<MeditationType> getMeditationTypes() {
    return const [
      MeditationType(
        id: 'calm',
        name: 'Calm',
        description: 'Find your inner peace',
        subtitle: 'J. Cole, Ty Dolla \$ign, Bryson Tiller',
        imageUrl: 'https://picsum.photos/seed/calm/400/400',
        color: Color(0xFF6B9B8E),
      ),
      MeditationType(
        id: 'focus',
        name: 'Focus',
        description: 'Enhance concentration',
        subtitle: 'Kendrick Lamar, Future, SZA',
        imageUrl: 'https://picsum.photos/seed/focus/400/400',
        color: Color(0xFF8B7BA8),
      ),
      MeditationType(
        id: 'sleep',
        name: 'Sleep',
        description: 'Drift off peacefully',
        subtitle: 'The Weeknd, Ariana Grande',
        imageUrl: 'https://picsum.photos/seed/sleep/400/400',
        color: Color(0xFF5C6BC0),
      ),
      MeditationType(
        id: 'breathe',
        name: 'Breathe',
        description: 'Guided breathing exercises',
        subtitle: 'Relaxing breath patterns',
        imageUrl: 'https://picsum.photos/seed/breathe/400/400',
        color: Color(0xFF26A69A),
      ),
      MeditationType(
        id: 'stress',
        name: 'Stress Relief',
        description: 'Release tension and anxiety',
        subtitle: 'Calming soundscapes',
        imageUrl: 'https://picsum.photos/seed/stress/400/400',
        color: Color(0xFFEF5350),
      ),
      MeditationType(
        id: 'morning',
        name: 'Morning',
        description: 'Start your day right',
        subtitle: 'Energizing meditations',
        imageUrl: 'https://picsum.photos/seed/morning/400/400',
        color: Color(0xFFFFA726),
      ),
    ];
  }

  // Get meditation types for "Based on your mood" section
  List<MeditationType> getMoodBasedTypes() {
    return const [
      MeditationType(
        id: 'happy',
        name: 'Happy Vibes',
        description: 'Uplift your spirits',
        subtitle: 'A.R. Rahman, S. P. Balasubrahmanyam',
        imageUrl: 'https://picsum.photos/seed/happy/400/400',
        color: Color(0xFFFFEB3B),
      ),
      MeditationType(
        id: 'relax',
        name: 'Deep Relax',
        description: 'Ultimate relaxation',
        subtitle: 'Pritam, Sachin-Jigar, Amit Trivedi',
        imageUrl: 'https://picsum.photos/seed/relax/400/400',
        color: Color(0xFF9C27B0),
      ),
      MeditationType(
        id: 'energy',
        name: 'Energy Boost',
        description: 'Revitalize your mind',
        subtitle: 'Dynamic meditation tracks',
        imageUrl: 'https://picsum.photos/seed/energy/400/400',
        color: Color(0xFFE91E63),
      ),
    ];
  }

  // Mock data - meditation audio content
  List<MeditationAudio> getAllAudios() {
    return const [
      MeditationAudio(
        id: '1',
        title: 'Ocean Waves',
        description: 'Gentle waves lapping on the shore',
        audioPath: 'assets/audio/ocean_waves.mp3',
        durationInSeconds: 600,
        category: 'calm',
        imageUrl: 'https://picsum.photos/seed/ocean/400/400',
      ),
      MeditationAudio(
        id: '2',
        title: 'Rainforest',
        description: 'Tropical rain and wildlife sounds',
        audioPath: 'assets/audio/rain.mp3',
        durationInSeconds: 720,
        category: 'calm',
        imageUrl: 'https://picsum.photos/seed/rainforest/400/400',
      ),
      MeditationAudio(
        id: '3',
        title: 'Forest Ambience',
        description: 'Birds chirping and gentle breeze',
        audioPath: 'assets/audio/forest.mp3',
        durationInSeconds: 900,
        category: 'focus',
        imageUrl: 'https://picsum.photos/seed/forest/400/400',
      ),
      MeditationAudio(
        id: '4',
        title: 'Birds Singing',
        description: 'Morning birds and wildlife',
        audioPath: 'assets/audio/birds.mp3',
        durationInSeconds: 600,
        category: 'morning',
        imageUrl: 'https://picsum.photos/seed/birds/400/400',
      ),
      MeditationAudio(
        id: '5',
        title: 'Campfire Crackling',
        description: 'Warm fire crackling sounds',
        audioPath: 'assets/audio/campfire.mp3',
        durationInSeconds: 840,
        category: 'sleep',
        imageUrl: 'https://picsum.photos/seed/campfire/400/400',
      ),
      MeditationAudio(
        id: '6',
        title: 'Wind Chimes',
        description: 'Peaceful wind chimes melody',
        audioPath: 'assets/audio/wind_chimes.mp3',
        durationInSeconds: 600,
        category: 'focus',
        imageUrl: 'https://picsum.photos/seed/windchimes/400/400',
      ),
      MeditationAudio(
        id: '7',
        title: 'River Stream',
        description: 'Flowing river and water sounds',
        audioPath: 'assets/audio/river.mp3',
        durationInSeconds: 720,
        category: 'calm',
        imageUrl: 'https://picsum.photos/seed/river/400/400',
      ),
      MeditationAudio(
        id: '8',
        title: 'Thunderstorm',
        description: 'Distant thunder and rain',
        audioPath: 'assets/audio/thunderstorm.mp3',
        durationInSeconds: 900,
        category: 'sleep',
        imageUrl: 'https://picsum.photos/seed/thunder/400/400',
      ),
      MeditationAudio(
        id: '9',
        title: 'Deep Breathing',
        description: '4-7-8 breathing technique',
        audioPath: 'assets/audio/breathing.mp3',
        durationInSeconds: 300,
        category: 'breathe',
        imageUrl: 'https://picsum.photos/seed/breathing/400/400',
      ),
      MeditationAudio(
        id: '10',
        title: 'Box Breathing',
        description: 'Square breathing for calm',
        audioPath: 'assets/audio/box_breathing.mp3',
        durationInSeconds: 480,
        category: 'breathe',
        imageUrl: 'https://picsum.photos/seed/boxbreathing/400/400',
      ),
      MeditationAudio(
        id: '11',
        title: 'Stress Melt',
        description: 'Release tension from your body',
        audioPath: 'assets/audio/stress_melt.mp3',
        durationInSeconds: 900,
        category: 'stress',
        imageUrl: 'https://picsum.photos/seed/stressmelt/400/400',
      ),
      MeditationAudio(
        id: '12',
        title: 'Morning Energy',
        description: 'Start your day with intention',
        audioPath: 'assets/audio/morning_energy.mp3',
        durationInSeconds: 600,
        category: 'morning',
        imageUrl: 'https://picsum.photos/seed/morningenergy/400/400',
      ),
      MeditationAudio(
        id: '13',
        title: 'Anxiety Relief',
        description: 'Calm your anxious thoughts',
        audioPath: 'assets/audio/anxiety_relief.mp3',
        durationInSeconds: 720,
        category: 'anxiety',
        imageUrl: 'https://picsum.photos/seed/anxiety/400/400',
      ),
      MeditationAudio(
        id: '14',
        title: 'Work Stress Release',
        description: 'Let go of work tension',
        audioPath: 'assets/audio/work_stress.mp3',
        durationInSeconds: 900,
        category: 'work stress',
        imageUrl: 'https://picsum.photos/seed/workstress/400/400',
      ),
      MeditationAudio(
        id: '15',
        title: 'Deep Relaxation',
        description: 'Total body and mind relaxation',
        audioPath: 'assets/audio/deep_relax.mp3',
        durationInSeconds: 1200,
        category: 'relax',
        imageUrl: 'https://picsum.photos/seed/deeprelax/400/400',
      ),
      MeditationAudio(
        id: '16',
        title: 'Panic Attack Help',
        description: 'Grounding exercises for anxiety',
        audioPath: 'assets/audio/panic_help.mp3',
        durationInSeconds: 300,
        category: 'anxiety',
        imageUrl: 'https://picsum.photos/seed/panichelp/400/400',
      ),
      MeditationAudio(
        id: '17',
        title: 'Office Break',
        description: '5-minute desk meditation',
        audioPath: 'assets/audio/office_break.mp3',
        durationInSeconds: 300,
        category: 'work stress',
        imageUrl: 'https://picsum.photos/seed/officebreak/400/400',
      ),
      MeditationAudio(
        id: '18',
        title: 'Progressive Relaxation',
        description: 'Muscle relaxation technique',
        audioPath: 'assets/audio/progressive.mp3',
        durationInSeconds: 900,
        category: 'relax',
        imageUrl: 'https://picsum.photos/seed/progressive/400/400',
      ),
    ];
  }

  List<MeditationAudio> getAudiosByCategory(String category) {
    return getAllAudios()
        .where((audio) => audio.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  MeditationAudio? getAudioById(String id) {
    try {
      return getAllAudios().firstWhere((audio) => audio.id == id);
    } catch (e) {
      return null;
    }
  }
}
