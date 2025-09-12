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
  final List<String> labels;
  final String uuid;

  Task({
    required this.name,
    required this.description,
    required this.subtasks,
    required List<String> labels,
  }) : labels = List.unmodifiable(labels),
       uuid = const Uuid().v4();

  @override
  bool operator ==(covariant Task other) =>
      uuid == other.uuid;
  
  @override
  int get hashCode => uuid.hashCode;

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

  List<Task> tasksByLabel (String label) {
    return _items.where((t) => t.labels.contains(label)).toList();
  }

  Set<String> allLabels() {
    final Set<String> out = {};
    for (final t in _items) {
      out.addAll(t.labels);
    }
    return out;
  }
}

class TaskWidget extends StatelessWidget {
  final UnmodifiableListView<Task> tasks;
  const TaskWidget({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet'),);
    }
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

class TagWidget extends StatelessWidget {
  final UnmodifiableListView<Task> tasks;
  const TagWidget({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final Set<String> uniqueLabels = {};
    for (final t in tasks) {
      uniqueLabels.addAll(t.labels);
    }
    final labels = uniqueLabels.toList();
    labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()),);

    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: labels.map((label) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TasksByLabelPage(label: label),
                    )
                  );
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.teal,
                  ),
                  child: Text(label)
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TasksByLabelPage extends StatelessWidget {
  final String label;
  const TasksByLabelPage({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks under "$label"'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, value, child) {
          final filteredTasks = value.tasksByLabel(label);

          if (filteredTasks.isEmpty) {
            return const Center(
              child: Text("No tasks with this label"),
            );
          }

          return TaskWidget(tasks: UnmodifiableListView(filteredTasks));
        },
      ),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
            if (task.subtasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No subtasks'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.subtasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(task.subtasks[index]),
                  );
                },
              ),
            SizedBox(height: 10,),
            Text(
              'Labels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (task.labels.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No labels'),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: task.labels.map((l) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(label: Text(l)),
                      );
                    }).toList(),
                  ),
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
          SizedBox(height: 50,
            child: Consumer<TaskProvider>(
              builder: (context, value, child) {
                return TagWidget(tasks: value.item);
              },
            ),
          ),
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
  final List<TextEditingController> _labelControllers = [];

  @override
  void dispose() {
    taskController.dispose();
    for (var controller in _subtaskControllers) {
      controller.dispose();
    }
    descriptionController.dispose();
    for (var controller in _labelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void addTasks() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  void addLabel() {
    setState(() {
      _labelControllers.add(TextEditingController());
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
                            icon: Icon(Icons.delete)
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
              SizedBox(height: 10,),
              Column(
                children: List.generate(
                  _labelControllers.length, 
                  (index) {
                    return TextField(
                      controller: _labelControllers[index],
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                            _labelControllers.removeAt(index);
                            });
                          },
                          icon: Icon(Icons.delete)
                        ),
                        labelText: 'label',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)
                        )
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10,),
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
                      addLabel();
                    }, 
                    child: Text('Add label')
                  ),
                  TextButton(
                    onPressed: () {
                      final text = taskController.text;
                      final description = descriptionController.text;
                      final subtasks = _subtaskControllers.map((e) => e.text).toList();
                      final labels = _labelControllers.map((e) => e.text).toList();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Enter Task'))
                        );
                        return;
                      }
                      if (text.isNotEmpty) {
                        final task = Task(
                          name: text,
                          description: description,
                          subtasks: subtasks,
                          labels: labels,
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
