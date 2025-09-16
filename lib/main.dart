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

class Subtask {
  final String title;
  bool isDone;

  Subtask({required this.title, this.isDone = false});
}

class Task {
  final String name;
  final String description;
  final List<Subtask> subtasks;
  final List<String> labels;
  final String uuid;

  Task({
    required this.name,
    required this.description,
    required this.subtasks,
    required List<String> labels,
    String? uuid,
  }) : labels = List.unmodifiable(labels),
       uuid = uuid ?? const Uuid().v4();

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

  void toggleSubtask(Task task, int index) {
    final taskIndex = _items.indexOf(task);
    if (taskIndex != -1) {
      _items[taskIndex].subtasks[index].isDone = !_items[taskIndex].subtasks[index].isDone;
      notifyListeners();
    }
  }

  void removeSubtask (Task task, int index) {
    final taskIndex = _items.indexOf(task);
    if (taskIndex != -1) {
      _items[taskIndex].subtasks.removeAt(index);
      notifyListeners();
    }
  }

  void addSubtask (Task task, String title) {
    final taskIndex = _items.indexOf(task);
    if (taskIndex != -1) {
      _items[taskIndex].subtasks.add(Subtask(title: title));
      notifyListeners();
    }
  }

  void addLabel(Task task, String label) {
    final taskIndex = _items.indexOf(task);
    if (taskIndex != -1 && !_items[taskIndex].labels.contains(label)) {
      final updatedLabels = List<String>.from(_items[taskIndex].labels)..add(label);
      _items[taskIndex] = Task(
        name: _items[taskIndex].name,
        description: _items[taskIndex].description,
        subtasks: _items[taskIndex].subtasks,
        labels: updatedLabels,
        uuid: _items[taskIndex].uuid,
      );
      notifyListeners();
    }
  }

  void removeLabel(Task task, String label) {
    final taskIndex = _items.indexOf(task);
    if (taskIndex != -1) {
      final updatedLabels = List<String>.from(_items[taskIndex].labels)..remove(label);
      _items[taskIndex] = Task(
        name: _items[taskIndex].name,
        description: _items[taskIndex].description,
        subtasks: _items[taskIndex].subtasks,
        labels: updatedLabels,
        uuid: _items[taskIndex].uuid
      );
      notifyListeners();
    }
  }

void updateTaskTitle(Task task, String newName) {
  final taskIndex = _items.indexOf(task);
  if (taskIndex != -1) {
    _items[taskIndex] = Task(
      name: newName, 
      description: _items[taskIndex].description, 
      subtasks: _items[taskIndex].subtasks, 
      labels: _items[taskIndex].labels,
      uuid: _items[taskIndex].uuid,
    );
    notifyListeners();
  }
}

void updateDescription(Task task, String newDescription) {
  final taskIndex = _items.indexOf(task);
  if (taskIndex != -1) {
    _items[taskIndex] = Task(
      name: _items[taskIndex].name, 
      description: newDescription, 
      subtasks: _items[taskIndex].subtasks, 
      labels: _items[taskIndex].labels,
      uuid: _items[taskIndex].uuid,
    );
    notifyListeners();
  }
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
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TaskDetailWidget(task: task),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  if (task.labels.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: task.labels.map((label) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Chip(
                              label: Text(
                                label,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        context.read<TaskProvider>().remove(task);
                      },
                    ),
                  )
                ],
              ),
            ),
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
    return Wrap(
      alignment: WrapAlignment.start,
      direction: Axis.horizontal,
      spacing: 8,
      children: labels.map((label) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TasksByLabelPage(label: label),
              )
            );
          },
          child: Chip(
            label: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16
              ),
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }).toList(),
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


class TaskDetailWidget extends StatefulWidget {
  final Task task;

  const TaskDetailWidget({super.key, required this.task});

  @override
  State<TaskDetailWidget> createState() => _TaskDetailWidgetState();
}

class _TaskDetailWidgetState extends State<TaskDetailWidget> {

  bool _isEditingName = false;
  bool _isEditingDescription = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          final currentTask = provider.item.firstWhere((t) => t.uuid == widget.task.uuid);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isEditingName 
                    ? TextField(
                      controller: _nameController,
                      onEditingComplete: () {
                        if (_nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Task must not be empty'))
                          );
                          return ;
                        }
                        provider.updateTaskTitle(currentTask, _nameController.text);
                        setState(() {
                          _isEditingName = false;
                        });
                      },
                    )
                    : GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditingName = true;
                        });
                      },
                      child: Text(
                        currentTask.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                const SizedBox(height: 10),
                _isEditingDescription
                    ? Column(
                      children: [
                        TextField(
                          controller: _descriptionController,
                          maxLines: null,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                provider.updateDescription(currentTask, _descriptionController.text);
                                setState(() => _isEditingDescription = false,);
                              }, 
                              child: Text('OK')
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _isEditingDescription = false,);
                              }, 
                              child: Text('Cancel')
                            ),
                          ],
                        )
                      ],
                    )
                    : GestureDetector(
                      onTap: () {
                        setState(() => _isEditingDescription = true,);
                      },
                      child: Text(
                        currentTask.description.isEmpty
                            ? "This is the description"
                            : currentTask.description
                      ),
                    ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtasks:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Add Subtask'),
                              content: TextField(
                                controller: _subtaskController,
                                decoration:
                                    const InputDecoration(labelText: 'Subtask name'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_subtaskController.text.isNotEmpty) {
                                      provider.addSubtask(
                                          currentTask, _subtaskController.text);
                                      _subtaskController.clear();
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                if (widget.task.subtasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No subtasks'),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    children: currentTask.subtasks.map((subtask) {
                      final index = currentTask.subtasks.indexOf(subtask);
                      return Chip(
                        label: GestureDetector(
                          onTap: () {
                            provider.toggleSubtask(currentTask, index);
                          },
                          child: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          provider.removeSubtask(currentTask, index);
                        },
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Labels',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context, 
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Add Label'),
                              content: TextField(
                                controller: _labelController,
                                decoration: const InputDecoration(
                                  labelText: 'Label'
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  }, 
                                  child: const Text('Cancel')
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_labelController.text.isNotEmpty) {
                                      provider.addLabel(
                                        currentTask, _labelController.text,
                                      );
                                      _labelController.clear();
                                    }
                                    Navigator.pop(context);
                                  }, 
                                  child: const Text('Add')
                                )
                              ],
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
                if (widget.task.labels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No labels'),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.start,
                    direction: Axis.horizontal,
                    spacing: 8,
                    children: currentTask.labels.map((l) {
                      return Chip(
                        label: Text(l),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          provider.removeLabel(currentTask, l);
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      )
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
              child: Chip(
                label: Text('Add new task')
              ),
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
          padding: const EdgeInsets.all(20),
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
                    child: Chip(label: Text('Add Subtask'))
                  ),
                  TextButton(
                    onPressed: () {
                      addLabel();
                    }, 
                    child: Chip(label: Text('Add label'))
                  ),
                  TextButton(
                    onPressed: () {
                      final text = taskController.text;
                      final description = descriptionController.text;
                      final subtasks = _subtaskControllers.map((e) => Subtask(title: e.text)).toList();
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
                    child: Chip(label: Text('Add'))
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
