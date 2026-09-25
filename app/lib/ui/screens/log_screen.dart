import 'package:flutter/material.dart';

import '../../domain/local_date.dart';
import '../../domain/resolver.dart';
import '../../domain/user_data.dart';
import '../app_scope.dart';
import '../format.dart';
import '../widgets/common.dart';

/// Answers: What did I already submit?
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Submitted'),
              Tab(text: 'Work search'),
              Tab(text: 'Status notes'),
            ],
          ),
        ),
        body: const TabBarView(children: [_Submissions(), _WorkSearch(), _StatusNotes()]),
      ),
    );
  }
}

class _Submissions extends StatelessWidget {
  const _Submissions();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = [...app.data.submissions]..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const Text(
            'Your own record of everything you sent or did: payment requests, registrations, '
            'appeals, calls. Save confirmation numbers and screenshots.',
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Nothing logged yet.', textAlign: TextAlign.center),
            ),
          for (final s in items)
            Card(
              child: ListTile(
                title: Text(s.kind.label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDate(s.date)),
                    if (s.confirmation.isNotEmpty) Text('Confirmation: ${s.confirmation}'),
                    if (s.note.isNotEmpty) Text(s.note),
                    if (s.attachmentIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      AttachmentThumbs(ids: s.attachmentIds),
                    ],
                  ],
                ),
                trailing: IconButton(
                  tooltip: 'Delete entry',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      'Delete this entry?',
                      'Its screenshots are deleted too.',
                    )) {
                      app.deleteSubmission(s);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-submission',
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const SubmissionFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Log something'),
      ),
    );
  }
}

class _WorkSearch extends StatelessWidget {
  const _WorkSearch();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final entries = [...app.data.workSearch]..sort((a, b) => b.date.compareTo(a.date));
    final required = app.data.profile.counts['work_search_required_per_week'];
    final weeks = <LocalDate, List<WorkSearchEntry>>{};
    for (final e in entries) {
      weeks.putIfAbsent(e.date.startOfWeekSunday, () => []).add(e);
    }
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const Text(
            'Same fields as TWC\'s Work Search Log: date, employer and contact, type of contact, '
            'result. Keep it for your whole benefit year. Only send it to TWC if they ask.',
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No activities recorded yet.', textAlign: TextAlign.center),
            ),
          for (final w in weeks.entries) ...[
            SectionTitle(
              'Week of ${formatShort(w.key)} – ${formatShort(w.key.endOfWeekSaturday)}: '
              '${w.value.length}${required != null ? ' of $required' : ''} recorded',
            ),
            for (final e in w.value)
              Card(
                child: ListTile(
                  title: Text(e.employer),
                  subtitle: Text(
                    [
                      formatDate(e.date),
                      if (e.activityType.isNotEmpty) e.activityType,
                      if (e.contact.isNotEmpty) 'Contact: ${e.contact}',
                      if (e.result.isNotEmpty) 'Result: ${e.result}',
                      if (e.note.isNotEmpty) e.note,
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Delete activity',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirm(context, 'Delete this activity?', '')) {
                        app.deleteWorkSearch(e);
                      }
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-work-search',
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const WorkSearchFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add activity'),
      ),
    );
  }
}

class _StatusNotes extends StatelessWidget {
  const _StatusNotes();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final notes = [...app.data.statusNotes]..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const Text(
            'Copy the exact status you see in TWC\'s system or hear on the phone, with the date. '
            'The app doesn\'t interpret statuses — this is so you can show someone later.',
          ),
          if (notes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No status notes yet.', textAlign: TextAlign.center),
            ),
          for (final n in notes)
            Card(
              child: ListTile(
                title: Text(n.text),
                subtitle: Text('${formatDate(n.date)}${n.where.isNotEmpty ? ' · ${n.where}' : ''}'),
                trailing: IconButton(
                  tooltip: 'Delete note',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => app.deleteStatusNote(n),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-status',
        onPressed: () => _addStatus(context),
        icon: const Icon(Icons.add),
        label: const Text('Add status'),
      ),
    );
  }

  Future<void> _addStatus(BuildContext context) async {
    final app = AppScope.read(context);
    final text = TextEditingController();
    final where = TextEditingController();
    var date = app.today;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Status you saw'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: text,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Status text, word for word'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: where,
                  decoration: const InputDecoration(
                    labelText: 'Where (e.g. TWC website, phone call)',
                  ),
                ),
                DateField(
                  label: 'Date',
                  value: date,
                  onChanged: (d) => set(() => date = d ?? app.today),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true && text.text.trim().isNotEmpty) {
      app.addStatusNote(date: date, text: text.text.trim(), where: where.text.trim());
    }
    text.dispose();
    where.dispose();
  }
}

