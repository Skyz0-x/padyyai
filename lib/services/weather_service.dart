import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Using Open-Meteo API (free, no API key required)
  static const String _baseUrl = 'https://api.open-meteo.com/v1';
  
  // Get location name from coordinates using reverse geocoding
  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=$latitude&lon=$longitude&format=json&accept-language=en'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'PaddyAI/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Build location name from address components
        String locationName = '';
        
        if (address['city'] != null) {
          locationName = address['city'];
        } else if (address['town'] != null) {
          locationName = address['town'];
        } else if (address['village'] != null) {
          locationName = address['village'];
        } else if (address['county'] != null) {
          locationName = address['county'];
        }
        
        if (address['state'] != null && locationName.isNotEmpty) {
          locationName += ', ${address['state']}';
        } else if (address['state'] != null) {
          locationName = address['state'];
        }
        
        if (address['country'] != null && locationName.isNotEmpty) {
          locationName += ', ${address['country']}';
        } else if (address['country'] != null) {
          locationName = address['country'];
        }
        
        print('✅ Location name: $locationName');
        return locationName.isNotEmpty ? locationName : 'Unknown Location';
      }
    } catch (e) {
      print('❌ Error getting location name: $e');
    }
    return 'Unknown Location';
  }
  
  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled.');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  // Get weather data
  Future<Map<String, dynamic>?> getWeatherData(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,wind_speed_10m'
        '&hourly=temperature_2m,precipitation_probability,precipitation,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max'
        '&timezone=auto'
        '&forecast_days=7'
      );

      print('🌤️ Fetching weather data from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weather data received');
        return data;
      } else {
        print('❌ Failed to fetch weather data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching weather data: $e');
      return null;
    }
  }

  // Get weather alerts based on conditions
  List<Map<String, dynamic>> getWeatherAlerts(Map<String, dynamic> weatherData) {
    List<Map<String, dynamic>> alerts = [];
    
    try {
      final current = weatherData['current'];
      final daily = weatherData['daily'];
      
      if (current != null) {
        // High temperature alert
        if (current['temperature_2m'] != null && current['temperature_2m'] > 35) {
          alerts.add({
            'type': 'heat',
            'severity': 'high',
            'title': 'High Temperature Alert',
            'message': 'Temperature is ${current['temperature_2m']}°C. Ensure adequate irrigation for your crops.',
            'icon': '🌡️',
            'color': 'red',
          });
        }
        
        // Heavy rain alert
        if (current['precipitation'] != null && current['precipitation'] > 10) {
          alerts.add({
            'type': 'rain',
            'severity': 'medium',
            'title': 'Heavy Rainfall',
            'message': 'Current rainfall: ${current['precipitation']}mm. Monitor for flooding and disease.',
            'icon': '🌧️',
            'color': 'blue',
          });
        }
        
        // Strong wind alert
        if (current['wind_speed_10m'] != null && current['wind_speed_10m'] > 30) {
          alerts.add({
            'type': 'wind',
            'severity': 'medium',
            'title': 'Strong Wind Warning',
            'message': 'Wind speed: ${current['wind_speed_10m']} km/h. Protect young plants.',
            'icon': '💨',
            'color': 'orange',
          });
        }
      }
      
      // Check daily forecast for upcoming alerts
      if (daily != null && daily['precipitation_sum'] != null) {
        final precipSum = daily['precipitation_sum'] as List;
        if (precipSum.isNotEmpty && precipSum[0] > 20) {
          alerts.add({
            'type': 'forecast',
            'severity': 'low',
            'title': 'Heavy Rain Forecast',
            'message': 'Expected rainfall: ${precipSum[0]}mm today. Plan irrigation accordingly.',
            'icon': '⛈️',
            'color': 'purple',
          });
        }
      }
      
      // Low humidity alert (drought risk)
      if (current['relative_humidity_2m'] != null && current['relative_humidity_2m'] < 30) {
        alerts.add({
          'type': 'drought',
          'severity': 'medium',
          'title': 'Low Humidity Alert',
          'message': 'Humidity: ${current['relative_humidity_2m']}%. Increase irrigation frequency.',
          'icon': '🏜️',
          'color': 'brown',
        });
      }
      
    } catch (e) {
      print('❌ Error processing weather alerts: $e');
    }
    
    return alerts;
  }

  // Get weather description from WMO code
  String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  // Get weather icon emoji
  String getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return '☀️';
      case 1:
      case 2:
      case 3:
        return '⛅';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
        return '🌦️';
      case 61:
      case 63:
      case 65:
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
        return '❄️';
      case 80:
      case 81:
      case 82:
        return '🌧️';
      case 85:
      case 86:
        return '🌨️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌤️';
    }
  }
}
