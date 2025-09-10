import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
      routes: {
        '/new': (context) => const AddingTaskWidget(),
      },
    );
  }
}

class Task {
  final String name;
  final String description;
  final List<String> subtasks;
  final String uuid;

  Task({
    required this.name,
    required this.description,
    required this.subtasks,
  }) : uuid = const Uuid().v4();

  @override
  bool operator ==(covariant Task other) =>
      uuid == other.uuid;

  @override
  String get title => name;
}

class TaskProvider extends ChangeNotifier {
  final List<Task> _items = [];
  UnmodifiableListView<Task> get item => UnmodifiableListView(_items);

  void add(Task task) {
    _items.add(task);
    notifyListeners();
  }

  void remove(Task task) {
    _items.remove(task);
    notifyListeners();
  }
}

class TaskWidget extends StatelessWidget {
  final UnmodifiableListView<Task> tasks;
  const TaskWidget({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskDetailWidget(task: task),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(task.title),
                IconButton(
                  onPressed: () {
                    context.read<TaskProvider>().remove(task);
                  },
                  icon: const Icon(Icons.delete)
                )
              ],
            )
          ),
        );
      },
    );
  }
}

class TaskDetailWidget extends StatelessWidget {
  final Task task;

  const TaskDetailWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              task.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Subtasks:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: task.subtasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(task.subtasks[index]),
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


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, value, child) {
                return TaskWidget(tasks: value.item);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/new');
              },
              child: Text('Add new task')
            ),
          ),
        ],
      ),
    );
  }
}

class AddingTaskWidget extends StatefulWidget {
  const AddingTaskWidget({super.key});

  @override
  State<AddingTaskWidget> createState() => _AddingTaskWidgetState();
}

class _AddingTaskWidgetState extends State<AddingTaskWidget> {

  final TextEditingController taskController = TextEditingController();
  final List<TextEditingController> _subtaskControllers = [];
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    taskController.dispose();
    for (var controller in _subtaskControllers) {
      controller.dispose();
    }
    descriptionController.dispose();
    super.dispose();
  }

  void addTasks() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Task'),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: taskController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                ),
              ),
              SizedBox(height: 15,),
              Column(
                children: List.generate(
                  _subtaskControllers.length, 
                  (index) {
                    return Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 10),
                      child: TextField(
                        controller: _subtaskControllers[index],
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _subtaskControllers.removeAt(index);
                              });
                            }, 
                            icon: Icon(Icons.remove)
                          ),
                          labelText: 'Subtask Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
              SizedBox(height: 15,),
              SizedBox(
                height: 100,
                child: TextField(
                  controller: descriptionController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    )
                  ),
                ),
              ),
              SizedBox(height: 15,),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      addTasks();
                    }, 
                    child: Text('Add Subtask')
                  ),
                  TextButton(
                    onPressed: () {
                      final text = taskController.text;
                      final description = descriptionController.text;
                      final subtasks = _subtaskControllers.map((e) => e.text).toList();
                      if (text.isNotEmpty) {
                        final task = Task(
                          name: text,
                          description: description,
                          subtasks: subtasks,
                        );
                        context.read<TaskProvider>().add(
                          task,
                        );
                      }
                      Navigator.of(context).pop();
                    }, 
                    child: Text('Add')
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
