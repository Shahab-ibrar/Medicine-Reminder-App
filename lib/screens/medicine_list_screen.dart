import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/providers/medicine_provider.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medProvider = Provider.of<MedicineProvider>(context);

    final filteredMeds = medProvider.medicines.where((med) {
      final nameMatches = med.medicineName.toLowerCase().contains(_searchQuery.toLowerCase());
      final notesMatches = med.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || notesMatches;
    }).toList();

    filteredMeds.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.scheduledDateTime.compareTo(b.scheduledDateTime);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search medicines...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: medProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMeds.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filteredMeds.length,
                        itemBuilder: (context, index) {
                          final med = filteredMeds[index];
                          return _buildMedicineItem(context, med);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No medicines found' : 'No medicines added yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching for something else'
                : 'Tap the "Add Medicine" button below to schedule your first medicine.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(BuildContext context, Medicine med) {
    final theme = Theme.of(context);

    final DateTime parsedDate = DateTime.tryParse(med.date) ?? DateTime.now();
    final String dateFormatted = DateFormat('MMM d, yyyy').format(parsedDate);

    Color statusColor;
    switch (med.status) {
      case 'Taken':
        statusColor = Colors.green;
        break;
      case 'Missed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.medical_services_outlined, color: theme.colorScheme.primary),
        ),
        title: Text(
          med.medicineName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Dosage: ${med.dosage}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$dateFormatted at ${med.time}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            med.status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          Navigator.of(context).pushNamed('/medicine_details', arguments: med);
        },
      ),
    );
  }
}
