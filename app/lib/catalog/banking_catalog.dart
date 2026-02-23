import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'mcp/mcp_app_frame.dart';

class _ResilientCatalog extends Catalog {
  const _ResilientCatalog(super.items, {super.catalogId});

  @override
  Widget buildWidget(CatalogItemContext itemContext) {
    final data = itemContext.data;
    if (data is! Map<String, Object?> || data.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgetType = data.keys.first;
    final item = _findItem(widgetType);
    if (item == null) {
      debugPrint('[Banking] Unknown widget type "$widgetType".');
      return const SizedBox.shrink();
    }

    final payload = data[widgetType] ?? data[item.name];
    if (payload is! Map) {
      return const SizedBox.shrink();
    }

    return item.widgetBuilder(
      CatalogItemContext(
        data: Map<String, Object?>.from(payload.cast<String, Object?>()),
        id: itemContext.id,
        buildChild: (String childId, [DataContext? childDataContext]) =>
            itemContext.buildChild(
          childId,
          childDataContext ?? itemContext.dataContext,
        ),
        dispatchEvent: itemContext.dispatchEvent,
        buildContext: itemContext.buildContext,
        dataContext: itemContext.dataContext,
        getComponent: itemContext.getComponent,
        surfaceId: itemContext.surfaceId,
      ),
    );
  }

  CatalogItem? _findItem(String widgetType) {
    for (final item in items) {
      if (item.name == widgetType) {
        return item;
      }
    }
    final normalizedType = _normalizeWidgetType(widgetType);
    for (final item in items) {
      if (_normalizeWidgetType(item.name) == normalizedType) {
        return item;
      }
    }
    return null;
  }

  String _normalizeWidgetType(String value) {
    var normalized = value.trim().replaceAll(r'\:', ':');
    final separator = normalized.indexOf(':');
    if (separator <= 0 || separator >= normalized.length - 1) {
      return normalized.toLowerCase();
    }
    final namespace = normalized.substring(0, separator).trim().toLowerCase();
    final name = normalized.substring(separator + 1).trim().toLowerCase();
    normalized = '$namespace:$name';
    return normalized;
  }
}

/// A Button override that uses [InkWell] for non-primary buttons.
///
/// The standard Button uses ElevatedButton, which wraps its child in
/// `Align(widthFactor: 1.0, alignment: Alignment.center)`. This lays out the
/// child with *loose* constraints, so the inner Row shrinks to content-width
/// and spaceBetween has nothing to distribute.
///
/// InkWell is layout-transparent: it passes tight constraints from the parent
/// Column (alignment: stretch) straight through to the child Row, so
/// spaceBetween correctly spans the full row width.
CatalogItem _bankingButtonItem() {
  return CatalogItem(
    name: 'Button',
    dataSchema: S.object(
      properties: {
        'child': A2uiSchemas.componentReference(),
        'action': A2uiSchemas.action(),
        'primary': S.boolean(),
      },
      required: ['child', 'action'],
    ),
    widgetBuilder: (CatalogItemContext itemContext) {
      final data = itemContext.data as Map<String, Object?>;
      final childId = data['child'] as String;
      final action = data['action'] as Map<String, Object?>;
      final primary = (data['primary'] as bool?) ?? false;

      final childWidget = itemContext.buildChild(childId);
      final actionName = action['name'] as String;
      final contextDef =
          (action['context'] as List<Object?>?) ?? const <Object?>[];

      void onPressed() {
        final resolved = resolveContext(itemContext.dataContext, contextDef);
        itemContext.dispatchEvent(UserActionEvent(
          name: actionName,
          sourceComponentId: itemContext.id,
          context: resolved,
        ));
      }

      if (primary) {
        final cs = Theme.of(itemContext.buildContext).colorScheme;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
          onPressed: onPressed,
          child: childWidget,
        );
      }

      // Non-primary: use InkWell for tap feedback.
      // SizedBox(width: infinity) expands to the parent's maxWidth, creating
      // tight constraints for the child Row so spaceBetween spans the full
      // width regardless of what ancestor columns do with constraints.
      return SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: onPressed,
          child: childWidget,
        ),
      );
    },
  );
}

List<Catalog> buildBankingCatalogs() {
  // Merge custom items into the standard catalog using copyWith so that
  // GenUiSurface can find ALL items under the same standardCatalogId without
  // needing an explicit catalogId in the beginRendering message.
  // _bankingButtonItem overrides the standard Button to use InkWell so that
  // tight constraints (from Column alignment:stretch) reach the inner Row.
  final merged = CoreCatalogItems.asCatalog()
      .copyWith([mcpAppFrameItem(), _bankingButtonItem()]);
  final catalog = _ResilientCatalog(merged.items, catalogId: merged.catalogId);
  assert(() {
    final names = catalog.items.map((i) => i.name).toList();
    debugPrint('[Banking] catalog items (${names.length}): $names');
    assert(
        names.contains('mcp:AppFrame'), 'mcp:AppFrame missing from catalog!');
    return true;
  }());
  return [catalog];
}
