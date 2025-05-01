import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/nutrition_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Please log in to view nutrition data',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nutritionProvider.user == null) {
        nutritionProvider.setUser(user);
      }
    });

    final nutrition = nutritionProvider.nutrition;
    final dailyNutrition = nutritionProvider.getDailyNutrition(_selectedDay!);
    final total = nutritionProvider.calculateDailyTotals(_selectedDay!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Nutrition',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => nutritionProvider.setUser(user),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactCalendar(nutritionProvider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildNutritionSummary(nutrition, total),
                    const SizedBox(height: 16),
                    _buildMacroProgress(
                      calories: total['calories']!,
                      protein: total['protein']!,
                      carbs: total['carbs']!,
                      fat: total['fat']!,
                      targets: nutrition,
                    ),
                    const SizedBox(height: 16),
                    _buildSuggestedFoods(nutrition['goal']),
                    const SizedBox(height: 16),
                    _buildMealLogSection(
                      meals: dailyNutrition,
                      total: total,
                      nutrition: nutrition,
                      onRemove: (meal) => _confirmDeleteMeal(context, meal, nutritionProvider),
                      onEdit: (meal) => _showEditMealDialog(context, meal, nutritionProvider),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealDialog(context, nutritionProvider),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCompactCalendar(NutritionProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 30)),
        lastDay: DateTime.now().add(const Duration(days: 30)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          markersAlignment: Alignment.bottomCenter,
          markersMaxCount: 1,
          canMarkersOverflow: false,
          cellPadding: EdgeInsets.zero,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: const Icon(Icons.chevron_left, size: 20),
          rightChevronIcon: const Icon(Icons.chevron_right, size: 20),
          titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
          weekendStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                day.day.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            );
          },
          markerBuilder: (context, date, events) {
            final hasData = provider.hasNutritionData(date);
            return hasData
                ? Positioned(
              bottom: 1,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildNutritionSummary(Map<String, dynamic> nutrition, Map<String, int> total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGoalColor(nutrition['goal']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nutrition['goal'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNutritionItem(
            icon: Icons.local_fire_department,
            title: 'Calories',
            value: '${total['calories']}/${nutrition['calories']} kcal',
            color: Colors.orange,
            progress: total['calories']! / nutrition['calories'],
          ),
          _buildNutritionItem(
            icon: Icons.set_meal,
            title: 'Protein',
            value: '${total['protein']}/${nutrition['protein']} g',
            color: Colors.blue,
            progress: total['protein']! / nutrition['protein'],
          ),
          _buildNutritionItem(
            icon: Icons.energy_savings_leaf,
            title: 'Carbs',
            value: '${total['carbs']}/${nutrition['carbs']} g',
            color: Colors.green,
            progress: total['carbs']! / nutrition['carbs'],
          ),
          _buildNutritionItem(
            icon: Icons.opacity,
            title: 'Fats',
            value: '${total['fat']}/${nutrition['fat']} g',
            color: Colors.amber,
            progress: total['fat']! / nutrition['fat'],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required Map<String, dynamic> targets,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macronutrient Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMacroProgressItem(
            label: 'Protein',
            value: protein,
            target: targets['protein'],
            color: Colors.blue,
            icon: Icons.fitness_center,
          ),
          _buildMacroProgressItem(
            label: 'Carbs',
            value: carbs,
            target: targets['carbs'],
            color: Colors.green,
            icon: Icons.energy_savings_leaf,
          ),
          _buildMacroProgressItem(
            label: 'Fats',
            value: fat,
            target: targets['fat'],
            color: Colors.amber,
            icon: Icons.opacity,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressItem({
    required String label,
    required int value,
    required int target,
    required Color color,
    required IconData icon,
  }) {
    final percentage = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final percentageText = '${(percentage * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$percentageText',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: percentage > 0.9 ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedFoods(String goal) {
    final isBulking = goal.toLowerCase().contains('gain');
    final isCutting = goal.toLowerCase().contains('lose');

    final suggestions = [
      if (isBulking || (!isBulking && !isCutting)) ...[
        _buildFoodSuggestion('Chicken breast with rice', Icons.restaurant),
        _buildFoodSuggestion('Eggs and oatmeal', Icons.breakfast_dining),
        _buildFoodSuggestion('Peanut butter toast', Icons.bakery_dining),
        _buildFoodSuggestion('Protein shakes', Icons.local_cafe),
      ],
      if (isCutting || (!isBulking && !isCutting)) ...[
        _buildFoodSuggestion('Grilled fish with salad', Icons.grass),
        _buildFoodSuggestion('Greek yogurt', Icons.icecream),
        _buildFoodSuggestion('Boiled eggs', Icons.egg),
        _buildFoodSuggestion('Mixed nuts', Icons.forest),
      ],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Suggestions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSuggestion(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMealLogSection({
    required List<Map<String, dynamic>> meals,
    required Map<String, int> total,
    required Map<String, dynamic> nutrition,
    required Function(Map<String, dynamic>) onRemove,
    required Function(Map<String, dynamic>) onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meal Log',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${total['calories']} kcal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.fastfood, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No meals logged today',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the + button to add your first meal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...meals.map((meal) => _buildMealItem(meal, onRemove, onEdit)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealItem(
      Map<String, dynamic> meal,
      Function(Map<String, dynamic>) onRemove,
      Function(Map<String, dynamic>) onEdit,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal['name'],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${meal['calories']} kcal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroChip('${meal['protein']}g P', Colors.blue),
              _buildMacroChip('${meal['carbs']}g C', Colors.green),
              _buildMacroChip('${meal['fat']}g F', Colors.amber),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                onPressed: () => onEdit(meal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: Colors.grey.shade600),
                onPressed: () => onRemove(meal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getGoalColor(String goal) {
    switch (goal.toLowerCase()) {
      case 'muscle gain':
        return Colors.blue;
      case 'weight loss':
        return Colors.green;
      case 'endurance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _confirmDeleteMeal(BuildContext context, Map<String, dynamic> meal, NutritionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeMeal(meal, _selectedDay!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted ${meal['name']}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, NutritionProvider provider) {
    final nameController = TextEditingController();
    final proteinController = TextEditingController(text: '0');
    final carbsController = TextEditingController(text: '0');
    final fatController = TextEditingController(text: '0');

    _showMealDialog(
      context: context,
      title: 'Add Meal',
      nameController: nameController,
      proteinController: proteinController,
      carbsController: carbsController,
      fatController: fatController,
      onSave: () {
        final protein = int.tryParse(proteinController.text) ?? 0;
        final carbs = int.tryParse(carbsController.text) ?? 0;
        final fat = int.tryParse(fatController.text) ?? 0;
        final calories = protein * 4 + carbs * 4 + fat * 9;

        if (nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a meal name')),
          );
          return;
        }

        provider.addMeal(
          {
            'name': nameController.text.trim(),
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'calories': calories,
          },
          _selectedDay!,
        );
        Navigator.pop(context);
      },
    );
  }

  void _showEditMealDialog(
      BuildContext context,
      Map<String, dynamic> meal,
      NutritionProvider provider,
      ) {
    final nameController = TextEditingController(text: meal['name']);
    final proteinController = TextEditingController(text: meal['protein'].toString());
    final carbsController = TextEditingController(text: meal['carbs'].toString());
    final fatController = TextEditingController(text: meal['fat'].toString());

    _showMealDialog(
      context: context,
      title: 'Edit Meal',
      nameController: nameController,
      proteinController: proteinController,
      carbsController: carbsController,
      fatController: fatController,
      onSave: () {
        final protein = int.tryParse(proteinController.text) ?? 0;
        final carbs = int.tryParse(carbsController.text) ?? 0;
        final fat = int.tryParse(fatController.text) ?? 0;
        final calories = protein * 4 + carbs * 4 + fat * 9;

        if (nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a meal name')),
          );
          return;
        }

        provider.removeMeal(meal, _selectedDay!);
        provider.addMeal(
          {
            'name': nameController.text.trim(),
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'calories': calories,
          },
          _selectedDay!,
        );
        Navigator.pop(context);
      },
    );
  }

  void _showMealDialog({
    required BuildContext context,
    required String title,
    required TextEditingController nameController,
    required TextEditingController proteinController,
    required TextEditingController carbsController,
    required TextEditingController fatController,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: proteinController,
                    decoration: InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: carbsController,
                    decoration: InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: fatController,
                    decoration: InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Calories:'),
                  Builder(
                    builder: (context) {
                      final protein = int.tryParse(proteinController.text) ?? 0;
                      final carbs = int.tryParse(carbsController.text) ?? 0;
                      final fat = int.tryParse(fatController.text) ?? 0;
                      final calories = protein * 4 + carbs * 4 + fat * 9;
                      return Text(
                        '$calories kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}