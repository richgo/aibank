import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../catalog/banking_catalog.dart';

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
          : (kIsWeb ? 'http://${Uri.base.host}:8080' : 'http://10.0.2.2:8080');
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
    _fetchFallbackData(text);
  }

  Future<void> _fetchFallbackData(String text) async {
    final serverUrl = (widget.serverUrl?.trim().isNotEmpty ?? false)
        ? widget.serverUrl!.trim()
        : (kIsWeb ? 'http://${Uri.base.host}:8080' : 'http://10.0.2.2:8080');
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/chat'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      if (response.statusCode != 200) return;
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return;
      final data = payload['data'];
      if (data is! Map<String, dynamic>) return;
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      setState(() => _messages.insert(0, AiTextMessage.text('Data:\n$pretty')));
    } catch (error) {
      _logger.warning('Fallback data fetch failed: $error');
    }
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
                if (_messages.isEmpty && _surfaceIds.isEmpty)
                  const ListTile(
                    title: Text('Ask: "show my accounts"'),
                    subtitle: Text('If nothing appears, start the backend agent at http://127.0.0.1:8080.'),
                  ),
                ..._messages.map((m) => ListTile(title: Text(switch (m) {
                  UserMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                  AiTextMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                  AiUiMessage(:final parts) => parts.whereType<TextPart>().map((e) => e.text).join('\n'),
                  _ => '',
                }))),
                ..._surfaceIds.map((id) => _processor == null
                    ? const SizedBox.shrink()
                    : SizedBox(height: 320, child: GenUiSurface(host: _processor!, surfaceId: id))),
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
