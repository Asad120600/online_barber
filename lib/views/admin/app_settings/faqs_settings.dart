import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
          title: Text(AppLocalizations.of(context)!.edit_faq),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.question),
              ),
              TextField(
                controller: _answerController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.answer),
              ),
            ],
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
                await FirebaseFirestore.instance.collection('faqs').doc(id).update({
                  'question': _questionController.text,
                  'answer': _answerController.text,
                });
                _questionController.clear();
                _answerController.clear();
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
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
          title: Text(AppLocalizations.of(context)!.manage_faqs),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
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
                      controller: _questionController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.question),
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _answerController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.answer),
                    ),
                    const SizedBox(height: 16.0),
                    Button(
                      onPressed: _addFAQ,
                      child: Text(AppLocalizations.of(context)!.add_faq),
                    ),
                  ],
                ),
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
                      return Center(child: Text(AppLocalizations.of(context)!.error_loading_faqs));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(AppLocalizations.of(context)!.no_faqs_available));
                    }

                    final faqDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: faqDocs.length,
                      itemBuilder: (context, index) {
                        final faq = faqDocs[index];
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
