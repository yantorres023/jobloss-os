import 'package:flutter/material.dart';

import '../../domain/dataset_validator.dart';
import '../../domain/export.dart' show factLabels;
import '../../domain/local_date.dart';
import '../../domain/rules.dart';
import '../../services/export_service.dart';
import '../app_scope.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'task_detail_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void go(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.timeline),
          title: const Text('Timeline'),
          subtitle: const Text('Everything in date order'),
          onTap: () => go(const TimelineScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('My questions for TWC'),
          subtitle: const Text('A list to have ready when you call'),
          onTap: () => go(const QuestionsScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text('Get help'),
          subtitle: const Text('TWC phone lines and free legal aid'),
          onTap: () => go(const HelpScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.event_note),
          title: const Text('My dates'),
          subtitle: const Text('Dates and numbers you entered'),
          onTap: () => go(const MyDatesScreen()),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy, export and delete'),
          onTap: () => go(const SettingsScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About this app and its sources'),
          onTap: () => go(const AboutScreen()),
        ),
      ],
    );
  }
}

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ds = app.dataset;
    final events = <(LocalDate, IconData, String, String?)>[];
    for (final e in app.data.profile.dates.entries) {
      events.add((e.value, Icons.flag_outlined, factLabels[e.key] ?? e.key, null));
    }
    for (final n in app.data.notices) {
      final title = ds?.noticeTypeById(n.typeId)?.title ?? n.typeId;
      events.add((
        n.mailedDate ?? n.loggedOn,
        Icons.mail_outline,
        'Letter: $title${n.mailedDate == null ? ' (logged)' : ' (mailed)'}',
        null,
      ));
    }
    for (final s in app.data.submissions) {
      events.add((
        s.date,
        Icons.receipt_long_outlined,
        '${s.kind.label}${s.confirmation.isNotEmpty ? ' · #${s.confirmation}' : ''}',
        null,
      ));
    }
    for (final s in app.data.statusNotes) {
      events.add((s.date, Icons.info_outline, 'Status: "${s.text}"', null));
    }
    for (final t in app.roadmap) {
      final c = t.completion;
      if (c != null) {
        events.add((c.completedOn, Icons.check_circle_outline, 'Done: ${t.rule.title}', t.key));
      }
    }
    events.sort((a, b) => b.$1.compareTo(a.$1));
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: events.isEmpty
          ? const Center(child: Text('Nothing yet.'))
          : ListView(
              children: [
                for (final e in events)
                  ListTile(
                    leading: Icon(e.$2),
                    title: Text(e.$3),
                    subtitle: Text(formatDate(e.$1)),
                    onTap: e.$4 == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TaskDetailScreen(taskKey: e.$4!),
                            ),
                          ),
                  ),
              ],
            ),
    );
  }
}

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My questions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Write questions before you call TWC or legal aid, and note the answer and who gave it.',
            ),
          ),
          if (app.data.questions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No questions yet. Steps have suggested questions you can add.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final q in app.data.questions)
            Card(
              child: CheckboxListTile(
                value: q.answered,
                onChanged: (v) {
                  q.answered = v ?? false;
                  app.updateQuestion(q);
                },
                title: Text(q.text),
                subtitle: q.answer.isEmpty
                    ? const Text('Tap the pencil to add the answer')
                    : Text('Answer: ${q.answer}'),
                secondary: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Add answer',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final a = await _prompt(context, 'Answer', q.answer);
                        if (a != null) {
                          q.answer = a;
                          app.updateQuestion(q);
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete question',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => app.deleteQuestion(q),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final t = await _prompt(context, 'New question', '');
          if (t != null && t.isNotEmpty) app.addQuestion(t);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add question'),
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, String title, String initial) async {
    final c = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    return r;
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final contacts = app.dataset?.helpContacts ?? const <HelpContact>[];
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Get help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('When you need a person, not an app', style: text.titleMedium),
                  const SizedBox(height: 8),
                  const Text('• You were denied, or got a determination you don\'t understand.'),
                  const Text('• You\'re thinking about an appeal or have a hearing.'),
                  const Text('• TWC says you were overpaid, or asks about why you left your job.'),
                  const Text('• Wages or employers on your statement are wrong.'),
                  const Text('• Anything about whether you qualify.'),
                  const SizedBox(height: 8),
                  const Text(
                    'The app can\'t answer these. TWC decides claims; legal aid can advise you for free if you qualify.',
                  ),
                ],
              ),
            ),
          ),
          for (final c in contacts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: text.titleMedium),
                    Text(_authority(c.authority), style: text.bodySmall),
                    const SizedBox(height: 4),
                    Text(c.description),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (c.phone != null)
                          TextButton.icon(
                            onPressed: () => callPhone(context, c.phone!),
                            icon: const Icon(Icons.call_outlined),
                            label: Text(c.phone!),
                          ),
                        if (c.url != null)
                          TextButton.icon(
                            onPressed: () => openExternal(context, c.url!),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(Uri.parse(c.url!).host),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Phone numbers and links were collected from search summaries of official and legal-aid pages '
            'and are waiting for a person to re-check them. If one doesn\'t work, use the organization\'s own website.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }

  String _authority(String a) => switch (a) {
    'STATE_AGENCY' => 'Texas state agency',
    'FEDERAL_AGENCY' => 'U.S. federal government',
    'LEGAL_AID' => 'Free legal aid (non-profit)',
    _ => 'Other',
  };
}

