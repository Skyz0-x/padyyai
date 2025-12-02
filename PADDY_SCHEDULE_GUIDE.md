# Paddy Fertilization & Pesticide Schedule Feature

## Overview
The farming calendar now automatically generates recommended fertilization and pesticide application schedules based on the selected paddy variety in the Paddy Growth Monitor.

## How It Works

### 1. Paddy Schedule Configuration
- **File**: `lib/config/paddy_schedule_config.dart`
- Contains fertilization and pesticide schedules for all 5 paddy varieties:
  - MR 297
  - MR 220
  - MR 219
  - MR 263 (Umur Pendek)
  - MR 315

### 2. Schedule Activities
Each paddy variety has a predefined schedule based on days after planting (HLT - Hari Selepas Tabur):

#### Activity Types:
- **Fertilization** (`fertilization`): NPK, Urea, Compound fertilizers
- **Pest Control** (`pest_control`): Weed killers, Fungicides, Insecticides

#### Activity Details:
- Days after planting
- Activity type (fertilization/pest_control)
- Title (English & Malay)
- Description (English & Malay)
- Priority level (low, medium, high, urgent)

### 3. Automatic Schedule Generation

When a farmer:
1. Selects a paddy variety in **Paddy Growth Monitor**
2. Sets the planting date
3. Saves the configuration

The system automatically:
- Calculates all schedule dates based on planting date
- Creates reminders for each activity
- Displays them on the farming calendar with color coding:
  - **Green**: Fertilization activities
  - **Deep Orange**: Pest control activities

### 4. Calendar Display

The farming calendar shows:
- **Colored date squares**: Based on activity type
- **Activity icons**: Visual indicators for each type
- **Date labels**: Colored to match activity type
- **Multiple activities**: Shows dominant color if multiple activities on same date

### 5. Bilingual Support

All schedule activities support both languages:
- **English**: Full descriptions and titles
- **Malay**: Fully translated content

## Schedule Examples

### MR 297 Schedule:
- Day 5: Racun Rumpai Pra-Tumbuh & Siput
- Day 14: P1: Baja Campuran (Pertumbuhan Vegetatif)
- Day 47: P3: Baja NPK + 10 kg Campuran
- Day 60: Racun Kulat (Karah Tangkai) & Bena Perang
- Day 69: P4: NPK (Pilihan)

### MR 220 Schedule:
- Day 5: Racun Rumpai Pra-Tumbuh & Siput
- Day 15: P1: Baja Campuran NPK (Aplikasi Awal)
- Day 20: P2: Urea
- Day 25: P2: Urea (Second application)
- Day 30: Racun Rumpai Pasca-Tumbuh & Ulat Awal
- Day 45: P3: Baja NPK Tinggi K + Racun Kulat
- Day 60: P4: Baja NPK Tinggi K + Racun Kulat & Bena

## Technical Implementation

### Files Modified:
1. **`lib/config/paddy_schedule_config.dart`** (NEW)
   - Schedule configurations for all varieties
   - Data models (ScheduleActivity, ScheduledReminder)
   - Utility methods for date calculations

2. **`lib/screens/home_screen.dart`**
   - Import paddy schedule config
   - Added `_generateScheduleReminders()` method
   - Updated `_savePaddyMonitoring()` to trigger schedule generation
   - Enhanced `_loadReminders()` to load month-specific data
   - Added `_loadMonthReminders()` for calendar display

### Key Methods:

#### `PaddyScheduleConfig.calculateScheduleDates()`
```dart
static List<ScheduledReminder> calculateScheduleDates({
  required String variety,
  required DateTime plantingDate,
})
```
Calculates actual dates for all activities based on planting date.

#### `_generateScheduleReminders()`
```dart
Future<void> _generateScheduleReminders() async
```
Creates all schedule reminders in the database when paddy variety is saved.

#### `_loadMonthReminders()`
```dart
Future<void> _loadMonthReminders() async
```
Loads and groups reminders by date for calendar display.

## User Experience

1. **Farmer selects paddy variety** → System knows which schedule to apply
2. **Farmer sets planting date** → System calculates all activity dates
3. **Farmer saves** → Automatic reminders created
4. **Calendar updates** → All activities appear with color coding
5. **Notifications** → Farmers get reminded before each activity

## Benefits

✅ **Automated**: No manual schedule entry needed
✅ **Accurate**: Based on agricultural best practices
✅ **Visual**: Color-coded calendar for easy planning
✅ **Timely**: Automatic notifications for each activity
✅ **Bilingual**: Full Malay and English support
✅ **Variety-specific**: Tailored to each paddy type

## Future Enhancements

Potential improvements:
- Allow farmers to adjust individual schedule dates
- Add custom activities to the schedule
- Weather-based schedule adjustments
- Soil condition recommendations
- Fertilizer quantity calculations
- Cost estimation for materials
- Historical yield tracking per schedule adherence
