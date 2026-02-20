import 'package:genui/genui.dart';

/// Resolves a value from a template path binding `{"path": "/key"}`,
/// a literal binding `{"literalString": "..."}`, or a direct value (tests).
///
/// In production the genui catalog passes raw binding objects to widgetBuilders.
/// In tests data is passed directly. This handles both cases.
T? resolveValue<T>(DataContext ctx, Object? ref) {
  if (ref is Map) {
    final path = ref['path'] as String?;
    if (path != null) return ctx.getValue<T>(DataPath(path));
    return (ref['literalString'] ?? ref['literalNumber'] ?? ref['literalBoolean']) as T?;
  }
  return ref as T?;
}

/// Resolves a list from a path binding or direct list value.
List<dynamic> resolveList(DataContext ctx, Object? ref) {
  if (ref is Map) {
    final path = ref['path'] as String?;
    if (path != null) return ctx.getValue<List>(DataPath(path)) ?? [];
    return (ref['literalArray'] as List?) ?? [];
  }
  if (ref is List) return ref;
  return [];
}
