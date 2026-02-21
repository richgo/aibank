import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:logging/logging.dart';

import '../catalog/banking_catalog.dart';
import '../widgets/brand_logo.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.enableAgent = true,
    this.serverUrl,
    this.testProcessor,
    this.onSurfaceListChanged,
  });

  final bool enableAgent;
  final String? serverUrl;
  final A2uiMessageProcessor? testProcessor;
  final ValueChanged<List<String>>? onSurfaceListChanged;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _logger = Logger('ChatScreen');
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _entries = [];

  A2uiMessageProcessor? _processor;
  A2uiContentGenerator? _generator;
  GenUiConversation? _conversation;
  String? _activeSurfaceId;

  @override
  void initState() {
    super.initState();
    if (widget.enableAgent) {
      final serverUrl = (widget.serverUrl?.trim().isNotEmpty ?? false)
          ? widget.serverUrl!.trim()
          : (kIsWeb
              ? 'http://${Uri.base.host}:8080'
              : defaultTargetPlatform == TargetPlatform.android
                  ? 'http://10.0.2.2:8080'
                  : 'http://127.0.0.1:8080');
      _processor = widget.testProcessor ?? A2uiMessageProcessor(catalogs: buildBankingCatalogs());
      _generator = A2uiContentGenerator(serverUrl: Uri.parse(serverUrl));
      _conversation = GenUiConversation(
        contentGenerator: _generator!,
        a2uiMessageProcessor: _processor!,
        onSurfaceAdded: (added) {
          setState(() {
            _activeSurfaceId = added.surfaceId;
            // Add surface entry after the latest AI text
            _entries.add(_ChatEntry.surface(added.surfaceId));
            widget.onSurfaceListChanged?.call([added.surfaceId]);
          });
          _scrollToBottom();
        },
        onSurfaceDeleted: (removed) {
          setState(() {
            if (_activeSurfaceId == removed.surfaceId) {
              _activeSurfaceId = null;
            }
            widget.onSurfaceListChanged?.call(
              _activeSurfaceId != null ? [_activeSurfaceId!] : [],
            );
          });
        },
      );

      _generator!.textResponseStream.listen((text) {
        setState(() => _entries.add(_ChatEntry.aiText(text)));
        _scrollToBottom();
      });
      _generator!.errorStream.listen((error) {
        _logger.warning(error.error);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${error.error}')));
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _conversation?.dispose();
    _generator?.dispose();
    _processor?.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _entries.add(_ChatEntry.user(text)));
    _conversation?.sendRequest(UserMessage.text(text));
    _scrollToBottom();
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    setState(() => _entries.add(_ChatEntry.user(text)));
    _conversation?.sendRequest(UserMessage.text(text));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 32),
            const SizedBox(width: 10),
            Text('AIBank', style: Theme.of(context).appBarTheme.titleTextStyle),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _entries.isEmpty ? 1 : _entries.length,
              itemBuilder: (context, index) {
                if (_entries.isEmpty) {
                  return const ListTile(
                    title: Text('Ask: "show my accounts"'),
                    subtitle: Text('If nothing appears, start the backend agent at http://127.0.0.1:8080.'),
                  );
                }
                final entry = _entries[index];
                switch (entry.type) {
                  case _EntryType.user:
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(entry.text!),
                        ),
                      ),
                    );
                  case _EntryType.aiText:
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Text(entry.text!),
                        ),
                      ),
                    );
                  case _EntryType.surface:
                    if (_processor == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GenUiSurface(host: _processor!, surfaceId: entry.surfaceId!),
                      ),
                    );
                }
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a banking question...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _EntryType { user, aiText, surface }

class _ChatEntry {
  final _EntryType type;
  final String? text;
  final String? surfaceId;

  const _ChatEntry._(this.type, {this.text, this.surfaceId});
  factory _ChatEntry.user(String text) => _ChatEntry._(_EntryType.user, text: text);
  factory _ChatEntry.aiText(String text) => _ChatEntry._(_EntryType.aiText, text: text);
  factory _ChatEntry.surface(String id) => _ChatEntry._(_EntryType.surface, surfaceId: id);
}
