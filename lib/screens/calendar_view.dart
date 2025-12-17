import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';

class CalendarView extends StatefulWidget {
  final List<Subscription> subscriptions;
  final List<CategoryModel> categories;
  final Function(Subscription) onEdit;

  const CalendarView({
    super.key,
    required this.subscriptions,
    required this.categories,
    required this.onEdit,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  CategoryModel _getCategory(String id) {
    return widget.categories.firstWhere(
      (c) => c.id == id,
      orElse: () => widget.categories.last,
    );
  }

  List<Subscription> _getEventsForDay(DateTime day) {
    return widget.subscriptions.where((sub) {
      return sub.getAllUpcomingPaymentDates().any(
        (date) =>
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Text(
          '今日無待付款項目',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final sub = events[index];
        final category = _getCategory(sub.categoryId);

        return InkWell(
          onTap: () => widget.onEdit(sub),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category.color.withOpacity(0.2),
                child: Icon(category.icon, color: category.color),
              ),
              title: Text(
                sub.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(sub.currency + ' ' + sub.cost.toString()),
              trailing: const Icon(Icons.chevron_right, size: 16),
            ),
          ),
        );
      },
    );
  }
}
