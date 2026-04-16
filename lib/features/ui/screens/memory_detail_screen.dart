import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';
import '../../memory/providers/memory_provider.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});

  final String memoryId;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  final _contentController = TextEditingController();
  final _datetimeController = TextEditingController();
  String _type = 'note';
  int _importance = 3;
  bool _loaded = false;
  late final Future<OmiMemory?> _memoryFuture;

  @override
  void initState() {
    super.initState();
    _memoryFuture = ref
        .read(memoryProvider.notifier)
        .getMemory(widget.memoryId);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _datetimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OmiMemory?>(
      future: _memoryFuture,
      builder: (context, snapshot) {
        final memory = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (memory == null) {
          return const Scaffold(body: Center(child: Text('Memory not found')));
        }

        if (!_loaded) {
          _contentController.text = memory.content;
          _datetimeController.text = memory.datetimeRaw ?? '';
          _type = memory.type;
          _importance = memory.importance;
          _loaded = true;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/memories'),
            ),
            title: const Text('Memory detail'),
            actions: [
              IconButton(
                onPressed: () async {
                  await ref
                      .read(memoryProvider.notifier)
                      .deleteMemory(memory.id);
                  if (context.mounted) {
                    context.go('/memories');
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Captured ${DateFormat('MMM d, yyyy - h:mm a').format(memory.createdAt)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Content'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _datetimeController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder datetime (raw)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const ['reminder', 'task', 'event', 'fact', 'note']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _type = value ?? _type;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('Importance: $_importance'),
                    Slider(
                      value: _importance.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$_importance',
                      onChanged: (value) {
                        setState(() {
                          _importance = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () async {
                        final updated = OmiMemory(
                          id: memory.id,
                          type: _type,
                          content: _contentController.text.trim(),
                          datetimeRaw: _datetimeController.text.trim().isEmpty
                              ? null
                              : _datetimeController.text.trim(),
                          importance: _importance,
                          createdAt: memory.createdAt,
                        );
                        try {
                          await ref
                              .read(memoryProvider.notifier)
                              .updateMemory(updated);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Update failed safely.'),
                              ),
                            );
                          }
                          return;
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Memory updated')),
                          );
                        }
                      },
                      child: const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}