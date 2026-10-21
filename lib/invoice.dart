import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oicana/oicana.dart';

import 'document_screen.dart';

/// The editable data of an invoice, matching the `invoice` input of the
/// invoice template. The biller is fixed, as it would be in an app's settings.
class InvoiceDraft extends ChangeNotifier {
  InvoiceDraft() {
    for (final controller in _recipientControllers) {
      controller.addListener(notifyListeners);
    }
    addItem('Wireless keyboard', '4', '25');
    addItem('USB-C cable', '2', '45');
    addItem('Network infrastructure consultation', '1', '200');
  }

  final number = TextEditingController(text: '2026-001');
  final name = TextEditingController(text: 'Maria Schmidt');
  final title = TextEditingController(text: 'IT Manager');
  final vatId = TextEditingController(text: 'DE7654321');
  final street = TextEditingController(text: 'Business Avenue 1');
  final postalCode = TextEditingController(text: '80331');
  final city = TextEditingController(text: 'Munich');
  final country = TextEditingController(text: 'Germany');
  final items = <InvoiceItemDraft>[];

  /// A logo replacing the default banner of the template.
  ({String name, Uint8List bytes})? logo;

  List<TextEditingController> get _recipientControllers => [
    number,
    name,
    title,
    vatId,
    street,
    postalCode,
    city,
    country,
  ];

  void addItem([
    String description = '',
    String quantity = '1',
    String price = '',
  ]) {
    items.add(
      InvoiceItemDraft(description, quantity, price)
        ..addListener(notifyListeners),
    );
    notifyListeners();
  }

  void removeItem(InvoiceItemDraft item) {
    items.remove(item);
    item.dispose();
    notifyListeners();
  }

  void setLogo(({String name, Uint8List bytes})? value) {
    logo = value;
    notifyListeners();
  }

  DocumentInputs toInputs() {
    final today = DateTime.now();
    String date(DateTime day) => day.toIso8601String().substring(0, 10);
    return (
      json: {
        'invoice': {
          'id': number.text,
          'issuingDate': date(today),
          'deliveryDate': date(today),
          'dueDate': date(today.add(const Duration(days: 14))),
          'biller': {
            'name': 'Alex Johnson',
            'title': 'Senior Consultant',
            'company': 'Example Solutions GmbH',
            'vat-id': 'DE1234567',
            'iban': 'DE89370400440532013000',
            'address': {
              'country': 'Germany',
              'city': 'Berlin',
              'postal-code': '10115',
              'street': 'Sample Street 23',
            },
          },
          'recipient': {
            'name': name.text,
            'title': title.text,
            'vat-id': vatId.text,
            'address': {
              'country': country.text,
              'city': city.text,
              'postal-code': postalCode.text,
              'street': street.text,
            },
          },
          'items': [
            for (final item in items)
              {
                'date': date(today),
                'description': item.description.text,
                'quantity': num.tryParse(item.quantity.text) ?? 0,
                'price': num.tryParse(item.price.text) ?? 0,
              },
          ],
        },
      },
      blobs: {if (logo case final logo?) 'banner': BlobInput(logo.bytes)},
    );
  }

  @override
  void dispose() {
    for (final controller in _recipientControllers) {
      controller.dispose();
    }
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }
}

class InvoiceItemDraft extends ChangeNotifier {
  InvoiceItemDraft(String description, String quantity, String price)
    : description = TextEditingController(text: description),
      quantity = TextEditingController(text: quantity),
      price = TextEditingController(text: price) {
    for (final controller in [this.description, this.quantity, this.price]) {
      controller.addListener(notifyListeners);
    }
  }

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController price;

  @override
  void dispose() {
    description.dispose();
    quantity.dispose();
    price.dispose();
    super.dispose();
  }
}

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key, required this.template});

  final Template template;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _draft = InvoiceDraft();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DocumentScreen(
    title: 'Invoice',
    template: widget.template,
    inputs: _draft,
    buildInputs: _draft.toInputs,
    fileName: 'invoice.pdf',
    form: InvoiceForm(draft: _draft),
  );
}

class InvoiceForm extends StatelessWidget {
  const InvoiceForm({super.key, required this.draft});

  final InvoiceDraft draft;

  Future<void> _pickLogo() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'svg'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/svg+xml'],
          uniformTypeIdentifiers: [
            'public.png',
            'public.jpeg',
            'public.svg-image',
          ],
        ),
      ],
    );
    if (file == null) return;
    draft.setLogo((name: file.name, bytes: await file.readAsBytes()));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _Field(draft.number, 'Invoice number'),
          const SizedBox(height: 24),
          Text('Recipient', style: textTheme.titleMedium),
          _Field(draft.name, 'Name'),
          _Field(draft.title, 'Title'),
          _Field(
            draft.vatId,
            'VAT ID',
            helper: 'The template schema requires at least 9 characters',
          ),
          _Field(draft.street, 'Street'),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: _Field(draft.postalCode, 'Postal code'),
              ),
              const SizedBox(width: 12),
              Expanded(child: _Field(draft.city, 'City')),
            ],
          ),
          _Field(draft.country, 'Country'),
          const SizedBox(height: 24),
          Text('Items', style: textTheme.titleMedium),
          for (final item in draft.items)
            _ItemRow(
              key: ObjectKey(item),
              item: item,
              onRemove: draft.items.length > 1
                  ? () => draft.removeItem(item)
                  : null,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: draft.addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Logo', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image),
                label: const Text('Choose image'),
              ),
              if (draft.logo case final logo?)
                InputChip(
                  label: Text(logo.name),
                  onDeleted: () => draft.setLogo(null),
                )
              else
                const Text('Default banner'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({super.key, required this.item, required this.onRemove});

  final InvoiceItemDraft item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final number = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _Field(item.description, 'Description')),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: _Field(item.quantity, 'Qty', formatters: number),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: _Field(item.price, 'Price', formatters: number),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove item',
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.controller, this.label, {this.helper, this.formatters});

  final TextEditingController controller;
  final String label;
  final String? helper;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextField(
      controller: controller,
      inputFormatters: formatters,
      keyboardType: formatters == null
          ? null
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}
