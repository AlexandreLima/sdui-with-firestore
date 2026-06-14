import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdui_with_firestore/screens/product_detail_screen.dart';
import 'package:sdui_with_firestore/sdui/sdui_engine.dart';
import 'package:sdui_with_firestore/sdui/sdui_template_repository.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({required this.categoryId, super.key});

  final int categoryId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final SduiTemplateRepository _repository;
  late final SduiEngine _engine;
  List<dynamic> _products = [];
  Map<String, dynamic> _template = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = SduiTemplateRepository();
    _engine = SduiEngine();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.escuelajs.co/api/v1/categories/${widget.categoryId}/products',
        ),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as List<dynamic>;
        final template = await _repository.loadTemplate('product_list');
        setState(() {
          _products = body;
          _template = template;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    final template = await _repository.loadTemplate('product_list');
    setState(() {
      _products = [];
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
            'appBar': {
              'title': 'Produtos por categoria',
              'backgroundColor': 'primary',
            },
            'body': {
              'type': 'column',
              'children': [
                {
                  'type': 'list',
                  'source': 'products',
                  'item': {
                    'type': 'card',
                    'action': {'type': 'openProduct'},
                    'children': [
                      {
                        'type': 'image',
                        'src': '\${images[0]}',
                        'width': 64,
                        'height': 64,
                        'fit': 'cover',
                      },
                      {'type': 'text', 'text': '\${title}'},
                      {'type': 'text', 'text': 'R\$ \${price}'},
                    ],
                  },
                },
              ],
            },
          }
        : _template;

    return _engine.render(
      template,
      data: {'products': _products},
      onAction: (type, itemData) {
        if (type == 'openProduct') {
          final id = itemData['id'];
          if (id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  productId: int.tryParse(id.toString()) ?? 1,
                ),
              ),
            );
          }
        }
      },
    );
  }
}
