import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with TickerProviderStateMixin {
  // Data storage
  Map<String, double> _weightEntries = {};
  Map<String, Map<String, double>> _measurements = {};
  Map<String, DateTime> _workoutCompletions = {};
  List<String> _customWorkouts = ['Cardio', 'Full Body', 'Leg Day', 'Upper Body'];

  // Controllers
  final weightController = TextEditingController();
  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final armsController = TextEditingController();
  final workoutNameController = TextEditingController();
  final dateController = TextEditingController();

  // UI State
  int _selectedTabIndex = 0;
  DateTimeRange? _dateRange;
  bool _showWeightChart = true;
  bool _showMeasurementChart = true;
  bool _showWorkoutStats = true;
  late TabController _tabController;

  // Chart data
  List<FlSpot> _weightChartData = [];
  List<FlSpot> _chestChartData = [];
  List<FlSpot> _waistChartData = [];
  List<FlSpot> _armsChartData = [];
  Map<String, int> _workoutFrequency = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgressData();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    weightController.dispose();
    chestController.dispose();
    waistController.dispose();
    armsController.dispose();
    workoutNameController.dispose();
    dateController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Load progress data from SharedPreferences
  Future<void> _loadProgressData() async {
    final prefs = await SharedPreferences.getInstance();

    final weightData = prefs.getString('weight_entries');
    if (weightData != null) {
      _weightEntries = Map<String, double>.from(
        jsonDecode(weightData).map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
      _prepareWeightChartData();
    }

    final measurementData = prefs.getString('measurements');
    if (measurementData != null) {
      final decoded = jsonDecode(measurementData) as Map<String, dynamic>;
      _measurements = decoded.map((k, v) {
        final values = Map<String, double>.from(
          (v as Map<String, dynamic>).map((key, value) => MapEntry(key, (value as num).toDouble())),
        );
        return MapEntry(k, values);
      });
      _prepareMeasurementChartData();
    }

    final completionData = prefs.getString('workout_completions');
    if (completionData != null) {
      _workoutCompletions = Map<String, DateTime>.from(
        jsonDecode(completionData).map((k, v) => MapEntry(k, DateTime.parse(v))),
      );
      _calculateWorkoutFrequency();
    }

    final customWorkouts = prefs.getStringList('custom_workouts');
    if (customWorkouts != null) {
      _customWorkouts = customWorkouts;
    }

    setState(() {});
  }

  // Save progress data to SharedPreferences
  Future<void> _saveProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_entries', jsonEncode(_weightEntries));
    await prefs.setString('measurements', jsonEncode(_measurements));
    await prefs.setString(
      'workout_completions',
      jsonEncode(_workoutCompletions.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
    await prefs.setStringList('custom_workouts', _customWorkouts);
  }

  // Prepare weight data for chart
  void _prepareWeightChartData() {
    final sorted = _weightEntries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _weightChartData = sorted.asMap().entries.map((entry) {
      final date = DateTime.parse(entry.value.key);
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  // Prepare measurement data for chart
  void _prepareMeasurementChartData() {
    final sorted = _measurements.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _chestChartData = sorted.asMap().entries.where((e) => e.value.value.containsKey('Chest')).map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value['Chest']!);
    }).toList();

    _waistChartData = sorted.asMap().entries.where((e) => e.value.value.containsKey('Waist')).map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value['Waist']!);
    }).toList();

    _armsChartData = sorted.asMap().entries.where((e) => e.value.value.containsKey('Arms')).map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value['Arms']!);
    }).toList();
  }

  // Calculate workout frequency stats
  void _calculateWorkoutFrequency() {
    _workoutFrequency = {};
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    _workoutCompletions.forEach((name, date) {
      if (date.isAfter(last30Days)) {
        _workoutFrequency[name] = (_workoutFrequency[name] ?? 0) + 1;
      }
    });
  }

  // Add a new weight entry
  void _addWeightEntry() {
    final weight = double.tryParse(weightController.text);
    if (weight == null || weight <= 0) {
      _showErrorSnackbar('Please enter a valid weight');
      return;
    }

    final dateStr = dateController.text.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : dateController.text;

    _weightEntries[dateStr] = weight;
    _prepareWeightChartData();
    _saveProgressData();
    weightController.clear();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {});
    _showSuccessSnackbar('Weight recorded successfully');
  }

  // Add a new body measurement entry
  void _addMeasurementEntry() {
    final chest = double.tryParse(chestController.text) ?? 0;
    final waist = double.tryParse(waistController.text) ?? 0;
    final arms = double.tryParse(armsController.text) ?? 0;

    if (chest <= 0 || waist <= 0 || arms <= 0) {
      _showErrorSnackbar('Please enter valid measurements');
      return;
    }

    final dateStr = dateController.text.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : dateController.text;

    _measurements[dateStr] = {'Chest': chest, 'Waist': waist, 'Arms': arms};
    _prepareMeasurementChartData();
    _saveProgressData();
    chestController.clear();
    waistController.clear();
    armsController.clear();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {});
    _showSuccessSnackbar('Measurements recorded successfully');
  }

  // Log a workout completion
  void _logWorkoutCompletion(String name) {
    final dateStr = dateController.text.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : dateController.text;

    _workoutCompletions['$name - ${DateFormat('MMM dd').format(DateTime.parse(dateStr))}'] = DateTime.parse(dateStr);
    _calculateWorkoutFrequency();
    _saveProgressData();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {});
    _showSuccessSnackbar('Workout logged successfully');
  }

  // Add custom workout type
  void _addCustomWorkout() {
    final name = workoutNameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackbar('Please enter a workout name');
      return;
    }

    if (_customWorkouts.contains(name)) {
      _showErrorSnackbar('Workout already exists');
      return;
    }

    _customWorkouts.add(name);
    _saveProgressData();
    workoutNameController.clear();
    setState(() {});
    _showSuccessSnackbar('Workout added successfully');
  }

  // Delete a weight entry
  void _deleteWeightEntry(String date) {
    _weightEntries.remove(date);
    _prepareWeightChartData();
    _saveProgressData();
    setState(() {});
    _showSuccessSnackbar('Weight entry deleted');
  }

  // Delete a measurement entry
  void _deleteMeasurementEntry(String date) {
    _measurements.remove(date);
    _prepareMeasurementChartData();
    _saveProgressData();
    setState(() {});
    _showSuccessSnackbar('Measurement entry deleted');
  }

  // Delete a workout entry
  void _deleteWorkoutEntry(String key) {
    _workoutCompletions.remove(key);
    _calculateWorkoutFrequency();
    _saveProgressData();
    setState(() {});
    _showSuccessSnackbar('Workout entry deleted');
  }

  // Show date range picker
  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Range'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SfDateRangePicker(
            selectionMode: DateRangePickerSelectionMode.range,
            initialSelectedRange: _dateRange != null
                ? PickerDateRange(_dateRange!.start, _dateRange!.end)
                : null,
            maxDate: DateTime.now(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final picker = context.findAncestorWidgetOfExactType<SfDateRangePicker>();
              if (picker != null && picker.controller != null) {
                Navigator.pop(context, picker.controller!.selectedRange);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  // Filter entries by date range
  Map<String, T> _filterByDateRange<T>(Map<String, T> entries) {
    if (_dateRange == null) return entries;

    return Map.fromEntries(entries.entries.where((entry) {
      final date = DateTime.parse(entry.key);
      return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }));
  }

  // Show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Progress Tracker'),
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
      Tab(icon: Icon(Icons.monitor_weight)),
    Tab(icon: Icon(Icons.straighten)),
    Tab(icon: Icon(Icons.fitness_center)),
    ],
            onTap: (index) {
      setState(() {
      _selectedTabIndex = index;
      });
      },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _showDateRangePicker(context),
        ),
      ],
    );
  }

  // Build the weight tracking section
  Widget _buildWeightSection() {
    final filteredEntries = _filterByDateRange(_weightEntries);
    final sortedEntries = filteredEntries.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Input card
          _buildInputCard(
            title: 'Add Weight Entry',
            icon: Icons.add,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addWeightEntry,
                child: const Text('Record Weight'),
              ),
            ],
          ),

          // Chart toggle and display
          _buildSectionToggle(
            title: 'Weight Progress Chart',
            value: _showWeightChart,
            onChanged: (value) => setState(() => _showWeightChart = value),
          ),
          if (_showWeightChart && _weightChartData.isNotEmpty)
            _buildWeightChart(),

          // Entries list
          _buildSectionHeader('Recent Entries'),
          if (sortedEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No weight entries found', textAlign: TextAlign.center),
            )
          else
            ...sortedEntries.map((e) => _buildWeightEntryItem(e.key, e.value)),
        ],
      ),
    );
  }

  // Build the measurements section
  Widget _buildMeasurementSection() {
    final filteredEntries = _filterByDateRange(_measurements);
    final sortedEntries = filteredEntries.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Input card
          _buildInputCard(
            title: 'Add Body Measurements',
            icon: Icons.add,
            children: [
              Row(
                children: [
                  Expanded(child: _buildMeasurementInput('Chest (cm)', chestController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMeasurementInput('Waist (cm)', waistController)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMeasurementInput('Arms (cm)', armsController)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addMeasurementEntry,
                child: const Text('Record Measurements'),
              ),
            ],
          ),

          // Chart toggle and display
          _buildSectionToggle(
            title: 'Measurement Trends',
            value: _showMeasurementChart,
            onChanged: (value) => setState(() => _showMeasurementChart = value),
          ),
          if (_showMeasurementChart && _chestChartData.isNotEmpty)
            _buildMeasurementChart(),

          // Entries list
          _buildSectionHeader('Recent Entries'),
          if (sortedEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No measurement entries found', textAlign: TextAlign.center),
            )
          else
            ...sortedEntries.map((e) => _buildMeasurementEntryItem(e.key, e.value)),
        ],
      ),
    );
  }

  // Build the workout section
  Widget _buildWorkoutSection() {
    final filteredEntries = _filterByDateRange(
      Map.fromEntries(_workoutCompletions.entries.map((e) =>
          MapEntry(DateFormat('yyyy-MM-dd').format(e.value), e.key))),
    );

    final sortedEntries = _workoutCompletions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        children: [
          // Input card
          _buildInputCard(
            title: 'Log Workout',
            icon: Icons.add,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: workoutNameController,
                      decoration: const InputDecoration(
                        labelText: 'New Workout Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addCustomWorkout,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customWorkouts.map((workout) => ActionChip(
                  label: Text(workout),
                  onPressed: () => _logWorkoutCompletion(workout),
                )).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
            ],
          ),

          // Stats toggle and display
          _buildSectionToggle(
            title: 'Workout Statistics',
            value: _showWorkoutStats,
            onChanged: (value) => setState(() => _showWorkoutStats = value),
          ),
          if (_showWorkoutStats && _workoutFrequency.isNotEmpty)
            _buildWorkoutStats(),

          // Entries list
          _buildSectionHeader('Recent Workouts'),
          if (sortedEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No workout entries found', textAlign: TextAlign.center),
            )
          else
            ...sortedEntries.take(10).map((e) => _buildWorkoutEntryItem(e.key, e.value)),
        ],
      ),
    );
  }

  // Build a weight chart
  Widget _buildWeightChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _weightChartData.length) {
                    final date = DateTime.parse(_weightEntries.keys.toList()[value.toInt()]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(DateFormat('MMM dd').format(date)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: _weightChartData.length > 1 ? (_weightChartData.length - 1).toDouble() : 1,
          minY: _weightChartData.isNotEmpty
              ? (_weightChartData.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5)
              : 0,
          maxY: _weightChartData.isNotEmpty
              ? (_weightChartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5)
              : 100,
          lineBarsData: [
            LineChartBarData(
              spots: _weightChartData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  // Build a measurement chart
  Widget _buildMeasurementChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _chestChartData.length) {
                    final date = DateTime.parse(_measurements.keys.toList()[value.toInt()]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(DateFormat('MMM dd').format(date)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: _chestChartData.length > 1 ? (_chestChartData.length - 1).toDouble() : 1,
          minY: 0,
          maxY: [
            if (_chestChartData.isNotEmpty) _chestChartData.map((e) => e.y).reduce((a, b) => a > b ? a : b),
            if (_waistChartData.isNotEmpty) _waistChartData.map((e) => e.y).reduce((a, b) => a > b ? a : b),
            if (_armsChartData.isNotEmpty) _armsChartData.map((e) => e.y).reduce((a, b) => a > b ? a : b),
          ].reduce((a, b) => a > b ? a : b) + 10,
          lineBarsData: [
            if (_chestChartData.isNotEmpty)
              LineChartBarData(
                spots: _chestChartData,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
              ),
            if (_waistChartData.isNotEmpty)
              LineChartBarData(
                spots: _waistChartData,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
              ),
            if (_armsChartData.isNotEmpty)
              LineChartBarData(
                spots: _armsChartData,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
              ),
          ],
        ),
      ),
    );
  }

  // Build workout statistics
  Widget _buildWorkoutStats() {
    final sortedWorkouts = _workoutFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 30 Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (sortedWorkouts.isEmpty)
            const Text('No workout data available')
          else
            Column(
              children: sortedWorkouts.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / sortedWorkouts.first.value,
                        backgroundColor: Colors.grey[200],
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  // Build a weight entry item
  Widget _buildWeightEntryItem(String date, double weight) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.monitor_weight, color: Colors.blue),
        title: Text(DateFormat.yMMMd().format(DateTime.parse(date))),
        subtitle: Text('${weight.toStringAsFixed(1)} kg'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteWeightEntry(date),
        ),
      ),
    );
  }

  // Build a measurement entry item
  Widget _buildMeasurementEntryItem(String date, Map<String, double> measurements) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.straighten, color: Colors.green),
        title: Text(DateFormat.yMMMd().format(DateTime.parse(date))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: measurements.entries.map((e) =>
              Text('${e.key}: ${e.value.toStringAsFixed(1)} cm')
          ).toList(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteMeasurementEntry(date),
        ),
      ),
    );
  }

  // Build a workout entry item
  Widget _buildWorkoutEntryItem(String name, DateTime date) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Colors.orange),
        title: Text(name.split(' - ')[0]),
        subtitle: Text(DateFormat.yMMMd().format(date)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteWorkoutEntry(name),
        ),
      ),
    );
  }

  // Build an input card
  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Build a section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Build a section toggle
  Widget _buildSectionToggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  // Build a measurement input field
  Widget _buildMeasurementInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeightSection(),
          _buildMeasurementSection(),
          _buildWorkoutSection(),
        ],
      ),
    );
  }
}