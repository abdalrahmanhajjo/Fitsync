import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitsync/data/models/workout_model.dart';
import 'package:fitsync/features/auth/providers/auth_provider.dart';
import 'package:fitsync/features/auth/providers/workout_provider.dart';
import 'package:fitsync/features/auth/providers/nutrition_provider.dart';
import 'package:fitsync/features/auth/providers/progress_provider.dart';
import 'package:fitsync/features/workouts/screens/workout_list_screen.dart';
import 'package:fitsync/features/nutrition/screens/nutrition_screen.dart';
import 'package:fitsync/features/progress/screens/progress_screen.dart';
import 'package:fitsync/features/profile/screens/profile_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);

    final user = authProvider.currentUser;
    final userName = user?.name.split(' ').first ?? 'User';
    final completedWorkouts = workoutProvider.uniqueCompletedWorkoutCount;
    final completedToday = workoutProvider.getTodayCompletedWorkouts().length;
    final activeDays = progressProvider.getActiveDaysCount(ProgressTimeRange.week);
    final calorieIntake = nutritionProvider.getTodayCalories();
    final todaysWorkout = workoutProvider.getTodaysWorkout();
    final recentActivities = progressProvider.getRecentActivities(limit: 3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: false,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Card
                _buildWelcomeCard(context, userName),
                const SizedBox(height: 24),

                // Weekly Progress

                const SizedBox(height: 24),

                // Quick Stats
                _buildQuickStats(
                  context,
                  workouts: completedWorkouts,
                  calories: calorieIntake,
                  activeDays: activeDays,
                ),
                const SizedBox(height: 24),

                // Today's Focus
                if (todaysWorkout != null) ...[
                  _buildTodaysFocus(
                    context,
                    workout: todaysWorkout,
                    isCompleted: workoutProvider.isWorkoutCompletedToday(todaysWorkout.id),
                    onComplete: () => _completeWorkoutWithFeedback(context, todaysWorkout),
                  ),
                  const SizedBox(height: 24),
                ],

                // Features Grid
                _buildFeaturesGrid(context),
                const SizedBox(height: 24),

                // Recent Activity
                if (recentActivities.isNotEmpty) ...[
                  _buildSectionHeader('Recent Activity'),
                  const SizedBox(height: 16),
                  ...recentActivities.map((activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityCard(
                      icon: _getActivityIcon(activity.workoutId),
                      title: activity.workoutName,
                      time: _formatTimeAgo(activity.completedAt),
                    ),
                  )),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to crush your goals today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            child: Icon(
              Icons.waving_hand,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickStats(
      BuildContext context, {
        required int workouts,
        required int calories,
        required int activeDays,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Stats'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                value: workouts.toString(),
                label: 'Workouts',
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: _buildStatItem(
                context,
                value: calories.toString(),
                label: 'Calories',
                icon: Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 12),

          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, {
        required String value,
        required String label,
        required IconData icon,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysFocus(
      BuildContext context, {
        required Workout workout,
        required bool isCompleted,
        required VoidCallback onComplete,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Today's Focus"),
        const SizedBox(height: 16),
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    workout.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildWorkoutDetail(
                    icon: Icons.timer,
                    value: '${workout.duration} min',
                  ),
                  const SizedBox(width: 16),
                  _buildWorkoutDetail(
                    icon: Icons.local_fire_department,
                    value: '${workout.calories} cal',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCompleted ? null : onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? Colors.grey.shade300
                        : Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Mark Complete',
                    style: TextStyle(
                      color: isCompleted ? Colors.grey.shade600 : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutDetail({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Features'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildFeatureButton(
              context,
              icon: Icons.fitness_center,
              label: 'Workouts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WorkoutListScreen()),
              ),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.restaurant,
              label: 'Nutrition',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              ),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.show_chart,
              label: 'Progress',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProgressScreen()),
              ),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.person,
              label: 'Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Workout completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Future<void> _completeWorkoutWithFeedback(BuildContext context, Workout workout) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completing workout...'),
          duration: Duration(seconds: 1),
        ),
      );

      await Provider.of<WorkoutProvider>(context, listen: false)
          .completeWorkout(workout.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${workout.title} completed!'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete workout: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'workout':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'measurement':
        return Icons.straighten;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}