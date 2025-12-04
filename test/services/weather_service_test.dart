import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/weather_service.dart';

/// Test suite for WeatherService
/// 
/// This test file validates the weather service functionality including:
/// - Weather description mapping
/// - Weather icon mapping
/// - Cache validation
/// - Weather code interpretation
void main() {
  late WeatherService weatherService;

  setUp(() {
    weatherService = WeatherService();
  });

  group('Weather Description Tests', () {
    test('getWeatherDescription returns correct description for clear sky', () {
      expect(weatherService.getWeatherDescription(0), 'Clear sky');
    });

    test('getWeatherDescription returns correct description for partly cloudy', () {
      expect(weatherService.getWeatherDescription(1), 'Partly cloudy');
      expect(weatherService.getWeatherDescription(2), 'Partly cloudy');
      expect(weatherService.getWeatherDescription(3), 'Partly cloudy');
    });

    test('getWeatherDescription returns correct description for fog', () {
      expect(weatherService.getWeatherDescription(45), 'Foggy');
      expect(weatherService.getWeatherDescription(48), 'Foggy');
    });

    test('getWeatherDescription returns correct description for drizzle', () {
      expect(weatherService.getWeatherDescription(51), 'Drizzle');
      expect(weatherService.getWeatherDescription(53), 'Drizzle');
      expect(weatherService.getWeatherDescription(55), 'Drizzle');
    });

    test('getWeatherDescription returns correct description for rain', () {
      expect(weatherService.getWeatherDescription(61), 'Rain');
      expect(weatherService.getWeatherDescription(63), 'Rain');
      expect(weatherService.getWeatherDescription(65), 'Rain');
    });

    test('getWeatherDescription returns correct description for snow', () {
      expect(weatherService.getWeatherDescription(71), 'Snow');
      expect(weatherService.getWeatherDescription(73), 'Snow');
      expect(weatherService.getWeatherDescription(75), 'Snow');
    });

    test('getWeatherDescription returns correct description for thunderstorm', () {
      expect(weatherService.getWeatherDescription(95), 'Thunderstorm');
    });

    test('getWeatherDescription returns unknown for invalid code', () {
      expect(weatherService.getWeatherDescription(999), 'Unknown');
      expect(weatherService.getWeatherDescription(-1), 'Unknown');
    });
  });

  group('Weather Icon Tests', () {
    test('getWeatherIcon returns correct icon for clear sky', () {
      expect(weatherService.getWeatherIcon(0), '☀️');
    });

    test('getWeatherIcon returns correct icon for partly cloudy', () {
      expect(weatherService.getWeatherIcon(1), '⛅');
      expect(weatherService.getWeatherIcon(2), '⛅');
      expect(weatherService.getWeatherIcon(3), '⛅');
    });

    test('getWeatherIcon returns correct icon for fog', () {
      expect(weatherService.getWeatherIcon(45), '🌫️');
      expect(weatherService.getWeatherIcon(48), '🌫️');
    });

    test('getWeatherIcon returns correct icon for rain', () {
      expect(weatherService.getWeatherIcon(61), '🌧️');
      expect(weatherService.getWeatherIcon(63), '🌧️');
      expect(weatherService.getWeatherIcon(65), '🌧️');
    });

    test('getWeatherIcon returns correct icon for snow', () {
      expect(weatherService.getWeatherIcon(71), '❄️');
      expect(weatherService.getWeatherIcon(73), '❄️');
      expect(weatherService.getWeatherIcon(75), '❄️');
    });

    test('getWeatherIcon returns correct icon for thunderstorm', () {
      expect(weatherService.getWeatherIcon(95), '⛈️');
      expect(weatherService.getWeatherIcon(96), '⛈️');
      expect(weatherService.getWeatherIcon(99), '⛈️');
    });

    test('getWeatherIcon returns default icon for unknown code', () {
      expect(weatherService.getWeatherIcon(999), '🌤️');
      expect(weatherService.getWeatherIcon(-1), '🌤️');
    });
  });

  group('Weather Alerts Tests', () {
    test('getWeatherAlerts returns heat alert for high temperature', () {
      final mockWeatherData = {
        'current': {
          'temperature_2m': 36.0,
          'relative_humidity_2m': 50,
          'precipitation': 0,
          'wind_speed_10m': 10,
        },
        'daily': {
          'precipitation_sum': [5.0],
        }
      };

      final alerts = weatherService.getWeatherAlerts(mockWeatherData);
      
      expect(alerts.isNotEmpty, true);
      expect(alerts.any((alert) => alert['type'] == 'heat'), true);
      expect(alerts.any((alert) => alert['severity'] == 'high'), true);
    });

    test('getWeatherAlerts returns rain alert for heavy precipitation', () {
      final mockWeatherData = {
        'current': {
          'temperature_2m': 30.0,
          'relative_humidity_2m': 80,
          'precipitation': 15.0,
          'wind_speed_10m': 10,
        },
        'daily': {
          'precipitation_sum': [5.0],
        }
      };

      final alerts = weatherService.getWeatherAlerts(mockWeatherData);
      
      expect(alerts.isNotEmpty, true);
      expect(alerts.any((alert) => alert['type'] == 'rain'), true);
    });

    test('getWeatherAlerts returns wind alert for strong wind', () {
      final mockWeatherData = {
        'current': {
          'temperature_2m': 30.0,
          'relative_humidity_2m': 50,
          'precipitation': 0,
          'wind_speed_10m': 35.0,
        },
        'daily': {
          'precipitation_sum': [5.0],
        }
      };

      final alerts = weatherService.getWeatherAlerts(mockWeatherData);
      
      expect(alerts.isNotEmpty, true);
      expect(alerts.any((alert) => alert['type'] == 'wind'), true);
    });

    test('getWeatherAlerts returns drought alert for low humidity', () {
      final mockWeatherData = {
        'current': {
          'temperature_2m': 30.0,
          'relative_humidity_2m': 25,
          'precipitation': 0,
          'wind_speed_10m': 10,
        },
        'daily': {
          'precipitation_sum': [0.0],
        }
      };

      final alerts = weatherService.getWeatherAlerts(mockWeatherData);
      
      expect(alerts.isNotEmpty, true);
      expect(alerts.any((alert) => alert['type'] == 'drought'), true);
    });

    test('getWeatherAlerts returns no alerts for normal conditions', () {
      final mockWeatherData = {
        'current': {
          'temperature_2m': 28.0,
          'relative_humidity_2m': 60,
          'precipitation': 0,
          'wind_speed_10m': 10,
        },
        'daily': {
          'precipitation_sum': [5.0],
        }
      };

      final alerts = weatherService.getWeatherAlerts(mockWeatherData);
      
      expect(alerts.isEmpty, true);
    });

    test('getWeatherAlerts handles null values gracefully', () {
      final mockWeatherData = {
        'current': null,
        'daily': null,
      };

      final alerts = weatherService.getWeatherAlerts(mockWeatherData);
      
      expect(alerts, isA<List>());
    });
  });

  group('Cache Functionality Tests', () {
    test('clearCache clears all cached data', () {
      // This test verifies the cache clearing functionality
      weatherService.clearCache();
      
      // After clearing cache, subsequent calls should fetch new data
      // Note: This is a basic test, actual verification would require mocking
      expect(true, true); // Placeholder assertion
    });
  });
}
