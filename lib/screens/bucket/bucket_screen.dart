import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/bucket_model.dart';
import '../../repositories/bucket_repository.dart';

class BucketScreen extends StatefulWidget {
  final String coupleId;

  const BucketScreen({
    super.key,
    required this.coupleId,
  });

  @override
  State<BucketScreen> createState() => _BucketScreenState();
}

class _BucketScreenState extends State<BucketScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    await BucketRepository.instance.add(
      coupleId: widget.coupleId,
      title: title,
      createdBy: FirebaseAuth.instance.currentUser!.uid,
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bucket list')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: Đi Đà Lạt cùng nhau',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: BucketRepository.instance.stream(widget.coupleId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = snapshot.data?.docs
                        .map(BucketModel.fromFirestore)
                        .toList() ??
                    [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Chưa có mục nào.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      child: CheckboxListTile(
                        value: item.completed,
                        onChanged: (value) {
                          BucketRepository.instance.toggle(
                            coupleId: widget.coupleId,
                            itemId: item.id,
                            completed: value ?? false,
                          );
                        },
                        title: Text(
                          item.title,
                          style: TextStyle(
                            decoration: item.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        secondary: IconButton(
                          onPressed: () {
                            BucketRepository.instance.delete(
                              coupleId: widget.coupleId,
                              itemId: item.id,
                            );
                          },
                          icon: const Icon(Icons.delete_outline),
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
    );
  }
}
