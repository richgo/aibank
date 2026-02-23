// Conditional export: on web use dart:html iframe implementation;
// on all other platforms (Android, iOS, desktop, test VM) use the
// webview_flutter-based native implementation.
export 'mcp_app_frame_io.dart'
    if (dart.library.html) 'mcp_app_frame_html.dart';
