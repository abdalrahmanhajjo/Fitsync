import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _obscurePassword = true;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Fitness data
  String? _selectedFitnessLevel;
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _selectedGoals = [];
  final List<String> _availableGoals = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Flexibility',
    'General Fitness'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _currentStep > 0
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: _previousStep,
      )
          : null,
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentStep == index ? 24 : 12,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentStep == index
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s get you started on your fitness journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your email';
            if (!value!.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade500,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Password is required'
              : value.length < PasswordRules.minLength
              ? 'Minimum ${PasswordRules.minLength} characters'
              : PasswordRules.requireUppercase && !value.contains(RegExp(r'[A-Z]'))
              ? 'At least one uppercase letter'
              : PasswordRules.requireNumbers && !value.contains(RegExp(r'[0-9]'))
              ? 'At least one number'
              : PasswordRules.requireSpecialChars && !value.contains(RegExp('[${PasswordRules.specialChars}]'))
              ? 'At least one special character'
              : null,
        
        ),
      ],
    );
  }

  Widget _buildPhysicalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Your Body Stats',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your experience',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  final weight = double.tryParse(value!);
                  if (weight == null) return 'Invalid number';
                  if (weight < 30 || weight > 300) return 'Enter realistic weight';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Height',
                  prefixIcon: const Icon(Icons.height_outlined),
                  suffixText: 'm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  final height = double.tryParse(value!);
                  if (height == null) return 'Invalid number';
                  if (height < 1 || height > 3) return 'Enter realistic height';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFitnessInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Your Fitness Goals',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select what you want to achieve',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        DropdownButtonFormField<String>(
          value: _selectedFitnessLevel,
          decoration: InputDecoration(
            labelText: 'Fitness Level',
            prefixIcon: const Icon(Icons.fitness_center_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _fitnessLevels.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedFitnessLevel = value),
          validator: (value) => value == null ? 'Please select your level' : null,
        ),
        const SizedBox(height: 24),
        Text(
          'Select Goals (Choose at least one)',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
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
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGoals.add(goal);
                  } else {
                    _selectedGoals.remove(goal);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (_currentStep < 2) {
              _nextStep();
            } else {
              _submitForm();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          child: authProvider.isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          )
              : Text(
            _currentStep < 2 ? 'Continue' : 'Get Started',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one fitness goal')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        fitnessLevel: _selectedFitnessLevel!,
        fitnessGoals: _selectedGoals,
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonalInfoStep(),
                      _buildPhysicalInfoStep(),
                      _buildFitnessInfoStep(),
                    ],
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRules {
  static const int minLength = 8;
  static const bool requireUppercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;
  static const String specialChars = r'!@#$%^&*(),.?":{}|<>';
}