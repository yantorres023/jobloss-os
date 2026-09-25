import 'package:flutter/material.dart';

import '../../domain/local_date.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool? _inTexas;
  LocalDate? _lastDay;
  LocalDate? _applied;
  LocalDate? _coverageEnd;
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canStart = _inTexas == true && _lastDay != null && _understood;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('JobLoss OS', style: t.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Lost your job? This helps you see what to do today, what deadline is next, '
              'and keep proof of what you sent — for unemployment benefits in Texas.',
              style: t.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What this app is — and isn\'t', style: t.titleMedium),
                    const SizedBox(height: 8),
                    const _Point(
                      Icons.block,
                      'It is not the Texas Workforce Commission (TWC) and is not connected to it. You apply and request payments on TWC\'s own site or phone line.',
                    ),
                    const _Point(
                      Icons.gavel_outlined,
                      'It can\'t tell you if you\'re eligible or whether to appeal. Only TWC decides your claim. Legal aid can advise you.',
                    ),
                    const _Point(
                      Icons.link,
                      'Every step links to the official page it comes from. Your letters and TWC\'s pages always win over this app.',
                    ),
                    const _Point(
                      Icons.lock_outline,
                      'It never asks for your Social Security number, passwords, PIN or bank details. What you enter stays on this phone.',
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Where do you file?'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Texas')),
                ButtonSegment(value: false, label: Text('Another state')),
              ],
              emptySelectionAllowed: true,
              selected: {?_inTexas},
              onSelectionChanged: (s) => setState(() => _inTexas = s.isEmpty ? null : s.first),
            ),
            if (_inTexas == false)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Sorry — this version only covers Texas. Rules differ a lot between states, '
                  'and we only include steps we can check against official sources. '
                  'Please use your own state\'s unemployment agency website.',
                  style: t.bodyMedium,
                ),
              ),
            if (_inTexas == true) ...[
              const SectionTitle('A few dates'),
              DateField(
                label: 'Your last day of work',
                value: _lastDay,
                onChanged: (d) => setState(() => _lastDay = d),
              ),
              DateField(
                label: 'Date you applied with TWC (leave empty if not yet)',
                value: _applied,
                onChanged: (d) => setState(() => _applied = d),
              ),
              DateField(
                label: 'When your job-based health coverage ends (optional)',
                helper: 'Used only to remind you about health coverage windows.',
                value: _coverageEnd,
                onChanged: (d) => setState(() => _coverageEnd = d),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _understood,
                onChanged: (v) => setState(() => _understood = v ?? false),
                title: const Text('I understand this app is not TWC and not legal advice.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: canStart
                    ? () => AppScope.read(context).completeOnboarding(
                        lastDayWorked: _lastDay,
                        appliedDate: _applied,
                        coverageEndDate: _coverageEnd,
                      )
                    : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Show my steps'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
