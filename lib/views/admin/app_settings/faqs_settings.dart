import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/button.dart';


class FAQsSettings extends StatefulWidget {
  const FAQsSettings({super.key});

  @override
  State<FAQsSettings> createState() => _FAQsSettingsState();
}

class _FAQsSettingsState extends State<FAQsSettings> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  Future<void> _addFAQ() async {
    if (_questionController.text.isEmpty || _answerController.text.isEmpty) {
      return;
    }
    await FirebaseFirestore.instance.collection('faqs').add({
      'question': _questionController.text,
      'answer': _answerController.text,
    });
    _questionController.clear();
    _answerController.clear();
  }

  Future<void> _editFAQ(String id, String question, String answer) async {
    _questionController.text = question;
    _answerController.text = answer;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit FAQ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
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
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('faqs').doc(id).update({
                  'question': _questionController.text,
                  'answer': _answerController.text,
                });
                _questionController.clear();
                _answerController.clear();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFAQ(String id) async {
    await FirebaseFirestore.instance.collection('faqs').doc(id).delete();
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
          title: const Text('Manage FAQs'),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
              ),
              const SizedBox(height: 10,),
              Button(
                onPressed: _addFAQ,
                child: const Text('Add FAQ'),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('faqs').orderBy('question').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading FAQs.'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No FAQs available.'));
                    }

                    final faqDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: faqDocs.length,
                      itemBuilder: (context, index) {
                        final faq = faqDocs[index];
                        return ListTile(
                          title: Text(faq['question']),
                          subtitle: Text(faq['answer']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editFAQ(faq.id, faq['question'], faq['answer']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteFAQ(faq.id);
                                },
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
