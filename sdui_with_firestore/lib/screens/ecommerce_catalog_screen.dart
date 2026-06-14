import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdui_with_firestore/screens/product_list_screen.dart';
import 'package:sdui_with_firestore/sdui/sdui_engine.dart';
import 'package:sdui_with_firestore/sdui/sdui_template_repository.dart';

class EcommerceCatalogScreen extends StatefulWidget {
  const EcommerceCatalogScreen({super.key});

  @override
  State<EcommerceCatalogScreen> createState() => _EcommerceCatalogScreenState();
}

class _EcommerceCatalogScreenState extends State<EcommerceCatalogScreen> {
  late final SduiTemplateRepository _repository;
  late final SduiEngine _engine;
  Map<String, dynamic> _data = {'categories': []};
  Map<String, dynamic> _template = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = SduiTemplateRepository();
    _engine = SduiEngine();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.escuelajs.co/api/v1/categories/'));
      if (response.statusCode == 200) {
        final categories = jsonDecode(response.body) as List<dynamic>;
        final template = await _repository.loadTemplate('product_filter');
        setState(() {
          _data = {'categories': categories};
          _template = template;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    final template = await _repository.loadTemplate('product_filter');
    setState(() {
      _data = {'categories': []};
      _template = template;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final template = _template.isEmpty
        ? {
            'type': 'screen',
            'appBar': {'title': 'Categorias'},
            'body': {
              'type': 'list',
              'source': 'categories',
              'item': {
                'type': 'card',
                'children': [
                  {'type': 'text', 'text': '\${name}'},
                  {'type': 'text', 'text': '\${image}'},
                ],
              },
            },
          }
        : _template;

    return _engine.render(
      template,
      data: _data,
      onAction: (type, itemData) {
        if (type == 'openCategory') {
          final id = itemData['id'] ?? itemData['categoryId'];
          if (id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductListScreen(
                      categoryId: int.tryParse(id.toString()) ?? 1)),
            );
          }
        }
      },
    );
  }
}
