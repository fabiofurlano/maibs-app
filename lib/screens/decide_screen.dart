import 'package:flutter/material.dart';
import '../services/agui_client.dart';

class DecideScreen extends StatefulWidget {
  final AguiClient client;
  const DecideScreen({super.key, required this.client});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onUpdate);
    widget.client.fetchDecideQueue();
  }

  @override
  void dispose() {
    widget.client.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = widget.client.decideItems;

    return Container(
      color: const Color(0xFF0B0D14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF131624),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pending, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Decide',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} pending',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  items.isEmpty
                      ? 'No decisions waiting. Hermes will ask when there is something.'
                      : "These are things agents can't decide alone. Your call.",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'Nothing to decide',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _buildDecisionCard(items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic> item) {
    final id = item['id'] ?? '';
    final title = item['title'] ?? 'Decision needed';
    final options = List<String>.from(item['options'] ?? []);
    final contextText = item['context'] as String?;
    final source = item['source'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (source.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            source,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFF59E0B)),
                          ),
                        ),
                    ],
                  ),
                  if (contextText != null && contextText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      contextText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFFB0B0C0)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      const Color(0xFF4ADE80), // green - approve
                      const Color(0xFFF59E0B), // amber - defer
                      const Color(0xFFEF4444), // red - reject
                    ].asMap().entries.map((e) {
                      final label = options.isNotEmpty
                          ? options[e.key.clamp(0, options.length - 1)]
                          : ['Approve', 'Defer', 'Reject'][e.key];
                      return _optionChip(
                        label: label,
                        color: e.value,
                        onTap: () => _handleDecision(id, label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDecision(String id, String label) {
    final choice = label.toLowerCase();
    final valid = ['approve', 'defer', 'reject', 'dismiss'];
    final mapped = valid.contains(choice) ? choice : 'defer';
    if (mapped == 'dismiss') return; // system health card, just refresh

    widget.client.decide(id, mapped).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $label'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF1A1E2E),
          ),
        );
        // Refresh after short delay so server processes
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.client.fetchDecideQueue();
        });
      }
    });
  }

  Widget _optionChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
