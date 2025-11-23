import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_animation/weather_animation.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';
import '../l10n/app_locale.dart';

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
      body: Stack(
        children: [
          // Weather animation background
          if (_weatherData != null)
            Positioned.fill(
              child: _buildWeatherAnimation(),
            ),
          // Content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.7),
                  backgroundColor.withOpacity(0.7),
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
        ],
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
                    Text(
                      AppLocale.weatherAlerts.getString(context),
                      style: const TextStyle(
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
                      Text(
                        AppLocale.monitorConditionsForCrops.getString(context),
                        style: const TextStyle(
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
                    _getLocalizedWeatherDescription(weatherCode, context),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocale.fetchingWeatherData.getString(context)),
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
                label: Text(AppLocale.retry.getString(context)),
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
                child: Text(AppLocale.openLocationSettings.getString(context)),
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
          Text(
            AppLocale.noWeatherAlerts.getString(context),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocale.weatherConditionsFavorable.getString(context),
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
        Text(
          AppLocale.activeAlerts.getString(context),
          style: const TextStyle(
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

    // Translate alert title and message based on alert type
    String localizedTitle = alert['title'];
    String localizedMessage = alert['message'];

    switch (alert['type']) {
      case 'heat':
        localizedTitle = AppLocale.highTempAlertTitle.getString(context);
        final temp = alert['message'].toString().split('is ')[1].split('°C')[0];
        localizedMessage = '${AppLocale.temperatureIs.getString(context)} $temp°C. ${AppLocale.ensureIrrigation.getString(context)}';
        break;
      case 'rain':
        localizedTitle = AppLocale.heavyRainfallTitle.getString(context);
        final rainfall = alert['message'].toString().split(': ')[1].split('mm')[0];
        localizedMessage = '${AppLocale.currentRainfall.getString(context)}: ${rainfall}mm. ${AppLocale.monitorFlooding.getString(context)}';
        break;
      case 'wind':
        localizedTitle = AppLocale.strongWindTitle.getString(context);
        final windSpeed = alert['message'].toString().split(': ')[1].split(' km/h')[0];
        localizedMessage = '${AppLocale.windSpeedIs.getString(context)}: $windSpeed km/h. ${AppLocale.protectYoungPlants.getString(context)}';
        break;
      case 'forecast':
        localizedTitle = AppLocale.heavyRainForecastTitle.getString(context);
        final expectedRain = alert['message'].toString().split(': ')[1].split('mm')[0];
        localizedMessage = '${AppLocale.expectedRainfall.getString(context)}: ${expectedRain}mm ${AppLocale.today.getString(context).toLowerCase()}. ${AppLocale.planIrrigationAccordingly.getString(context)}';
        break;
      case 'drought':
        localizedTitle = AppLocale.lowHumidityAlertTitle.getString(context);
        final humidity = alert['message'].toString().split(': ')[1].split('%')[0];
        localizedMessage = '${AppLocale.humidity.getString(context)}: $humidity%. ${AppLocale.increaseIrrigationFreq.getString(context)}';
        break;
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
                  localizedTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizedMessage,
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
        Text(
          AppLocale.sevenDayForecast.getString(context),
          style: const TextStyle(
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
                ? AppLocale.today.getString(context)
                : index == 1
                    ? AppLocale.tomorrow.getString(context)
                    : _getDayName(date.weekday, context);

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

  String _getDayName(int weekday, BuildContext context) {
    switch (weekday) {
      case 1:
        return AppLocale.monday.getString(context);
      case 2:
        return AppLocale.tuesday.getString(context);
      case 3:
        return AppLocale.wednesday.getString(context);
      case 4:
        return AppLocale.thursday.getString(context);
      case 5:
        return AppLocale.friday.getString(context);
      case 6:
        return AppLocale.saturday.getString(context);
      case 7:
        return AppLocale.sunday.getString(context);
      default:
        return '';
    }
  }

  String _getLocalizedWeatherDescription(int weatherCode, BuildContext context) {
    switch (weatherCode) {
      case 0:
        return AppLocale.clearSky.getString(context);
      case 1:
      case 2:
      case 3:
        return AppLocale.partlyCloudy.getString(context);
      case 45:
      case 48:
        return AppLocale.foggy.getString(context);
      case 51:
      case 53:
      case 55:
        return AppLocale.drizzle.getString(context);
      case 61:
      case 63:
      case 65:
        return AppLocale.rain.getString(context);
      case 71:
      case 73:
      case 75:
        return AppLocale.snow.getString(context);
      case 77:
        return AppLocale.snowGrains.getString(context);
      case 80:
      case 81:
      case 82:
        return AppLocale.rainShowers.getString(context);
      case 85:
      case 86:
        return AppLocale.snowShowers.getString(context);
      case 95:
        return AppLocale.thunderstorm.getString(context);
      case 96:
      case 99:
        return AppLocale.thunderstormHail.getString(context);
      default:
        return AppLocale.unknown.getString(context);
    }
  }

  Widget _buildWeatherAnimation() {
    if (_weatherData == null) return const SizedBox();
    
    final current = _weatherData!['current'];
    final weatherCode = current['weather_code'] ?? 0;
    
    // Map weather codes to weather scenes
    // Weather codes: 0=clear, 1-3=partly cloudy, 45-48=fog, 51-67=rain, 71-77=snow, 80-99=rain/storms
    if (weatherCode == 0) {
      return WeatherScene.scorchingSun.sceneWidget;
    } else if (weatherCode >= 1 && weatherCode <= 3) {
      return WeatherScene.sunset.sceneWidget;
    } else if (weatherCode >= 51 && weatherCode <= 67) {
      return WeatherScene.rainyOvercast.sceneWidget;
    } else if (weatherCode >= 71 && weatherCode <= 77) {
      return WeatherScene.frosty.sceneWidget;
    } else if (weatherCode >= 80 && weatherCode <= 99) {
      return WeatherScene.stormy.sceneWidget;
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      return WeatherScene.rainyOvercast.sceneWidget;
    } else {
      return WeatherScene.sunset.sceneWidget;
    }
  }
}
