import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/providers/medicine_provider.dart';

class MedicineDetailsScreen extends StatelessWidget {
  const MedicineDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);

    final med = ModalRoute.of(context)!.settings.arguments as Medicine;

    final parsedDate = DateTime.tryParse(med.date) ?? DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(parsedDate);

    Color statusColor;
    IconData statusIcon;
    switch (med.status) {
      case 'Taken':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Missed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/add_medicine', arguments: med);
            },
            tooltip: 'Edit Schedule',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Schedule'),
                  content: const Text('Are you sure you want to delete this medicine reminder?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final success = await medProvider.deleteMedicine(med);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine reminder deleted')),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
            tooltip: 'Delete Schedule',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.medical_services_rounded, size: 40, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.medicineName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dosage: ${med.dosage}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Schedule Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.calendar_today_outlined, 'Scheduled Date', dateFormatted),
            const Divider(),
            _buildDetailRow(context, Icons.access_time_outlined, 'Scheduled Time', med.time),
            const Divider(),
            _buildDetailRow(
              context, 
              Icons.info_outline_rounded, 
              'Adherence Status', 
              med.status,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      med.status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            _buildDetailRow(
              context, 
              Icons.note_alt_outlined, 
              'Instructions & Notes', 
              med.notes.isNotEmpty ? med.notes : 'No instructions added.',
            ),
            
            const SizedBox(height: 40),
            if (med.status == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await medProvider.markAsMissed(med);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Mark as Missed', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await medProvider.markAsTaken(med);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await medProvider.markAsPending(med);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('Reset Status to Pending'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    IconData icon, 
    String label, 
    String value, 
    {Widget? trailing}
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
