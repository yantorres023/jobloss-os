import 'package:flutter/material.dart';

import '../../domain/local_date.dart';
import '../../domain/rules.dart';
import '../../domain/user_data.dart';
import '../app_scope.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'task_detail_screen.dart';

/// Letters from TWC and others. Logging a letter creates its step and
/// deadline from the dates the user copies off it.
class LettersScreen extends StatelessWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final notices = [...app.data.notices]..sort((a, b) => b.loggedOn.compareTo(a.loggedOn));
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text('Letters', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'TWC sends important decisions and deadlines by mail. Log each letter here with '
            'the dates printed on it. Take a photo so you keep your own copy.',
          ),
          const SizedBox(height: 12),
          if (notices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No letters logged yet.', textAlign: TextAlign.center),
            ),
          for (final n in notices) _NoticeTile(notice: n),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-letter',
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const NoticeFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Log a letter'),
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice});
  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final type = app.dataset?.noticeTypeById(notice.typeId);
    final tasks = app.roadmap.where((t) => t.notice?.id == notice.id).toList();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => tasks.isNotEmpty
                ? TaskDetailScreen(taskKey: tasks.first.key)
                : NoticeFormScreen(existing: notice),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type?.title ?? notice.typeId, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Logged ${formatShort(notice.loggedOn)}'
                '${notice.mailedDate != null ? ' · mailed ${formatShort(notice.mailedDate!)}' : ''}',
              ),
              for (final t in tasks)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${t.isDone ? '✓ ' : ''}${dueLine(t, app.today)}',
                    style: TextStyle(
                      color: t.isOverdue(app.today) && t.rule.deadline.hard
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              if (notice.attachmentIds.isNotEmpty) ...[
                const SizedBox(height: 6),
                AttachmentThumbs(ids: notice.attachmentIds),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NoticeFormScreen extends StatefulWidget {
  const NoticeFormScreen({super.key, this.existing});
  final Notice? existing;

  @override
  State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  String? _typeId;
  LocalDate? _mailed;
  LocalDate? _printed;
  LocalDate? _event;
  final _note = TextEditingController();
  late final List<String> _attachments;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _typeId = e?.typeId;
    _mailed = e?.mailedDate;
    _printed = e?.printedDeadline;
    _event = e?.eventDate;
    _note.text = e?.note ?? '';
    _attachments = [...?e?.attachmentIds];
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final types = app.dataset?.noticeTypes ?? const <NoticeType>[];
    final type = _typeId == null ? null : app.dataset?.noticeTypeById(_typeId!);
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit letter' : 'Log a letter'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Delete letter',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Delete this letter?',
                  'Its step, dates and photos will be removed from the app.',
                )) {
                  app.deleteNotice(widget.existing!);
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _typeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'What kind of letter is it?'),
            items: [
              for (final t in types)
                DropdownMenuItem(
                  value: t.id,
                  child: Text(t.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: editing ? null : (v) => setState(() => _typeId = v),
          ),
          if (type != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(type.description),
            ),
            if (type.asksMailedDate)
              DateField(
                label: 'Mailing date (printed on the letter)',
                helper: 'Usually near the top. Deadlines are often counted from this date, not from when it arrived.',
                value: _mailed,
                onChanged: (d) => setState(() => _mailed = d),
              ),
            if (type.asksPrintedDeadline)
              DateField(
                label: type.printedDeadlineLabel,
                helper: 'If the letter prints a deadline, enter it — it always wins over the app\'s estimate.',
                value: _printed,
                onChanged: (d) => setState(() => _printed = d),
              ),
            if (type.asksEventDate)
              DateField(
                label: type.eventDateLabel,
                value: _event,
                onChanged: (d) => setState(() => _event = d),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                helperText: 'Don\'t type your Social Security number or claim PIN here.',
              ),
            ),
            const SizedBox(height: 16),
            AttachmentEditor(ids: _attachments, label: 'Photo of the letter'),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _typeId == null ? null : () => _save(context),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Save')),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    final app = AppScope.read(context);
    final e = widget.existing;
    if (e == null) {
      app.addNotice(
        typeId: _typeId!,
        mailedDate: _mailed,
        printedDeadline: _printed,
        eventDate: _event,
        note: _note.text.trim(),
        attachmentIds: _attachments,
      );
    } else {
      e
        ..mailedDate = _mailed
        ..printedDeadline = _printed
        ..eventDate = _event
        ..note = _note.text.trim();
      e.attachmentIds
        ..clear()
        ..addAll(_attachments);
      app.updateNotice(e);
    }
    Navigator.of(context).pop();
  }
}
