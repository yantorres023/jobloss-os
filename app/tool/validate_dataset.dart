// Validates every rule dataset under assets/rules and prints the release gate.
//
//   dart run tool/validate_dataset.dart            # fails on validation errors
//   dart run tool/validate_dataset.dart --release  # also fails if any active
//                                                  # official rule is unverified
import 'dart:io';

import 'package:jobloss_os/domain/dataset_validator.dart';
import 'package:jobloss_os/domain/local_date.dart';
import 'package:jobloss_os/domain/rules.dart';

void main(List<String> args) {
  final release = args.contains('--release');
  final files = Directory('assets/rules')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
  var failed = false;
  final now = DateTime.now();
  final today = LocalDate(now.year, now.month, now.day);
  for (final f in files) {
    stdout.writeln('== ${f.path}');
    final RuleDataset d;
    try {
      d = parseAndValidateDataset(f.readAsStringSync());
    } on InvalidDatasetException catch (e) {
      failed = true;
      for (final i in e.issues) {
        stdout.writeln('  ERROR $i');
      }
      continue;
    }
    final result = validateDataset(d);
    final official = d.rules.where((r) => r.kind == RuleKind.official).length;
    stdout.writeln(
      '  dataset ${d.datasetId} v${d.datasetVersion}: '
      '${d.rules.length} rules ($official official), '
      '${d.noticeTypes.length} notice types',
    );
    final blocking = rulesBlockingRelease(d, today);
    stdout.writeln(
      '  release gate: ${blocking.length} official rule(s) '
      'awaiting human source review',
    );
    for (final r in blocking) {
      stdout.writeln(
        '    SOURCE_REVIEW_REQUIRED ${r.ruleId} '
        '(${r.review.status.name}) ${r.source?.url}',
      );
    }
    for (final w in result.warnings.where(
      (w) => !w.message.startsWith('official rule not human-verified'),
    )) {
      stdout.writeln('  WARN $w');
    }
    if (release && blocking.isNotEmpty) failed = true;
  }
  if (failed) {
    stderr.writeln(
      release
          ? 'FAILED: dataset errors or unverified official rules (release mode).'
          : 'FAILED: dataset validation errors.',
    );
    exit(1);
  }
  stdout.writeln('OK');
}
