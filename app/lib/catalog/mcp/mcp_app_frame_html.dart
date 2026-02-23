// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema_builder/json_schema_builder.dart';

/// Creates a CatalogItem for the mcp:AppFrame component.
///
/// Renders an MCP App HTML UI in a sandboxed iframe following the MCP Apps
/// protocol from https://github.com/modelcontextprotocol/ext-apps.
///
/// Protocol flow:
///   1. Fetch HTML from MCP server via resources/read
///   2. Render HTML in sandboxed iframe (srcdoc)
///   3. Post ui/notifications/tool-input to iframe after load
///   4. Relay tools/call postMessages from iframe back to the MCP server
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

      // Resolve a value that may be a literal string or a path-binding map
      // {"path": "/frame/foo"} → looked up in dataContext.
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

      final mcpEndpointUrl = resolveString(map['mcpEndpointUrl']);
      final resourceUri = resolveString(map['resourceUri']);
      final toolName = resolveString(map['toolName']);
      final toolInput = resolveMap(map['toolInput']);

      return McpAppFrameWidget(
        mcpEndpointUrl: mcpEndpointUrl,
        resourceUri: resourceUri,
        toolName: toolName,
        toolInput: toolInput,
      );
    },
  );
}

/// Widget that renders an MCP App HTML UI in a sandboxed iframe.
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
  String? _viewId;
  bool _isLoading = true;
  bool _toolInputSent = false;
  String? _error;
  StreamSubscription<html.Event>? _iframeLoadSubscription;
  StreamSubscription<html.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _viewId = 'mcp-app-frame-${DateTime.now().millisecondsSinceEpoch}';
    _initFrame();
  }

  @override
  void dispose() {
    _iframeLoadSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initFrame() async {
    try {
      // 1. Fetch HTML from MCP server via resources/read
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

      // 2. Create sandboxed iframe; write HTML via document.write (matching
      // basic-host behavior, which is more reliable for the Cesium map app
      // than srcdoc).
      final iframe = html.IFrameElement()
        ..src = 'about:blank'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute(
            'sandbox', 'allow-scripts allow-same-origin allow-forms');

      var htmlInjected = false;
      _iframeLoadSubscription = iframe.onLoad.listen((_) {
        if (!htmlInjected) {
          htmlInjected = true;
          final targetWindow = iframe.contentWindow;
          if (targetWindow is html.Window) {
            try {
              final jsDoc =
                  js.JsObject.fromBrowserObject(targetWindow.document);
              jsDoc.callMethod('open');
              jsDoc.callMethod('write', [htmlContent]);
              jsDoc.callMethod('close');
            } catch (_) {
              iframe.srcdoc = htmlContent;
            }
          } else {
            iframe.srcdoc = htmlContent;
          }
          return;
        }

        _sendToolInputToIframe(iframe);
        _iframeLoadSubscription?.cancel();
        _iframeLoadSubscription = null;
      });

      // 3. Register the iframe with the Flutter platform view registry
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => iframe,
      );

      // 4. Relay loop: forward tools/call from iframe to MCP server
      _messageSubscription = html.window.onMessage.listen((event) async {
        final source = event.source;
        if (source is! html.WindowBase) return;

        final data = _decodeMessageData(event.data);
        if (data == null) return;
        final method = data['method'];
        if (method is! String) return;
        if (method == 'ui/notifications/initialized') {
          _sendToolInputToIframe(iframe);
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
        _postToWindow(source, {'jsonrpc': '2.0', 'id': id, ...rpcResponse});
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error initialising map: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _sendToolInputToIframe(html.IFrameElement iframe) {
    if (_toolInputSent) return;
    _toolInputSent = true;
    _postToIframe(iframe, {
      'jsonrpc': '2.0',
      'method': 'ui/notifications/tool-input',
      'params': {
        'arguments': widget.toolInput,
      },
    });
  }

  /// Fetch HTML content from the MCP server via resources/read.
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

      // Response is SSE — find the "data:" line and parse
      for (final line in response.body.split('\n')) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final jsonStr = trimmed.substring('data:'.length).trim();
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final result = data['result'] as Map<String, dynamic>?;
          final contents = result?['contents'] as List?;
          if (contents != null && contents.isNotEmpty) {
            final first = contents.first as Map<String, dynamic>;
            final html = first['text'] as String?;
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

  // Clamp the bundled map app minimum camera height to 1km.
  String _patchMapHtml(String html) {
    var patched = html;
    patched = patched.replaceAll(
      RegExp(r'Math\.max\(\s*(?:1[eE]5|100000)\s*,'),
      'Math.max(1e3,',
    );
    patched = patched.replaceAllMapped(
      RegExp(r'Math\.max\(\s*([A-Za-z_$][\w$]*)\s*,\s*(?:5[eE]5|500000)\s*\)'),
      (match) => 'Math.max(${match.group(1)},1e3)',
    );
    patched = patched.replaceAllMapped(
      RegExp(r'Math\.max\(\s*([A-Za-z_$][\w$]*)\s*,\s*(?:5[eE]4|50000)\s*\)'),
      (match) => 'Math.max(${match.group(1)},1e3)',
    );
    return patched;
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
            'platform': 'web',
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

  Map<String, dynamic>? _decodeMessageData(Object? rawData) {
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        return null;
      }
      return null;
    }

    if (rawData is Map) {
      return rawData.map((key, value) => MapEntry(key.toString(), value));
    }

    if (rawData is js.JsObject) {
      try {
        final jsonApi = js.context['JSON'];
        if (jsonApi is js.JsObject) {
          final jsonString = jsonApi.callMethod('stringify', [rawData]);
          if (jsonString is String) {
            final decoded = jsonDecode(jsonString);
            if (decoded is Map) {
              return decoded.map(
                (key, value) => MapEntry(key.toString(), value),
              );
            }
          }
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  void _postToIframe(html.IFrameElement iframe, Map<String, dynamic> message) {
    final target = iframe.contentWindow;
    if (target != null) {
      _postToWindow(target, message);
    }
  }

  void _postToWindow(html.WindowBase target, Map<String, dynamic> message) {
    target.postMessage(message, '*');
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
      child: HtmlElementView(viewType: _viewId!),
    );
  }
}
