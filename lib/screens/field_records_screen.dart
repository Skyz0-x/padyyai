import 'package:flutter/material.dart';
import '../services/field_records_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class FieldRecordsScreen extends StatefulWidget {
  const FieldRecordsScreen({super.key});

  @override
  State<FieldRecordsScreen> createState() => _FieldRecordsScreenState();
}

class _FieldRecordsScreenState extends State<FieldRecordsScreen> with SingleTickerProviderStateMixin {
  final FieldRecordsService _fieldRecordsService = FieldRecordsService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = true;
  String? _selectedFilter;
  
  final List<String> _recordTypes = [
    'All',
    'irrigation',
    'fertilizer',
    'pesticide',
    'harvest',
    'planting',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    
    try {
      final records = await _fieldRecordsService.getFieldRecords();
      if (mounted) {
        setState(() {
          _allRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading records: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return _allRecords;
    }
    return _allRecords.where((r) => r['record_type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsCards(),
                _buildFilterChips(),
              ],
            ),
          ),
          _buildRecordsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordDialog,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
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
          decoration: const BoxDecoration(gradient: primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Field Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track your farming activities',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadRecords,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _calculateStats();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Records',
              '${stats['total']}',
              Icons.assignment,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Cost',
              'RM${stats['cost']}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'This Month',
              '${stats['thisMonth']}',
              Icons.calendar_today,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: textLightColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recordTypes.length,
        itemBuilder: (context, index) {
          final type = _recordTypes[index];
          final isSelected = _selectedFilter == type || 
                            (type == 'All' && _selectedFilter == null);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                type == 'All' ? type : type[0].toUpperCase() + type.substring(1),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = type == 'All' ? null : type;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : textDarkColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final records = _filteredRecords;

    if (records.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No records found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your field activities',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final record = records[index];
            return _buildRecordCard(record);
          },
          childCount: records.length,
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final type = record['record_type'] ?? 'other';
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);
    final date = DateTime.parse(record['record_date']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (record['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record['description'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: textLightColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (record['cost'] != null)
                    Text(
                      'RM${(record['cost'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLightColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return Colors.blue;
      case 'fertilizer':
        return Colors.green;
      case 'pesticide':
        return Colors.orange;
      case 'harvest':
        return Colors.amber;
      case 'planting':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return Icons.water_drop;
      case 'fertilizer':
        return Icons.eco;
      case 'pesticide':
        return Icons.pest_control;
      case 'harvest':
        return Icons.agriculture;
      case 'planting':
        return Icons.grass;
      default:
        return Icons.assignment;
    }
  }

  Map<String, dynamic> _calculateStats() {
    double totalCost = 0;
    int thisMonthCount = 0;
    final now = DateTime.now();

    for (var record in _allRecords) {
      if (record['cost'] != null) {
        totalCost += (record['cost'] as num).toDouble();
      }
      
      final recordDate = DateTime.parse(record['record_date']);
      if (recordDate.year == now.year && recordDate.month == now.month) {
        thisMonthCount++;
      }
    }

    return {
      'total': _allRecords.length,
      'cost': totalCost.toStringAsFixed(2),
      'thisMonth': thisMonthCount,
    };
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    final date = DateTime.parse(record['record_date']);
    final formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    final type = record['record_type'] ?? 'other';
    final color = _getTypeColor(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getTypeIcon(type), color: color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.calendar_today, 'Date', formattedDate),
                    if (record['description'] != null)
                      _buildDetailRow(Icons.description, 'Description', record['description']),
                    if (record['location'] != null)
                      _buildDetailRow(Icons.location_on, 'Location', record['location']),
                    if (record['area_size'] != null)
                      _buildDetailRow(Icons.landscape, 'Area Size', '${record['area_size']} hectares'),
                    if (record['quantity'] != null && record['unit'] != null)
                      _buildDetailRow(Icons.straighten, 'Quantity', '${record['quantity']} ${record['unit']}'),
                    if (record['cost'] != null)
                      _buildDetailRow(Icons.attach_money, 'Cost', 'RM ${(record['cost'] as num).toStringAsFixed(2)}'),
                    if (record['weather_condition'] != null)
                      _buildDetailRow(Icons.wb_sunny, 'Weather', record['weather_condition']),
                    if (record['notes'] != null)
                      _buildDetailRow(Icons.notes, 'Notes', record['notes']),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(record['id']);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textLightColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: textDarkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog() {
    final formKey = GlobalKey<FormState>();
    String recordType = 'irrigation';
    String title = '';
    String? description;
    double? areaSize;
    double? quantity;
    String? unit;
    double? cost;
    String? location;
    String? notes;
    DateTime recordDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Field Record'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: recordType,
                  decoration: const InputDecoration(
                    labelText: 'Record Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['irrigation', 'fertilizer', 'pesticide', 'harvest', 'planting', 'other']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type[0].toUpperCase() + type.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) => recordType = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => title = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSaved: (value) => description = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cost (RM)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => cost = value != null && value.isNotEmpty ? double.tryParse(value) : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context);
                
                final result = await _fieldRecordsService.addFieldRecord(
                  recordType: recordType,
                  title: title,
                  description: description,
                  areaSize: areaSize,
                  quantity: quantity,
                  unit: unit,
                  cost: cost,
                  location: location,
                  notes: notes,
                  recordDate: recordDate,
                );

                if (result['success'] && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Record added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadRecords();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String recordId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _fieldRecordsService.deleteFieldRecord(recordId);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Record deleted'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _loadRecords();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
