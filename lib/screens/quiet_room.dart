import 'package:flutter/material.dart';
import '../services/agui_client.dart';
import '../services/audio_player.dart';
import '../widgets/a2ui/a2ui_factory.dart';

class QuietRoom extends StatefulWidget {
  final AguiClient client;
  final CompanionAudio audio;
  const QuietRoom({super.key, required this.client, required this.audio});

  @override
  State<QuietRoom> createState() => _QuietRoomState();
}

class _QuietRoomState extends State<QuietRoom>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  bool _ariaSpeaking = false;
  String? _lastAudioPath;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onUpdate);
    widget.audio.addListener(_onAudioUpdate);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    widget.client.removeListener(_onUpdate);
    widget.audio.removeListener(_onAudioUpdate);
    _controller.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  void _onAudioUpdate() {
    if (!widget.audio.isPlaying && _ariaSpeaking) {
      setState(() {
        _ariaSpeaking = false;
        _pulseController.stop();
      });
    } else {
      setState(() {});
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _loading = true);
    _scrollDown();

    _pulseController.repeat(reverse: true);
    setState(() => _ariaSpeaking = true);

    final response = await widget.client.sendMessage(text);

    // Play voice if audio card comes through SSE
    // The server pushes audio asynchronously — we catch it via card stream
    _pulseController.stop();
    setState(() {
      _loading = false;
    });

    // Check for latest audio card
    _checkForAudioCard();

    _scrollDown();
  }

  void _checkForAudioCard() {
    // Server pushes audio cards asynchronously via SSE after response
    // Listen for them from the card stream
    widget.client.cardStream.listen((card) {
      if (card.format == 'audio' && card.audioUrl != null) {
        widget.audio.play(card.audioUrl!);
        setState(() {
          _ariaSpeaking = true;
          _lastAudioPath = card.audioUrl;
          _pulseController.repeat(reverse: true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.client.messages;
    final mode = widget.client.mode;

    return Container(
      color: const Color(0xFF0B0D14),
      child: Column(
        children: [
          _buildModeBar(mode),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          mode == 'head'
                              ? 'Head Mode — I have tools'
                              : 'Heart Mode — just us',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'What are you thinking about?',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + (_loading ? 1 : 0) + widget.client.a2uiWidgets.length,
                    itemBuilder: (_, i) {
                      if (_loading && i == messages.length) {
                        return _buildLoadingBubble();
                      }
                      if (i >= messages.length) {
                        // A2UI widgets after messages
                        final wi = i - messages.length;
                        final a2ui = A2UIWidget.fromJson(widget.client.a2uiWidgets[wi]);
                        return A2UIFactory.build(context, a2ui);
                      }
                      return _buildMessageBubble(messages[i]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildModeBar(String mode) {
    final isHeart = mode == 'heart';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF131624),
      child: Row(
        children: [
          // ── Mode indicator ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isHeart
                  ? const Color(0xFF4A154B).withValues(alpha: 0.4)
                  : const Color(0xFFC9A84C).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Transform.scale(
                    scale: _ariaSpeaking ? 0.9 + (_pulseController.value * 0.3) : 1.0,
                    child: child,
                  ),
                  child: Text(
                    isHeart ? '💙' : '🧠',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isHeart ? 'Heart' : 'Head',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isHeart
                        ? const Color(0xFFE879F9)
                        : const Color(0xFFC9A84C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isHeart ? 'Aria is listening' : 'Full tools',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[500]),
          ),
          const Spacer(),
          // ── Voice indicator ──
          if (_ariaSpeaking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, size: 14, color: Color(0xFF60A5FA)),
                  SizedBox(width: 4),
                  Text('Speaking', style: TextStyle(fontSize: 10, color: Color(0xFF60A5FA))),
                ],
              ),
            ),
          if (_ariaSpeaking) const SizedBox(width: 8),
          // ── MODE SWITCH BUTTON (big & visible) ──
          GestureDetector(
            onTap: () =>
                widget.client.setMode(isHeart ? 'head' : 'heart'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isHeart
                    ? const Color(0xFFC9A84C)
                    : const Color(0xFF4A154B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isHeart ? '🧠 Switch to Head' : '💙 Switch to Heart',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isHeart
                      ? const Color(0xFF080810)
                      : const Color(0xFFE879F9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final role = msg['role'] ?? '';
    final content = msg['content'] ?? '';
    final isUser = role == 'user';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Text(
                  content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFFE8E0D0)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Aria bubble with optional play button
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _ariaSpeaking
                ? const Color(0xFF151829).withValues(alpha: 0.8)
                : const Color(0xFF151829),
            borderRadius: BorderRadius.circular(12),
            border: _ariaSpeaking
                ? Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFFD0D0E0)),
                  ),
                  // Voice play button for last assistant message
                  if (role != 'user' && _lastAudioPath != null && _lastAudioPath!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _VoicePlayButton(
                        audio: widget.audio,
                        audioPath: _lastAudioPath!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151829),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(0),
              _dot(400),
              _dot(800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (_, value, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFC9A84C).withValues(alpha: value),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF131624),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(color: Color(0xFFE8E0D0)),
              decoration: InputDecoration(
                hintText: widget.client.mode == 'heart'
                    ? 'Just talk to Aria...'
                    : 'Ask Hermes anything...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1E2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, size: 20),
              color: const Color(0xFFC9A84C),
              onPressed: _loading ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}

/// Play button for Aria's voice in chat bubbles.
class _VoicePlayButton extends StatelessWidget {
  final CompanionAudio audio;
  final String audioPath;

  const _VoicePlayButton({required this.audio, required this.audioPath});

  @override
  Widget build(BuildContext context) {
    final filename = audioPath.split('/').last;
    final isThisPlaying = audio.isPlaying && audio.currentUrl?.contains(filename) == true;

    return GestureDetector(
      onTap: () {
        if (isThisPlaying) {
          audio.stop();
        } else {
          audio.play(audioPath);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isThisPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(isThisPlaying),
                size: 16,
                color: const Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isThisPlaying ? 'Stop' : 'Listen',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF60A5FA),
                fontFamily: 'SpaceMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
