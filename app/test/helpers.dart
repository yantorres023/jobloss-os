import 'dart:convert';
import 'dart:io';

import 'package:jobloss_os/domain/dataset_validator.dart';
import 'package:jobloss_os/domain/local_date.dart';
import 'package:jobloss_os/domain/rules.dart';

const datasetPath = 'assets/rules/us_tx/rules.json';

String rawDataset() => File(datasetPath).readAsStringSync();

Map<String, dynamic> datasetMap() => jsonDecode(rawDataset()) as Map<String, dynamic>;

RuleDataset realDataset() => parseAndValidateDataset(rawDataset());

RuleDataset datasetFrom(Map<String, dynamic> m) => parseAndValidateDataset(jsonEncode(m));

Map<String, dynamic> ruleIn(Map<String, dynamic> m, String id) =>
    (m['rules'] as List).cast<Map<String, dynamic>>().firstWhere((r) => r['rule_id'] == id);

LocalDate d(String s) => LocalDate.parse(s);
