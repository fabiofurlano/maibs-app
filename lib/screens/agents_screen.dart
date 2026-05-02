import 'package:flutter/material.dart';
import '../services/agui_client.dart';

class AgentsScreen extends StatefulWidget {
  final AguiClient client;
  const AgentsScreen({super.key, required this.client});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onUpdate);
    widget.client.fetchAgentStatus();
  }

  @override
  void dispose() {
    widget.client.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final agents = widget.client.agents;

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
                    const Icon(Icons.dns, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 8),
                    Text(
                      'Agents',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${agents.length} in fleet',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your agent fleet. Running on ThinkPad, accessed over Tailscale.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: agents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dns_outlined,
                            size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'Loading agent fleet...',
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
                    itemCount: agents.length,
                    itemBuilder: (_, i) => _buildAgentCard(agents[i]),
                  ),
          ),
          // Refresh button
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF131624),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.client.fetchAgentStatus(),
                icon: const Icon(Icons.refresh, size: 16,
                    color: Color(0xFFC9A84C)),
                label: Text(
                  'Refresh',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: const Color(0xFFC9A84C)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFFC9A84C), width: 0.5),
                  backgroundColor:
                      const Color(0xFFC9A84C).withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final name = agent['name'] ?? 'Unknown';
    final status = agent['status'] ?? 'offline';
    final lastActive = agent['last_active'] ?? 'never';

    Color statusColor;
    IconData statusIcon;

    switch (status.toString().toLowerCase()) {
      case 'online':
        statusColor = const Color(0xFF4ADE80);
        statusIcon = Icons.check_circle;
        break;
      case 'busy':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_top;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          leading: Icon(statusIcon, color: statusColor, size: 28),
          title: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            status == 'online' ? 'Running — $lastActive' : lastActive.toString(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toString().toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
