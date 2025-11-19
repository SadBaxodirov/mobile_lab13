import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 13',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Firebase lab 13'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _msgText = TextEditingController();

  void _submitMsg() async {
    final text = _msgText.text;
    if (text.isEmpty) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'text': text,
      'timestamp': Timestamp.now(),
    });

    _msgText.clear();
  }

  @override
  void dispose() {
    _msgText.dispose();
    super.dispose();
  }

  void _editMessage(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final TextEditingController controller = TextEditingController(
      text: doc['text'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new message text',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newText = controller.text;
                if (newText.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('messages')
                      .doc(doc.id)
                      .update({'text': newText});
                }

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _msgText,
            decoration: InputDecoration(
              labelText: 'Enter message',
              hintText: 'e.g., Hello world',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (text) {
              _submitMsg();
            },
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            onPressed: _submitMsg,
            tooltip: 'Submit',
            child: const Text("Submit"),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = data['text'] ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeString = timestamp != null
                        ? timestamp.toDate().toString()
                        : '';

                    return ListTile(
                      title: Text(text),
                      subtitle: Text(timeString),
                      trailing: OutlinedButton(
                        onPressed: () {
                          _editMessage(context, docs[index]);
                        },
                        child: const Text('Edit'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
