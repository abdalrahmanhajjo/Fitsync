import 'package:fitsync/features/auth/providers/nutrition_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitsync/features/auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String? _selectedFitnessLevel;
  List<String> _selectedGoals = [];
  bool _isLoading = false;

  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _availableGoals = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Flexibility',
    'General Fitness'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _weightController = TextEditingController(text: user?.weight?.toStringAsFixed(1) ?? '');
    _heightController = TextEditingController(text: user?.height?.toStringAsFixed(2) ?? '');
    _selectedFitnessLevel = user?.fitnessLevel;
    _selectedGoals = user?.fitnessGoals?.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isEditing = authProvider.isEditingProfile;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view profile',
              style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isEditing)
            TextButton(
              onPressed: () => authProvider.toggleEditingProfile(),
              child: const Text('EDIT',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'My Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your personal and fitness information',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  enabled: isEditing,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: isEditing,
                ),
                const SizedBox(height: 24),

                // Fitness Information Section
                Text(
                  'Fitness Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label: 'Weight',
                        icon: Icons.monitor_weight_outlined,
                        suffixText: 'kg',
                        keyboardType: TextInputType.number,
                        enabled: isEditing,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: 'Height',
                        icon: Icons.height_outlined,
                        suffixText: 'm',
                        keyboardType: TextInputType.number,
                        enabled: isEditing,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFitnessLevelDropdown(isEditing),
                const SizedBox(height: 24),

                // Fitness Goals Section
                Text(
                  'Fitness Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildGoalsChips(isEditing),
                const SizedBox(height: 32),

                // Save/Cancel Buttons
                if (isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleSave(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => authProvider.toggleEditingProfile(),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? suffixText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildFitnessLevelDropdown(bool isEditing) {
    return DropdownButtonFormField<String>(
      value: _selectedFitnessLevel,
      decoration: InputDecoration(
        labelText: 'Fitness Level',
        prefixIcon: const Icon(Icons.fitness_center_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: isEditing ? Colors.grey.shade50 : Colors.grey.shade200,
      ),
      items: _fitnessLevels.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level),
        );
      }).toList(),
      onChanged: isEditing
          ? (value) => setState(() => _selectedFitnessLevel = value)
          : null,
    );
  }

  Widget _buildGoalsChips(bool isEditing) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableGoals.map((goal) {
        return ChoiceChip(
          label: Text(goal),
          selected: _selectedGoals.contains(goal),
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: _selectedGoals.contains(goal)
                ? Theme.of(context).primaryColor
                : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _selectedGoals.contains(goal)
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
            ),
          ),
          onSelected: isEditing
              ? (selected) {
            setState(() {
              if (selected) {
                _selectedGoals.add(goal);
              } else {
                _selectedGoals.remove(goal);
              }
            });
          }
              : null,
        );
      }).toList(),
    );
  }

  Future<void> _handleSave(AuthProvider authProvider) async {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one fitness goal')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the nutrition provider
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);

      // Update user in auth provider
      await authProvider.updateUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        fitnessLevel: _selectedFitnessLevel,
        fitnessGoals: _selectedGoals,
      );

      // Also update the nutrition provider with the new user data
      if (authProvider.currentUser != null) {
        nutritionProvider.setUser(authProvider.currentUser!);
      }

      authProvider.toggleEditingProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}