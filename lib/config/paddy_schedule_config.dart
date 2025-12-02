/// Paddy Fertilization and Pesticide Schedule Configuration
/// Based on Malaysian rice cultivation best practices

class PaddyScheduleConfig {
  // Schedule data structure
  static const Map<String, List<ScheduleActivity>> paddySchedules = {
    'MR 297': [
      // Days 5-10: Pre-planting preparation
      ScheduleActivity(
        daysAfterPlanting: 5,
        type: 'pest_control',
        title: 'Pre-Emergence Weed Killer & Snail Control',
        titleMalay: 'Racun Rumpai Pra-Tumbuh & Siput',
        description: 'Apply pre-emergence weed killer and snail control',
        descriptionMalay: 'Aplikasi racun rumpai pra-tumbuh dan kawalan siput',
        priority: 'high',
      ),
      // Days 14: First fertilization
      ScheduleActivity(
        daysAfterPlanting: 14,
        type: 'fertilization',
        title: 'P1: Compound Fertilizer (Vegetative Growth)',
        titleMalay: 'P1: Baja Campuran (Pertumbuhan Vegetatif)',
        description: 'First compound fertilizer application for vegetative growth',
        descriptionMalay: 'Aplikasi baja campuran pertama untuk pertumbuhan vegetatif',
        priority: 'high',
      ),
      // Days 20: P2 Urea
      ScheduleActivity(
        daysAfterPlanting: 20,
        type: 'fertilization',
        title: 'P2: Urea',
        titleMalay: 'P2: Urea',
        description: 'Second urea fertilizer application',
        descriptionMalay: 'Aplikasi baja Urea kedua',
        priority: 'high',
      ),
      // Days 47: Third fertilization
      ScheduleActivity(
        daysAfterPlanting: 47,
        type: 'fertilization',
        title: 'P3: NPK + 10 kg Compound Fertilizer',
        titleMalay: 'P3: Baja NPK + 10 kg Campuran',
        description: 'NPK fertilizer with additional compound fertilizer',
        descriptionMalay: 'Baja NPK dengan tambahan baja campuran',
        priority: 'high',
      ),
      // Days 60-65: Fungicide and pest control
      ScheduleActivity(
        daysAfterPlanting: 60,
        type: 'pest_control',
        title: 'Fungicide (Stem Rot) & Brown Planthopper Control',
        titleMalay: 'Racun Kulat (Karah Tangkai) & Bena Perang',
        description: 'Fungicide for stem rot and brown planthopper control',
        descriptionMalay: 'Racun kulat untuk karah tangkai dan kawalan bena perang',
        priority: 'urgent',
      ),
      // Days 69: NPK application
      ScheduleActivity(
        daysAfterPlanting: 69,
        type: 'fertilization',
        title: 'P4: NPK (Optional)',
        titleMalay: 'P4: NPK (Pilihan)',
        description: 'Optional NPK fertilizer application',
        descriptionMalay: 'Aplikasi baja NPK (pilihan)',
        priority: 'medium',
      ),
    ],
    'MR 220': [
      // Days 5-10: Pre-planting preparation
      ScheduleActivity(
        daysAfterPlanting: 5,
        type: 'pest_control',
        title: 'Pre-Emergence Weed Killer & Snail Control',
        titleMalay: 'Racun Rumpai Pra-Tumbuh & Siput',
        description: 'Apply pre-emergence weed killer and snail control',
        descriptionMalay: 'Aplikasi racun rumpai pra-tumbuh dan kawalan siput',
        priority: 'high',
      ),
      // Days 15-20: First NPK
      ScheduleActivity(
        daysAfterPlanting: 15,
        type: 'fertilization',
        title: 'P1: NPK Compound Fertilizer (Early Application)',
        titleMalay: 'P1: Baja Campuran NPK (Aplikasi Awal)',
        description: 'First NPK compound fertilizer application',
        descriptionMalay: 'Aplikasi baja campuran NPK pertama',
        priority: 'high',
      ),
      // Days 20: Second fertilization
      ScheduleActivity(
        daysAfterPlanting: 20,
        type: 'fertilization',
        title: 'P2: Urea',
        titleMalay: 'P2: Urea',
        description: 'Urea fertilizer application',
        descriptionMalay: 'Aplikasi baja Urea',
        priority: 'high',
      ),
      // Days 25-30: Post-emergence weed control
      ScheduleActivity(
        daysAfterPlanting: 25,
        type: 'pest_control',
        title: 'P2: Urea',
        titleMalay: 'P2: Urea',
        description: 'Second urea application',
        descriptionMalay: 'Aplikasi Urea kedua',
        priority: 'high',
      ),
      // Days 30-35: Post weed control
      ScheduleActivity(
        daysAfterPlanting: 30,
        type: 'pest_control',
        title: 'Post-Emergence Weed Killer & Early Caterpillar Control',
        titleMalay: 'Racun Rumpai Pasca-Tumbuh & Ulat Awal',
        description: 'Post-emergence weed killer and early caterpillar control',
        descriptionMalay: 'Racun rumpai pasca-tumbuh dan kawalan ulat awal',
        priority: 'high',
      ),
      // Days 45-50: Third NPK
      ScheduleActivity(
        daysAfterPlanting: 45,
        type: 'fertilization',
        title: 'P3: High K NPK (Panicle Formation) + Fungicide (Leaf/Sheath Blight)',
        titleMalay: 'P3: Baja NPK Tinggi K (Pembentukan Tangkai) + Racun Kulat (Karah Daun/Seludang)',
        description: 'High K NPK fertilizer for panicle formation with fungicide',
        descriptionMalay: 'Baja NPK tinggi K untuk pembentukan tangkai dengan racun kulat',
        priority: 'urgent',
      ),
      // Days 60-65: Fourth application
      ScheduleActivity(
        daysAfterPlanting: 60,
        type: 'pest_control',
        title: 'P4: High K NPK (Optional) + Fungicide (Stem Rot) & Planthopper Control',
        titleMalay: 'P4: Baja NPK Tinggi K (Pilihan) + Racun Kulat (Karah Tangkai) & Bena',
        description: 'Optional high K NPK with fungicide and planthopper control',
        descriptionMalay: 'Baja NPK tinggi K (pilihan) dengan racun kulat dan kawalan bena',
        priority: 'urgent',
      ),
    ],
    'MR 219': [
      // Days 5-10: Pre-planting preparation
      ScheduleActivity(
        daysAfterPlanting: 5,
        type: 'pest_control',
        title: 'Pre-Emergence Weed Killer & Snail Control',
        titleMalay: 'Racun Rumpai Pra-Tumbuh & Siput',
        description: 'Apply pre-emergence weed killer and snail control',
        descriptionMalay: 'Aplikasi racun rumpai pra-tumbuh dan kawalan siput',
        priority: 'high',
      ),
      // Days 15-20: First NPK
      ScheduleActivity(
        daysAfterPlanting: 15,
        type: 'fertilization',
        title: 'P1: NPK Compound Fertilizer (Early Application)',
        titleMalay: 'P1: Baja Campuran NPK (Aplikasi Awal)',
        description: 'First NPK compound fertilizer application',
        descriptionMalay: 'Aplikasi baja campuran NPK pertama',
        priority: 'high',
      ),
      // Days 30-35: Urea application
      ScheduleActivity(
        daysAfterPlanting: 30,
        type: 'fertilization',
        title: 'P2: Urea',
        titleMalay: 'P2: Urea',
        description: 'Urea fertilizer application',
        descriptionMalay: 'Aplikasi baja Urea',
        priority: 'high',
      ),
      // Days 45-50: Third NPK
      ScheduleActivity(
        daysAfterPlanting: 45,
        type: 'fertilization',
        title: 'P3: High K NPK (Panicle Formation) + Fungicide (Leaf/Sheath Blight)',
        titleMalay: 'P3: Baja NPK Tinggi K (Pembentukan Tangkai) + Racun Kulat (Karah Daun/Seludang)',
        description: 'High K NPK fertilizer for panicle formation with fungicide',
        descriptionMalay: 'Baja NPK tinggi K untuk pembentukan tangkai dengan racun kulat',
        priority: 'urgent',
      ),
      // Days 60-65: Fungicide and pest control
      ScheduleActivity(
        daysAfterPlanting: 60,
        type: 'pest_control',
        title: 'Fungicide (Stem Rot) & Brown Planthopper Control',
        titleMalay: 'Racun Kulat (Karah Tangkai) & Bena Perang',
        description: 'Fungicide for stem rot and brown planthopper control',
        descriptionMalay: 'Racun kulat untuk karah tangkai dan kawalan bena perang',
        priority: 'urgent',
      ),
    ],
    'MR 263': [
      // Days 5-10: Pre-planting preparation
      ScheduleActivity(
        daysAfterPlanting: 5,
        type: 'pest_control',
        title: 'Pre-Emergence Weed Killer & Snail Control',
        titleMalay: 'Racun Rumpai Pra-Tumbuh & Siput',
        description: 'Apply pre-emergence weed killer and snail control',
        descriptionMalay: 'Aplikasi racun rumpai pra-tumbuh dan kawalan siput',
        priority: 'high',
      ),
      // Days 10-15: First NPK
      ScheduleActivity(
        daysAfterPlanting: 10,
        type: 'fertilization',
        title: 'P1: NPK Compound Fertilizer (Early Application)',
        titleMalay: 'P1: Baja Campuran NPK (Aplikasi Awal)',
        description: 'First NPK compound fertilizer application',
        descriptionMalay: 'Aplikasi baja campuran NPK pertama',
        priority: 'high',
      ),
      // Days 20-25: Urea application
      ScheduleActivity(
        daysAfterPlanting: 20,
        type: 'fertilization',
        title: 'P2: Urea',
        titleMalay: 'P2: Urea',
        description: 'Urea fertilizer application',
        descriptionMalay: 'Aplikasi baja Urea',
        priority: 'high',
      ),
      // Days 40-45: Third NPK
      ScheduleActivity(
        daysAfterPlanting: 40,
        type: 'fertilization',
        title: 'P3: High K NPK (Panicle Formation) + Fungicide (Leaf Blight)',
        titleMalay: 'P3: Baja NPK Tinggi K (Pembentukan Tangkai) + Racun Kulat (Karah Daun)',
        description: 'High K NPK fertilizer for panicle formation with fungicide',
        descriptionMalay: 'Baja NPK tinggi K untuk pembentukan tangkai dengan racun kulat',
        priority: 'urgent',
      ),
      // Days 60-65: Fungicide and pest control
      ScheduleActivity(
        daysAfterPlanting: 60,
        type: 'pest_control',
        title: 'Fungicide (Stem Rot) & Brown Planthopper Control',
        titleMalay: 'Racun Kulat (Karah Tangkai) & Bena Perang',
        description: 'Fungicide for stem rot and brown planthopper control',
        descriptionMalay: 'Racun kulat untuk karah tangkai dan kawalan bena perang',
        priority: 'urgent',
      ),
    ],
    'MR 315': [
      // Days 5-10: Pre-planting preparation
      ScheduleActivity(
        daysAfterPlanting: 5,
        type: 'pest_control',
        title: 'Pre-Emergence Weed Killer & Snail Control',
        titleMalay: 'Racun Rumpai Pra-Tumbuh & Siput',
        description: 'Apply pre-emergence weed killer and snail control',
        descriptionMalay: 'Aplikasi racun rumpai pra-tumbuh dan kawalan siput',
        priority: 'high',
      ),
      // Days 10-15: First NPK
      ScheduleActivity(
        daysAfterPlanting: 10,
        type: 'fertilization',
        title: 'P1: NPK Compound Fertilizer (Early Application)',
        titleMalay: 'P1: Baja Campuran NPK (Aplikasi Awal)',
        description: 'First NPK compound fertilizer application',
        descriptionMalay: 'Aplikasi baja campuran NPK pertama',
        priority: 'high',
      ),
      // Days 25-30: Urea/Compound fertilizer
      ScheduleActivity(
        daysAfterPlanting: 25,
        type: 'fertilization',
        title: 'P2: Urea / Compound Fertilizer',
        titleMalay: 'P2: Urea / Baja Campuran',
        description: 'Urea or compound fertilizer application',
        descriptionMalay: 'Aplikasi baja Urea atau campuran',
        priority: 'high',
      ),
      // Days 30-35: Post-emergence weed control
      ScheduleActivity(
        daysAfterPlanting: 30,
        type: 'pest_control',
        title: 'Post-Emergence Weed Killer & Early Caterpillar Control',
        titleMalay: 'Racun Rumpai Pasca-Tumbuh & Ulat Awal',
        description: 'Post-emergence weed killer and early caterpillar control',
        descriptionMalay: 'Racun rumpai pasca-tumbuh dan kawalan ulat awal',
        priority: 'high',
      ),
      // Days 45-50: Third NPK
      ScheduleActivity(
        daysAfterPlanting: 45,
        type: 'fertilization',
        title: 'P3: High K NPK (Panicle Formation) + Fungicide (Leaf/Sheath Blight)',
        titleMalay: 'P3: Baja NPK Tinggi K (Pembentukan Tangkai) + Racun Kulat (Karah Daun/Seludang)',
        description: 'High K NPK fertilizer for panicle formation with fungicide',
        descriptionMalay: 'Baja NPK tinggi K untuk pembentukan tangkai dengan racun kulat',
        priority: 'urgent',
      ),
      // Days 60-65: Fungicide and pest control
      ScheduleActivity(
        daysAfterPlanting: 60,
        type: 'pest_control',
        title: 'Fungicide (Stem Rot) & Brown Planthopper Control',
        titleMalay: 'Racun Kulat (Karah Tangkai) & Bena Perang',
        description: 'Fungicide for stem rot and brown planthopper control',
        descriptionMalay: 'Racun kulat untuk karah tangkai dan kawalan bena perang',
        priority: 'urgent',
      ),
    ],
  };

