import 'package:flutter/material.dart';
import '../services/agui_client.dart';
import '../services/audio_player.dart';

class FeedScreen extends StatefulWidget {
  final AguiClient client;
  final CompanionAudio audio;
  const FeedScreen({super.key, required this.client, required this.audio});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onUpdate);
    widget.audio.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.client.removeListener(_onUpdate);
    widget.audio.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cards = widget.client.cards;

    return Container(
      color: const Color(0xFF0B0D14),
      child: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No cards from server',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for connection...',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => _buildCard(cards[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final conn = widget.client.connected;
    final mode = widget.client.mode.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF131624),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: conn ? const Color(0xFF4ADE80) : Colors.redAccent,
              boxShadow: conn
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            conn ? '$mode — MAIBS Connected' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: conn ? const Color(0xFFC9A84C) : Colors.grey,
                ),
          ),
          const Spacer(),
          Text(
            '${widget.client.cards.length} cards',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(TouchEnvelope card) {
    Color accent;
    IconData icon;

    switch (card.format) {
      case 'brief':
        accent = const Color(0xFFC9A84C);
        icon = Icons.wb_sunny;
        break;
      case 'decide':
        accent = const Color(0xFFF59E0B);
        icon = Icons.pending;
        break;
      case 'status':
        accent = const Color(0xFF4ADE80);
        icon = Icons.check_circle_outline;
        break;
      case 'audio':
        accent = const Color(0xFF60A5FA);
        icon = Icons.headphones;
        break;
      default:
        accent = const Color(0xFF818CF8);
        icon = Icons.article;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: accent,
                          ),
                    ),
                  ),
                ],
              ),
              if (card.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  card.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD0D0E0),
                      ),
                ),
              ],
              // Audio play button
              if (card.format == 'audio') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _AudioPlayButton(
                      audio: widget.audio,
                      audioPath: card.audioUrl ?? '',
                      transcript: card.body,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                card.timestamp,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline play/pause button for audio cards.
class _AudioPlayButton extends StatelessWidget {
  final CompanionAudio audio;
  final String audioPath;
  final String transcript;

  const _AudioPlayButton({
    required this.audio,
    required this.audioPath,
    required this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    final isThisPlaying = audio.isPlaying && audio.currentUrl?.contains(audioPath.split('/').last) == true;

    return GestureDetector(
      onTap: () {
        if (isThisPlaying) {
          audio.stop();
        } else {
          audio.play(audioPath);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isThisPlaying ? Icons.pause : Icons.play_arrow,
              size: 18,
              color: const Color(0xFF60A5FA),
            ),
            const SizedBox(width: 6),
            Text(
              isThisPlaying ? 'Playing...' : 'Play voice',
              style: TextStyle(
                color: const Color(0xFF60A5FA),
                fontSize: 13,
                fontFamily: 'SpaceMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
