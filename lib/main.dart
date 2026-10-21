import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oicana/oicana.dart';

import 'certificate.dart';
import 'invoice.dart';

void main() {
  // Loading the templates reads assets, which needs the binding.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OicanaExampleApp(templates: Templates.load()));
}

/// The templates of the app, loaded once and kept for the lifetime of the app.
class Templates {
  const Templates({required this.invoice, required this.certificate});

  final Template invoice;
  final Template certificate;

  static Future<Templates> load() async {
    // On the web, synchronous calls like configureDiagnosticColor need the
    // WebAssembly module, which initOicana loads.
    await initOicana();
    configureDiagnosticColor(DiagnosticColor.none);

    Future<Template> template(String name) async {
      final bytes = await rootBundle.load('templates/$name-0.1.0.zip');
      return Template.load(bytes.buffer.asUint8List());
    }

    final (invoice, certificate) = await (
      template('invoice'),
      template('certificate'),
    ).wait;
    return Templates(invoice: invoice, certificate: certificate);
  }
}

class OicanaExampleApp extends StatelessWidget {
  const OicanaExampleApp({super.key, required this.templates});

  final Future<Templates> templates;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oicana example',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF2E5C8A)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFF2E5C8A),
      brightness: Brightness.dark,
    ),
    home: FutureBuilder(
      future: templates,
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot(hasData: true, :final data!) => HomeScreen(
          templates: data,
        ),
        AsyncSnapshot(hasError: true, :final error!) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load the templates: $error'),
            ),
          ),
        ),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      },
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.templates});

  final Templates templates;

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: const Text('Oicana example')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Create PDFs on this device from Typst templates. '
              'Nothing leaves the device.',
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Invoice'),
              subtitle: const Text(
                'JSON input with schema validation and an image from the device',
              ),
              onTap: () => open(InvoiceScreen(template: templates.invoice)),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Certificate'),
              subtitle: const Text('A single JSON input'),
              onTap: () =>
                  open(CertificateScreen(template: templates.certificate)),
            ),
          ),
        ],
      ),
    );
  }
}
