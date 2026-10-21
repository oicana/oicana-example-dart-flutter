# Oicana Example Dart Flutter

Small example Flutter app that uses Oicana to create PDFs on the device. It runs on Android, iOS, Linux, macOS, Windows and the web from one code base.

The app edits an invoice with a live preview and shares or saves it as PDF. The invoice data is a JSON input that the template validates against its schema, and the logo is an image picked on the device. Nothing leaves the device.

## Getting Started

1. Install the dependencies: `flutter pub get`
2. Start the app: `flutter run`

The first build of a native target downloads the native Oicana library for that target. Web builds use the WebAssembly build of Oicana that comes with the package.

The interesting parts are in [`lib/document_screen.dart`](lib/document_screen.dart), which renders the preview and exports the PDF, and [`lib/invoice.dart`](lib/invoice.dart), which turns the form into template inputs. The templates are packed versions of the invoice and certificate templates from [oicana-example-templates](https://github.com/oicana/oicana-example-templates).

## Licensing

The code of this example project is licensed under the [MIT license](LICENSE).

But please be aware, that the Oicana dependency [is licensed under PolyForm Noncommercial License 1.0.0][oicana-license] and, after 30 days, requires a commercial license for use cases that are not covered by the PolyForm license. Visit [the Oicana website][oicana-website] for pricing options.


[oicana-license]: https://github.com/oicana/oicana?tab=readme-ov-file#licensing
[oicana-website]: https://oicana.com
