import 'dart:convert';

import 'local_date.dart';
import 'resolver.dart';
import 'rules.dart';
import 'user_data.dart';

/// Plain-text summary the user can hand to a legal-aid lawyer or TWC staff.
/// Contains only what the user entered plus the step list with sources.
String buildTextExport({
  required RuleDataset dataset,
  required UserData data,
  required List<TaskInstance> roadmap,
  required LocalDate today,
}) {
  final b = StringBuffer()
    ..writeln('JobLoss OS — personal record export')
    ..writeln('Exported: ${today.toIso()}')
    ..writeln('Rules dataset: ${dataset.datasetId} v${dataset.datasetVersion}')
    ..writeln()
    ..writeln(
      'This is the user\'s own record, made with an unofficial app. '
      'It is not from the Texas Workforce Commission and is not legal advice.',
    )
    ..writeln();

  b.writeln('== Key dates entered by the user');
  if (data.profile.dates.isEmpty && data.profile.counts.isEmpty) {
    b.writeln('(none)');
  }
  for (final e in data.profile.dates.entries) {
    b.writeln('${_factLabel(e.key)}: ${e.value.toIso()}');
  }
  for (final e in data.profile.counts.entries) {
    b.writeln('${_factLabel(e.key)}: ${e.value}');
  }

  b
    ..writeln()
    ..writeln('== Letters logged');
  if (data.notices.isEmpty) b.writeln('(none)');
  for (final n in data.notices) {
    final t = dataset.noticeTypeById(n.typeId)?.title ?? n.typeId;
    b.writeln(
      '- $t | logged ${n.loggedOn.toIso()}'
      '${n.mailedDate != null ? ' | mailed ${n.mailedDate!.toIso()}' : ''}'
      '${n.printedDeadline != null ? ' | printed deadline ${n.printedDeadline!.toIso()}' : ''}'
      '${n.eventDate != null ? ' | date on letter ${n.eventDate!.toIso()}' : ''}'
      '${n.note.isNotEmpty ? ' | ${n.note}' : ''}'
      '${n.attachmentIds.isNotEmpty ? ' | ${n.attachmentIds.length} photo(s)' : ''}',
    );
  }

  b
    ..writeln()
    ..writeln('== Submissions (what I already did)');
  if (data.submissions.isEmpty) b.writeln('(none)');
  final subs = [...data.submissions]..sort((a, c) => a.date.compareTo(c.date));
  for (final s in subs) {
    b.writeln(
      '- ${s.date.toIso()} | ${s.kind.label}'
      '${s.confirmation.isNotEmpty ? ' | confirmation: ${s.confirmation}' : ''}'
      '${s.note.isNotEmpty ? ' | ${s.note}' : ''}'
      '${s.attachmentIds.isNotEmpty ? ' | ${s.attachmentIds.length} screenshot(s)' : ''}',
    );
  }

  b
    ..writeln()
    ..writeln('== Work search log (fields as on the TWC Work Search Log)');
  if (data.workSearch.isEmpty) b.writeln('(none)');
  final ws = [...data.workSearch]..sort((a, c) => a.date.compareTo(c.date));
  for (final w in ws) {
    b.writeln(
      '- ${w.date.toIso()} | ${w.employer} | contact: ${w.contact} | '
      'type: ${w.activityType} | result: ${w.result}'
      '${w.note.isNotEmpty ? ' | ${w.note}' : ''}',
    );
  }

  b
    ..writeln()
    ..writeln('== Status notes (copied by the user)');
  if (data.statusNotes.isEmpty) b.writeln('(none)');
  for (final s in data.statusNotes) {
    b.writeln('- ${s.date.toIso()}${s.where.isNotEmpty ? ' (${s.where})' : ''}: ${s.text}');
  }

  b
    ..writeln()
    ..writeln('== Steps and status');
  final sorted = [...roadmap]..sort(compareTasks);
  for (final t in sorted) {
    final state = t.isDone
        ? 'DONE${t.completion != null ? ' ${t.completion!.completedOn.toIso()}' : ''}'
        : (t.isOverdue(today) ? 'OPEN (date passed)' : 'OPEN');
    b.writeln(
      '- [$state] ${t.rule.title}'
      '${t.due != null ? ' | date: ${t.due!.toIso()} (${basisLabel(t.basis)})' : ''}'
      '${t.rule.source != null ? ' | source: ${t.rule.source!.url}' : ''}',
    );
  }

  b
    ..writeln()
    ..writeln('== Questions for the agency');
  if (data.questions.isEmpty) b.writeln('(none)');
  for (final q in data.questions) {
    b.writeln(
      '- ${q.answered ? '[answered] ' : ''}${q.text}'
      '${q.answer.isNotEmpty ? ' — answer: ${q.answer}' : ''}',
    );
  }
  return b.toString();
}

/// Full machine-readable backup of everything the user entered.
String buildJsonExport(UserData data, RuleDataset dataset) => const JsonEncoder.withIndent('  ')
    .convert({
      'exported_by': 'JobLoss OS',
      'dataset_id': dataset.datasetId,
      'dataset_version': dataset.datasetVersion,
      'data': data.toJson(),
    });

String basisLabel(DateBasis b) => switch (b) {
  DateBasis.none => 'no date',
  DateBasis.asap => 'as soon as possible',
  DateBasis.printedOnNotice => 'date printed on your letter',
  DateBasis.eventOnNotice => 'date on your letter',
  DateBasis.computedEstimate => 'estimate — check your letter',
  DateBasis.userSchedule => 'from your filing schedule',
};

String _factLabel(String key) => factLabels[key] ?? key;

const Map<String, String> factLabels = {
  'last_day_worked': 'Last day worked',
  'applied_date': 'Date applied with TWC',
  'first_filing_date': 'First Filing Date (from TWC)',
  'work_search_start_date': 'Work search starts (from TWC letter)',
  'work_search_required_per_week': 'Work search activities per week (from TWC letter)',
  'coverage_end_date': 'Job-based health coverage ends',
  'claim_ended_date': 'Stopped claiming benefits',
};