  /// Get schedule activities for a specific paddy variety
  static List<ScheduleActivity> getScheduleForVariety(String variety) {
    return paddySchedules[variety] ?? [];
  }

  /// Calculate actual dates for schedule activities based on planting date
  static List<ScheduledReminder> calculateScheduleDates({
    required String variety,
    required DateTime plantingDate,
  }) {
    final activities = getScheduleForVariety(variety);
    
    return activities.map((activity) {
      final scheduledDate = plantingDate.add(Duration(days: activity.daysAfterPlanting));
      return ScheduledReminder(
        activity: activity,
        scheduledDate: scheduledDate,
      );
    }).toList();
  }
}

/// Schedule activity definition
class ScheduleActivity {
  final int daysAfterPlanting;
  final String type; // 'fertilization' or 'pest_control'
  final String title;
  final String titleMalay;
  final String description;
  final String descriptionMalay;
  final String priority; // 'low', 'medium', 'high', 'urgent'

  const ScheduleActivity({
    required this.daysAfterPlanting,
    required this.type,
    required this.title,
    required this.titleMalay,
    required this.description,
    required this.descriptionMalay,
    required this.priority,
  });
}

/// Scheduled reminder with calculated date
class ScheduledReminder {
  final ScheduleActivity activity;
  final DateTime scheduledDate;

  const ScheduledReminder({
    required this.activity,
    required this.scheduledDate,
  });

  /// Convert to reminder data map for database insertion
  Map<String, dynamic> toReminderData(String userId, {String? locale}) {
    final isMalay = locale != null && locale.toLowerCase().startsWith('ms');
    
    return {
      'title': isMalay ? activity.titleMalay : activity.title,
      'description': isMalay ? activity.descriptionMalay : activity.description,
      'reminder_type': activity.type,
      'scheduled_date': scheduledDate.toIso8601String(),
      'priority': activity.priority,
      'is_completed': false,
      'notification_sent': false,
      'user_id': userId,
    };
  }
}
