import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/goal_entity.dart';
import '../bloc/goals_bloc.dart';
import '../bloc/goals_event.dart';

class GoalDetailPage extends StatefulWidget {
  final String? goalId;

  const GoalDetailPage({super.key, this.goalId});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();

  String _selectedCategory = AppConstants.goalCategories[0];
  DateTime? _targetDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGoalIfEdit();
  }

  void _loadGoalIfEdit() async {
    if (widget.goalId != null) {
      setState(() => _isLoading = true);
      // In a real app, we'd load the goal from the repository
      // For now, we'll just show the form empty
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalId == null ? 'New Goal' : 'Edit Goal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create a new wellness goal',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingL),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g., Meditate daily',
                        prefixIcon: Icon(Icons.emoji_events),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What do you want to achieve?',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppConstants.goalCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    TextFormField(
                      controller: _targetValueController,
                      decoration: const InputDecoration(
                        labelText: 'Target (days/sessions)',
                        hintText: 'e.g., 30',
                        prefixIcon: Icon(Icons.track_changes),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a target value';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    InkWell(
                      onTap: () => _selectTargetDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Target Date (Optional)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _targetDate == null
                              ? 'Select a target date'
                              : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXL),
                    ElevatedButton(
                      onPressed: _saveGoal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Goal'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _targetDate) {
      setState(() => _targetDate = picked);
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = GoalEntity(
        id: widget.goalId ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        targetValue: int.parse(_targetValueController.text),
        createdAt: DateTime.now(),
        targetDate: _targetDate,
      );

      if (widget.goalId == null) {
        context.read<GoalsBloc>().add(AddGoal(goal));
      } else {
        context.read<GoalsBloc>().add(UpdateGoal(goal));
      }

      context.pop();
    }
  }
}
