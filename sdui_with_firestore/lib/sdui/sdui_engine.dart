import 'package:flutter/material.dart';

typedef SduiActionCallback =
    void Function(String type, Map<String, dynamic> itemData);

class SduiEngine {
  Widget render(
    Map<String, dynamic> template, {
    Map<String, dynamic>? data,
    SduiActionCallback? onAction,
  }) {
    return _buildNode(template, data ?? const {}, onAction: onAction);
  }

  Widget _buildNode(
    Map<String, dynamic> node,
    Map<String, dynamic> data, {
    SduiActionCallback? onAction,
  }) {
    final type = (node['type'] ?? 'container').toString();

    switch (type) {
      case 'screen':
        return _buildScreen(node, data, onAction: onAction);
      case 'list':
        return _buildList(node, data, onAction: onAction);
      case 'column':
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: _crossAxisAlignment(node['crossAxisAlignment']),
            children: _buildChildren(
              node['children'],
              data,
              onAction: onAction,
            ),
          ),
        );
      case 'row':
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: _crossAxisAlignment(node['crossAxisAlignment']),
            children: _buildChildren(
              node['children'],
              data,
              onAction: onAction,
            ),
          ),
        );
      case 'card':
        final content = Padding(
          padding: _edgeInsets(node['padding']) ?? const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildChildren(
              node['children'],
              data,
              onAction: onAction,
            ),
          ),
        );

        final action = _resolveAction(node, data);
        return action != null
            ? InkWell(
                onTap: () => onAction?.call(action['type'].toString(), data),
                child: Card(child: content),
              )
            : Card(child: content);
      case 'padding':
        return Padding(
          padding: _edgeInsets(node['padding']) ?? EdgeInsets.zero,
          child: _buildSingleChild(node['child'], data, onAction: onAction),
        );
      case 'container':
        return Container(
          padding: _edgeInsets(node['padding']),
          margin: _edgeInsets(node['margin']),
          color: _color(node['color']),
          child: _buildSingleChild(node['child'], data, onAction: onAction),
        );
      case 'text':
        return Text(_resolveText(node['text'], data));
      case 'image':
        return Image.network(
          _resolveText(node['src'], data),
          width: (node['width'] ?? node['size'])?.toDouble(),
          height: (node['height'] ?? node['size'])?.toDouble(),
          fit: _fit(node['fit']),
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScreen(
    Map<String, dynamic> node,
    Map<String, dynamic> data, {
    SduiActionCallback? onAction,
  }) {
    final appBarNode = node['appBar'];
    final footerNode = node['footer'];

    return Scaffold(
      appBar: appBarNode == null
          ? null
          : AppBar(
              title: _buildSimpleTitle(appBarNode, data, onAction: onAction),
              backgroundColor:
                  _color(appBarNode['backgroundColor']) ??
                  ThemeData.light().colorScheme.primary,
            ),
      body: _buildSingleChild(node['body'], data, onAction: onAction),
      bottomNavigationBar: footerNode == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildNode(footerNode, data, onAction: onAction),
              ),
            ),
    );
  }

  Widget _buildList(
    Map<String, dynamic> node,
    Map<String, dynamic> data, {
    SduiActionCallback? onAction,
  }) {
    final source = node['source'] as String? ?? 'items';
    final items = (data[source] is List)
        ? List<dynamic>.from(data[source] as List)
        : <dynamic>[];

    final itemTemplate = Map<String, dynamic>.from(
      node['item'] as Map<String, dynamic>? ?? {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNode(itemTemplate, {
              ...data,
              if (item is Map) ...Map<String, dynamic>.from(item),
            }, onAction: onAction),
          ),
      ],
    );
  }

  Widget _buildSimpleTitle(
    Map<String, dynamic> node,
    Map<String, dynamic> data, {
    SduiActionCallback? onAction,
  }) {
    if (node['title'] != null) {
      return Text(_resolveText(node['title'], data));
    }

    if (node['child'] != null) {
      return _buildNode(
        Map<String, dynamic>.from(node['child']),
        data,
        onAction: onAction,
      );
    }

    return const Text('');
  }

  List<Widget> _buildChildren(
    dynamic children,
    Map<String, dynamic> data, {
    SduiActionCallback? onAction,
  }) {
    if (children is! List) return const <Widget>[];

    return children
        .whereType<Map>()
        .map(
          (child) => _buildNode(
            Map<String, dynamic>.from(child),
            data,
            onAction: onAction,
          ),
        )
        .toList(growable: false);
  }

  Widget _buildSingleChild(
    dynamic child,
    Map<String, dynamic> data, {
    SduiActionCallback? onAction,
  }) {
    if (child is Map<String, dynamic>) {
      return _buildNode(child, data, onAction: onAction);
    }
    if (child is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildChildren(child, data, onAction: onAction),
      );
    }
    return const SizedBox.shrink();
  }

  String _resolveText(dynamic value, Map<String, dynamic> data) {
    if (value is String) {
      final expression = value.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (
        match,
      ) {
        final key = match.group(1) ?? '';
        final resolved = _resolveDataPath(key, data);
        return resolved?.toString() ?? '';
      });
      return expression;
    }

    return value?.toString() ?? '';
  }

  dynamic _resolveDataPath(String path, Map<String, dynamic> data) {
    if (path.trim().isEmpty) return null;

    dynamic current = data;
    final tokens = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*|\[(\d+)\])',
    ).allMatches(path).map((match) => match.group(0) ?? '').toList();

    for (final token in tokens) {
      if (token.startsWith('[') && token.endsWith(']')) {
        final index = int.tryParse(token.substring(1, token.length - 1));
        if (index == null || current is! List) return null;
        current = current[index];
      } else if (current is Map) {
        current = current[token];
      } else {
        return null;
      }
    }

    return current;
  }

  CrossAxisAlignment _crossAxisAlignment(dynamic value) {
    switch (value?.toString()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      default:
        return CrossAxisAlignment.start;
    }
  }

  Map<String, dynamic>? _resolveAction(
    Map<String, dynamic> node,
    Map<String, dynamic> data,
  ) {
    final raw = node['action'];
    if (raw is Map) {
      final resolved = Map<String, dynamic>.from(raw);
      resolved.forEach((key, value) {
        if (value is String) {
          resolved[key] = _resolveText(value, data);
        }
      });
      return resolved;
    }
    return null;
  }

  EdgeInsets? _edgeInsets(dynamic value) {
    if (value is Map) {
      final top = (value['top'] ?? value['all'] ?? 0).toDouble();
      final right = (value['right'] ?? value['horizontal'] ?? value['all'] ?? 0)
          .toDouble();
      final bottom = (value['bottom'] ?? value['vertical'] ?? value['all'] ?? 0)
          .toDouble();
      final left = (value['left'] ?? value['horizontal'] ?? value['all'] ?? 0)
          .toDouble();
      return EdgeInsets.fromLTRB(left, top, right, bottom);
    }
    return null;
  }

  BoxFit _fit(dynamic value) {
    switch (value?.toString()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }

  Color? _color(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'primary':
          return Colors.blue;
        case 'accent':
          return Colors.teal;
        case 'surface':
          return Colors.white;
        default:
          return null;
      }
    }
    return null;
  }
}
