import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/local_date.dart';
import '../../domain/rules.dart';
import '../app_scope.dart';
import '../format.dart';

/// Persistent reminder that this is not the state agency.
class NotAgencyBanner extends StatelessWidget {
  const NotAgencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Unofficial app. Not the Texas Workforce Commission. Not legal advice.',
      child: Container(
        width: double.infinity,
        color: s.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ExcludeSemantics(
          child: Text(
            'Unofficial organizer · Not TWC · Not legal advice',
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class KindBadge extends StatelessWidget {
  const KindBadge(this.rule, {super.key});
  final Rule rule;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final official = rule.kind == RuleKind.official;
    final color = official ? s.primary : s.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            official ? Icons.account_balance_outlined : Icons.lightbulb_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            official ? 'Official step' : 'App suggestion',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class ReviewChip extends StatelessWidget {
  const ReviewChip(this.rule, {super.key});
  final Rule rule;

  @override
  Widget build(BuildContext context) {
    if (rule.review.status == ReviewStatus.verified) return const SizedBox.shrink();
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: s.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Source not yet human-checked', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 6),
    child: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ],
    ),
  );
}

/// A tappable field that opens a date picker. Allows clearing.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String? helper;
  final LocalDate? value;
  final ValueChanged<LocalDate?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          final today = AppScope.read(context).today;
          final init = value ?? today;
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(init.year, init.month, init.day),
            firstDate: DateTime(today.year - 3),
            lastDate: DateTime(today.year + 2),
            helpText: label,
          );
          if (picked != null) onChanged(LocalDate.fromDateTime(picked));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 3,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined)
                : IconButton(
                    tooltip: 'Clear $label',
                    icon: const Icon(Icons.clear),
                    onPressed: () => onChanged(null),
                  ),
          ),
          child: Text(value == null ? 'Tap to choose' : formatDate(value!)),
        ),
      ),
    );
  }
}

Future<void> openExternal(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

Future<void> callPhone(BuildContext context, String phone) =>
    openExternal(context, 'tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');

Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String ok = 'Delete',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r ?? false;
}

/// Lets the user attach photos/screenshots. Files are copied into private
/// app storage; the list of attachment ids is kept in [ids].
class AttachmentEditor extends StatefulWidget {
  const AttachmentEditor({super.key, required this.ids, this.label = 'Photos / screenshots'});
  final List<String> ids;
  final String label;

  @override
  State<AttachmentEditor> createState() => _AttachmentEditorState();
}

class _AttachmentEditorState extends State<AttachmentEditor> {
  Future<void> _pick(ImageSource source) async {
    final app = AppScope.read(context);
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (x == null) return;
      final a = await app.importAttachment(x.path);
      if (a != null) setState(() => widget.ids.add(a.id));
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not add the image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        AttachmentThumbs(ids: widget.ids, onRemove: (id) => setState(() => widget.ids.remove(id))),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take photo'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add screenshot'),
            ),
          ],
        ),
      ],
    );
  }
}

class AttachmentThumbs extends StatelessWidget {
  const AttachmentThumbs({super.key, required this.ids, this.onRemove});
  final List<String> ids;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    final app = AppScope.of(context);
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      final f = app.attachmentFile(id);
                      if (f == null) return;
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => _ImageViewer(file: f)));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _thumb(app.attachmentFile(id)),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove image',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => onRemove!(id),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _thumb(File? f) {
    if (f == null || !f.existsSync()) {
      return Container(
        width: 88,
        height: 88,
        color: Colors.black12,
        child: const Icon(Icons.broken_image_outlined),
      );
    }
    return Image.file(f, width: 88, height: 88, fit: BoxFit.cover, semanticLabel: 'Attached image');
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Image')),
    body: InteractiveViewer(child: Center(child: Image.file(file))),
  );
}
