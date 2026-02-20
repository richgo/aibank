import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:logging/logging.dart';

import '../catalog/banking_catalog.dart';
import '../catalog/catalog_callbacks.dart';
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
  final List<ChatMessage> _messages = [];
  final List<String> _surfaceIds = [];

  A2uiMessageProcessor? _processor;
  A2uiContentGenerator? _generator;
  GenUiConversation? _conversation;

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
            _surfaceIds.add(added.surfaceId);
            widget.onSurfaceListChanged?.call(_surfaceIds);
          });
        },
        onSurfaceDeleted: (removed) {
          setState(() {
            _surfaceIds.remove(removed.surfaceId);
            widget.onSurfaceListChanged?.call(_surfaceIds);
          });
        },
      );

      _generator!.textResponseStream.listen((text) {
        setState(() => _messages.insert(0, AiTextMessage.text(text)));
      });
      _generator!.errorStream.listen((error) {
        _logger.warning(error.error);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${error.error}')));
        }
      });
    }

    CatalogCallbacks.onAccountTap = (accountName) {
      _sendMessage('Show transactions for $accountName');
    };
    CatalogCallbacks.onAccountDetailTap = (accountName) {
      _sendMessage('show details for $accountName');
    };
    CatalogCallbacks.onBackToOverview = () {
      _sendMessage('show my accounts');
    };
  }

  @override
  void dispose() {
    CatalogCallbacks.onAccountTap = null;
    CatalogCallbacks.onAccountDetailTap = null;
    CatalogCallbacks.onBackToOverview = null;
    _controller.dispose();
    _conversation?.dispose();
    _generator?.dispose();
    _processor?.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final msg = UserMessage.text(text);
    setState(() => _messages.insert(0, msg));
    _conversation?.sendRequest(msg);
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    final msg = UserMessage.text(text);
    setState(() => _messages.insert(0, msg));
    _conversation?.sendRequest(msg);
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
            child: ListView(
              reverse: true,
              children: [
                if (_messages.isEmpty && _surfaceIds.isEmpty)
                  const ListTile(
                    title: Text('Ask: "show my accounts"'),
                    subtitle: Text('If nothing appears, start the backend agent at http://127.0.0.1:8080.'),
                  ),
                ..._messages.map((m) {
                  final isUser = m is UserMessage;
                  final text = switch (m) {
                    UserMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                    AiTextMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                    AiUiMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                    _ => '',
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFFE8F5E9) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isUser ? null : [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(text),
                      ),
                    ),
                  );
                }),
                ..._surfaceIds.map((id) => _processor == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 160, maxHeight: 560),
                            child: GenUiSurface(host: _processor!, surfaceId: id),
                          )
                        ),
                      )),
              ],
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
