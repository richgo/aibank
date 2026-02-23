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
///   2. Render HTML in sandboxed iframe (Blob URL, srcdoc fallback)
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
  String? _resourceObjectUrl;
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
    if (_resourceObjectUrl != null) {
      html.Url.revokeObjectUrl(_resourceObjectUrl!);
      _resourceObjectUrl = null;
    }
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

      // 2. Create sandboxed iframe and load HTML via Blob URL. This avoids
      // srcdoc-specific behavior that can break map asset loading.
      final iframe = html.IFrameElement()
        ..src = 'about:blank'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute(
            'sandbox', 'allow-scripts allow-same-origin allow-forms');

      _iframeLoadSubscription = iframe.onLoad.listen((_) {
        _iframeLoadSubscription?.cancel();
        _iframeLoadSubscription = null;
        // Primary send happens on ui/notifications/initialized; this fallback
        // handles apps that never emit that event.
        Future<void>.delayed(
          const Duration(milliseconds: 1500),
          () => _sendToolInputToIframe(iframe),
        );
      });

      if (_resourceObjectUrl != null) {
        html.Url.revokeObjectUrl(_resourceObjectUrl!);
        _resourceObjectUrl = null;
      }
      try {
        final blob = html.Blob(<String>[htmlContent], 'text/html');
        _resourceObjectUrl = html.Url.createObjectUrlFromBlob(blob);
        iframe.src = _resourceObjectUrl!;
      } catch (_) {
        iframe.srcdoc = htmlContent;
      }

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

  // For the bundled Cesium MCP app, switch to an embedded OSM iframe fallback
  // to avoid persistent WebGL/tiles stalls in constrained host environments.
  String _patchMapHtml(String html) {
    if (widget.resourceUri == 'ui://cesium-map/mcp-app.html') {
      return _embeddedOsmMapHtml();
    }
    return html;
  }

  String _embeddedOsmMapHtml() => r'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html, body { width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden; background: #111827; }
    #tiles {
      width: 100%;
      height: 100%;
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      grid-template-rows: repeat(3, 1fr);
      overflow: hidden;
      background: #1f2937;
    }
    #tiles img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
      background: #111827;
    }
    #marker {
      position: absolute;
      left: 50%;
      top: 50%;
      width: 14px;
      height: 14px;
      margin-left: -7px;
      margin-top: -7px;
      border-radius: 50%;
      background: #ef4444;
      border: 2px solid white;
      box-shadow: 0 0 0 2px rgba(0, 0, 0, 0.35);
      z-index: 2;
      pointer-events: none;
      display: none;
    }
    #loading {
      position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
      color: #fff; font: 14px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: rgba(17, 24, 39, 0.8);
    }
  </style>
</head>
<body>
  <div id="tiles" aria-label="Map tiles"></div>
  <div id="marker" aria-hidden="true"></div>
  <div id="loading">Loading map...</div>
  <script>
    (function () {
      const tiles = document.getElementById('tiles');
      const marker = document.getElementById('marker');
      const loading = document.getElementById('loading');

      function asNumber(value) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : NaN;
      }

      function parseMessage(data) {
        if (typeof data === 'string') {
          try { return JSON.parse(data); } catch (_) { return null; }
        }
        return data && typeof data === 'object' ? data : null;
      }

      function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value));
      }

      function lonToTileX(lon, zoom) {
        return Math.floor(((lon + 180) / 360) * Math.pow(2, zoom));
      }

      function latToTileY(lat, zoom) {
        const latRad = (lat * Math.PI) / 180;
        return Math.floor(
          ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2) *
            Math.pow(2, zoom),
        );
      }

      function chooseZoom(west, south, east, north) {
        const lonSpan = Math.max(Math.abs(east - west), 0.0001);
        const latSpan = Math.max(Math.abs(north - south), 0.0001);
        const lonZoom = Math.log2(360 / lonSpan);
        const latZoom = Math.log2(170 / latSpan);
        return clamp(Math.floor(Math.min(lonZoom, latZoom, 17)), 3, 17);
      }

      function setBounds(args) {
        const west = asNumber(args.west);
        const south = asNumber(args.south);
        const east = asNumber(args.east);
        const north = asNumber(args.north);
        if ([west, south, east, north].some((n) => Number.isNaN(n))) {
          console.warn('[APP] Invalid bbox arguments:', args);
          return;
        }
        const lon = (west + east) / 2;
        const lat = (south + north) / 2;
        const zoom = chooseZoom(west, south, east, north);
        const maxTile = Math.pow(2, zoom);
        const centerX = lonToTileX(lon, zoom);
        const centerY = latToTileY(lat, zoom);

        tiles.innerHTML = '';
        for (let dy = -1; dy <= 1; dy += 1) {
          for (let dx = -1; dx <= 1; dx += 1) {
            let x = centerX + dx;
            const y = centerY + dy;
            x = ((x % maxTile) + maxTile) % maxTile;
            const img = document.createElement('img');
            if (y < 0 || y >= maxTile) {
              img.alt = '';
              img.src = 'data:image/gif;base64,R0lGODlhAQABAAAAACw=';
            } else {
              img.alt = `tile ${zoom}/${x}/${y}`;
              img.src = `https://tile.openstreetmap.org/${zoom}/${x}/${y}.png`;
              img.referrerPolicy = 'no-referrer';
              img.onerror = function () {
                console.warn('[APP] Tile failed to load:', img.src);
              };
            }
            tiles.appendChild(img);
          }
        }
        marker.style.display = 'block';
        loading.style.display = 'none';
        console.info('[APP] Embedded OSM tiles set:', {
          west,
          south,
          east,
          north,
          lat,
          lon,
          zoom,
          centerX,
          centerY,
        });
      }

      window.addEventListener('message', (event) => {
        const msg = parseMessage(event.data);
        if (!msg || msg.method !== 'ui/notifications/tool-input') return;
        const args = ((msg.params || {}).arguments) || {};
        console.info('[APP] Received tool input:', msg.params || {});
        setBounds(args);
      });
    })();
  </script>
</body>
</html>''';

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
