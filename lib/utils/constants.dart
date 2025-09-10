import 'package:flutter/material.dart';

// App Colors - Paddy/Agricultural theme
const Color primaryColor = Color(0xFF2E7D32); // Forest Green
const Color secondaryColor = Color(0xFF388E3C); // Darker Green
const Color accentColor = Color(0xFF4CAF50); // Medium Green
const Color backgroundColor = Color(0xFFF1F8E9); // Light Green Background
const Color cardColor = Color(0xFFFFFFFF); // White for cards
const Color textDarkColor = Color(0xFF1B5E20); // Dark Green for text
const Color textLightColor = Color(0xFF81C784); // Light Green for secondary text

// Gradient colors for interactive elements
const LinearGradient primaryGradient = LinearGradient(
  colors: [primaryColor, secondaryColor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient accentGradient = LinearGradient(
  colors: [accentColor, Color(0xFF66BB6A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Custom text styles
const TextStyle headingStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: textDarkColor,
);

const TextStyle subHeadingStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: textDarkColor,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 16,
  color: textDarkColor,
);

const TextStyle captionStyle = TextStyle(
  fontSize: 14,
  color: textLightColor,
);

// Button styles
final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryColor,
  foregroundColor: Colors.white,
  elevation: 4,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(25),
  ),
);

final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: primaryColor,
  elevation: 2,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(25),
    side: const BorderSide(color: primaryColor, width: 2),
  ),
);

// Card decoration
const BoxDecoration cardDecoration = BoxDecoration(
  color: cardColor,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ],
);

// Interactive card decoration with gradient
const BoxDecoration interactiveCardDecoration = BoxDecoration(
  gradient: LinearGradient(
    colors: [Color(0xFFE8F5E8), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ],
);

// Input decoration
const InputDecoration customInputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: textLightColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: primaryColor, width: 2),
  ),
  filled: true,
  fillColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
);

// App constants
const String appName = 'PaddyAI';
const String logoPath = 'lib/assets/img/PadyyAI.png';

// AI Model paths
const String modelPath = 'lib/assets/tflite/paddyai_model.tflite';
const String labelsPath = 'lib/assets/tflite/labels.txt';

// Farming-related messages and tips
const List<String> farmingTips = [
  '🌾 Check your paddy fields early morning for best disease detection',
  '💧 Proper water management prevents many rice diseases',
  '🔍 Regular monitoring helps catch problems before they spread',
  '🌱 Healthy soil leads to healthy crops',
  '📱 Use technology to improve your farming efficiency',
];

const List<String> welcomeMessages = [
  'Welcome back, Farmer!',
  'Hello, Agricultural Hero!',
  'Good to see you again!',
  'Ready to check your crops?',
  'Let\'s grow together!',
];
