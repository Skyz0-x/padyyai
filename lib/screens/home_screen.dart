import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../l10n/app_locale.dart';
import '../config/supabase_config.dart';
import '../config/paddy_schedule_config.dart';
import '../utils/constants.dart';
import '../services/weather_service.dart';
import '../services/paddy_monitoring_service.dart';
import '../services/disease_records_service.dart';
import '../services/farming_reminders_service.dart';
import 'detect_screen.dart';
import 'marketplace_screen.dart';
import 'weather_alert_screen.dart';
import 'detect_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _paddyCardController;
  late Animation<double> _paddyCardAnimation;
  
  // Weather data
  final WeatherService _weatherService = WeatherService();
  final PaddyMonitoringService _paddyMonitoringService = PaddyMonitoringService();
  final DiseaseRecordsService _diseaseRecordsService = DiseaseRecordsService();
  final FarmingRemindersService _remindersService = FarmingRemindersService();
  Map<String, dynamic>? _weatherData;
  String _locationName = 'Loading...';
  bool _loadingWeather = true;
  
  // Farming stats
  Map<String, dynamic> _farmingStats = {};
  bool _loadingStats = true;
  
  // Reminders
  int _pendingNotificationsCount = 0;
  bool _loadingReminders = true;
  
  // Calendar state
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  Map<DateTime, List<Map<String, dynamic>>> _monthReminders = {};
  
  // Paddy variety tracking
  String? selectedVariety;
  DateTime? plantingDate;
  int? daysElapsed;
  int? estimatedHarvestDaysMin;
  int? estimatedHarvestDaysMax;
  
  // Paddy varieties with their harvest days
  final Map<String, Map<String, int>> paddyVarieties = {
    'MR 297': {'min': 110, 'max': 115},
    'MR 220': {'min': 104, 'max': 109},
    'MR 219': {'min': 105, 'max': 111},
    'MR 263': {'min': 97, 'max': 104},
    'MR 315': {'min': 110, 'max': 120},
  };
  
  String get userName {
    final user = SupabaseConfig.client.auth.currentUser;
    return user?.userMetadata?['full_name']?.split(' ')?.first ?? 'Farmer';
  }

  String getWelcomeMessage(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocale.goodMorning.getString(context);
    if (hour < 17) return AppLocale.goodAfternoon.getString(context);
    return AppLocale.goodEvening.getString(context);
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWeatherData();
    _loadSavedPaddyMonitoring();
    _loadFarmingStats();
    _loadReminders();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _paddyCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _paddyCardAnimation = CurvedAnimation(
      parent: _paddyCardController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _paddyCardController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _paddyCardController.dispose();
    super.dispose();
  }
  
  void _calculateDaysElapsed() {
    if (plantingDate != null) {
      final now = DateTime.now();
      final difference = now.difference(plantingDate!);
      setState(() {
        daysElapsed = difference.inDays;
      });
    }
  }
  
  void _selectPaddyVariety(String variety) {
    setState(() {
      selectedVariety = variety;
      estimatedHarvestDaysMin = paddyVarieties[variety]!['min'];
      estimatedHarvestDaysMax = paddyVarieties[variety]!['max'];
    });
    
    // Save to database if planting date is also set
    if (plantingDate != null) {
      _savePaddyMonitoring();
    }
  }
  
  Future<void> _selectPlantingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: plantingDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        plantingDate = picked;
        _calculateDaysElapsed();
      });
      
      // Save to database if variety is also set
      if (selectedVariety != null) {
        _savePaddyMonitoring();
      }
    }
  }
  
  Future<void> _loadSavedPaddyMonitoring() async {
    try {
      final data = await _paddyMonitoringService.getActivePaddyMonitoring();
      if (data != null && mounted) {
        setState(() {
          selectedVariety = data['variety'];
          plantingDate = DateTime.parse(data['planting_date']);
          estimatedHarvestDaysMin = data['estimated_harvest_days_min'];
          estimatedHarvestDaysMax = data['estimated_harvest_days_max'];
          _calculateDaysElapsed();
        });
        print('✅ Loaded saved paddy monitoring: $selectedVariety');
      }
    } catch (e) {
      print('❌ Error loading saved paddy monitoring: $e');
    }
  }
  
  Future<void> _savePaddyMonitoring() async {
    if (selectedVariety == null || plantingDate == null) return;
    
    try {
      final result = await _paddyMonitoringService.savePaddyMonitoring(
        variety: selectedVariety!,
        plantingDate: plantingDate!,
        estimatedHarvestDaysMin: estimatedHarvestDaysMin!,
        estimatedHarvestDaysMax: estimatedHarvestDaysMax!,
      );
      
      if (result['success']) {
        // Generate schedule reminders based on paddy variety
        await _generateScheduleReminders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result['message'] ?? 'Saved successfully'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving paddy monitoring: $e');
    }
  }
  
  Future<void> _generateScheduleReminders() async {
    if (selectedVariety == null || plantingDate == null) return;
    
    try {
      // Get current user ID
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
        return;
      }
      
      // Delete existing schedule-based reminders (fertilization and pest_control)
      print('🗑️ Deleting existing schedule reminders...');
      final existingReminders = await _remindersService.getAllReminders(includeCompleted: false);
      for (final reminder in existingReminders) {
        final type = reminder['reminder_type'];
        if (type == 'fertilization' || type == 'pest_control') {
          await _remindersService.deleteReminder(reminder['id']);
        }
      }
      
      // Get current locale
      final flutterLocalization = FlutterLocalization.instance;
      final locale = flutterLocalization.currentLocale?.languageCode ?? 'en';
      
      print('🌍 Current locale: $locale');
      print('🌍 Full locale: ${flutterLocalization.currentLocale}');
      
      // Calculate schedule dates
      final scheduledReminders = PaddyScheduleConfig.calculateScheduleDates(
        variety: selectedVariety!,
        plantingDate: plantingDate!,
      );
      
      print('📅 Generating ${scheduledReminders.length} schedule reminders for $selectedVariety');
      
      // Create reminders in database
      int successCount = 0;
      for (final reminder in scheduledReminders) {
        final reminderData = reminder.toReminderData(userId, locale: locale);
        print('📝 Creating reminder: ${reminderData['title']} (locale: $locale)');
        final result = await _remindersService.createReminder(reminderData);
        
        if (result['success']) {
          successCount++;
        }
      }
      
      print('✅ Created $successCount/${scheduledReminders.length} schedule reminders');
      
      // Reload reminders to show on calendar
      await _loadReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.startsWith('ms')
                  ? '$successCount jadual baja & racun ditambah ke kalendar'
                  : '$successCount fertilization & pest control schedules added to calendar',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error generating schedule reminders: $e');
    }
  }
  
  Future<void> _loadFarmingStats() async {
    try {
      final diseaseStats = await _diseaseRecordsService.getDetectionStats();
      
      if (mounted) {
        setState(() {
          _farmingStats = {
            'total_detections': diseaseStats['total_detections'] ?? 0,
            'healthy_count': diseaseStats['healthy_count'] ?? 0,
            'disease_count': diseaseStats['disease_count'] ?? 0,
            'avg_confidence': diseaseStats['avg_confidence'] ?? 0.0,
          };
          _loadingStats = false;
        });
      }
    } catch (e) {
      print('❌ Error loading detection stats: $e');
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }
  
  Future<void> _loadReminders() async {
    try {
      await _remindersService.getUpcomingReminders(days: 7);
      final notificationCount = await _remindersService.getPendingNotificationsCount();
      
      // Load reminders for the selected month (for calendar)
      await _loadMonthReminders();
      
      if (mounted) {
        setState(() {
          _pendingNotificationsCount = notificationCount;
          _loadingReminders = false;
        });
      }
    } catch (e) {
      print('❌ Error loading reminders: $e');
      if (mounted) {
        setState(() {
          _loadingReminders = false;
        });
      }
    }
  }
  
  Future<void> _loadMonthReminders() async {
    try {
      final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      // Get all reminders for the month
      final allReminders = await _remindersService.getAllReminders(includeCompleted: false);
      
      // Group reminders by date
      final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
      
      for (final reminder in allReminders) {
        final scheduledDate = DateTime.parse(reminder['scheduled_date']);
        final dateOnly = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
        
        // Only include reminders in the current month
        if (dateOnly.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
          if (!grouped.containsKey(dateOnly)) {
            grouped[dateOnly] = [];
          }
          grouped[dateOnly]!.add(reminder);
        }
      }
      
      if (mounted) {
        setState(() {
          _monthReminders = grouped;
        });
      }
    } catch (e) {
      print('❌ Error loading month reminders: $e');
    }
  }
  
  Future<void> _loadWeatherData() async {
    try {
      final position = await _weatherService.getCurrentLocation();
      if (position != null) {
        // Fetch weather data and location name in parallel
        final results = await Future.wait([
          _weatherService.getWeatherData(
            position.latitude,
            position.longitude,
          ),
          _weatherService.getLocationName(
            position.latitude,
            position.longitude,
          ),
        ]);
        
        final weatherData = results[0] as Map<String, dynamic>?;
        final locationName = results[1] as String;
        
        if (mounted) {
          setState(() {
            _weatherData = weatherData;
            _locationName = locationName;
            _loadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationName = AppLocale.locationUnavailable.getString(context);
            _loadingWeather = false;
          });
        }
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _locationName = AppLocale.weatherUnavailable1.getString(context);
          _loadingWeather = false;
        });
      }
    }
  }
  
  String _getWeatherCondition() {
    if (_weatherData == null) return AppLocale.perfectWeatherToday.getString(context);
    
    final current = _weatherData!['current'];
    final temp = current['temperature_2m']?.toDouble() ?? 0.0;
    final humidity = current['relative_humidity_2m']?.toInt() ?? 0;
    final weatherCode = current['weather_code'] ?? 0;
    
    // Weather codes from Open-Meteo API
    if (weatherCode == 0) {
      if (temp >= 25 && temp <= 32 && humidity >= 40 && humidity <= 70) {
        return AppLocale.perfectWeatherToday.getString(context);
      } else if (temp > 32) {
        return AppLocale.hotSunnyIrrigation.getString(context);
      } else {
        return AppLocale.clearSkiesFieldWork.getString(context);
      }
    } else if (weatherCode <= 3) {
      return AppLocale.partlyCloudyGood.getString(context);
    } else if (weatherCode <= 67) {
      return AppLocale.rainyMonitorFields.getString(context);
    } else if (weatherCode >= 71) {
      return AppLocale.poorWeatherPostpone.getString(context);
    }
    
    return AppLocale.checkConditions.getString(context);
  }
  
  String _getWeatherDetails() {
    if (_weatherData == null) return AppLocale.loadingWeather.getString(context);
    
    final current = _weatherData!['current'];
    final temp = current['temperature_2m']?.toDouble() ?? 0.0;
    final humidity = current['relative_humidity_2m']?.toInt() ?? 0;
    final windSpeed = current['wind_speed_10m']?.toDouble() ?? 0.0;
    
    String humidityLevel;
    if (humidity < 40) {
      humidityLevel = AppLocale.lowHumidity.getString(context);
    } else if (humidity <= 70) {
      humidityLevel = AppLocale.moderateHumidity.getString(context);
    } else {
      humidityLevel = AppLocale.highHumidity.getString(context);
    }
    
    String windCondition;
    if (windSpeed < 10) {
      windCondition = AppLocale.calmWinds.getString(context);
    } else if (windSpeed < 20) {
      windCondition = AppLocale.lightBreeze.getString(context);
    } else {
      windCondition = AppLocale.windy.getString(context);
    }
    
    return '${temp.toStringAsFixed(1)}°C • $humidityLevel • $windCondition';
  }
  
  IconData _getWeatherIcon() {
    if (_weatherData == null) return Icons.wb_sunny;
    
    final weatherCode = _weatherData!['current']['weather_code'] ?? 0;
    
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode <= 3) return Icons.wb_cloudy;
    if (weatherCode <= 67) return Icons.umbrella;
    if (weatherCode >= 71) return Icons.ac_unit;
    
    return Icons.wb_sunny;
  }
  
  Color _getWeatherBackgroundColor() {
    if (_weatherData == null) return const Color(0xFFFFF8E1); // Light yellow for perfect weather
    
    final weatherCode = _weatherData!['current']['weather_code'] ?? 0;
    final temp = _weatherData!['current']['temperature_2m']?.toDouble() ?? 0.0;
    
    // Clear/Sunny
    if (weatherCode == 0) {
      if (temp > 32) {
        return const Color(0xFFFFE0B2); // Light orange for hot
      }
      return const Color(0xFFFFF8E1); // Light yellow for perfect
    }
    // Partly cloudy
    else if (weatherCode <= 3) {
      return const Color(0xFFE3F2FD); // Light blue for cloudy
    }
    // Rainy
    else if (weatherCode <= 67) {
      return const Color(0xFFB3E5FC); // Blue for rain
    }
    // Snow/Poor weather
    else if (weatherCode >= 71) {
      return const Color(0xFFCFD8DC); // Gray for poor weather
    }
    
    return const Color(0xFFF5F5F5); // Light gray default
  }
  
  Color _getWeatherIconColor() {
    if (_weatherData == null) return const Color(0xFFFFA726); // Orange for sunny
    
    final weatherCode = _weatherData!['current']['weather_code'] ?? 0;
    final temp = _weatherData!['current']['temperature_2m']?.toDouble() ?? 0.0;
    
    // Clear/Sunny
    if (weatherCode == 0) {
      if (temp > 32) {
        return const Color(0xFFFF6F00); // Dark orange for hot
      }
      return const Color(0xFFFFA726); // Orange for sunny
    }
    // Partly cloudy
    else if (weatherCode <= 3) {
      return const Color(0xFF42A5F5); // Blue for cloudy
    }
    // Rainy
    else if (weatherCode <= 67) {
      return const Color(0xFF1976D2); // Dark blue for rain
    }
    // Snow/Poor weather
    else if (weatherCode >= 71) {
      return const Color(0xFF607D8B); // Blue gray for poor weather
    }
    
    return const Color(0xFF757575); // Gray default
  }
  
  Color _getWeatherTextColor() {
    if (_weatherData == null) return const Color(0xFFF57C00); // Orange text for sunny
    
    final weatherCode = _weatherData!['current']['weather_code'] ?? 0;
    final temp = _weatherData!['current']['temperature_2m']?.toDouble() ?? 0.0;
    
    // Clear/Sunny
    if (weatherCode == 0) {
      if (temp > 32) {
        return const Color(0xFFE65100); // Deep orange for hot
      }
      return const Color(0xFFF57C00); // Orange for sunny
    }
    // Partly cloudy
    else if (weatherCode <= 3) {
      return const Color(0xFF1976D2); // Blue for cloudy
    }
    // Rainy
    else if (weatherCode <= 67) {
      return const Color(0xFF0D47A1); // Deep blue for rain
    }
    // Snow/Poor weather
    else if (weatherCode >= 71) {
      return const Color(0xFF455A64); // Dark gray for poor weather
    }
    
    return const Color(0xFF424242); // Dark gray default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildPaddyMonitoringCard(),
                    const SizedBox(height: 24),
                    _buildFarmingCalendar(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildFarmingStats(),
                    const SizedBox(height: 24),
                    _buildFeaturedContent(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.chat, color: Colors.white),
        label: Text(
          AppLocale.farmingTips.getString(context),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Compute collapse percentage: 1 when expanded, 0 when collapsed
                  const double expandedHeight = 120.0;
                  final double currentHeight = constraints.maxHeight;
                  final double collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
                  final double percent = ((currentHeight - collapsedHeight) /
                          (expandedHeight - collapsedHeight))
                      .clamp(0.0, 1.0);

                  // As user scrolls down (collapsing), move logo group toward center
                  final double alignX = -1.0 + (1.0 - percent); // -1 (left) -> 0 (center)

                  return Row(
                    children: [
                      Expanded(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: Alignment(alignX, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/Logo1.png',
                                height: 40,
                                width: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading Logo1.png: $error');
                                  return Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'P',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                appName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              _showNotificationsSheet();
                            },
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                          if (_pendingNotificationsCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _pendingNotificationsCount > 9 ? '9+' : '$_pendingNotificationsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: interactiveCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppLocale.welcome.getString(context)}👋',
            style: headingStyle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocale.readyToTakeCare.getString(context),
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _buildWeatherWidget(),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _loadingWeather ? primaryColor.withOpacity(0.1) : _getWeatherBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _loadingWeather ? primaryColor.withOpacity(0.2) : _getWeatherIconColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: _loadingWeather
          ? Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocale.loadingWeather.getString(context),
                    style: captionStyle.copyWith(color: textDarkColor),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getWeatherIconColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getWeatherIcon(), 
                    color: _getWeatherIconColor(), 
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWeatherCondition(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getWeatherTextColor(),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getWeatherDetails(),
                        style: captionStyle.copyWith(
                          color: _getWeatherTextColor().withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: _getWeatherTextColor().withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationName,
                              style: captionStyle.copyWith(
                                color: _getWeatherTextColor().withOpacity(0.6),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.quickActions.getString(context),
          style: subHeadingStyle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                AppLocale.detectDisease.getString(context),
                AppLocale.scanCrops.getString(context),
                Icons.camera_alt,
                accentGradient,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetectScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                AppLocale.marketplace.getString(context),
                AppLocale.findSupplies.getString(context),
                Icons.shopping_bag,
                LinearGradient(
                  colors: [Colors.orange.shade300, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                AppLocale.detectionHistory.getString(context),
                AppLocale.viewScans.getString(context),
                Icons.history,
                LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetectHistoryScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                AppLocale.weatherAlert.getString(context),
                AppLocale.checkForecast.getString(context),
                Icons.cloud,
                LinearGradient(
                  colors: [Colors.purple.shade300, Colors.purple.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WeatherAlertScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmingStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocale.detectionOverview.getString(context),
                style: subHeadingStyle,
              ),
              if (_loadingStats)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  AppLocale.totalScans.getString(context),
                  _loadingStats ? '...' : '${_farmingStats['total_detections'] ?? 0}',
                  Icons.image_search,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  AppLocale.healthy.getString(context),
                  _loadingStats ? '...' : '${_farmingStats['healthy_count'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  AppLocale.diseases.getString(context),
                  _loadingStats ? '...' : '${_farmingStats['disease_count'] ?? 0}',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: captionStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.featuredForYou.getString(context),
          style: subHeadingStyle,
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          decoration: cardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.8), accentColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocale.riceFarmingTips.getString(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocale.riceFarmingDesc.getString(context),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/chat');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                        ),
                        child: Text(AppLocale.getFarmingTips.getString(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final totalDetections = _farmingStats['total_detections'] ?? 0;
    final diseaseCount = _farmingStats['disease_count'] ?? 0;
    final healthyCount = _farmingStats['healthy_count'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocale.recentActivity.getString(context),
              style: subHeadingStyle,
            ),
            if (totalDetections > 0)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/detect-history');
                },
                child: Text(
                  AppLocale.viewAll.getString(context),
                  style: const TextStyle(color: primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: cardDecoration,
          child: totalDetections == 0
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: textLightColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocale.noActivity.getString(context),
                        style: bodyStyle.copyWith(color: textLightColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocale.startScanningCrops.getString(context),
                        style: captionStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (totalDetections > 0)
                      _buildActivityItem(
                        AppLocale.totalScansCompleted.getString(context),
                        '$totalDetections ${totalDetections > 1 ? AppLocale.scansPerformed.getString(context) : AppLocale.scansPerformed.getString(context)}',
                        Icons.camera_alt,
                        Colors.blue,
                        AppLocale.allTime.getString(context),
                      ),
                    if (totalDetections > 0 && (healthyCount > 0 || diseaseCount > 0))
                      const Divider(),
                    if (healthyCount > 0)
                      _buildActivityItem(
                        AppLocale.healthyCropsDetected.getString(context),
                        '$healthyCount ${healthyCount > 1 ? AppLocale.healthyScansRecorded.getString(context) : AppLocale.healthyScansRecorded.getString(context)}',
                        Icons.check_circle,
                        Colors.green,
                        AppLocale.recent.getString(context),
                      ),
                    if (healthyCount > 0 && diseaseCount > 0)
                      const Divider(),
                    if (diseaseCount > 0)
                      _buildActivityItem(
                        AppLocale.diseasesFoundTitle.getString(context),
                        '$diseaseCount ${diseaseCount > 1 ? AppLocale.diseasesDetectedCheck.getString(context) : AppLocale.diseasesDetectedCheck.getString(context)}',
                        Icons.warning,
                        Colors.orange,
                        AppLocale.actionNeeded.getString(context),
                      ),
                    if (_weatherData != null)
                      const Divider(),
                    if (_weatherData != null)
                      _buildActivityItem(
                        AppLocale.weatherUpdate.getString(context),
                        'Temperature: ${_weatherData!['temperature']?.round() ?? '--'}°C, Humidity: ${_weatherData!['humidity']?.round() ?? '--'}%',
                        Icons.cloud,
                        Colors.blue,
                        AppLocale.today.getString(context),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textDarkColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: captionStyle,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: captionStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaddyMonitoringCard() {
    return ScaleTransition(
      scale: _paddyCardAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocale.paddyGrowthMonitor.getString(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Variety Selection
            Text(
              AppLocale.selectPaddyVariety.getString(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildVarietySelector(),
            
            if (selectedVariety != null) ...[
              const SizedBox(height: 20),
              _buildPlantingDateSelector(),
            ],
            
            if (selectedVariety != null && plantingDate != null) ...[
              const SizedBox(height: 20),
              _buildProgressTracker(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVarietySelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: paddyVarieties.keys.length,
        itemBuilder: (context, index) {
          final variety = paddyVarieties.keys.elementAt(index);
          final isSelected = selectedVariety == variety;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectPaddyVariety(variety),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(isSelected ? 1 : 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grass,
                        color: isSelected 
                            ? const Color(0xFF2E7D32) 
                            : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        variety,
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF2E7D32) 
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantingDateSelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectPlantingDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.plantingDate1.getString(context),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plantingDate != null
                          ? '${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}'
                          : AppLocale.tapToSelectDate1.getString(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTracker() {
    _calculateDaysElapsed();
    final progress = daysElapsed! / estimatedHarvestDaysMax!;
    final progressClamped = progress.clamp(0.0, 1.0);
    final daysRemaining = estimatedHarvestDaysMax! - daysElapsed!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocale.daysElapsed.getString(context),
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$daysElapsed ${AppLocale.days.getString(context)}',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocale.daysRemaining.getString(context),
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysRemaining > 0 
                        ? '$daysRemaining ${AppLocale.days.getString(context)}' 
                        : AppLocale.ready.getString(context),
                    style: TextStyle(
                      color: daysRemaining > 0 
                          ? const Color(0xFFFF6F00) 
                          : const Color(0xFF2E7D32),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 20,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                tween: Tween<double>(
                  begin: 0,
                  end: progressClamped,
                ),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value < 0.5 
                        ? const Color(0xFF66BB6A)
                        : value < 0.8
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLocale.harvest.getString(context)} $estimatedHarvestDaysMin-$estimatedHarvestDaysMax ${AppLocale.days.getString(context)}',
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progressClamped * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (daysRemaining <= 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocale.paddyReadyForHarvest.getString(context),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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

  Widget _buildFarmingCalendar() {
    return ScaleTransition(
      scale: _paddyCardAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocale.farmingCalendar.getString(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showCalendarGuide,
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: AppLocale.calendarGuide.getString(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                  _loadReminders();
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                  _loadReminders();
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Calendar grid
          if (_loadingReminders)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            _buildCalendarGrid(),
          
          const SizedBox(height: 16),
          
          // Add Reminder Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddReminderDialog(),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: Text(
                AppLocale.addReminder.getString(context),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
      AppLocale.january.getString(context),
      AppLocale.february.getString(context),
      AppLocale.march.getString(context),
      AppLocale.april.getString(context),
      AppLocale.may.getString(context),
      AppLocale.june.getString(context),
      AppLocale.july.getString(context),
      AppLocale.august.getString(context),
      AppLocale.september.getString(context),
      AppLocale.october.getString(context),
      AppLocale.november.getString(context),
      AppLocale.december.getString(context),
    ];
    return months[month - 1];
  }

  Color _getReminderTypeColor(String type) {
    switch (type) {
      case 'fertilization':
        return const Color(0xFF4CAF50); // Green
      case 'irrigation':
        return const Color(0xFF2196F3); // Blue
      case 'pest_control':
        return const Color(0xFFFF5722); // Deep Orange
      case 'planting':
        return const Color(0xFF8BC34A); // Light Green
      case 'harvest':
        return const Color(0xFFFFC107); // Amber
      case 'field_inspection':
        return const Color(0xFF9C27B0); // Purple
      case 'weather_alert':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  Color _getDominantReminderColor(List<Map<String, dynamic>> reminders) {
    if (reminders.isEmpty) return Colors.amber;
    
    // Priority order for colors
    final typeOrder = [
      'weather_alert',
      'pest_control',
      'harvest',
      'planting',
      'fertilization',
      'irrigation',
      'field_inspection',
      'custom',
    ];
    
    for (final type in typeOrder) {
      if (reminders.any((r) => r['reminder_type'] == type)) {
        return _getReminderTypeColor(type);
      }
    }
    
    return _getReminderTypeColor(reminders.first['reminder_type'] ?? 'custom');
  }

  String? _getDominantReminderType(List<Map<String, dynamic>> reminders) {
    if (reminders.isEmpty) return null;
    
    // Priority order for types
    final typeOrder = [
      'weather_alert',
      'pest_control',
      'harvest',
      'planting',
      'fertilization',
      'irrigation',
      'field_inspection',
      'custom',
    ];
    
    for (final type in typeOrder) {
      if (reminders.any((r) => r['reminder_type'] == type)) {
        return type;
      }
    }
    
    return reminders.first['reminder_type'] ?? 'custom';
  }

  void _showCalendarGuide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocale.calendarGuide.getString(context),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Legend title
              Text(
                AppLocale.calendarSymbols.getString(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Fertilization
              _buildLegendItem(
                Icons.spa,
                const Color(0xFF4CAF50),
                AppLocale.fertilizationLabel.getString(context),
                AppLocale.fertilizationDesc.getString(context),
              ),
              const SizedBox(height: 12),
              
              // Pest Control
              _buildLegendItem(
                Icons.bug_report,
                const Color(0xFFFF5722),
                AppLocale.pestControlLabel.getString(context),
                AppLocale.pestControlDesc.getString(context),
              ),
              const SizedBox(height: 12),
              
              // Planting
              _buildLegendItem(
                Icons.agriculture,
                const Color(0xFF8BC34A),
                AppLocale.plantingDateLabel.getString(context),
                AppLocale.plantingDateDesc.getString(context),
              ),
              const SizedBox(height: 12),
              
              // Harvest
              _buildLegendItem(
                Icons.grass,
                const Color(0xFFFFC107),
                AppLocale.harvestDateLabel.getString(context),
                AppLocale.harvestDateDesc.getString(context),
              ),
              const SizedBox(height: 20),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocale.calendarTip.getString(context),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocale.calendarTipMessage.getString(context),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocale.gotIt.getString(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;
    
    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        
        // Calendar days
        ...List.generate((daysInMonth + firstWeekday) ~/ 7 + 1, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                final hasReminders = _monthReminders.containsKey(date) && 
                                   _monthReminders[date]!.isNotEmpty;
                final isToday = DateTime.now().year == date.year &&
                              DateTime.now().month == date.month &&
                              DateTime.now().day == date.day;
                final isSelected = _selectedDate?.year == date.year &&
                                 _selectedDate?.month == date.month &&
                                 _selectedDate?.day == date.day;
                
                // Check if this date is planting date
                final isPlantingDate = plantingDate != null &&
                                      date.year == plantingDate!.year &&
                                      date.month == plantingDate!.month &&
                                      date.day == plantingDate!.day;
                
                // Check if this date is estimated harvest date
                final isHarvestDate = plantingDate != null && 
                                     estimatedHarvestDaysMax != null &&
                                     date.year == plantingDate!.add(Duration(days: estimatedHarvestDaysMax!)).year &&
                                     date.month == plantingDate!.add(Duration(days: estimatedHarvestDaysMax!)).month &&
                                     date.day == plantingDate!.add(Duration(days: estimatedHarvestDaysMax!)).day;
                
                // Get dominant reminder color and type if has reminders
                final reminderColor = hasReminders 
                    ? _getDominantReminderColor(_monthReminders[date]!)
                    : Colors.amber;
                final dominantType = hasReminders
                    ? _getDominantReminderType(_monthReminders[date]!)
                    : null;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      if (hasReminders) {
                        _showDayReminders(date);
                      } else {
                        _showAddReminderDialog(preselectedDate: date);
                      }
                    },
                    child: Container(
                      height: 38,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : hasReminders
                                ? reminderColor.withOpacity(0.85)
                                : isPlantingDate
                                    ? const Color(0xFF8BC34A).withOpacity(0.75)
                                    : isHarvestDate
                                        ? const Color(0xFFFFC107).withOpacity(0.75)
                                        : isToday
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: (hasReminders || isPlantingDate || isHarvestDate) && !isSelected
                            ? Border.all(
                                color: hasReminders
                                    ? reminderColor
                                    : isPlantingDate
                                        ? const Color(0xFF8BC34A)
                                        : const Color(0xFFFFC107),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : Colors.white,
                                fontWeight: isToday || hasReminders || isPlantingDate || isHarvestDate
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (hasReminders)
                            Positioned(
                              top: 1,
                              right: 1,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isSelected ? reminderColor : Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 2,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  dominantType == 'fertilization'
                                      ? Icons.spa
                                      : dominantType == 'pest_control'
                                          ? Icons.bug_report
                                          : Icons.event_note,
                                  size: 10,
                                  color: isSelected ? Colors.white : reminderColor,
                                ),
                              ),
                            ),
                          if (isPlantingDate)
                            Positioned(
                              bottom: 2,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Icon(
                                  Icons.agriculture,
                                  size: 8,
                                  color: isSelected ? const Color(0xFF8BC34A) : Colors.white,
                                ),
                              ),
                            ),
                          if (isHarvestDate)
                            Positioned(
                              bottom: 2,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Icon(
                                  Icons.grass,
                                  size: 8,
                                  color: isSelected ? const Color(0xFFFFC107) : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  void _showDayReminders(DateTime date) {
    final reminders = _monthReminders[date] ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddReminderDialog(preselectedDate: date);
                  },
                  icon: const Icon(Icons.add_circle, color: Color(0xFF1565C0)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reminders.map((reminder) => _buildReminderCard(reminder)),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, {bool isToday = false, bool enableSwipeToDelete = false}) {
    final scheduledDate = DateTime.parse(reminder['scheduled_date']);
    final isOverdue = scheduledDate.isBefore(DateTime.now()) && !(reminder['is_completed'] ?? false);
    final priority = reminder['priority'] ?? 'medium';
    final reminderType = reminder['reminder_type'] ?? 'custom';
    
    // Icon mapping
    IconData getIcon() {
      switch (reminderType) {
        case 'fertilization':
          return Icons.spa;
        case 'irrigation':
          return Icons.water_drop;
        case 'pest_control':
          return Icons.bug_report;
        case 'planting':
          return Icons.agriculture;
        case 'harvest':
          return Icons.grass;
        case 'field_inspection':
          return Icons.find_in_page;
        case 'weather_alert':
          return Icons.cloud;
        default:
          return Icons.event_note;
      }
    }
    
    // Priority color
    Color getPriorityColor() {
      switch (priority) {
        case 'urgent':
          return Colors.red;
        case 'high':
          return Colors.orange;
        case 'medium':
          return Colors.blue;
        case 'low':
          return Colors.grey;
        default:
          return Colors.blue;
      }
    }
    
    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF2E7D32).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue 
              ? Colors.red.shade200 
              : isToday 
                  ? const Color(0xFF2E7D32).withOpacity(0.3)
                  : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getPriorityColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIcon(),
                color: getPriorityColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocale.dueToday.getString(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocale.overdue.getString(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (reminder['description'] != null && reminder['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        reminder['description'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!(reminder['is_completed'] ?? false))
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: const Color(0xFF2E7D32),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  await _remindersService.markAsCompleted(reminder['id']);
                  await _loadReminders();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocale.taskCompleted.getString(context)),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
    
    // Wrap with Dismissible if swipe to delete is enabled
    if (enableSwipeToDelete) {
      return Dismissible(
        key: Key('reminder_${reminder['id']}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(AppLocale.confirmDelete.getString(context)),
              content: Text(AppLocale.deleteReminderMessage.getString(context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocale.cancel.getString(context)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocale.delete.getString(context)),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) async {
          await _remindersService.deleteReminder(reminder['id']);
          await _loadReminders();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocale.reminderDeleted.getString(context)),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: AppLocale.undo.getString(context),
                  textColor: Colors.white,
                  onPressed: () {
                    // Note: Undo would require storing the deleted reminder data
                    // For now, just show that it was deleted
                  },
                ),
              ),
            );
          }
        },
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocale.notifications.getString(context),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    if (_pendingNotificationsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_pendingNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _remindersService.getAllReminders(
                    includeCompleted: false,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocale.noNotifications.getString(context),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final allReminders = snapshot.data!;
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    
                    // Group reminders
                    final overdue = allReminders.where((r) {
                      final date = DateTime.parse(r['scheduled_date']);
                      return date.isBefore(today);
                    }).toList();
                    
                    final todayReminders = allReminders.where((r) {
                      final date = DateTime.parse(r['scheduled_date']);
                      return date.year == today.year &&
                             date.month == today.month &&
                             date.day == today.day;
                    }).toList();
                    
                    final upcoming = allReminders.where((r) {
                      final date = DateTime.parse(r['scheduled_date']);
                      return date.isAfter(today);
                    }).toList();
                    
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (overdue.isNotEmpty) ...[
                          _buildNotificationSection(
                            AppLocale.overdue.getString(context),
                            overdue,
                            Colors.red,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (todayReminders.isNotEmpty) ...[
                          _buildNotificationSection(
                            AppLocale.todayTasks.getString(context),
                            todayReminders,
                            const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (upcoming.isNotEmpty) ...[
                          _buildNotificationSection(
                            AppLocale.thisWeekTasks.getString(context),
                            upcoming,
                            Colors.blue,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(
    String title,
    List<Map<String, dynamic>> reminders,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${reminders.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...reminders.map((reminder) => _buildReminderCard(reminder, enableSwipeToDelete: true)),
      ],
    );
  }

  void _showAddReminderDialog({DateTime? preselectedDate}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = preselectedDate ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'custom';
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_task,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocale.addReminder.getString(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Form container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: AppLocale.reminderTitle.getString(context),
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.title, color: Color(0xFF1565C0)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Description field
                          TextField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: AppLocale.reminderDescription.getString(context),
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.description, color: Color(0xFF1565C0)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Date picker
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF1565C0),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() => selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocale.reminderDate.getString(context),
                                          style: const TextStyle(
                                            color: Color(0xFF1565C0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Time picker
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF1565C0),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() => selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocale.reminderTime.getString(context),
                                          style: const TextStyle(
                                            color: Color(0xFF1565C0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedTime.format(context),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Reminder type
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: AppLocale.reminderType.getString(context),
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.category, color: Color(0xFF1565C0)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: [
                              DropdownMenuItem(value: 'fertilization', child: Text(AppLocale.fertilization.getString(context))),
                              DropdownMenuItem(value: 'irrigation', child: Text(AppLocale.irrigation.getString(context))),
                              DropdownMenuItem(value: 'pest_control', child: Text(AppLocale.pestControl.getString(context))),
                              DropdownMenuItem(value: 'planting', child: Text(AppLocale.planting.getString(context))),
                              DropdownMenuItem(value: 'harvest', child: Text(AppLocale.harvest.getString(context))),
                              DropdownMenuItem(value: 'field_inspection', child: Text(AppLocale.fieldInspection.getString(context))),
                              DropdownMenuItem(value: 'weather_alert', child: Text(AppLocale.weatherAlert.getString(context))),
                              DropdownMenuItem(value: 'custom', child: Text(AppLocale.custom.getString(context))),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Priority
                          DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: InputDecoration(
                              labelText: AppLocale.reminderPriority.getString(context),
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.flag, color: Color(0xFF1565C0)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: [
                              DropdownMenuItem(value: 'low', child: Text(AppLocale.low.getString(context))),
                              DropdownMenuItem(value: 'medium', child: Text(AppLocale.medium.getString(context))),
                              DropdownMenuItem(value: 'high', child: Text(AppLocale.high.getString(context))),
                              DropdownMenuItem(value: 'urgent', child: Text(AppLocale.urgent.getString(context))),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedPriority = value);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Color(0xFF1565C0), width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocale.cancel.getString(context),
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (titleController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AppLocale.pleaseEnterTitle.getString(context))),
                                      );
                                      return;
                                    }

                                    final scheduledDateTime = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );

                                    final reminderData = {
                                      'title': titleController.text,
                                      'description': descriptionController.text,
                                      'reminder_type': selectedType,
                                      'scheduled_date': scheduledDateTime.toIso8601String(),
                                      'priority': selectedPriority,
                                      'is_completed': false,
                                      'notification_sent': false,
                                    };

                                    final result = await _remindersService.createReminder(reminderData);

                                    if (mounted) {
                                      Navigator.pop(context);
                                      
                                      if (result['success']) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocale.reminderCreatedSuccess.getString(context)),
                                            backgroundColor: const Color(0xFF1565C0),
                                          ),
                                        );
                                        await _loadReminders();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message']),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    AppLocale.create.getString(context),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



