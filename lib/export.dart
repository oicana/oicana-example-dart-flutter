import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Whether [exportPdf] opens a save dialog instead of the share sheet.
bool get savesToFile =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };

/// Hands the PDF to the user: a save dialog on desktop, the share sheet on
/// mobile, and the share sheet or a download on the web.
///
/// [origin] is the widget that triggered the export; iPads anchor the share
/// sheet to it.
Future<void> exportPdf(Uint8List pdf, String name, BuildContext origin) async {
  final file = XFile.fromData(pdf, mimeType: 'application/pdf', name: name);

  if (savesToFile) {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );
    if (location != null) await file.saveTo(location.path);
    return;
  }

  final box = origin.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [file],
      fileNameOverrides: [name],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
