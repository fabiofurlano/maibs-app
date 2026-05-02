import 'package:flutter/material.dart';

/// A2UI Widget — data model parsed from AG-UI A2UI_WIDGET events.
class A2UIWidget {
  final String widgetId;
  final String widgetType;
  final Map<String, dynamic> props;

  A2UIWidget({
    required this.widgetId,
    required this.widgetType,
    required this.props,
  });

  factory A2UIWidget.fromJson(Map<String, dynamic> json) {
    return A2UIWidget(
      widgetId: json['widgetId'] ?? '',
      widgetType: json['widgetType'] ?? 'unknown',
      props: Map<String, dynamic>.from(json['props'] ?? {}),
    );
  }
}

/// Converts A2UIWidget data models into Flutter widgets.
class A2UIFactory {
  static Widget build(BuildContext context, A2UIWidget a2ui) {
    switch (a2ui.widgetType) {
      case 'wiki_result':
        return _WikiResultCard(
          title: a2ui.props['title'] ?? '',
          snippet: a2ui.props['snippet'] ?? '',
        );
      case 'task_card':
        return _TaskCard(
          title: a2ui.props['title'] ?? '',
          description: a2ui.props['description'] ?? '',
          status: a2ui.props['status'] ?? 'pending',
        );
      case 'agent_status':
        return _AgentStatusChip(
          name: a2ui.props['name'] ?? '',
          status: a2ui.props['status'] ?? 'unknown',
        );
      default:
        return _UnknownWidget(type: a2ui.widgetType);
    }
  }
}

/// Wiki search result card — tappable, shows excerpt.
class _WikiResultCard extends StatelessWidget {
  final String title;
  final String snippet;

  const _WikiResultCard({required this.title, required this.snippet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.book, size: 14, color: Color(0xFFC9A84C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC9A84C),
                        fontFamily: 'Sora',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  snippet,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9090A0),
                    fontFamily: 'SpaceMono',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Task/action card — shows title, description, and status chip.
class _TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'completed':
        return const Color(0xFF4ADE80);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF707088);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _statusColor().withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8E0D0),
                        fontFamily: 'Sora',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 9,
                        color: _statusColor(),
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9090A0),
                    fontFamily: 'SpaceMono',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Agent status chip — compact indicator.
class _AgentStatusChip extends StatelessWidget {
  final String name;
  final String status;

  const _AgentStatusChip({required this.name, required this.status});

  Color _statusColor() {
    switch (status) {
      case 'online':
        return const Color(0xFF4ADE80);
      case 'busy':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF707088);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFD0D0E0),
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              color: _statusColor(),
              fontFamily: 'SpaceMono',
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback for unknown widget types.
class _UnknownWidget extends StatelessWidget {
  final String type;
  const _UnknownWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Widget: $type',
          style: const TextStyle(fontSize: 10, color: Color(0xFF707088)),
        ),
      ),
    );
  }
}
