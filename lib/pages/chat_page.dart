import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../services/gateway_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  bool _isLoading = false;
  String _target = 'agent'; // default target
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      await GatewayService.connect();
      _messageSub = GatewayService.messageStream.listen(_onMessage);
      setState(() => _isConnected = true);
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _onMessage(GatewayMessage message) {
    if (message.type == 'response' || message.type == 'message') {
      setState(() {
        _messages.add(
          ChatMessage(
            content: message.content?.toString() ?? '',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(content: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      if (_isConnected) {
        GatewayService.sendMessage(_target, text);
      } else {
        // Fallback to CLI
        final result = await GatewayService.runAgent(
          message: text,
          deliver: false,
        );
        if (result != null && mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                content: result.response,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              content: 'Error: $e',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: HudPanel(
              title: 'CONVERSATION',
              titleIcon: Icons.chat,
              accent: CicadaColors.data,
              child: _buildChatContent(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AGENT CHAT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: CicadaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              _StatusIndicator(
                isActive: _isConnected,
                activeText: 'Connected',
                inactiveText: 'Disconnected',
              ),
            ],
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _target,
            items: const [
              DropdownMenuItem(value: 'agent', child: Text('Agent')),
              DropdownMenuItem(value: 'gateway', child: Text('Gateway')),
            ],
            onChanged: (v) => setState(() => _target = v ?? 'agent'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: CicadaColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation with the agent',
              style: TextStyle(color: CicadaColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessage(_messages[index]),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: CicadaColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: CicadaColors.textTertiary),
                filled: true,
                fillColor: CicadaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CicadaColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CicadaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CicadaColors.data),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendMessage,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send),
              label: const Text('SEND'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CicadaColors.data,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                message.isUser
                    ? CicadaColors.data.withAlpha(40)
                    : message.isError
                    ? CicadaColors.alert.withAlpha(40)
                    : CicadaColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  message.isUser
                      ? CicadaColors.data
                      : message.isError
                      ? CicadaColors.alert
                      : CicadaColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color:
                      message.isError
                          ? CicadaColors.alert
                          : CicadaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: CicadaColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String activeText;
  final String inactiveText;

  const _StatusIndicator({
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? CicadaColors.ok : CicadaColors.alert;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? activeText : inactiveText,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
