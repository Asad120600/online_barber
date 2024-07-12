import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                return HelpSection(
                  number: index + 1, // Add the numbering here
                  title: help['title'],
                  content: help['content'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class HelpSection extends StatelessWidget {
  final int number;
  final String title;
  final String content;

  const HelpSection({super.key, required this.number, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title', // Display the number here
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
