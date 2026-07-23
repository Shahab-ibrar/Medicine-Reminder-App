import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/providers/medicine_provider.dart';

class AddEditMedicineScreen extends StatefulWidget {
  const AddEditMedicineScreen({super.key});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isEditing = false;
  Medicine? _editingMedicine;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Medicine && !_isEditing) {
      _isEditing = true;
      _editingMedicine = args;
      _nameController.text = args.medicineName;
      _dosageController.text = args.dosage;
      _notesController.text = args.notes;

      _selectedDate = DateTime.tryParse(args.date) ?? DateTime.now();

      try {
        final timeClean = args.time.trim();
        final amPm = timeClean.substring(timeClean.length - 2).toUpperCase();
        final parts = timeClean.substring(0, timeClean.length - 2).trim().split(':');
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        if (amPm == 'PM' && hour < 12) {
          hour += 12;
        } else if (amPm == 'AM' && hour == 12) {
          hour = 0;
        }
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        _selectedTime = TimeOfDay.now();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _formatTimeOfDay(_selectedTime);

    bool success;

    if (_isEditing && _editingMedicine != null) {
      final updatedMed = _editingMedicine!.copyWith(
        medicineName: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        notes: _notesController.text.trim(),
        date: dateStr,
        time: timeStr,
      );
      success = await medProvider.updateMedicine(updatedMed);
    } else {
      success = await medProvider.addMedicine(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        notes: _notesController.text.trim(),
        date: dateStr,
        time: timeStr,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Medicine updated successfully' : 'Medicine added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save medicine schedule'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine Schedule' : 'Add New Medicine'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter Medication Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All details help schedule accurate push notifications on your device.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Medicine Name',
                        hintText: 'e.g. Metformin, Panadol',
                        prefixIcon: const Icon(Icons.medication_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter medicine name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        labelText: 'Dosage',
                        hintText: 'e.g. 500mg, 1 pill, 2 drops',
                        prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter dosage details';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Scheduled Date',
                                prefixIcon: const Icon(Icons.calendar_today_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Scheduled Time',
                                prefixIcon: const Icon(Icons.access_time_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _formatTimeOfDay(_selectedTime),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Instructions / Notes (Optional)',
                        hintText: 'e.g. Take after breakfast, avoid cold water',
                        prefixIcon: const Icon(Icons.note_alt_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _saveForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isEditing ? 'Update Schedule' : 'Schedule Reminder',
                        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
