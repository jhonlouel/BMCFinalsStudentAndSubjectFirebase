
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController();
    final section = TextEditingController();
    final course = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var item in [
              ['Name', name],
              ['Section', section],
              ['Course', course],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: item[1] as TextEditingController,
                  decoration: InputDecoration(
                    labelText: item[0] as String,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isEmpty ||
                    section.text.trim().isEmpty ||
                    course.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill in all fields')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectScreen(
                      name: name.text.trim(),
                      section: section.text.trim(),
                      course: course.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}


class SubjectScreen extends StatefulWidget {
  final String name, section, course;

  const SubjectScreen({
    super.key,
    required this.name,
    required this.section,
    required this.course,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final subjects = <Map<String, TextEditingController>>[];

  void addSubject() {
    subjects.add({
      'subject': TextEditingController(),
      'start': TextEditingController(),
      'end': TextEditingController(),
    });
  }

  @override
  void initState() {
    super.initState();
    addSubject();
  }

  @override
  void dispose() {
    for (var subject in subjects) {
      for (var controller in subject.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Enrollment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(subjects.length, (i) {
              return Column(
                children: [
                  Text('Subject ${i + 1}'),
                  for (var field in ['subject', 'start', 'end'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: subjects[i][field],
                        decoration: InputDecoration(
                          labelText: {
                            'subject': 'Subject',
                            'start': 'Start Time',
                            'end': 'End Time',
                          }[field],
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: subjects.length == 1
                        ? null
                        : () {
                            setState(() {
                              for (var c in subjects.removeAt(i).values) {
                                c.dispose();
                              }
                            });
                          },
                    child: const Text('Remove Subject'),
                  ),
                ],
              );
            }),
            ElevatedButton(
              onPressed: () => setState(addSubject),
              child: const Text('Add Subject'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subjects.any((s) =>
                    s.values.any((c) => c.text.trim().isEmpty))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete all fields')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      name: widget.name,
                      section: widget.section,
                      course: widget.course,
                      subjects: subjects.map((s) => {
                        for (var e in s.entries) e.key: e.value.text.trim()
                      }).toList(),
                    ),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewScreen extends StatelessWidget {
  final String name, section, course;
  final List<Map<String, String>> subjects;

  const ReviewScreen({
    super.key,
    required this.name,
    required this.section,
    required this.course,
    required this.subjects,
  });

  Future<void> saveData(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('enrollments').add({
        'name': name,
        'section': section,
        'course': course,
        'subjects': subjects,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firebase!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Name: $name'),
            Text('Section: $section'),
            Text('Course: $course'),
            const SizedBox(height: 16),
            for (int i = 0; i < subjects.length; i++)
              ListTile(
                title: Text('${i + 1}. ${subjects[i]['subject']}'),
                subtitle: Text(
                  '${subjects[i]['start']} - ${subjects[i]['end']}',
                ),
              ),
            ElevatedButton(
              onPressed: () => saveData(context),
              child: const Text('Save to Firebase'),
            ),
          ],
        ),
      ),
    );
  }
}