class SubmissionFormScreen extends StatefulWidget {
  const SubmissionFormScreen({
    super.key,
    this.initialKind,
    this.instanceKey,
    this.completeTaskOnSave = false,
  });

  final SubmissionKind? initialKind;
  final String? instanceKey;
  final bool completeTaskOnSave;

  @override
  State<SubmissionFormScreen> createState() => _SubmissionFormScreenState();
}

class _SubmissionFormScreenState extends State<SubmissionFormScreen> {
  late SubmissionKind _kind = widget.initialKind ?? SubmissionKind.paymentRequest;
  LocalDate? _date;
  final _confirmation = TextEditingController();
  final _note = TextEditingController();
  final List<String> _attachments = [];

  @override
  void dispose() {
    _confirmation.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    _date ??= app.today;
    return Scaffold(
      appBar: AppBar(title: const Text('Log what you submitted')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<SubmissionKind>(
            initialValue: _kind,
            decoration: const InputDecoration(labelText: 'What was it?'),
            items: [
              for (final k in SubmissionKind.values)
                DropdownMenuItem(value: k, child: Text(k.label)),
            ],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          DateField(label: 'Date', value: _date, onChanged: (d) => setState(() => _date = d)),
          TextField(
            controller: _confirmation,
            decoration: const InputDecoration(
              labelText: 'Confirmation number (optional)',
              helperText: 'Never your SSN, password or PIN.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (who you spoke with, what you sent)',
            ),
          ),
          const SizedBox(height: 16),
          AttachmentEditor(ids: _attachments, label: 'Screenshot or photo (proof)'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _date == null
                ? null
                : () {
                    app.addSubmission(
                      kind: _kind,
                      date: _date!,
                      confirmation: _confirmation.text.trim(),
                      note: _note.text.trim(),
                      instanceKey: widget.instanceKey,
                      attachmentIds: _attachments,
                    );
                    final key = widget.instanceKey;
                    if (widget.completeTaskOnSave && key != null) {
                      final TaskInstance? t = app.taskByKey(key);
                      if (t != null && !t.isDone) app.completeTask(t);
                    }
                    Navigator.of(context).pop();
                  },
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Save')),
          ),
        ],
      ),
    );
  }
}

class WorkSearchFormScreen extends StatefulWidget {
  const WorkSearchFormScreen({super.key, this.initialDate});
  final LocalDate? initialDate;

  @override
  State<WorkSearchFormScreen> createState() => _WorkSearchFormScreenState();
}

class _WorkSearchFormScreenState extends State<WorkSearchFormScreen> {
  LocalDate? _date;
  final _employer = TextEditingController();
  final _contact = TextEditingController();
  final _result = TextEditingController();
  final _note = TextEditingController();
  String _type = _types.first;

  // Descriptive labels only; whether an activity counts is decided by TWC.
  static const _types = [
    'Applied for a job',
    'Interview',
    'Contacted an employer',
    'Job fair or hiring event',
    'Workforce Solutions office service',
    'Other',
  ];

  @override
  void dispose() {
    for (final c in [_employer, _contact, _result, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    _date ??= widget.initialDate ?? app.today;
    return Scaffold(
      appBar: AppBar(title: const Text('Work search activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DateField(label: 'Date', value: _date, onChanged: (d) => setState(() => _date = d)),
          TextField(
            controller: _employer,
            decoration: const InputDecoration(labelText: 'Employer or organization'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contact,
            decoration: const InputDecoration(
              labelText: 'Contact info (person, phone, address or website)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type of contact'),
            items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _result,
            decoration: const InputDecoration(
              labelText: 'Result (e.g. applied, no opening, interview set)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 8),
          Text(
            'Not sure if something counts? Ask your local Workforce Solutions office — the app doesn\'t decide that.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (_date == null || _employer.text.trim().isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Add a date and employer.')));
                return;
              }
              app.addWorkSearch(
                date: _date!,
                employer: _employer.text.trim(),
                contact: _contact.text.trim(),
                activityType: _type,
                result: _result.text.trim(),
                note: _note.text.trim(),
              );
              Navigator.of(context).pop();
            },
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Save')),
          ),
        ],
      ),
    );
  }
}
