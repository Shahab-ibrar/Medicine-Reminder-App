import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/providers/medicine_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Active filter: 'Today', 'Weekly', or 'Monthly'
  String _selectedFilter = 'Today';

  static const List<String> _filters = ['Today', 'Weekly', 'Monthly'];

  /// Returns the date range for the selected filter.
  DateTimeRange _getFilterRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (_selectedFilter) {
      case 'Weekly':
        return DateTimeRange(
          start: todayStart.subtract(Duration(days: todayStart.weekday - 1)),
          end: now,
        );
      case 'Monthly':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'Today':
      default:
        return DateTimeRange(start: todayStart, end: now);
    }
  }

  /// Returns the status color for Taken / Missed / Skipped entries.
  Color _statusColor(String status) {
    switch (status) {
      case 'Taken':
        return Colors.green;
      case 'Missed':
        return Colors.red;
      case 'Skipped':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Returns the status icon for Taken / Missed / Skipped entries.
  IconData _statusIcon(String status) {
    switch (status) {
      case 'Taken':
        return Icons.check_circle_rounded;
      case 'Missed':
        return Icons.cancel_rounded;
      case 'Skipped':
        return Icons.skip_next_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medProvider = Provider.of<MedicineProvider>(context);

    final range = _getFilterRange();

    final historyMeds = medProvider.medicines.where((m) {
      if (m.status == 'Pending') return false;
      final medDate = DateTime.tryParse(m.date);
      if (medDate == null) return false;
      return !medDate.isBefore(range.start) &&
          !medDate.isAfter(DateTime(range.end.year, range.end.month, range.end.day));
    }).toList();

    historyMeds.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.scheduledDateTime.compareTo(a.scheduledDateTime);
    });

    final Map<String, List<Medicine>> groupedMeds = {};
    for (var med in historyMeds) {
      if (!groupedMeds.containsKey(med.date)) {
        groupedMeds[med.date] = [];
      }
      groupedMeds[med.date]!.add(med);
    }

    final sortedDates = groupedMeds.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final totalCount = historyMeds.length;
    final takenCount = historyMeds.where((m) => m.status == 'Taken').length;
    final adherenceRate =
        totalCount > 0 ? (takenCount / totalCount * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Filter chips ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── Stats row ─────────────────────────────────────────────────────
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      context, 'Total Doses', '$totalCount', Icons.history_edu),
                  Container(height: 40, width: 1, color: Colors.grey[300]),
                  _buildStatItem(context, 'Taken', '$takenCount',
                      Icons.check_circle_outline,
                      color: Colors.green),
                  Container(height: 40, width: 1, color: Colors.grey[300]),
                  _buildStatItem(
                    context,
                    'Adherence',
                    '$adherenceRate%',
                    Icons.percent_rounded,
                    color: adherenceRate >= 80
                        ? Colors.green
                        : (adherenceRate >= 50 ? Colors.orange : Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: medProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedDates.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateStr = sortedDates[index];
                          final medsForDate = groupedMeds[dateStr]!;

                          final parsedDate =
                              DateTime.tryParse(dateStr) ?? DateTime.now();
                          final headerDate =
                              DateFormat('EEEE, MMMM d, yyyy').format(parsedDate);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 4.0),
                                child: Text(
                                  headerDate,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              ...medsForDate
                                  .map((med) => _buildHistoryItem(context, med)),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
      IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style:
              theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No history for this period',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Once you confirm or miss your scheduled doses, they will appear here.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Medicine med) {
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    final color = _statusColor(med.status);
    final icon = _statusIcon(med.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          med.medicineName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Dosage: ${med.dosage} • Scheduled: ${med.time}'),
        trailing: OutlinedButton(
          onPressed: () => medProvider.markAsPending(med),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Undo', style: TextStyle(fontSize: 12)),
        ),
        onTap: () {
          Navigator.of(context).pushNamed('/medicine_details', arguments: med);
        },
      ),
    );
  }
}
