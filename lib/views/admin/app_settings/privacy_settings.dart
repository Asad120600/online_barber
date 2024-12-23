import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../utils/button.dart'; // Replace with your custom button implementation

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

  Future<void> _editPolicy(String id, String title, String content) async {
    _titleController.text = title;
    _contentController.text = content;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.edit_privacy_policy),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                ),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.content),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                await _firestore.collection('privacyPolicies').doc(id).update({
                  'title': _titleController.text,
                  'content': _contentController.text,
                });
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePolicy(String id) async {
    await _firestore.collection('privacyPolicies').doc(id).delete();
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
          title: Text(AppLocalizations.of(context)!.privacy_policy_settings),
        ),
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                            ),
                            const SizedBox(height: 8.0),
                            TextField(
                              controller: _contentController,
                              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.content),
                              maxLines: 5,
                            ),
                            const SizedBox(height: 16.0),
                            Button(
                              onPressed: _addPolicy,
                              child: Text(AppLocalizations.of(context)!.add_policy),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('privacyPolicies').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text(AppLocalizations.of(context)!.error_loading_policies));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(child: Text(AppLocalizations.of(context)!.no_policies_available));
                          }

                          final policyDocs = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: policyDocs.length,
                            itemBuilder: (context, index) {
                              final policy = policyDocs[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4.0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    policy['title'],
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    policy['content'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _editPolicy(policy.id, policy['title'], policy['content']);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deletePolicy(policy.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
