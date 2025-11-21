import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../l10n/app_locale.dart';
import '../config/supabase_config.dart';
import '../utils/constants.dart';
import '../services/weather_service.dart';
import '../services/paddy_monitoring_service.dart';
import '../services/disease_records_service.dart';
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
  Map<String, dynamic>? _weatherData;
  String _locationName = 'Loading...';
  bool _loadingWeather = true;
  
  // Farming stats
  Map<String, dynamic> _farmingStats = {};
  bool _loadingStats = true;
  
  // Paddy variety tracking
  String? selectedVariety;
  DateTime? plantingDate;
  int? daysElapsed;
  int? estimatedHarvestDaysMin;
  int? estimatedHarvestDaysMax;
  
  // Paddy varieties with their harvest days
  final Map<String, Map<String, int>> paddyVarieties = {
    'MR 297': {'min': 110, 'max': 120},
    'MR 220': {'min': 104, 'max': 109},
    'MR 219': {'min': 105, 'max': 111},
    'MR 263': {'min': 97, 'max': 104},
    'MR 315': {'min': 110, 'max': 120},
  };
  
  String get userName {
    final user = SupabaseConfig.client.auth.currentUser;
    return user?.userMetadata?['full_name']?.split(' ')?.first ?? 'Farmer';
  }

  String get welcomeMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWeatherData();
    _loadSavedPaddyMonitoring();
    _loadFarmingStats();
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
  
  Future<void> _loadWeatherData() async {
    try {
      final position = await _weatherService.getCurrentLocation();
      if (position != null) {
        final weatherData = await _weatherService.getWeatherData(
          position.latitude,
          position.longitude,
        );
        final locationName = await _weatherService.getLocationName(
          position.latitude,
          position.longitude,
        );
        
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
            _locationName = 'Location unavailable';
            _loadingWeather = false;
          });
        }
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _locationName = 'Weather unavailable';
          _loadingWeather = false;
        });
      }
    }
  }
  
  String _getWeatherCondition() {
    if (_weatherData == null) return 'Perfect farming weather today';
    
    final current = _weatherData!['current'];
    final temp = current['temperature_2m']?.toDouble() ?? 0.0;
    final humidity = current['relative_humidity_2m']?.toInt() ?? 0;
    final weatherCode = current['weather_code'] ?? 0;
    
    // Weather codes from Open-Meteo API
    if (weatherCode == 0) {
      if (temp >= 25 && temp <= 32 && humidity >= 40 && humidity <= 70) {
        return 'Perfect farming weather today';
      } else if (temp > 32) {
        return 'Hot and sunny - ensure irrigation';
      } else {
        return 'Clear skies - great for field work';
      }
    } else if (weatherCode <= 3) {
      return 'Partly cloudy - good conditions';
    } else if (weatherCode <= 67) {
      return 'Rainy conditions - monitor fields';
    } else if (weatherCode >= 71) {
      return 'Poor weather - postpone field work';
    }
    
    return 'Check conditions before field work';
  }
  
  String _getWeatherDetails() {
    if (_weatherData == null) return 'Loading weather data...';
    
    final current = _weatherData!['current'];
    final temp = current['temperature_2m']?.toDouble() ?? 0.0;
    final humidity = current['relative_humidity_2m']?.toInt() ?? 0;
    final windSpeed = current['wind_speed_10m']?.toDouble() ?? 0.0;
    
    String humidityLevel;
    if (humidity < 40) {
      humidityLevel = 'Low humidity';
    } else if (humidity <= 70) {
      humidityLevel = 'Moderate humidity';
    } else {
      humidityLevel = 'High humidity';
    }
    
    String windCondition;
    if (windSpeed < 10) {
      windCondition = 'Calm winds';
    } else if (windSpeed < 20) {
      windCondition = 'Light breeze';
    } else {
      windCondition = 'Windy';
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
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'Farming Tips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              child: Row(
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
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Show notifications
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
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
            '${AppLocale.welcome.getString(context)}, $userName! 👋',
            style: headingStyle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to take care of your crops today?',
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
                    'Loading weather data...',
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
                'Scan your crops',
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
                'Find supplies',
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
                'Detect History',
                'View scan records',
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
                'Weather Alert',
                'Check forecast',
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
                'Detection Overview',
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
                  'Total Scans',
                  _loadingStats ? '...' : '${_farmingStats['total_detections'] ?? 0}',
                  Icons.image_search,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Healthy',
                  _loadingStats ? '...' : '${_farmingStats['healthy_count'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Diseases',
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
          'Featured for You',
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
                      const Text(
                        '🌾 Rice Farming Tips',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Learn the best practices for healthy rice cultivation and disease prevention.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to tips
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                        ),
                        child: const Text('Read More'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.recentActivity.getString(context),
          style: subHeadingStyle,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: cardDecoration,
          child: Column(
            children: [
              _buildActivityItem(
                'Disease detected in Field A',
                'Brown Spot found - Treatment recommended',
                Icons.warning,
                Colors.orange,
                '2 hours ago',
              ),
              const Divider(),
              _buildActivityItem(
                'New product available',
                'Organic Fungicide now in marketplace',
                Icons.shopping_cart,
                Colors.green,
                '1 day ago',
              ),
              const Divider(),
              _buildActivityItem(
                'Weather alert',
                'Heavy rain expected tomorrow',
                Icons.cloud,
                Colors.blue,
                '2 days ago',
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
                const Expanded(
                  child: Text(
                    'Paddy Growth Monitor',
                    style: TextStyle(
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
              'Select Your Paddy Variety',
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
    return Container(
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
                      'Planting Date',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plantingDate != null
                          ? '${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}'
                          : 'Tap to select date',
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
                    'Days Elapsed',
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$daysElapsed days',
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
                    'Days Remaining',
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysRemaining > 0 ? '$daysRemaining days' : 'Ready!',
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
                'Harvest ${estimatedHarvestDaysMin}-${estimatedHarvestDaysMax} days',
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
              child: const Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your paddy is ready for harvest! 🌾',
                      style: TextStyle(
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
}



