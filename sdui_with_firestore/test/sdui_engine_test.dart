import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_with_firestore/sdui/sdui_engine.dart';

void main() {
  testWidgets('renders header, footer and repeated list items from JSON', (
    tester,
  ) async {
    final template = {
      'type': 'screen',
      'appBar': {'title': 'Catálogo'},
      'body': {
        'type': 'column',
        'children': [
          {
            'type': 'image',
            'src': '\${product.image}',
            'width': 64,
            'height': 64,
          },
          {'type': 'text', 'text': 'Categoria: \${product.category.name}'},
        ],
      },
      'footer': {'type': 'text', 'text': 'Total: \${count}'},
    };

    final data = {
      'product': {
        'image': 'https://example.com/image.png',
        'category': {'name': 'Eletrônicos'},
      },
      'count': 2,
    };

    await tester.pumpWidget(
      MaterialApp(home: SduiEngine().render(template, data: data)),
    );

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Categoria: Eletrônicos'), findsOneWidget);
    expect(find.text('Total: 2'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
