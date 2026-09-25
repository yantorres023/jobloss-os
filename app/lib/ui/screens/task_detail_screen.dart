import 'package:flutter/material.dart';

import '../../app_controller.dart';
import '../../domain/export.dart' show factLabels;
import '../../domain/local_date.dart';
import '../../domain/resolver.dart';
import '../../domain/rules.dart';
import '../../domain/user_data.dart';
import '../app_scope.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'letters_screen.dart';
import 'log_screen.dart';
import 'more_screen.dart';

/// Answers: What exactly do I do? Where is the official source? What needs a
/// professional or the agency?
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskKey});
  final String taskKey;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.taskByKey(taskKey);
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This step no longer applies.')),
      );
    }
    final r = t.rule;
    final text = Theme.of(context).textTheme;
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(r.title, style: text.headlineSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [KindBadge(r), ReviewChip(r)]),
          if (r.kind == RuleKind.suggested)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'This is a suggestion from the app, not a TWC requirement.',
                style: text.bodySmall,
              ),
            ),
          _DateBlock(task: t, app: app),
          if (t.warnings.isNotEmpty)
            for (final w in t.warnings)
              Card(
                color: s.tertiaryContainer,
                child: ListTile(leading: const Icon(Icons.warning_amber_rounded), title: Text(w)),
              ),
          if (t.notice != null) _LetterCard(notice: t.notice!),
          const SectionTitle('What to do', icon: Icons.checklist),
          Text(r.description, style: text.bodyLarge),
          _FactInputs(rule: r),
          if (r.deadline.type == DeadlineType.weekly && t.occurrence != null)
            _WorkSearchWeek(task: t),
          if (r.documentsNeeded.isNotEmpty) ...[
            const SectionTitle('What you\'ll need', icon: Icons.folder_open),
            for (final d in r.documentsNeeded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(d)),
                  ],
                ),
              ),
          ],
          const SectionTitle('Official source', icon: Icons.account_balance_outlined),
          if (r.source == null)
            const Text('No official source — this is an app suggestion.')
          else
            _SourceTile(source: r.source!, rule: r),
          for (final src in r.additionalSources) _SourceTile(source: src, rule: r, secondary: true),
          if (r.getHelp.isNotEmpty) ...[
            const SectionTitle('When to get help', icon: Icons.support_agent),
            Text(r.getHelp),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const HelpScreen())),
                child: const Text('See who can help'),
              ),
            ),
          ],
          if (r.questionsToAsk.isNotEmpty) ...[
            const SectionTitle('Questions you could ask TWC', icon: Icons.help_outline),
            for (final q in r.questionsToAsk)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(q),
                trailing: app.data.questions.any((x) => x.text == q)
                    ? const Icon(Icons.check, semanticLabel: 'On your list')
                    : IconButton(
                        tooltip: 'Add to my question list',
                        icon: const Icon(Icons.playlist_add),
                        onPressed: () => app.addQuestion(q, ruleId: r.ruleId),
                      ),
              ),
          ],
          const SizedBox(height: 24),
          _Actions(task: t),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.task, required this.app});
  final TaskInstance task;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final t = task;
    final text = Theme.of(context).textTheme;
    final d = t.due;
    if (d == null) return const SizedBox(height: 8);
    final hard = t.hardDeadline;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.isDone ? 'Status' : 'When', style: text.labelLarge),
            const SizedBox(height: 4),
            Text(dueLine(t, app.today), style: text.titleMedium),
            if (hard != null && hard != d)
              Text('Late after: ${formatDate(hard)}', style: text.bodyMedium),
            const SizedBox(height: 4),
            Text(basisText(t.basis), style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.notice});
  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final type = app.dataset?.noticeTypeById(notice.typeId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type?.title ?? 'Letter',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => NoticeFormScreen(existing: notice)),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
            if (notice.mailedDate != null) Text('Mailed: ${formatDate(notice.mailedDate!)}'),
            if (notice.printedDeadline != null)
              Text('Date printed on it: ${formatDate(notice.printedDeadline!)}'),
            if (notice.eventDate != null)
              Text('Appointment/hearing: ${formatDate(notice.eventDate!)}'),
            if (notice.note.isNotEmpty) Text(notice.note),
            const SizedBox(height: 6),
            AttachmentThumbs(ids: notice.attachmentIds),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source, required this.rule, this.secondary = false});
  final RuleSource source;
  final Rule rule;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final checked = rule.lastCheckedAt;
    final verified = rule.lastVerifiedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.title, style: secondary ? text.titleSmall : text.titleMedium),
            Text(_authority(source.authority), style: text.bodySmall),
            if (!secondary) ...[
              const SizedBox(height: 4),
              Text(
                verified != null
                    ? 'Checked by a person on ${formatDate(verified)}.'
                    : 'Last looked up ${checked == null ? '(unknown)' : formatDate(checked)} from a search summary. '
                          'Not yet checked by a person — open the official page to confirm.',
                style: text.bodySmall,
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openExternal(context, source.url),
                icon: const Icon(Icons.open_in_new),
                label: Text(Uri.parse(source.url).host),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _authority(String a) => switch (a) {
    'STATE_AGENCY' => 'Official — Texas state agency',
    'FEDERAL_AGENCY' => 'Official — U.S. federal agency',
    'STATE_LEGISLATURE' => 'Official — Texas Legislature',
    'LEGAL_AID' => 'Legal aid organization (not the agency)',
    _ => 'Other source (not official)',
  };
}

/// Lets the user enter the fact that completes a setup step, e.g. the First
/// Filing Date or the work search number from their TWC letter.
class _FactInputs extends StatelessWidget {
  const _FactInputs({required this.rule});
  final Rule rule;

  static const _related = {
    'work_search_required_per_week': ['work_search_start_date'],
  };

  @override
  Widget build(BuildContext context) {
    final f = rule.completesWithFact;
    if (f == null) return const SizedBox.shrink();
    final app = AppScope.of(context);
    final keys = [f, ...?_related[f]];
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter from your letter or TWC account',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            for (final k in keys)
              if (knownFacts[k] == FactType.date)
                DateField(
                  label: factLabels[k] ?? k,
                  value: app.data.profile.dates[k],
                  onChanged: (d) => app.setDateFact(k, d),
                )
              else
                _CountField(factKey: k),
          ],
        ),
      ),
    );
  }
}

