import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../services/gateway_service.dart';
import 'chat_page.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<Session> _sessions = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadSessions(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    try {
      final sessions = await GatewayService.getSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(title: 'SESSIONS', onRefresh: _loadSessions),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessions.isEmpty) {
      return _buildEmptyState();
    }
    return _buildSessionsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: CicadaColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No Active Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CicadaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to create a session',
            style: TextStyle(color: CicadaColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HudPanel(
            title: 'SESSION // ${session.id.substring(0, 8).toUpperCase()}',
            titleIcon: Icons.chat_bubble,
            accent: CicadaColors.data,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Recipient', session.recipient ?? 'Unknown'),
                          const SizedBox(height: 8),
                          _infoRow('Channel', session.channel ?? 'Direct'),
                          const SizedBox(height: 8),
                          _infoRow('Messages', session.messageCount.toString()),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Last Activity',
                          style: TextStyle(
                            fontSize: 11,
                            color: CicadaColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(session.lastActivity),
                          style: const TextStyle(
                            fontSize: 13,
                            color: CicadaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _continueSession(session),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Continue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CicadaColors.data,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CicadaColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _continueSession(Session session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _PageHeader({required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: CicadaColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: CicadaColors.muted),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
