import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/button.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  _PrivacySettingsState createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _addPolicy() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      return;
    }

    await _firestore.collection('privacyPolicies').add({
      'title': _titleController.text,
      'content': _contentController.text,
    });

    _titleController.clear();
    _contentController.clear();
  }

  Future<void> _deletePolicy(String id) async {
    await _firestore.collection('privacyPolicies').doc(id).delete();
  }

  Future<void> _editPolicy(String id, String newTitle, String newContent) async {
    await _firestore.collection('privacyPolicies').doc(id).update({
      'title': newTitle,
      'content': newContent,
    });
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
          automaticallyImplyLeading: true,
          title: const Text('Privacy Policy Settings'),
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
              const SizedBox(height: 10),
              Button(
                onPressed: _addPolicy,
                child: const Text('Add Policy'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('privacyPolicies').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading privacy policies.'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No privacy policies available.'));
                    }

                    final policyDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: policyDocs.length,
                      itemBuilder: (context, index) {
                        final policy = policyDocs[index];

                        return PolicyEditSection(
                          id: policy.id,
                          title: policy['title'],
                          content: policy['content'],
                          onDelete: _deletePolicy,
                          onEdit: _editPolicy,
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

class PolicyEditSection extends StatefulWidget {
  final String id;
  final String title;
  final String content;
  final Function(String) onDelete;
  final Function(String, String, String) onEdit;

  const PolicyEditSection({
    super.key,
    required this.id,
    required this.title,
    required this.content,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  _PolicyEditSectionState createState() => _PolicyEditSectionState();
}

class _PolicyEditSectionState extends State<PolicyEditSection> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            Column(
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
                ElevatedButton(
                  onPressed: () {
                    widget.onEdit(widget.id, _titleController.text, _contentController.text);
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.content,
                  style: const TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => widget.onDelete(widget.id),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
