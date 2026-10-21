import 'package:flutter/material.dart';
import 'package:oicana/oicana.dart';

import 'document_screen.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, required this.template});

  final Template template;

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _name = TextEditingController(text: 'Jane Doe');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DocumentScreen(
    title: 'Certificate',
    template: widget.template,
    inputs: _name,
    buildInputs: () => (
      json: {
        'certificate': {'name': _name.text},
      },
      blobs: const {},
    ),
    fileName: 'certificate.pdf',
    form: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
  );
}
