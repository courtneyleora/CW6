import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        } else {
          return const TaskListScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _error = "";

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } catch (e) {
      setState(() => _error = "Login failed: \${e.toString()}");
    }
  }

  Future<void> _register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } catch (e) {
      setState(() => _error = "Registration failed: \${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login / Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Login")),
            TextButton(onPressed: _register, child: const Text("Register")),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _subTaskNameController = TextEditingController();
  final TextEditingController _timeRangeController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  String _selectedDay = 'Monday';

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late final CollectionReference tasksRef;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
    _initFCM();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("\u{1F525} FCM Token: \$token");
      setState(() {
        _fcmToken = token;
      });
    } else {
      print("\u274C User declined or has not accepted permission");
    }
  }

  Future<void> _addTask(String taskName) async {
    if (taskName.trim().isEmpty) return;
    await tasksRef.add({
      'name': taskName.trim(),
      'isCompleted': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _taskController.clear();
  }

  Future<void> _toggleComplete(String id, bool current) async {
    await tasksRef.doc(id).update({'isCompleted': !current});
  }

  Future<void> _deleteTask(String id) async {
    await tasksRef.doc(id).delete();
  }

  Future<void> _addSubTask() async {
    final user = FirebaseAuth.instance.currentUser!;
    final subTaskName = _subTaskNameController.text.trim();
    final timeRange = _timeRangeController.text.trim();
    final selectedDay = _selectedDay;

    if (subTaskName.isEmpty || timeRange.isEmpty) return;

    final dayRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('days')
        .doc(selectedDay);

    await dayRef.set({'day': selectedDay});
    final blockRef = dayRef.collection('timeBlocks').doc(timeRange);
    await blockRef.set({'timeRange': timeRange});

    await blockRef.collection('subTasks').add({
      'name': subTaskName,
      'isCompleted': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _subTaskNameController.clear();
    _timeRangeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          labelText: "Enter task name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _addTask(_taskController.text),
                        child: const Text("Add Task"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Add Nested Sub-Task",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedDay,
                            items:
                                _daysOfWeek.map((day) {
                                  return DropdownMenuItem(
                                    value: day,
                                    child: Text(day),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedDay = val);
                            },
                            decoration: const InputDecoration(labelText: "Day"),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _timeRangeController,
                            decoration: const InputDecoration(
                              labelText: "Time Range (e.g. 9am–10am)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _subTaskNameController,
                            decoration: const InputDecoration(
                              labelText: "Sub-Task Name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _addSubTask,
                            child: const Text("Add Sub-Task"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_fcmToken != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "FCM Token:\n\$_fcmToken",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksRef.orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!.docs;

                  if (tasks.isEmpty) {
                    return const Center(child: Text("No tasks added yet."));
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final taskData = task.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: Checkbox(
                          value: taskData['isCompleted'],
                          onChanged:
                              (_) => _toggleComplete(
                                task.id,
                                taskData['isCompleted'],
                              ),
                        ),
                        title: Text(
                          taskData['name'],
                          style: TextStyle(
                            decoration:
                                taskData['isCompleted']
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(task.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
