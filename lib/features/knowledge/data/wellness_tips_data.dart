import 'package:flutter/material.dart';
import 'models/knowledge_models.dart';

/// Static curated wellness tips and articles — local fallback content
class WellnessTipsData {
  WellnessTipsData._();

  /// Get daily tip (deterministic by day)
  static WellnessTip getTipOfTheDay() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return allTips[dayOfYear % allTips.length];
  }

  /// Get tips by category
  static List<WellnessTip> getByCategory(String category) {
    return allTips.where((t) => t.category == category).toList();
  }

  static const List<WellnessTip> allTips = [
    // Nutrition
    WellnessTip(
      title: 'Protein timing matters',
      body: 'Distribute protein evenly across meals (20-30g each) rather than loading it at dinner for better muscle protein synthesis.',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF10B981),
      category: 'nutrition',
    ),
    WellnessTip(
      title: 'Gut health = Brain health',
      body: 'Your gut microbiome produces 95% of your serotonin. Feed it with fermented foods like yogurt, kimchi, and kombucha.',
      icon: Icons.eco_rounded,
      color: Color(0xFF059669),
      category: 'nutrition',
    ),

    // Sleep
    WellnessTip(
      title: 'The 10-3-2-1 rule',
      body: '10 hrs before bed: no caffeine. 3 hrs: no food/alcohol. 2 hrs: no work. 1 hr: no screens.',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF6366F1),
      category: 'sleep',
    ),
    WellnessTip(
      title: 'Cool your bedroom',
      body: 'The optimal sleep temperature is 65-68°F (18-20°C). A cooler room triggers your body\'s natural sleep signals.',
      icon: Icons.thermostat_rounded,
      color: Color(0xFF818CF8),
      category: 'sleep',
    ),

    // Mindfulness
    WellnessTip(
      title: 'The 5-4-3-2-1 grounding',
      body: 'Feeling anxious? Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste.',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF8B5CF6),
      category: 'mindfulness',
    ),
    WellnessTip(
      title: 'Two-minute rule',
      body: 'If meditating feels hard, commit to just 2 minutes. You\'ll often continue once seated — starting is the hardest part.',
      icon: Icons.timer_rounded,
      color: Color(0xFFA78BFA),
      category: 'mindfulness',
    ),

    // Movement
    WellnessTip(
      title: 'Movement snacking',
      body: 'Instead of one 30-min session, scatter 5-minute movement bursts throughout the day. Your body benefits equally.',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFFF59E0B),
      category: 'movement',
    ),
    WellnessTip(
      title: 'Morning light exposure',
      body: 'Get 10 min of sunlight within the first hour of waking. It resets your circadian rhythm and boosts energy all day.',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFBBF24),
      category: 'movement',
    ),

    // Mental Health
    WellnessTip(
      title: 'Journaling reduces anxiety',
      body: 'Writing down worries before bed reduces intrusive thoughts by 50%. Keep a notebook on your nightstand.',
      icon: Icons.edit_note_rounded,
      color: Color(0xFFEC4899),
      category: 'mental-health',
    ),
    WellnessTip(
      title: 'Social connection heals',
      body: 'A 15-minute conversation with a friend activates the same brain regions as exercise. Don\'t underestimate social wellness.',
      icon: Icons.people_rounded,
      color: Color(0xFFF472B6),
      category: 'mental-health',
    ),
  ];

  /// Curated fallback articles (displayed when API is unavailable)
  static final List<Article> fallbackArticles = [
    Article(
      id: 'local-1',
      title: 'The Science of Sleep: Why 7 Hours Changes Everything',
      summary: 'Understanding how sleep architecture affects your mental clarity, emotional regulation, and physical recovery.',
      body: '''Sleep isn't just "rest" — it's an active process where your brain consolidates memories, clears metabolic waste, and repairs tissues.

**The 4 Stages of Sleep**
Each 90-minute cycle moves through light sleep (N1, N2), deep sleep (N3), and REM. Deep sleep handles physical repair; REM handles emotional processing and creativity.

**Why 7+ Hours Matter**
The first half of the night is rich in deep sleep. The second half is REM-heavy. Cutting sleep short by even 1 hour disproportionately reduces REM, which impacts mood, problem-solving, and stress resilience.

**Practical Steps**
• Set a consistent wake time (even weekends)
• Create a 30-minute wind-down ritual
• Keep your room cool (65-68°F) and dark
• Limit alcohol — it fragments sleep architecture even if you "feel" asleep''',
      category: 'sleep',
      readTimeMinutes: 5,
      author: 'Great Feel',
    ),
    Article(
      id: 'local-2',
      title: 'Mindful Eating: Transform Your Relationship with Food',
      summary: 'How slowing down at meals can reduce overeating, improve digestion, and make food more enjoyable.',
      body: '''Mindful eating isn't about restriction — it's about presence. When you eat with attention, everything changes.

**The Satiety Signal Delay**
It takes 20 minutes for your gut to signal fullness to your brain. Most meals last 7 minutes. This mismatch leads to chronic overeating.

**How to Practice**
1. Put your fork down between bites
2. Chew each bite 15-20 times
3. Notice flavors, textures, and temperatures
4. Eat at a table without screens
5. Check in with hunger at the halfway point of your meal

**The Benefits**
Research shows mindful eaters consume 300 fewer calories per day without feeling deprived. They also report higher meal satisfaction and less emotional eating.''',
      category: 'nutrition',
      readTimeMinutes: 4,
      author: 'Great Feel',
    ),
    Article(
      id: 'local-3',
      title: 'Box Breathing: The Military Technique for Instant Calm',
      summary: 'Navy SEALs use this 4-4-4-4 breathing pattern to stay focused under extreme pressure. You can too.',
      body: '''Box breathing (also called tactical breathing) is one of the most effective tools for managing stress in the moment.

**How It Works**
The technique works by activating your parasympathetic nervous system — the "rest and digest" side that counteracts fight-or-flight.

**The Protocol**
• Inhale for 4 seconds
• Hold for 4 seconds
• Exhale for 4 seconds
• Hold for 4 seconds
• Repeat for 4 cycles

**When to Use It**
• Before a stressful meeting or conversation
• During moments of anger or frustration
• Before sleep to calm racing thoughts
• After an intense workout to accelerate recovery

**The Science**
Controlled breathing with extended holds increases CO2 tolerance and vagal tone. This reduces baseline anxiety over time, not just in the moment.''',
      category: 'mindfulness',
      readTimeMinutes: 3,
      author: 'Great Feel',
    ),
    Article(
      id: 'local-4',
      title: 'Movement as Medicine: Why Exercise Beats Antidepressants',
      summary: 'A comprehensive look at the mental health benefits of regular physical activity.',
      body: '''A landmark 2023 meta-analysis found that exercise is 1.5x more effective than medication for mild-to-moderate depression.

**Why Movement Works**
Exercise triggers a cascade of neurochemical changes:
• **Endorphins** — natural painkillers that create the "runner's high"
• **BDNF** — brain-derived neurotrophic factor that grows new neurons
• **Serotonin** — the "feel-good" neurotransmitter
• **Norepinephrine** — improves attention and response to stress

**The Minimum Effective Dose**
You don't need hours in the gym. Research shows:
• 30 minutes of moderate exercise, 3x/week matches SSRI effectiveness
• Even a 10-minute walk immediately improves mood
• Consistency matters more than intensity

**Getting Started**
The best exercise is the one you'll actually do. Walking, dancing, swimming, gardening — all count. The key is finding movement you enjoy.''',
      category: 'movement',
      readTimeMinutes: 5,
      author: 'Great Feel',
    ),
    Article(
      id: 'local-5',
      title: 'Digital Detox: Reclaiming Your Attention Span',
      summary: 'Practical strategies to reduce screen time and rebuild your ability to focus deeply.',
      body: '''The average person checks their phone 96 times per day. Each check fragments your attention and raises baseline cortisol.

**The Attention Cost**
Every notification triggers a micro stress response. Even seeing your phone on the table reduces cognitive capacity by 10% — a phenomenon called "brain drain."

**Practical Detox Steps**
1. **Morning rule**: No phone for the first 30 minutes after waking
2. **Notification audit**: Disable all except calls and messages from close contacts
3. **Grayscale mode**: Remove color from your screen to reduce dopamine triggers
4. **Phone-free zones**: Bedroom and dining table are sanctuaries
5. **Batch checking**: Check social media at set times (e.g., 12pm and 6pm only)

**What to Expect**
The first 3 days feel uncomfortable. By day 7, most people report improved focus, better sleep, and reduced anxiety. By day 30, the old habits feel foreign.''',
      category: 'mental-health',
      readTimeMinutes: 4,
      author: 'Great Feel',
    ),
  ];
}
