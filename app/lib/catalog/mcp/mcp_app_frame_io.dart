import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Creates a CatalogItem for the mcp:AppFrame component (native platforms).
///
/// Renders an MCP App HTML UI in a native WebView following the MCP Apps
/// protocol from https://github.com/modelcontextprotocol/ext-apps.
///
/// A JavaScript shim is injected into the loaded HTML so that the app can
/// use the standard `window.parent.postMessage(...)` API; the shim forwards
/// those calls to Flutter through the `_FlutterMcpBridge` JavaScript channel.
CatalogItem mcpAppFrameItem() {
  final schema = S.object(
    properties: {
      'mcpEndpointUrl': S.string(),
      'resourceUri': S.string(),
      'toolName': S.string(),
      'toolInput': S.object(properties: {}),
    },
    required: ['mcpEndpointUrl', 'resourceUri', 'toolName', 'toolInput'],
  );

  return CatalogItem(
    name: 'mcp:AppFrame',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;

      String resolveString(Object? value) {
        if (value is Map) {
          final path = value['path'];
          if (path is String) {
            return itemContext.dataContext.getValue<String>(DataPath(path)) ??
                '';
          }
        }
        return value is String ? value : '';
      }

      Map<String, Object?> resolveMap(Object? value) {
        if (value is Map) {
          final path = value['path'];
          if (path is String) {
            return itemContext.dataContext
                    .getValue<Map<String, Object?>>(DataPath(path)) ??
                {};
          }
          return value.cast<String, Object?>();
        }
        return {};
      }

      return McpAppFrameWidget(
        mcpEndpointUrl: resolveString(map['mcpEndpointUrl']),
        resourceUri: resolveString(map['resourceUri']),
        toolName: resolveString(map['toolName']),
        toolInput: resolveMap(map['toolInput']),
      );
    },
  );
}

/// Widget that renders an MCP App HTML UI in a native WebView.
class McpAppFrameWidget extends StatefulWidget {
  final String mcpEndpointUrl;
  final String resourceUri;
  final String toolName;
  final Map<String, Object?> toolInput;

  const McpAppFrameWidget({
    super.key,
    required this.mcpEndpointUrl,
    required this.resourceUri,
    required this.toolName,
    required this.toolInput,
  });

  @override
  State<McpAppFrameWidget> createState() => _McpAppFrameWidgetState();
}

