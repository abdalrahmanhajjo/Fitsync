import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/workout_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/workout_provider.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      Future.delayed(const Duration(milliseconds: 300), () {
        workoutProvider.loadFavorites(['1', '3', '5']);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;

    final fitnessLevel = user?.fitnessLevel != null
        ? WorkoutDifficulty.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == user!.fitnessLevel?.toLowerCase(),
      orElse: () => WorkoutDifficulty.intermediate,
    )
        : WorkoutDifficulty.intermediate;

    final filteredWorkouts = _filterWorkouts(workoutProvider, fitnessLevel);

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
          'Workouts',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
            onPressed: () => _showFilterDialog(context, workoutProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search workouts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFilterChip(
                    icon: Icons.star,
                    label: 'Favorites',
                    active: workoutProvider.showFavoritesOnly,
                    onTap: workoutProvider.toggleShowFavoritesOnly,
                    activeColor: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  if (user != null)
                    _buildFilterChip(
                      icon: Icons.thumb_up,
                      label: 'Recommended',
                      active: workoutProvider.showRecommendedOnly,
                      onTap: workoutProvider.toggleShowRecommendedOnly,
                      activeColor: Colors.green,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredWorkouts.isEmpty
                    ? _buildEmptyState(workoutProvider)
                    : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredWorkouts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final workout = filteredWorkouts[index];
                    return _buildWorkoutCard(context, workout, workoutProvider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: active ? activeColor : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: active,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: activeColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: active ? activeColor : Colors.black,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: active ? activeColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildEmptyState(WorkoutProvider workoutProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (workoutProvider.showFavoritesOnly)
            Text(
              'You haven\'t marked any workouts as favorites yet',
              style: TextStyle(color: Colors.grey[500]),
            ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  workoutProvider.clearFilters();
                });
              },
              child: const Text('Clear search and filters'),
            ),
        ],
      ),
    );
  }

  List<Workout> _filterWorkouts(WorkoutProvider workoutProvider, WorkoutDifficulty? userFitnessLevel) {
    List<Workout> allWorkouts = _getDummyWorkouts();

    return allWorkouts.where((workout) {
      if (workoutProvider.showFavoritesOnly && !workoutProvider.isFavorite(workout.id)) {
        return false;
      }

      if (workoutProvider.showRecommendedOnly && !workout.matchesDifficulty(userFitnessLevel!)) {
        return false;
      }

      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty &&
          !workout.title.toLowerCase().contains(searchQuery) &&
          !workout.description.toLowerCase().contains(searchQuery)) {
        return false;
      }

      if (workoutProvider.selectedDifficulty != null &&
          workout.difficulty != workoutProvider.selectedDifficulty) {
        return false;
      }

      if (workoutProvider.selectedMuscleGroup != null &&
          !workout.primaryMuscleGroups.contains(workoutProvider.selectedMuscleGroup) &&
          !workout.secondaryMuscleGroups.contains(workoutProvider.selectedMuscleGroup)) {
        return false;
      }

      if (workoutProvider.selectedWorkoutType != null &&
          workout.type != workoutProvider.selectedWorkoutType) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout, WorkoutProvider workoutProvider) {
    final isFavorite = workoutProvider.isFavorite(workout.id);
    final wasRecentlyCompleted = workoutProvider.wasRecentlyCompleted(workout.id);
    final isCompletedToday = workoutProvider.isWorkoutCompletedToday(workout.id);

    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToWorkoutDetail(context, workout, workoutProvider),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (workout.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      workout.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () => workoutProvider.toggleFavorite(workout.id),
                  ),
                ),
                if (wasRecentlyCompleted || isCompletedToday)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompletedToday ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompletedToday ? Icons.check_circle : Icons.history,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompletedToday ? 'Completed' : 'Recent',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          workout.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(workout.difficulty).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workout.difficulty.displayName,
                          style: TextStyle(
                            color: _getDifficultyColor(workout.difficulty),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workout.description,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildWorkoutInfoChip(
                        icon: Icons.timer,
                        text: workout.formattedDuration,
                      ),
                      const SizedBox(width: 8),
                      _buildWorkoutInfoChip(
                        icon: Icons.local_fire_department,
                        text: '${workout.calories} cal',
                      ),
                      const Spacer(),
                      Text(
                        workout.type.displayName,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return Colors.green;
      case WorkoutDifficulty.intermediate:
        return Colors.orange;
      case WorkoutDifficulty.advanced:
        return Colors.red;
    }
  }

  Widget _buildWorkoutInfoChip({required IconData icon, required String text}) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey.shade100,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 16),
    );
  }

  Future<void> _showFilterDialog(BuildContext context, WorkoutProvider workoutProvider) async {
    WorkoutDifficulty? tempDifficulty = workoutProvider.selectedDifficulty;
    MuscleGroup? tempMuscleGroup = workoutProvider.selectedMuscleGroup;
    WorkoutType? tempWorkoutType = workoutProvider.selectedWorkoutType;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Workouts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFilterSection(
                      title: 'Difficulty',
                      selectedValue: tempDifficulty,
                      values: WorkoutDifficulty.values,
                      displayText: (value) => value.displayName,
                      onChanged: (value) => tempDifficulty = value,
                    ),
                    _buildFilterSection(
                      title: 'Muscle Group',
                      selectedValue: tempMuscleGroup,
                      values: MuscleGroup.values,
                      displayText: (value) => value.displayName,
                      onChanged: (value) => tempMuscleGroup = value,
                    ),
                    _buildFilterSection(
                      title: 'Workout Type',
                      selectedValue: tempWorkoutType,
                      values: WorkoutType.values,
                      displayText: (value) => value.displayName,
                      onChanged: (value) => tempWorkoutType = value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      workoutProvider.clearFilters();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      workoutProvider.setFilters(
                        difficulty: tempDifficulty,
                        muscleGroup: tempMuscleGroup,
                        workoutType: tempWorkoutType,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection<T>({
    required String title,
    required T? selectedValue,
    required List<T> values,
    required String Function(T) displayText,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selectedValue == null,
                onSelected: (_) => onChanged(null),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selectedValue == null ? Theme.of(context).primaryColor : Colors.black,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedValue == null ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  ),
                ),
              ),
              ...values.map((value) {
                return ChoiceChip(
                  label: Text(displayText(value)),
                  selected: selectedValue == value,
                  onSelected: (_) => onChanged(value),
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selectedValue == value ? Theme.of(context).primaryColor : Colors.black,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selectedValue == value ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToWorkoutDetail(BuildContext context, Workout workout, WorkoutProvider workoutProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutProgressScreen(workout: workout),
      ),
    ).then((_) {
      workoutProvider.completeWorkout(workout.id);
    });
  }

  List<Workout> _getDummyWorkouts() {
    return [
      Workout(
        id: '1',
        title: 'Beginner Full Body',
        description: 'Perfect for starters, targets all major muscle groups',
        difficulty: WorkoutDifficulty.beginner,
        duration: 30,
        primaryMuscleGroups: [MuscleGroup.fullBody],
        secondaryMuscleGroups: [],
        type: WorkoutType.strength,
        calories: 200,
        imageUrl: 'assets/workouts/full_body.jpg',
        exercises: [
          WorkoutExercise(
            id: '1-1',
            name: 'Push-ups',
            description: 'Standard push-ups targeting chest and triceps',
            targetedMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
            sets: 3,
            reps: 10,
            restPeriod: 60,
            imageUrl: 'assets/exercises/pushups.jpg',
          ),
          WorkoutExercise(
            id: '1-2',
            name: 'Squats',
            description: 'Bodyweight squats',
            targetedMuscles: [MuscleGroup.legs, MuscleGroup.glutes],
            sets: 3,
            reps: 15,
            restPeriod: 60,
            imageUrl: 'assets/exercises/squats.jpg',
          ),
          WorkoutExercise(
            id: '1-3',
            name: 'Plank',
            description: 'Core stabilization exercise',
            targetedMuscles: [MuscleGroup.abs, MuscleGroup.shoulders],
            sets: 3,
            duration: 30,
            reps: 0,
            restPeriod: 60,
            imageUrl: 'assets/exercises/plank.jpg',
          ),
        ],
      ),
      Workout(
        id: '2',
        title: 'Intermediate Upper Body',
        description: 'Focus on chest, shoulders and arms',
        difficulty: WorkoutDifficulty.intermediate,
        duration: 45,
        primaryMuscleGroups: [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.arms],
        secondaryMuscleGroups: [MuscleGroup.triceps, MuscleGroup.biceps],
        type: WorkoutType.strength,
        calories: 300,
        imageUrl: 'assets/workouts/upper_body.jpg',
        exercises: [
          WorkoutExercise(
            id: '2-1',
            name: 'Bench Press',
            description: 'Barbell bench press',
            targetedMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
            sets: 4,
            reps: 8,
            restPeriod: 90,
            imageUrl: 'assets/exercises/bench_press.jpg',
          ),
          WorkoutExercise(
            id: '2-2',
            name: 'Shoulder Press',
            description: 'Dumbbell shoulder press',
            targetedMuscles: [MuscleGroup.shoulders],
            sets: 3,
            reps: 10,
            restPeriod: 60,
            imageUrl: 'assets/exercises/shoulder_press.jpg',
          ),
          WorkoutExercise(
            id: '2-3',
            name: 'Bicep Curls',
            description: 'Dumbbell bicep curls',
            targetedMuscles: [MuscleGroup.biceps],
            sets: 3,
            reps: 12,
            restPeriod: 60,
            imageUrl: 'assets/exercises/bicep_curls.jpg',
          ),
        ],
      ),
      Workout(
        id: '3',
        title: 'Advanced HIIT',
        description: 'High intensity interval training for fat burning',
        difficulty: WorkoutDifficulty.advanced,
        duration: 25,
        primaryMuscleGroups: [MuscleGroup.fullBody],
        secondaryMuscleGroups: [],
        type: WorkoutType.hiit,
        calories: 350,
        imageUrl: 'assets/workouts/hiit.jpg',
        exercises: [
          WorkoutExercise(
            id: '3-1',
            name: 'Burpees',
            description: 'Full body explosive movement',
            targetedMuscles: [MuscleGroup.fullBody],
            sets: 4,
            reps: 15,
            restPeriod: 30,
            imageUrl: 'assets/exercises/burpees.jpg',
          ),
          WorkoutExercise(
            id: '3-2',
            name: 'Jump Squats',
            description: 'Explosive squat jumps',
            targetedMuscles: [MuscleGroup.legs, MuscleGroup.glutes],
            sets: 4,
            reps: 20,
            restPeriod: 30,
            imageUrl: 'assets/exercises/jump_squats.jpg',
          ),
          WorkoutExercise(
            id: '3-3',
            name: 'Mountain Climbers',
            description: 'Fast core and cardio exercise',
            targetedMuscles: [MuscleGroup.abs, MuscleGroup.shoulders],
            sets: 4,
            duration: 45,
            reps: 0,
            restPeriod: 30,
            imageUrl: 'assets/exercises/mountain_climbers.jpg',
          ),
        ],
      ),
      Workout(
        id: '4',
        title: 'Yoga Flow',
        description: 'Relaxing yoga sequence for flexibility and mindfulness',
        difficulty: WorkoutDifficulty.beginner,
        duration: 40,
        primaryMuscleGroups: [MuscleGroup.fullBody],
        secondaryMuscleGroups: [],
        type: WorkoutType.yoga,
        calories: 180,
        imageUrl: 'assets/workouts/yoga.jpg',
        exercises: [
          WorkoutExercise(
            id: '4-1',
            name: 'Sun Salutation',
            description: 'Classic yoga warm-up sequence',
            targetedMuscles: [MuscleGroup.fullBody],
            sets: 1,
            duration: 300,
            reps: 0,
            restPeriod: 0,
            imageUrl: 'assets/exercises/sun_salutation.jpg',
          ),
          WorkoutExercise(
            id: '4-2',
            name: 'Warrior Poses',
            description: 'Warrior I, II and III sequence',
            targetedMuscles: [MuscleGroup.legs, MuscleGroup.abs],
            sets: 1,
            duration: 180,
            reps: 0,
            restPeriod: 0,
            imageUrl: 'assets/exercises/warrior_pose.jpg',
          ),
        ],
      ),
      Workout(
        id: '5',
        title: 'Core Blaster',
        description: 'Intense core workout for strong abs',
        difficulty: WorkoutDifficulty.intermediate,
        duration: 20,
        primaryMuscleGroups: [MuscleGroup.abs],
        secondaryMuscleGroups: [MuscleGroup.back],
        type: WorkoutType.strength,
        calories: 220,
        imageUrl: 'assets/workouts/core.jpg',
        exercises: [
          WorkoutExercise(
            id: '5-1',
            name: 'Hanging Leg Raises',
            description: 'Advanced core exercise',
            targetedMuscles: [MuscleGroup.abs],
            sets: 3,
            reps: 12,
            restPeriod: 45,
            imageUrl: 'assets/exercises/leg_raises.jpg',
          ),
          WorkoutExercise(
            id: '5-2',
            name: 'Russian Twists',
            description: 'Weighted oblique exercise',
            targetedMuscles: [MuscleGroup.abs],
            sets: 3,
            reps: 20,
            restPeriod: 45,
            imageUrl: 'assets/exercises/russian_twists.jpg',
          ),
          WorkoutExercise(
            id: '5-3',
            name: 'Plank to Push-up',
            description: 'Core and shoulder stability',
            targetedMuscles: [MuscleGroup.abs, MuscleGroup.shoulders],
            sets: 3,
            duration: 45,
            reps: 0,
            restPeriod: 45,
            imageUrl: 'assets/exercises/plank_pushup.jpg',
          ),
        ],
      ),
      Workout(
        id: '6',
        title: 'Leg Day Special',
        description: 'Comprehensive leg workout for strength and size',
        difficulty: WorkoutDifficulty.advanced,
        duration: 50,
        primaryMuscleGroups: [MuscleGroup.legs],
        secondaryMuscleGroups: [MuscleGroup.glutes],
        type: WorkoutType.strength,
        calories: 400,
        imageUrl: 'assets/workouts/legs.jpg',
        exercises: [
          WorkoutExercise(
            id: '6-1',
            name: 'Barbell Squats',
            description: 'Heavy squats with barbell',
            targetedMuscles: [MuscleGroup.legs, MuscleGroup.glutes],
            sets: 4,
            reps: 6,
            restPeriod: 120,
            imageUrl: 'assets/exercises/barbell_squats.jpg',
          ),
          WorkoutExercise(
            id: '6-2',
            name: 'Romanian Deadlifts',
            description: 'Hamstring focused deadlift variation',
            targetedMuscles: [MuscleGroup.legs, MuscleGroup.glutes],
            sets: 3,
            reps: 8,
            restPeriod: 90,
            imageUrl: 'assets/exercises/romanian_deadlifts.jpg',
          ),
          WorkoutExercise(
            id: '6-3',
            name: 'Bulgarian Split Squats',
            description: 'Unilateral leg exercise',
            targetedMuscles: [MuscleGroup.legs],
            sets: 3,
            reps: 10,
            restPeriod: 60,
            imageUrl: 'assets/exercises/split_squats.jpg',
          ),
        ],
      ),
      Workout(
        id: '7',
        title: 'Upper Body Burner',
        description: 'High volume upper body workout',
        difficulty: WorkoutDifficulty.intermediate,
        duration: 40,
        primaryMuscleGroups: [MuscleGroup.chest, MuscleGroup.back],
        secondaryMuscleGroups: [MuscleGroup.arms],
        type: WorkoutType.strength,
        calories: 320,
        imageUrl: 'assets/workouts/upper_body_burner.jpg',
        exercises: [
          WorkoutExercise(
            id: '7-1',
            name: 'Pull-ups',
            description: 'Bodyweight back exercise',
            targetedMuscles: [MuscleGroup.back, MuscleGroup.biceps],
            sets: 4,
            reps: 8,
            restPeriod: 90,
            imageUrl: 'assets/exercises/pullups.jpg',
          ),
          WorkoutExercise(
            id: '7-2',
            name: 'Dips',
            description: 'Chest and triceps focused',
            targetedMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
            sets: 4,
            reps: 10,
            restPeriod: 90,
            imageUrl: 'assets/exercises/dips.jpg',
          ),
          WorkoutExercise(
            id: '7-3',
            name: 'Incline Dumbbell Press',
            description: 'Upper chest focus',
            targetedMuscles: [MuscleGroup.chest],
            sets: 3,
            reps: 12,
            restPeriod: 75,
            imageUrl: 'assets/exercises/incline_press.jpg',
          ),
        ],
      ),
      Workout(
        id: '8',
        title: 'Cardio Blast',
        description: '30 minute intense cardio session',
        difficulty: WorkoutDifficulty.intermediate,
        duration: 30,
        primaryMuscleGroups: [MuscleGroup.fullBody],
        secondaryMuscleGroups: [],
        type: WorkoutType.cardio,
        calories: 350,
        imageUrl: 'assets/workouts/cardio.jpg',
        exercises: [
          WorkoutExercise(
            id: '8-1',
            name: 'Treadmill Intervals',
            description: 'Alternate between sprint and recovery',
            targetedMuscles: [MuscleGroup.legs],
            sets: 1,
            duration: 900,
            reps: 0,
            restPeriod: 0,
            imageUrl: 'assets/exercises/treadmill.jpg',
          ),
        ],
      ),
      Workout(
        id: '9',
        title: 'Mobility Routine',
        description: 'Improve flexibility and joint health',
        difficulty: WorkoutDifficulty.beginner,
        duration: 20,
        primaryMuscleGroups: [MuscleGroup.fullBody],
        secondaryMuscleGroups: [],
        type: WorkoutType.mobility,
        calories: 120,
        imageUrl: 'assets/workouts/mobility.jpg',
        exercises: [
          WorkoutExercise(
            id: '9-1',
            name: 'Dynamic Stretching',
            description: 'Full body dynamic movements',
            targetedMuscles: [MuscleGroup.fullBody],
            sets: 1,
            duration: 600,
            reps: 0,
            restPeriod: 0,
            imageUrl: 'assets/exercises/dynamic_stretching.jpg',
          ),
          WorkoutExercise(
            id: '9-2',
            name: 'Foam Rolling',
            description: 'Myofascial release techniques',
            targetedMuscles: [MuscleGroup.fullBody],
            sets: 1,
            duration: 600,
            reps: 0,
            restPeriod: 0,
            imageUrl: 'assets/exercises/foam_rolling.jpg',
          ),
        ],
      ),
      Workout(
        id: '10',
        title: 'Bodyweight Challenge',
        description: 'No equipment needed full body workout',
        difficulty: WorkoutDifficulty.advanced,
        duration: 35,
        primaryMuscleGroups: [MuscleGroup.fullBody],
        secondaryMuscleGroups: [],
        type: WorkoutType.strength,
        calories: 380,
        imageUrl: 'assets/workouts/bodyweight.jpg',
        exercises: [
          WorkoutExercise(
            id: '10-1',
            name: 'Pistol Squats',
            description: 'Single leg squats',
            targetedMuscles: [MuscleGroup.legs],
            sets: 3,
            reps: 8,
            restPeriod: 60,
            imageUrl: 'assets/exercises/pistol_squats.jpg',
          ),
          WorkoutExercise(
            id: '10-2',
            name: 'Archer Push-ups',
            description: 'Advanced push-up variation',
            targetedMuscles: [MuscleGroup.chest, MuscleGroup.arms],
            sets: 3,
            reps: 10,
            restPeriod: 60,
            imageUrl: 'assets/exercises/archer_pushups.jpg',
          ),
          WorkoutExercise(
            id: '10-3',
            name: 'Dragon Flags',
            description: 'Advanced core exercise',
            targetedMuscles: [MuscleGroup.abs],
            sets: 3,
            reps: 6,
            restPeriod: 90,
            imageUrl: 'assets/exercises/dragon_flags.jpg',
          ),
        ],
      ),
    ];
  }
}

class WorkoutProgressScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutProgressScreen({Key? key, required this.workout}) : super(key: key);

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  int _restTimeRemaining = 0;
  late Timer _restTimer;
  bool _workoutCompleted = false;
  final Map<String, int> _completedReps = {};
  final Map<String, bool> _exerciseCompleted = {};

  @override
  void initState() {
    super.initState();
    _restTimeRemaining = widget.workout.exercises[_currentExerciseIndex].restPeriod;
    for (var exercise in widget.workout.exercises) {
      _completedReps[exercise.id] = exercise.reps;
      _exerciseCompleted[exercise.id] = false;
    }
  }

  @override
  void dispose() {
    _restTimer.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    _isResting = true;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_restTimeRemaining > 0) {
          _restTimeRemaining--;
        } else {
          _isResting = false;
          timer.cancel();
        }
      });
    });
  }

  void _nextSetOrExercise() {
    if (_currentSet < widget.workout.exercises[_currentExerciseIndex].sets) {
      setState(() {
        _currentSet++;
        _restTimeRemaining = widget.workout.exercises[_currentExerciseIndex].restPeriod;
        _startRestTimer();
      });
    } else if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _restTimeRemaining = widget.workout.exercises[_currentExerciseIndex].restPeriod;
        _startRestTimer();
      });
    } else {
      setState(() {
        _workoutCompleted = true;
      });
      _showCompletionDialog();
    }
  }

  void _markSetCompleted() {
    if (_isResting) {
      _restTimer.cancel();
      _isResting = false;
      _nextSetOrExercise();
    } else {
      _startRestTimer();
    }
  }

  void _showCompletionDialog() {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.completeWorkout(widget.workout.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'You completed ${widget.workout.title}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Total time: ${widget.workout.formattedDuration}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated calories burned: ${widget.workout.calories}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _adjustReps(String exerciseId, int change) {
    setState(() {
      _completedReps[exerciseId] = (_completedReps[exerciseId] ?? 0) + change;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_workoutCompleted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    final totalExercises = widget.workout.exercises.length;
    final totalSets = currentExercise.sets;

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
          widget.workout.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: _showWorkoutInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentExerciseIndex + (_currentSet / totalSets)) / totalExercises,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise ${_currentExerciseIndex + 1}/$totalExercises',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentExercise.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set $_currentSet/$totalSets',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (currentExercise.imageUrl != null)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(currentExercise.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        currentExercise.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (currentExercise.duration != null) ...[
                        const SizedBox(height: 16),
                        _buildExerciseDetailRow(
                          icon: Icons.timer,
                          label: 'Duration',
                          value: '${currentExercise.duration} seconds',
                        ),
                      ],
                      if (currentExercise.reps > 0) ...[
                        const SizedBox(height: 16),
                        _buildExerciseDetailRow(
                          icon: Icons.repeat,
                          label: 'Reps',
                          value: '${_completedReps[currentExercise.id] ?? currentExercise.reps}',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 32),
                              color: Theme.of(context).primaryColor,
                              onPressed: () => _adjustReps(currentExercise.id, -1),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 32),
                              color: Theme.of(context).primaryColor,
                              onPressed: () => _adjustReps(currentExercise.id, 1),
                            ),
                          ],
                        ),
                      ],
                      if (currentExercise.equipment != null) ...[
                        const SizedBox(height: 16),
                        _buildExerciseDetailRow(
                          icon: Icons.fitness_center,
                          label: 'Equipment',
                          value: currentExercise.equipment!,
                        ),
                      ],
                      if (currentExercise.notes != null) ...[
                        const SizedBox(height: 16),
                        _buildExerciseDetailRow(
                          icon: Icons.lightbulb_outline,
                          label: 'Tips',
                          value: currentExercise.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isResting) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rest Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_restTimeRemaining seconds remaining',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Next: ${_currentSet < totalSets ? 'Set ${_currentSet + 1}' : 'Next Exercise'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markSetCompleted,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isResting ? 'Skip Rest' : 'Complete Set',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWorkoutInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workout Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWorkoutInfoRow(
                      icon: Icons.fitness_center,
                      label: 'Difficulty',
                      value: widget.workout.difficulty.displayName,
                    ),
                    _buildWorkoutInfoRow(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: widget.workout.formattedDuration,
                    ),
                    _buildWorkoutInfoRow(
                      icon: Icons.local_fire_department,
                      label: 'Calories',
                      value: '${widget.workout.calories} cal',
                    ),
                    _buildWorkoutInfoRow(
                      icon: Icons.category,
                      label: 'Type',
                      value: widget.workout.type.displayName,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.workout.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Exercises (${widget.workout.exercises.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.workout.exercises.map((exercise) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.workout.exercises.indexOf(exercise) + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (exercise.sets > 0)
                                  Text(
                                    '${exercise.sets} sets • ${exercise.reps} reps',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (exercise.duration != null)
                                  Text(
                                    '${exercise.duration} seconds',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}