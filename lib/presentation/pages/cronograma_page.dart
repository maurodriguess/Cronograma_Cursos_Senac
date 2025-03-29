import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CronogramaPage extends StatefulWidget {
  const CronogramaPage({super.key});

  @override
  _CronogramaPageState createState() => _CronogramaPageState();
}

class _CronogramaPageState extends State<CronogramaPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Event>> events = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _loadSampleEvents();
  }

  void _loadSampleEvents() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    setState(() {
      events = {
        today: [
          Event('Matemática - Aula 1', '08:00 - 10:00', Colors.blue),
          Event('Português - Revisão', '14:00 - 16:00', Colors.green),
        ],
        tomorrow: [
          Event('História - Capítulo 3', '10:00 - 12:00', Colors.orange),
        ],
        nextWeek: [
          Event('Química - Laboratório', '09:00 - 11:00', Colors.purple),
          Event('Física - Experimento', '13:00 - 15:00', Colors.red),
        ],
      };
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

  Widget _buildEventList() {
    final eventsForSelectedDay = _getEventsForDay(_selectedDay!);

    if (eventsForSelectedDay.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma aula agendada para este dia',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: eventsForSelectedDay.length,
      itemBuilder: (context, index) {
        final event = eventsForSelectedDay[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Container(
              width: 10,
              height: 40,
              color: event.color,
            ),
            title: Text(event.title),
            subtitle: Text(event.time),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeEvent(event, _selectedDay!),
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Aula'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Matéria/Aula'),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                  labelText: 'Horário (ex: 08:00 - 10:00)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  timeController.text.isNotEmpty) {
                _addEvent(
                  titleController.text,
                  timeController.text,
                  _selectedDay!,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addEvent(String title, String time, DateTime day) {
    setState(() {
      events[day] = [
        ...(events[day] ?? []),
        Event(title, time, _getRandomColor()),
      ];
    });
  }

  void _removeEvent(Event event, DateTime day) {
    setState(() {
      events[day]?.remove(event);
      if (events[day]?.isEmpty ?? false) {
        events.remove(day);
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.indigo,
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime.now().subtract(const Duration(days: 365));
    final lastDay = DateTime.now().add(const Duration(days: 365));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Aulas'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildEventList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddEventDialog,
      ),
    );
  }
}

class Event {
  final String title;
  final String time;
  final Color color;

  Event(this.title, this.time, this.color);
}