class MyDatesScreen extends StatelessWidget {
  const MyDatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.data.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('My dates')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Changing a date updates your steps and reminders. Steps you already marked done stay done.',
          ),
          const SizedBox(height: 8),
          for (final e in knownFacts.entries)
            if (e.value == FactType.date)
              DateField(
                label: factLabels[e.key] ?? e.key,
                value: p.dates[e.key],
                onChanged: (d) => app.setDateFact(e.key, d),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextFormField(
                  key: ValueKey('count-${p.counts[e.key]}'),
                  initialValue: p.counts[e.key]?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: factLabels[e.key] ?? e.key,
                    helperText: 'From your TWC letter. Press done on the keyboard to save.',
                  ),
                  onFieldSubmitted: (s) {
                    final n = int.tryParse(s.trim());
                    app.setCountFact(e.key, (n == null || n < 0 || n > 50) ? null : n);
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy, export and delete')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Where your information lives', style: text.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Everything you enter — dates, letters, photos, notes — is stored only on this phone, '
            'in the app\'s private storage. There is no account and no server. The app has no ads '
            'and no analytics. It never asks for your SSN, passwords, PIN or bank details.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Because nothing is backed up by the app, deleting it or losing your phone deletes your '
            'records. Export regularly if you want a copy.',
          ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminders'),
            subtitle: const Text(
              'Notifications on this phone for due dates. They can be delayed or blocked by your '
              'phone\'s settings — always check the Steps screen too.',
            ),
            value: app.data.settings.remindersEnabled,
            onChanged: (v) async {
              final granted = await app.setRemindersEnabled(v);
              if (v && !granted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifications are blocked. Turn them on in your phone settings.',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share),
            title: const Text('Export my records'),
            subtitle: const Text(
              'Creates a readable summary, a full backup file and your photos, then opens the share '
              'menu. You choose where it goes (e.g. to legal aid, or your own e-mail).',
            ),
            onTap: () async {
              try {
                await shareExport(app);
              } on Object catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Delete all my data'),
            subtitle: const Text(
              'Removes all dates, letters, logs, photos and reminders from this phone. This can\'t be undone.',
            ),
            onTap: () async {
              if (await confirm(
                context,
                'Delete everything?',
                'All your records and photos in this app will be permanently deleted. Export first if you want a copy.',
                ok: 'Delete everything',
              )) {
                await app.deleteAllData();
                await clearExportCache();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ds = app.dataset;
    final text = Theme.of(context).textTheme;
    final pending = ds == null ? const <Rule>[] : rulesBlockingRelease(ds, app.today);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('JobLoss OS', style: text.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'An independent, unofficial organizer for people filing for unemployment benefits in Texas. '
            'It is not the Texas Workforce Commission, is not affiliated with or endorsed by any government '
            'agency, and does not give legal advice. It cannot file anything, see your claim, or decide '
            'anything about it.',
          ),
          const SectionTitle('How steps are chosen'),
          const Text(
            'Each step comes from a written rule with an official source link, the date it was last looked up, '
            'and whether a person has checked it. The app never guesses eligibility. When sources disagree, '
            'it reminds you by the earlier date. Dates printed on your own letters always win.',
          ),
          if (ds != null) ...[
            const SectionTitle('Rules in this version'),
            Text(
              '${ds.jurisdictionName} rules, version ${ds.datasetVersion} '
              '(published ${ds.publishedAt == null ? '?' : formatDate(ds.publishedAt!)}).',
            ),
            Text(
              '${ds.rules.length} steps; ${pending.length} official steps are still waiting for a person to '
              're-check their sources.',
            ),
          ],
          if (app.datasetError != null) ...[
            const SectionTitle('Rules unavailable'),
            Text('${app.datasetError}'),
          ],
          const SectionTitle('Draft documents'),
          const Text(
            'The privacy policy and terms for this app are drafts pending legal review. '
            'In short: no account, no server, no tracking, your data stays on your phone.',
          ),
        ],
      ),
    );
  }
}
