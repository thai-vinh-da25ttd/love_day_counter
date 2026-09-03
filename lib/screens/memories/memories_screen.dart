import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/memory_model.dart';
import '../../repositories/memory_repository.dart';
import 'memory_editor_screen.dart';

class MemoriesScreen extends StatelessWidget {
  final String coupleId;

  const MemoriesScreen({
    super.key,
    required this.coupleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kỷ niệm')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MemoryEditorScreen(coupleId: coupleId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: MemoryRepository.instance.stream(coupleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memories = snapshot.data?.docs
                  .map(MemoryModel.fromFirestore)
                  .toList() ??
              [];

          if (memories.isEmpty) {
            return const Center(
              child: Text('Chưa có kỷ niệm nào.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (memory.imageUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          memory.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memory.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(memory.date),
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          if (memory.note.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(memory.note),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
