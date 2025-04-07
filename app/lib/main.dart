import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TaskManager(),
    );
  }
}

class TaskManager extends StatefulWidget {
  const TaskManager({super.key});

  @override
  State<TaskManager> createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();

  final Map<String, Map<String, List<Map<String, dynamic>>>> _taskMap = {};

  void _addTask() {
    final day = _dayController.text.trim();
    final time = _timeController.text.trim();
    final subTask = _subTaskController.text.trim();

    if (day.isNotEmpty && time.isNotEmpty && subTask.isNotEmpty) {
      setState(() {
        _taskMap.putIfAbsent(day, () => {});
        _taskMap[day]!.putIfAbsent(time, () => []);
        _taskMap[day]![time]!.add({'name': subTask, 'completed': false});

        // Clear input fields
        _taskController.clear();
        _dayController.clear();
        _timeController.clear();
        _subTaskController.clear();
      });
    }
  }

  void _toggleCompletion(String day, String time, int index) {
    setState(() {
      _taskMap[day]![time]![index]['completed'] =
          !_taskMap[day]![time]![index]['completed'];
    });
  }

  void _deleteTask(String day, String time, int index) {
    setState(() {
      _taskMap[day]![time]!.removeAt(index);
      if (_taskMap[day]![time]!.isEmpty) {
        _taskMap[day]!.remove(time);
        if (_taskMap[day]!.isEmpty) {
          _taskMap.remove(day);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nested Task Manager')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Input fields
            TextField(
              controller: _dayController,
              decoration: const InputDecoration(
                labelText: 'Day (e.g., Monday)',
              ),
            ),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time Block (e.g., 9am - 10am)',
              ),
            ),
            TextField(
              controller: _subTaskController,
              decoration: const InputDecoration(
                labelText: 'Sub-task Name (e.g., HW1)',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addTask, child: const Text('Add')),
            const SizedBox(height: 20),

            // Task List
            Expanded(
              child:
                  _taskMap.isEmpty
                      ? const Center(child: Text('No tasks yet.'))
                      : ListView(
                        children:
                            _taskMap.entries.map((dayEntry) {
                              final day = dayEntry.key;
                              final timeBlocks = dayEntry.value;

                              return ExpansionTile(
                                title: Text(
                                  day,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                children:
                                    timeBlocks.entries.map((timeEntry) {
                                      final time = timeEntry.key;
                                      final tasks = timeEntry.value;

                                      return ExpansionTile(
                                        title: Text(
                                          time,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        children:
                                            tasks.asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final task = entry.value;
                                              return ListTile(
                                                leading: Checkbox(
                                                  value: task['completed'],
                                                  onChanged:
                                                      (_) => _toggleCompletion(
                                                        day,
                                                        time,
                                                        index,
                                                      ),
                                                ),
                                                title: Text(
                                                  task['name'],
                                                  style: TextStyle(
                                                    decoration:
                                                        task['completed']
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => _deleteTask(
                                                        day,
                                                        time,
                                                        index,
                                                      ),
                                                ),
                                              );
                                            }).toList(),
                                      );
                                    }).toList(),
                              );
                            }).toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
