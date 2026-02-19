import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:logging/logging.dart';

import '../catalog/banking_catalog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.enableAgent = true,
    this.serverUrl = const String.fromEnvironment('AIBANK_AGENT_URL', defaultValue: 'http://10.0.2.2:8080'),
  });

  final bool enableAgent;
  final String serverUrl;

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
      _processor = A2uiMessageProcessor(catalogs: buildBankingCatalogs());
      _generator = A2uiContentGenerator(serverUrl: Uri.parse(widget.serverUrl));
      _conversation = GenUiConversation(
        contentGenerator: _generator!,
        a2uiMessageProcessor: _processor!,
        onSurfaceAdded: (added) => setState(() => _surfaceIds.add(added.surfaceId)),
        onSurfaceDeleted: (removed) => setState(() => _surfaceIds.remove(removed.surfaceId)),
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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIBank')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: [
                ..._surfaceIds.map((id) => _processor == null
                    ? const SizedBox.shrink()
                    : SizedBox(height: 320, child: GenUiSurface(host: _processor!, surfaceId: id))),
                ..._messages.map((m) => ListTile(title: Text(switch (m) {
                  UserMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                  AiTextMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                  AiUiMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                  _ => '',
                }))),
              ],
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, onSubmitted: (_) => _send())),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
