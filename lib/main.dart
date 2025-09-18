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

  void updateTask(Task oldTask, String newName, String newDescription,
      List<Subtask> newSubtasks, List<String> newLabels) {
    final taskIndex = _items.indexOf(oldTask);
    if (taskIndex != -1) {
      _items[taskIndex] = Task(
        name: newName,
        description: newDescription,
        subtasks: newSubtasks,
        labels: newLabels,
        uuid: oldTask.uuid,
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

  late String _localName;
  late String _localDescription;
  late List<Subtask> _localSubtasks;
  late List<String> _localLabels;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localName = widget.task.name;
    _localDescription = widget.task.description;
    _localSubtasks = widget.task.subtasks
        .map((s) => Subtask(title: s.title, isDone: s.isDone))
        .toList();
    _localLabels = List.from(widget.task.labels);

    _nameController.text = _localName;
    _descriptionController.text = _localDescription;
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
      appBar: AppBar(title: const Text("Task Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isEditingName
                ? TextField(
                    controller: _nameController,
                    onSubmitted: (value) {
                      setState(() {
                        _localName = value;
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
                      _localName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 10),
            _isEditingDescription
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _descriptionController,
                        maxLines: null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _localDescription = _descriptionController.text;
                                _isEditingDescription = false;
                              });
                            },
                            child: const Text('OK'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _descriptionController.text = _localDescription;
                                _isEditingDescription = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingDescription = true;
                        _descriptionController.text = _localDescription;
                      });
                    },
                    child: Text(
                      _localDescription.isEmpty ? "No description" : _localDescription,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtasks",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddSubtaskDialog,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: List.generate(_localSubtasks.length, (i) {
                final subtask = _localSubtasks[i];
                return Chip(
                  label: GestureDetector(
                    onTap: () {
                      setState(() {
                        _localSubtasks[i].isDone =
                            !_localSubtasks[i].isDone;
                      });
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
                    setState(() {
                      _localSubtasks.removeAt(i);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Labels",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddLabelDialog,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: List.generate(_localLabels.length, (i) {
                final label = _localLabels[i];
                return Chip(
                  label: Text(label),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() {
                      _localLabels.removeAt(i);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 30),
            TextButton(onPressed: _saveChanges, child: Chip(label: Text('Save')))
          ],
        ),
      ),
    );
  }

  void _showAddSubtaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Subtask"),
        content: TextField(
          controller: _subtaskController,
          decoration: const InputDecoration(labelText: "Subtask name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Chip(label: const Text("Cancel"))),
          TextButton(
            onPressed: () {
              if (_subtaskController.text.isNotEmpty) {
                final newSub = _subtaskController.text.trim();
                final exists = _localSubtasks.any((s) => s.title == newSub);
                
                if (!exists) {
                  setState(() {
                  _localSubtasks
                      .add(Subtask(title: newSub));
                });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Subtask already exists")),
                  );
                }
                _subtaskController.clear();
              }
              Navigator.pop(context);
            },
            child: Chip(label: const Text("Add")),
          ),
        ],
      ),
    );
  }

  void _showAddLabelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Label"),
        content: TextField(
          controller: _labelController,
          decoration: const InputDecoration(labelText: "Label"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Chip(label: const Text("Cancel"))),
          TextButton(
            onPressed: () {
              if (_labelController.text.isNotEmpty) {
                final newLabel = _labelController.text.trim();
                final exists = _localLabels.contains(newLabel);
                if (!exists) {
                  setState(() {
                  _localLabels.add(newLabel);
                });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Label already exists"))
                  );
                }
                _labelController.clear();
              }
              Navigator.pop(context);
            },
            child: Chip(label: const Text("Add")),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_localName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task name cannot be empty")),
      );
      return;
    }

    context.read<TaskProvider>().updateTask(
          widget.task,
          _localName,
          _localDescription,
          _localSubtasks,
          _localLabels,
        );

    Navigator.pop(context);
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Set<String> _selectedLabels = {};

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
                final labels = value.allLabels().toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...labels.map((label) {
                        final isSelected = _selectedLabels.contains(label);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(label), 
                            selected: isSelected,
                            selectedColor: Colors.teal,
                            onSelected: (selected) {
                              setState(() {
                                if (isSelected) {
                                  _selectedLabels.remove(label);
                                } else {
                                  _selectedLabels.add(label);
                                }
                              });
                            },
                          ),
                        );
                      }),
                      if (_selectedLabels.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            label: const Text('Clear'),
                            onPressed: () {
                              setState(() {
                                _selectedLabels.clear();
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, value, child) {
                final allTasks = value.item;
                final filteredTasks = _selectedLabels.isEmpty
                    ? allTasks
                    : allTasks.where((task) {
                      return _selectedLabels
                            .any((label) => task.labels.contains(label));
                    });
                return TaskWidget(
                  tasks: UnmodifiableListView(filteredTasks),
                );
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
  String _localName = "";
  String _localDescription = "";
  final List<Subtask> _localSubtasks = [];
  final List<String> _localLabels = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

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
      appBar: AppBar(title: const Text("Add Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Task Name"),
              onChanged: (value) => _localName = value,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: null,
              onChanged: (value) => _localDescription = value,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddSubtaskDialog,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: List.generate(_localSubtasks.length, (i) {
                final subtask = _localSubtasks[i];
                return Chip(
                  label: GestureDetector(
                    onTap: () {
                      setState(() {
                        _localSubtasks[i].isDone = !_localSubtasks[i].isDone;
                      });
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
                    setState(() {
                      _localSubtasks.removeAt(i);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Labels", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddLabelDialog,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: List.generate(_localLabels.length, (i) {
                final label = _localLabels[i];
                return Chip(
                  label: Text(label),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() {
                      _localLabels.removeAt(i);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 30),
            TextButton(onPressed: _saveTask, child: Chip(label: Text('Add')))
          ],
        ),
      ),
    );
  }

  void _showAddSubtaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Subtask"),
        content: TextField(
          controller: _subtaskController,
          decoration: const InputDecoration(labelText: "Subtask name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Chip(label: const Text("Cancel"))),
          TextButton(
            onPressed: () {
              if (_subtaskController.text.isNotEmpty) {
                final newSub = _subtaskController.text.trim();
                final exists = _localSubtasks.any((s) => s.title == newSub);
                if (!exists) {
                  setState(() {
                    _localSubtasks.add(Subtask(title: newSub));
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Subtask already exists'))
                  );
                }
                _subtaskController.clear();
              }
              Navigator.pop(context);
            },
            child: Chip(label: const Text("Add")),
          ),
        ],
      ),
    );
  }

  void _showAddLabelDialog() {
    final existing = context.read<TaskProvider>().allLabels();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Label"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: "Label"),
              ),
              const SizedBox(height: 12),
              if (existing.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: existing.map((lab) {
                    return ActionChip(
                      label: Text(lab),
                      onPressed: () {
                        final selected = lab.trim();
                        final exists = _localLabels.contains(selected);
                        if (!exists) {
                          setState(() {
                            _localLabels.add(selected);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Label already added")),
                          );
                        }
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Chip(label: const Text("Cancel"))),
          TextButton(
            onPressed: () {
              final newLabel = _labelController.text.trim();
              if (newLabel.isNotEmpty) {
                final exists = _localLabels.contains(newLabel);
                if (!exists) {
                  setState(() {
                    _localLabels.add(newLabel);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Label already exists'))
                  );
                }
                _labelController.clear();
              }
              Navigator.pop(context);
            },
            child: Chip(label: const Text("Add")),
          ),
        ],
      ),
    );
  }

  void _saveTask() {
    if (_localName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task name cannot be empty")),
      );
      return;
    }

    context.read<TaskProvider>().add(
          Task(
            name: _localName,
            description: _localDescription,
            subtasks: _localSubtasks,
            labels: _localLabels,
          ),
        );

    Navigator.pop(context);
  }
}
