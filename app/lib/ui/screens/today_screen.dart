import 'package:flutter/material.dart';

import '../../app_controller.dart';
import '../../domain/resolver.dart';
import '../../domain/rules.dart';
import '../app_scope.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'letters_screen.dart';
import 'log_screen.dart';
import 'task_detail_screen.dart';

/// Answers: What do I do today? What deadline is next?
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

enum _View { today, upcoming, done }

class _TodayScreenState extends State<TodayScreen> {
  _View _view = _View.today;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.dataset == null) return _FallbackMode(error: app.datasetError);

    final today = app.tasksIn(Bucket.today);
    final upcoming = [
      ...app.tasksIn(Bucket.upcoming),
      ...app.tasksIn(Bucket.waiting),
      ...app.tasksIn(Bucket.anytime),
    ];
    final done = app.tasksIn(Bucket.done).reversed.toList();
    final retired = app.retiredCompletions;

    final list = switch (_view) {
      _View.today => today,
      _View.upcoming => upcoming,
      _View.done => done,
    };

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _NextDeadlineCard(app: app),
          const SizedBox(height: 8),
          SegmentedButton<_View>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _View.today, label: Text('Today (${today.length})')),
              ButtonSegment(value: _View.upcoming, label: Text('Next (${upcoming.length})')),
              ButtonSegment(
                value: _View.done,
                label: Text('Done (${done.length + retired.length})'),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty) _EmptyState(view: _view),
          for (final t in list) TaskCard(task: t),
          if (_view == _View.done)
            for (final c in retired)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(c.ruleId),
                  subtitle: Text(
                    'Done ${formatShort(c.completedOn)} · this step is no longer in the '
                    'current rules (kept for your records)',
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _quickAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _quickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('I got a letter'),
              subtitle: const Text('Log it and see any deadline on it'),
              onTap: () {
                Navigator.pop(c);
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const NoticeFormScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('I submitted something'),
              subtitle: const Text('Save the confirmation number or a screenshot'),
              onTap: () {
                Navigator.pop(c);
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const SubmissionFormScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('I did a work search activity'),
              onTap: () {
                Navigator.pop(c);
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const WorkSearchFormScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NextDeadlineCard extends StatelessWidget {
  const _NextDeadlineCard({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final t = app.nextHardDeadline;
    final s = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (t == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: const Text('No deadlines tracked yet'),
          subtitle: const Text(
            'Log letters from TWC and enter your filing date to see deadlines here.',
          ),
        ),
      );
    }
    final d = t.deadlineDate!;
    final overdue = d.isBefore(app.today);
    return Card(
      color: overdue ? s.errorContainer : s.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(taskKey: t.key))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEXT DEADLINE', style: text.labelMedium),
              const SizedBox(height: 4),
              Text(t.rule.title, style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${t.rule.deadline.label ?? 'Deadline'}: ${formatDate(d)} · ${relativeDay(d, app.today)}',
                style: text.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(basisText(t.basis), style: text.bodySmall),
              if (overdue)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'This date has passed. Check your letter and contact TWC or legal aid about what you can still do.',
                    style: text.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = Theme.of(context).colorScheme;
    final overdue = task.isOverdue(app.today) && task.rule.deadline.hard;
    final waiting = task.blockedBy.isNotEmpty;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(taskKey: task.key))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: Icon(
                  task.isDone
                      ? Icons.check_circle
                      : overdue
                      ? Icons.error_outline
                      : waiting
                      ? Icons.hourglass_empty
                      : Icons.radio_button_unchecked,
                  color: task.isDone
                      ? s.primary
                      : overdue
                      ? s.error
                      : s.outline,
                  semanticLabel: task.isDone
                      ? 'Done'
                      : overdue
                      ? 'Date passed'
                      : 'Open',
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title(context), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      waiting
                          ? 'After: ${task.blockedBy.map((id) => app.dataset?.ruleById(id)?.title ?? id).join(', ')}'
                          : dueLine(task, app.today),
                      style: TextStyle(color: overdue ? s.error : null),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        KindBadge(task.rule),
                        if (task.warnings.isNotEmpty)
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            semanticLabel: 'Check the date',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    final occ = task.occurrence;
    if (occ == null) return task.rule.title;
    if (task.rule.deadline.type == DeadlineType.weekly) {
      return '${task.rule.title} — week of ${formatShort(occ)}';
    }
    return '${task.rule.title} — ${formatShort(occ)}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.view});
  final _View view;

  @override
  Widget build(BuildContext context) {
    final msg = switch (view) {
      _View.today =>
        'Nothing due today. Check "Next" for what\'s coming, or log a letter you received.',
      _View.upcoming =>
        'Nothing scheduled yet. Enter your First Filing Date and log letters to fill this in.',
      _View.done => 'Steps you finish show up here.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(msg, textAlign: TextAlign.center),
    );
  }
}

class _FallbackMode extends StatelessWidget {
  const _FallbackMode({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 48),
        const SizedBox(height: 12),
        const Text(
          'The step list couldn\'t be loaded safely, so it\'s turned off. '
          'Your letters, log and photos are still here — use the Letters and Log tabs, '
          'and follow TWC\'s website for steps.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text('$error', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    ),
  );
}
