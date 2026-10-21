import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oicana/oicana.dart';

import 'export.dart';

typedef DocumentInputs = ({
  Map<String, Object?> json,
  Map<String, BlobInput> blobs,
});

/// Edits the inputs of [template] with [form] next to a live preview of the
/// document, and exports it as PDF.
///
/// The preview updates whenever [inputs] notifies its listeners.
class DocumentScreen extends StatefulWidget {
  const DocumentScreen({
    super.key,
    required this.title,
    required this.template,
    required this.inputs,
    required this.buildInputs,
    required this.fileName,
    required this.form,
  });

  final String title;
  final Template template;
  final Listenable inputs;
  final DocumentInputs Function() buildInputs;
  final String fileName;
  final Widget form;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  Uint8List? _preview;
  String? _error;
  bool _rendering = false;
  bool _exporting = false;
  Timer? _debounce;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.inputs.addListener(_schedulePreview);
    _renderPreview();
  }

  @override
  void dispose() {
    widget.inputs.removeListener(_schedulePreview);
    _debounce?.cancel();
    super.dispose();
  }

  void _schedulePreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _renderPreview);
  }

  Future<void> _renderPreview() async {
    final generation = ++_generation;
    setState(() => _rendering = true);
    final inputs = widget.buildInputs();
    try {
      final png = await widget.template.exportPng(
        jsonInputs: inputs.json,
        blobInputs: inputs.blobs,
        pixelsPerPt: 2,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _preview = png;
        _error = null;
      });
    } on OicanaException catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _rendering = false);
      }
    }
  }

  Future<void> _export(BuildContext origin) async {
    setState(() => _exporting = true);
    final inputs = widget.buildInputs();
    try {
      final pdf = await widget.template.exportPdf(
        jsonInputs: inputs.json,
        blobInputs: inputs.blobs,
      );
      if (!origin.mounted) return;
      await exportPdf(pdf, widget.fileName, origin);
    } on OicanaException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${error.message}')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _PreviewPane(
      preview: _preview,
      error: _error,
      rendering: _rendering,
    );
    final exportButton = Builder(
      builder: (origin) => FloatingActionButton.extended(
        onPressed: _exporting ? null : () => _export(origin),
        icon: _exporting
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(savesToFile ? Icons.save_alt : Icons.share),
        label: Text(savesToFile ? 'Save PDF' : 'Share PDF'),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            floatingActionButton: _error == null ? exportButton : null,
            body: Row(
              children: [
                SizedBox(width: 420, child: widget.form),
                const VerticalDivider(width: 1),
                Expanded(child: preview),
              ],
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.edit), text: 'Edit'),
                  Tab(icon: Icon(Icons.description), text: 'Preview'),
                ],
              ),
            ),
            floatingActionButton: _error == null ? exportButton : null,
            body: TabBarView(children: [widget.form, preview]),
          ),
        );
      },
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.preview,
    required this.error,
    required this.rendering,
  });

  final Uint8List? preview;
  final String? error;
  final bool rendering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          SizedBox(
            height: 4,
            child: rendering ? const LinearProgressIndicator() : null,
          ),
          if (error case final error?)
            Card(
              margin: const EdgeInsets.all(16),
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  error,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          Expanded(
            child: switch (preview) {
              null => const SizedBox.shrink(),
              final png => Opacity(
                // The preview is outdated while the inputs are invalid.
                opacity: error == null ? 1 : 0.4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Image.memory(
                        png,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: 'Document preview',
                      ),
                    ),
                  ),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}