class _McpAppFrameWidgetState extends State<McpAppFrameWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _toolInputSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        '_FlutterMcpBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _error = 'WebView error: ${error.description}';
              _isLoading = false;
            });
          }
        },
      ));
    _initFrame();
  }

  Future<void> _initFrame() async {
    final htmlContent = await _fetchResource();
    if (htmlContent == null) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load map UI from ${widget.resourceUri}';
          _isLoading = false;
        });
      }
      return;
    }

    // Inject a shim so the MCP app's window.parent.postMessage(...) calls
    // are intercepted and forwarded to Flutter via the JS channel.
    final shimmedHtml = _injectShim(htmlContent);
    await _controller.loadHtmlString(shimmedHtml);
    if (mounted) setState(() => _isLoading = false);
  }

  /// Prepends a <script> shim that overrides window.parent.postMessage so the
  /// MCP app can communicate with Flutter using the standard postMessage API.
  String _injectShim(String html) {
    const shim = '''<script>
(function(){
  Object.defineProperty(window,'parent',{
    configurable:true,
    get:function(){
      return {
        postMessage:function(data,targetOrigin,transfer){
          if(window._FlutterMcpBridge){
            window._FlutterMcpBridge.postMessage(JSON.stringify(data));
          }
        }
      };
    }
  });
})();
</script>''';

    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$shim');
    }
    if (html.contains('<HEAD>')) {
      return html.replaceFirst('<HEAD>', '<HEAD>$shim');
    }
    return '<html><head>$shim</head><body>$html</body></html>';
  }

  /// Sends the ui/notifications/tool-input message into the WebView after load.
  void _sendToolInput() {
    if (_toolInputSent) return;
    _toolInputSent = true;
    final message = {
      'jsonrpc': '2.0',
      'method': 'ui/notifications/tool-input',
      'params': {
        'arguments': widget.toolInput,
      },
    };
    _dispatchMessageToWebView(message);
  }

  /// Dispatches a JSON-RPC message into the WebView as a native `message` event.
  void _dispatchMessageToWebView(Map<String, dynamic> message) {
    final json = jsonEncode(message);
    _controller.runJavaScript(
      'window.dispatchEvent(new MessageEvent("message",{data:$json,origin:"*"}));',
    );
  }

  /// Handles incoming tools/call messages from the MCP app WebView.
  Future<void> _handleBridgeMessage(JavaScriptMessage jsMessage) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsMessage.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final method = data['method'];
    if (method is! String) return;
    if (method == 'ui/notifications/initialized') {
      _sendToolInput();
      return;
    }
    final id = data['id'];
    if (id == null) return;

    Map<String, dynamic> rpcResponse;
    if (method.startsWith('ui/')) {
      rpcResponse = _handleUiHostRequest(method, data['params']);
    } else if (method == 'ping') {
      rpcResponse = {'result': <String, Object?>{}};
    } else if (method == 'tools/list') {
      rpcResponse = await _callMcpRequest('tools/list', data['params']);
    } else if (method == 'tools/call') {
      final params = data['params'];
      if (params is! Map) {
        rpcResponse = {
          'error': {
            'code': -32602,
            'message': 'Invalid params: tools/call requires an object',
          },
        };
      } else {
        final toolName = params['name'] as String?;
        if (toolName == null) {
          rpcResponse = {
            'error': {
              'code': -32602,
              'message': 'Invalid params: tools/call requires name',
            },
          };
        } else {
          rpcResponse = await _callMcpRequest('tools/call', {
            'name': toolName,
            'arguments': params['arguments'] ?? <String, Object?>{},
          });
        }
      }
    } else {
      rpcResponse = {
        'error': {
          'code': -32601,
          'message': 'Method not found: $method',
        },
      };
    }
    _dispatchMessageToWebView({'jsonrpc': '2.0', 'id': id, ...rpcResponse});
  }

  Map<String, dynamic> _handleUiHostRequest(String method, Object? params) {
    if (method == 'ui/initialize') {
      var protocolVersion = '2026-01-26';
      if (params is Map && params['protocolVersion'] is String) {
        protocolVersion = params['protocolVersion'] as String;
      }
      return {
        'result': {
          'protocolVersion': protocolVersion,
          'hostInfo': {
            'name': 'aibank-host',
            'version': '0.1.0',
          },
          'hostCapabilities': {
            'openLinks': <String, Object?>{},
            'serverTools': {'listChanged': false},
            'serverResources': {'listChanged': false},
            'logging': <String, Object?>{},
            'updateModelContext': {
              'text': <String, Object?>{},
              'structuredContent': <String, Object?>{},
            },
            'message': {
              'text': <String, Object?>{},
              'structuredContent': <String, Object?>{},
            },
          },
          'hostContext': {
            'displayMode': 'inline',
            'availableDisplayModes': ['inline'],
          },
        },
      };
    }

    if (method == 'ui/request-display-mode') {
      return {
        'result': {'mode': 'inline'}
      };
    }

    if (method == 'ui/open-link' ||
        method == 'ui/update-model-context' ||
        method == 'ui/message' ||
        method == 'ui/resource-teardown' ||
        method == 'ui/notifications/initialized') {
      return {'result': <String, Object?>{}};
    }

    return {'result': <String, Object?>{}};
  }

  /// Fetches HTML content from the MCP server via resources/read.
  Future<String?> _fetchResource() async {
    if (widget.mcpEndpointUrl.isEmpty) return null;
    try {
      final payload = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'resources/read',
        'params': {'uri': widget.resourceUri},
      };
      final response = await http.post(
        Uri.parse(widget.mcpEndpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/event-stream',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) return null;

      for (final line in response.body.split('\n')) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final jsonStr = trimmed.substring('data:'.length).trim();
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final result = data['result'] as Map<String, dynamic>?;
          final contents = result?['contents'] as List?;
          if (contents != null && contents.isNotEmpty) {
            final html =
                (contents.first as Map<String, dynamic>)['text'] as String?;
            if (html == null) return null;
            return _patchMapHtml(html);
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Keep embedded map framing closer than upstream defaults and force
  // ellipsoid terrain to avoid Ion-terrain stalls in embedded contexts.
  String _patchMapHtml(String html) {
    var patched = html;
    patched = patched.replaceAll(
      RegExp(r'terrainProvider\s*:\s*void 0'),
      'terrainProvider:new Cesium.EllipsoidTerrainProvider()',
    );
    patched = patched.replaceAll(
      'I.info("Viewer created"),',
      'I.info("Viewer created"),e.terrainProvider=new Cesium.EllipsoidTerrainProvider(),',
    );
    patched = patched.replaceAll(
      RegExp(r'Math\.max\(\s*(?:1[eE]5|100000)\s*,'),
      'Math.max(1e4,',
    );
    patched = patched.replaceAllMapped(
      RegExp(r'Math\.max\(\s*([A-Za-z_$][\w$]*)\s*,\s*(?:5[eE]5|500000)\s*\)'),
      (match) => 'Math.max(${match.group(1)},5e4)',
    );
    return patched;
  }

  /// Forward an MCP JSON-RPC request to the MCP server and return result/error.
  Future<Map<String, dynamic>> _callMcpRequest(
    String method, [
    Object? params,
  ]) async {
    try {
      final payload = <String, Object?>{
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
      };
      if (params != null) payload['params'] = params;
      final response = await http.post(
        Uri.parse(widget.mcpEndpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/event-stream',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        return {
          'error': {
            'code': -32000,
            'message': 'HTTP ${response.statusCode}',
          },
        };
      }
      for (final line in response.body.split('\n')) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final jsonStr = trimmed.substring('data:'.length).trim();
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final error = data['error'];
          if (error is Map) {
            return {
              'error': error.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            };
          }
          final result = data['result'];
          if (result is Map) {
            return {
              'result': result.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            };
          }
        } catch (_) {
          continue;
        }
      }
      return {
        'error': {
          'code': -32000,
          'message': 'No MCP response data',
        },
      };
    } catch (e) {
      return {
        'error': {
          'code': -32000,
          'message': '$e',
        },
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 350,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return SizedBox(
      height: 350,
      child: WebViewWidget(controller: _controller),
    );
  }
}
