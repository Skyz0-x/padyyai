import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';

class WeatherAlertScreen extends StatefulWidget {
  const WeatherAlertScreen({super.key});

  @override
  State<WeatherAlertScreen> createState() => _WeatherAlertScreenState();
}

class _WeatherAlertScreenState extends State<WeatherAlertScreen> {
  final WeatherService _weatherService = WeatherService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _alerts = [];
  String? _errorMessage;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      final position = await _weatherService.getCurrentLocation();
      
      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to get location. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      // Get weather data
      final weatherData = await _weatherService.getWeatherData(
        position.latitude,
        position.longitude,
      );

      if (weatherData == null) {
        setState(() {
          _errorMessage = 'Unable to fetch weather data. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Get location name
      final locationName = await _weatherService.getLocationName(
        position.latitude,
        position.longitude,
      );

      // Get alerts
      final alerts = _weatherService.getWeatherAlerts(weatherData);

      setState(() {
        _weatherData = weatherData;
        _alerts = alerts;
        _locationName = locationName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading weather data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weather Alerts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_locationName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Monitor conditions for your crops',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadWeatherData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (_weatherData != null) ...[
            const SizedBox(height: 16),
            _buildCurrentWeather(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_weatherData == null) return const SizedBox();
    
    final current = _weatherData!['current'];
    final weatherCode = current['weather_code'] ?? 0;
    final temp = current['temperature_2m']?.toStringAsFixed(1) ?? '--';
    final humidity = current['relative_humidity_2m']?.toString() ?? '--';
    final windSpeed = current['wind_speed_10m']?.toStringAsFixed(1) ?? '--';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    _weatherService.getWeatherIcon(weatherCode),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _weatherService.getWeatherDescription(weatherCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$temp°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$humidity%',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.air, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$windSpeed km/h',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching weather data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadWeatherData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Open Location Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWeatherData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_alerts.isEmpty)
              _buildNoAlerts()
            else
              _buildAlertsList(),
            const SizedBox(height: 24),
            if (_weatherData != null) _buildForecast(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlerts() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Weather Alerts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weather conditions are favorable for your crops',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _alerts.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAlertCard(_alerts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    Color alertColor;
    switch (alert['color']) {
      case 'red':
        alertColor = Colors.red;
        break;
      case 'orange':
        alertColor = Colors.orange;
        break;
      case 'blue':
        alertColor = Colors.blue;
        break;
      case 'purple':
        alertColor = Colors.purple;
        break;
      case 'brown':
        alertColor = Colors.brown;
        break;
      default:
        alertColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert['icon'],
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast() {
    if (_weatherData == null) return const SizedBox();
    
    final daily = _weatherData!['daily'];
    if (daily == null) return const SizedBox();

    final dates = daily['time'] as List;
    final weatherCodes = daily['weather_code'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final precipitation = daily['precipitation_sum'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-Day Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          dates.length > 7 ? 7 : dates.length,
          (index) {
            final date = DateTime.parse(dates[index]);
            final dayName = index == 0
                ? 'Today'
                : index == 1
                    ? 'Tomorrow'
                    : _getDayName(date.weekday);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    _weatherService.getWeatherIcon(weatherCodes[index]),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thermostat, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              '${maxTemps[index].toStringAsFixed(0)}°',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.thermostat, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('${minTemps[index].toStringAsFixed(0)}°'),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('${precipitation[index].toStringAsFixed(0)}mm'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}
