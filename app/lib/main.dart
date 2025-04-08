import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: const TaskListScreen(), // <-- set Firebase-based screen as home
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _controller = TextEditingController();
  late final CollectionReference tasksRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('tasks');
  }

  Future<void> _addTask(String taskName) async {
    if (taskName.trim().isEmpty) return;
    await tasksRef.add({
      'name': taskName.trim(),
      'isCompleted': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  Future<void> _toggleComplete(String id, bool current) async {
    await tasksRef.doc(id).update({'isCompleted': !current});
  }

  Future<void> _deleteTask(String id) async {
    await tasksRef.doc(id).delete();
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "Enter task name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _addTask(_controller.text),
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 20),
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

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  User? get currentUser => _auth.currentUser;
}