class _CountField extends StatelessWidget {
  const _CountField({required this.factKey});
  final String factKey;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final v = app.data.profile.counts[factKey];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        key: ValueKey('count-$factKey-$v'),
        initialValue: v?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: factLabels[factKey] ?? factKey,
          helperText: 'Type the number exactly as it appears on your TWC letter.',
        ),
        onFieldSubmitted: (s) {
          final n = int.tryParse(s.trim());
          app.setCountFact(factKey, (n == null || n < 0 || n > 50) ? null : n);
        },
      ),
    );
  }
}

class _WorkSearchWeek extends StatelessWidget {
  const _WorkSearchWeek({required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final week = task.occurrence!;
    final count = workSearchCountForWeek(app.data, week);
    final required = app.data.profile.counts['work_search_required_per_week'];
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week of ${formatDate(week)} – ${formatShort(week.endOfWeekSaturday)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              required == null
                  ? 'You\'ve recorded $count activit${count == 1 ? 'y' : 'ies'} this week.'
                  : 'You\'ve recorded $count of the $required activities you entered from your TWC letter.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('This is a count of what you recorded, not a decision about your claim.'),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkSearchFormScreen(initialDate: _clamp(app.today, week)),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Record an activity'),
            ),
          ],
        ),
      ),
    );
  }

  static LocalDate _clamp(LocalDate today, LocalDate week) {
    final end = week.endOfWeekSaturday;
    if (today.isBefore(week)) return week;
    if (today.isAfter(end)) return end;
    return today;
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (task.autoCompletedByFact != null) {
      return Text(
        'Marked done because you entered "${factLabels[task.autoCompletedByFact] ?? task.autoCompletedByFact}". '
        'Clear that date to reopen this step.',
      );
    }
    if (task.isDone) {
      return OutlinedButton.icon(
        onPressed: () => app.reopenTask(task.key),
        icon: const Icon(Icons.undo),
        label: const Text('Mark as not done'),
      );
    }
    final kind = _submissionKindFor(task.rule.ruleId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: task.rule.completesWithFact != null
              ? null
              : () {
                  app.completeTask(task);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked done. Tip: save proof in Log.')),
                  );
                },
          icon: const Icon(Icons.check),
          label: Text(
            task.rule.completesWithFact != null ? 'Enter the date above to finish' : 'Mark done',
          ),
        ),
        if (kind != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SubmissionFormScreen(
                  initialKind: kind,
                  instanceKey: task.key,
                  completeTaskOnSave: true,
                ),
              ),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Done — save proof (confirmation / screenshot)'),
          ),
        ],
      ],
    );
  }

  SubmissionKind? _submissionKindFor(String ruleId) => switch (ruleId) {
    'tx.request_payment' => SubmissionKind.paymentRequest,
    'tx.register_workintexas' => SubmissionKind.registration,
    'tx.verify_identity' => SubmissionKind.identity,
    'tx.determination_deadline' || 'tx.commission_appeal_deadline' => SubmissionKind.appeal,
    'tx.respond_to_twc' => SubmissionKind.phoneCall,
    'tx.review_wage_statement' => SubmissionKind.phoneCall,
    'tx.choose_payment_option' || 'tx.tax_withholding' => SubmissionKind.other,
    'tx.prepare_for_hearing' => SubmissionKind.documentSent,
    _ => null,
  };
}
