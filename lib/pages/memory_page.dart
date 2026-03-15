import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../services/gateway_service.dart';

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<MemoryEntry> _results = [];
  bool _searching = false;
  String? _lastQuery;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _lastQuery = query;
    });

    try {
      final results = await GatewayService.searchMemory(query, limit: 20);
      if (mounted) {
        setState(() {
          _results.clear();
          _results.addAll(results);
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: CicadaColors.alert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _results.isEmpty ? _buildEmptyState() : _buildResultsList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEMORY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search through agent memory and conversation history',
            style: TextStyle(color: CicadaColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: CicadaColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search memory...',
              hintStyle: TextStyle(color: CicadaColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: CicadaColors.muted),
              filled: true,
              fillColor: CicadaColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CicadaColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CicadaColors.data),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _searching ? null : _search,
            icon:
                _searching
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.search),
            label: const Text('SEARCH'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CicadaColors.data,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.memory, size: 64, color: CicadaColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _lastQuery == null
                ? 'Enter a query to search memory'
                : 'No results found for "$_lastQuery"',
            style: TextStyle(color: CicadaColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildMemoryCard(_results[index]),
    );
  }

  Widget _buildMemoryCard(MemoryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HudPanel(
        title: 'MEMORY ENTRY // ${entry.id.substring(0, 8).toUpperCase()}',
        titleIcon: Icons.storage,
        accent: CicadaColors.data,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.content,
              style: const TextStyle(color: CicadaColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildEntryFooter(entry),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryFooter(MemoryEntry entry) {
    return Row(
      children: [
        if (entry.relevance != null) ...[
          _buildMetric(
            'Relevance',
            '${(entry.relevance! * 100).toStringAsFixed(1)}%',
          ),
          const SizedBox(width: 24),
        ],
        _buildMetric('Timestamp', _formatDate(entry.timestamp)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _showDetails(entry),
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Details'),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: CicadaColors.textTertiary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CicadaColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showDetails(MemoryEntry entry) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: CicadaColors.surface,
            title: const Text(
              'Memory Entry Details',
              style: TextStyle(color: CicadaColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('ID', entry.id, CicadaColors.textSecondary),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Content',
                    entry.content,
                    CicadaColors.textPrimary,
                  ),
                  if (entry.metadata.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Metadata:',
                      style: TextStyle(color: CicadaColors.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    ...entry.metadata.entries.map(
                      (e) => Text(
                        '${e.key}: ${e.value}',
                        style: TextStyle(color: CicadaColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: TextStyle(color: CicadaColors.textTertiary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor)),
      ],
    );
  }
}
