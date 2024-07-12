import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/button.dart';

class HelpSettings extends StatefulWidget {
  const HelpSettings({super.key});

  @override
  State<HelpSettings> createState() => _HelpSettingsState();
}

class _HelpSettingsState extends State<HelpSettings> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _addHelpSection() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Content cannot be empty')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('helpSections').add({
      'title': _titleController.text,
      'content': _contentController.text,
    });

    _titleController.clear();
    _contentController.clear();
  }

  Future<void> _editHelpSection(DocumentSnapshot help) async {
    _titleController.text = help['title'];
    _contentController.text = help['content'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Help Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('helpSections')
                  .doc(help.id)
                  .update({
                'title': _titleController.text,
                'content': _contentController.text,
              });

              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHelpSection(String id) async {
    await FirebaseFirestore.instance.collection('helpSections').doc(id).delete();
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Help'),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
              ),
              const SizedBox(height: 10,),
              Button(
                onPressed: _addHelpSection,
                child: const Text('Add Help Section'),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('helpSections').orderBy('title').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading help sections.'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No help sections available.'));
                    }

                    final helpDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: helpDocs.length,
                      itemBuilder: (context, index) {
                        final help = helpDocs[index];
                        return ListTile(
                          title: Text(help['title']),
                          subtitle: Text(help['content']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editHelpSection(help),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteHelpSection(help.id),
                              ),
                            ],
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
      ),
    );
  }
}
