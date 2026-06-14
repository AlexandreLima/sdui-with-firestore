import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdui_with_firestore/sdui/sdui_engine.dart';
import 'package:sdui_with_firestore/sdui/sdui_template_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final SduiTemplateRepository _repository;
  late final SduiEngine _engine;
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = SduiTemplateRepository();
    _engine = SduiEngine();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.escuelajs.co/api/v1/products/${widget.productId}',
        ),
      );
      if (response.statusCode == 200) {
        final product = jsonDecode(response.body) as Map<String, dynamic>;
        final template = await _repository.loadTemplate('product_detail');
        setState(() {
          _data = product;
          _template = template;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    final template = await _repository.loadTemplate('product_detail');
    setState(() {
      _data = {
        'title': 'Produto',
        'price': '0',
        'description': 'Sem dados',
        'category': {'name': 'Geral'},
      };
      _loading = false;
      _template = template;
    });
  }

  Map<String, dynamic> _template = {};

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final template = _template.isEmpty
        ? {
            'type': 'screen',
            'appBar': {'title': 'Detalhe'},
            'body': {
              'type': 'column',
              'children': [
                {
                  'type': 'image',
                  'src': '\${images[0]}',
                  'width': 220,
                  'height': 220,
                  'fit': 'cover',
                },
                {'type': 'text', 'text': '\${title}'},
                {'type': 'text', 'text': 'Preço: \${price}'},
              ],
            },
          }
        : _template;

    return _engine.render(template, data: _data);
  }
}
