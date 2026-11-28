import 'package:flutter/material.dart';

import 'config.dart';
import 'data/backup_service.dart';
import 'data/document_service.dart';
import 'data/repository.dart';

const double _cardRadius = 8;

void _showMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

void _showError(BuildContext context, Object error) =>
    _showMessage(context, 'Error: $error');

double _toAmount(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? 0;
}

int _number(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

String _money(double amount) => '৳${amount.toStringAsFixed(2)}';

String _datePart(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;

Widget _card(
  Palette palette, {
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(14),
}) =>
    Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );

Widget _sectionTitle(String text, Palette palette) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: palette.primary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

Widget _statCard(Palette palette, String label, String value) => _card(
      palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

Widget _emptyText(Palette palette, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(color: palette.muted, fontSize: 12),
      ),
    );

InputDecoration _decoration(Palette palette, String hint) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_cardRadius),
    borderSide: BorderSide(color: palette.border),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: palette.muted, fontSize: 13),
    filled: true,
    fillColor: palette.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
  );
}

TextField _field(
  Palette palette,
  TextEditingController controller,
  String hint, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) =>
    TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _decoration(palette, hint),
    );

ButtonStyle _primaryButton(Palette palette) => FilledButton.styleFrom(
      backgroundColor: palette.primary,
      foregroundColor: palette.onPrimary,
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
    );

ButtonStyle _secondaryButton(Palette palette) => OutlinedButton.styleFrom(
      foregroundColor: palette.secondary,
      side: BorderSide(color: palette.border),
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
    );

IconData _iconForAction(String action) {
  final value = action.toLowerCase();
  if (value.contains('patient') || value.contains('registration')) {
    return Icons.people_alt_rounded;
  }
  if (value.contains('schedule') ||
      value.contains('appointment') ||
      value.contains('calendar')) {
    return Icons.calendar_month_rounded;
  }
  if (value.contains('treatment') || value.contains('therapy')) {
    return Icons.healing_rounded;
  }
  if (value.contains('account') || value.contains('payment')) {
    return Icons.account_balance_wallet_rounded;
  }
  if (value.contains('finance') || value.contains('report')) {
    return Icons.show_chart_rounded;
  }
  if (value.contains('file') || value.contains('media') || value.contains('document')) {
    return Icons.folder_open_rounded;
  }
  if (value.contains('backup') || value.contains('restore')) {
    return Icons.backup_rounded;
  }
  if (value.contains('setting') || value.contains('profile')) {
    return Icons.settings_outlined;
  }
  return Icons.medical_services_rounded;
}

class _Module {
  const _Module(this.label, this.action, this.icon);

  final String label;
  final String action;
  final IconData icon;

  static const List<_Module> fallback = <_Module>[
    _Module('Schedule', 'schedule', Icons.calendar_month_rounded),
    _Module('Treatment', 'treatment', Icons.healing_rounded),
    _Module('Accounts', 'patient_accounts', Icons.account_balance_wallet_rounded),
    _Module('Finance', 'financial_reports', Icons.show_chart_rounded),
    _Module('Files & media', 'files_media', Icons.folder_open_rounded),
    _Module('Backup', 'backup_restore', Icons.backup_rounded),
    _Module('Settings', 'settings', Icons.settings_outlined),
    _Module('Patients', 'patients', Icons.people_alt_rounded),
  ];
}

mixin _PatientSource<T extends StatefulWidget> on State<T> {
  AlsefaRepository get repository;
  RemoteConfig get config;

  List<Patient> patients = <Patient>[];
  String? selectedPatientId;

  Future<void> loadPatients({String? preferredId}) async {
    try {
      final items = await repository.patients();
      if (!mounted) return;
      setState(() {
        patients = items;
        final wanted = preferredId ?? selectedPatientId;
        final hasWanted =
            wanted != null && items.any((item) => item.id == wanted);
        selectedPatientId = hasWanted
            ? wanted
            : (items.isEmpty ? null : items.first.id);
      });
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  String patientName(String id) {
    for (final patient in patients) {
      if (patient.id == id) {
        return patient.name.trim().isEmpty ? 'Unnamed patient' : patient.name;
      }
    }
    return 'Unknown patient';
  }

  Widget patientDropdown(Palette palette, {ValueChanged<String?>? onChanged}) {
    return DropdownButtonFormField<String>(
      value: selectedPatientId,
      isExpanded: true,
      items: <DropdownMenuItem<String>>[
        for (final patient in patients)
          DropdownMenuItem<String>(
            value: patient.id,
            child: Text(
              patient.name.trim().isEmpty ? 'Unnamed patient' : patient.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      hint: Text('Select patient'),
      decoration: _decoration(palette, 'Select patient'),
      onChanged: onChanged ??
          (value) {
            if (mounted) setState(() => selectedPatientId = value);
          },
    );
  }
}

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({
    super.key,
    required this.config,
    required this.repository,
    required this.onAction,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;
  final void Function(String) onAction;

  @override
  State<DashboardOverviewScreen> createState() =>
      _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  Map<String, dynamic> _summary = <String, dynamic>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool notify = false}) async {
    try {
      final summary = await widget.repository.dashboardSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
      if (notify) _showMessage(context, 'Overview refreshed');
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(context, error);
    }
  }

  List<Widget> _summaryTiles(Palette palette) => <Widget>[
        _statCard(
            palette, 'Patients', '${_number(_summary['patients'])}'),
        _statCard(
            palette, 'Today visits', '${_number(_summary['todayVisits'])}'),
        _statCard(palette, 'Today sessions',
            '${_number(_summary['todaySessions'])}'),
        _statCard(palette, 'Completed sessions',
            '${_number(_summary['completedSessions'])}'),
        _statCard(
            palette, 'Documents', '${_number(_summary['documents'])}'),
        _statCard(
            palette, 'Treatments', '${_number(_summary['treatments'])}'),
        _statCard(
            palette, 'Income', _money(_toAmount(_summary['income']))),
        _statCard(
            palette, 'Expenses', _money(_toAmount(_summary['expenses']))),
        _statCard(
            palette, 'Net balance', _money(_toAmount(_summary['balance']))),
        _statCard(
            palette, 'Pending sync', '${_number(_summary['pendingSync'])}'),
      ];

  @override
  Widget build(BuildContext context) {
    final palette = widget.config.palette;
    final configured = widget.config.grid.items
        .where((item) => item.visible)
        .map(
          (item) => _Module(
            item.label,
            item.action,
            _iconForAction(item.action),
          ),
        )
        .toList();
    final modules = configured.isEmpty ? _Module.fallback : configured;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('Overview', palette)),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _load(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (_loading)
            _card(
              palette,
              padding: const EdgeInsets.all(10),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: palette.primary,
                backgroundColor: palette.border,
              ),
            ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: _summaryTiles(palette),
              );
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Quick modules', palette),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.9,
                children: <Widget>[
                  for (final module in modules)
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary.withOpacity(0.12),
                        foregroundColor: palette.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_cardRadius),
                        ),
                      ),
                      onPressed: () => widget.onAction(module.action),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(module.icon, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            module.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with _PatientSource<ScheduleScreen> {
  AlsefaRepository get repository => widget.repository;
  RemoteConfig get config => widget.config;

  List<Visit> _visits = <Visit>[];
  List<Visit> _allVisits = <Visit>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await loadPatients();
    await _loadVisits();
  }

  Future<void> _loadVisits({bool notify = false}) async {
    try {
      final visits = await repository.visits();
      if (!mounted) return;
      final filtered = selectedPatientId == null
          ? visits
          : visits
              .where((visit) => visit.patientId == selectedPatientId)
              .toList();
      setState(() {
        _allVisits = visits;
        _visits = filtered;
      });
      if (notify) _showMessage(context, 'Schedule refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _markArrival() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      _showMessage(context, 'Select a patient first');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final visit = Visit(
        patientId: patientId,
        arrivedAt: nowIso(),
        status: 'arrived',
        isRushHour: now.hour >= 16 && now.hour < 20,
      );
      await repository.saveVisit(visit);
      await _loadVisits();
      if (!mounted) return;
      _showMessage(context, 'Arrival recorded');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startSession() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      _showMessage(context, 'Select a patient first');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final rushHour = now.hour >= 16 && now.hour < 20;
      final openVisits = _visits
          .where(
            (visit) =>
                visit.patientId == patientId && visit.sessionAt.trim().isEmpty,
          )
          .toList();
      final visit = openVisits.isEmpty
          ? Visit(
              patientId: patientId,
              arrivedAt: nowIso(),
              sessionAt: nowIso(),
              status: 'in_session',
              isRushHour: rushHour,
            )
          : openVisits.first.copyWith(
              sessionAt: nowIso(),
              status: 'in_session',
            );
      await repository.saveVisit(visit);
      await _loadVisits();
      if (!mounted) return;
      _showMessage(context, 'Session started');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _visitCard(Palette palette, Visit visit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        palette,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName(visit.patientId),
              style: TextStyle(
                color: palette.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Arrival: ${visit.arrivedAt.isEmpty ? 'not recorded' : visit.arrivedAt}',
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
            Text(
              'Session: ${visit.sessionAt.isEmpty ? 'not started' : visit.sessionAt}',
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
            Text(
              'Status: ${visit.status}${visit.isRushHour ? ' (rush hour)' : ''}',
              style: TextStyle(
                color: visit.isRushHour ? palette.secondary : palette.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    final today = dateKey();
    final rushTotal = _allVisits.where((visit) => visit.isRushHour).length;
    final rushToday = _allVisits
        .where(
          (visit) =>
              visit.isRushHour && _datePart(visit.arrivedAt) == today,
        )
        .length;
    final arrivalsToday = _allVisits
        .where((visit) => _datePart(visit.arrivedAt) == today)
        .length;
    final sessionsToday = _allVisits
        .where((visit) => _datePart(visit.sessionAt) == today)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Schedule', palette),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                patientDropdown(
                  palette,
                  onChanged: (value) {
                    setState(() => selectedPatientId = value);
                    _loadVisits();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: _primaryButton(palette),
                        onPressed: _busy ? null : _markArrival,
                        child: const Text('Mark arrival'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: _secondaryButton(palette),
                        onPressed: _busy ? null : _startSession,
                        child: const Text('Start session'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Rush hour analytics', palette),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: <Widget>[
                  _statCard(palette, 'Rush visits (all)',
                      '${_number(rushTotal)}'),
                  _statCard(
                      palette, 'Rush visits today', '${_number(rushToday)}'),
                  _statCard(palette, 'Arrivals today',
                      '${_number(arrivalsToday)}'),
                  _statCard(palette, 'Sessions today',
                      '${_number(sessionsToday)}'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sectionTitle('Visits', palette)),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _loadVisits(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          _card(
            palette,
            child: _visits.isEmpty
                ? _emptyText(palette, 'No visits recorded for this patient.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final visit in _visits) _visitCard(palette, visit),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class TreatmentScreen extends StatefulWidget {
  const TreatmentScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen>
    with _PatientSource<TreatmentScreen> {
  AlsefaRepository get repository => widget.repository;
  RemoteConfig get config => widget.config;

  final TextEditingController _assessment = TextEditingController();
  final TextEditingController _plan = TextEditingController();
  final TextEditingController _checklist = TextEditingController();

  List<Treatment> _treatments = <Treatment>[];
  List<SessionRecord> _sessions = <SessionRecord>[];
  String? _treatmentId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _assessment.dispose();
    _plan.dispose();
    _checklist.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await loadPatients();
    await _load(hydrate: true);
  }

  Future<void> _load({bool hydrate = false, bool notify = false}) async {
    final patientId = selectedPatientId;
    try {
      final treatments = patientId == null
          ? <Treatment>[]
          : await repository.treatments(patientId);
      final sessions = patientId == null
          ? <SessionRecord>[]
          : await repository.sessions(patientId);
      if (!mounted) return;
      setState(() {
        _treatments = treatments;
        _sessions = sessions;
        if (hydrate) {
          if (treatments.isEmpty) {
            _treatmentId = null;
            _assessment.clear();
            _plan.clear();
            _checklist.clear();
          } else {
            final latest = treatments.first;
            _treatmentId = latest.id;
            _assessment.text = latest.assessment;
            _plan.text = latest.plan;
            _checklist.text = latest.checklist.join('\n');
          }
        }
      });
      if (notify) _showMessage(context, 'Treatment record refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  void _selectPatient(String? value) {
    setState(() {
      selectedPatientId = value;
      _treatmentId = null;
      _assessment.clear();
      _plan.clear();
      _checklist.clear();
    });
    _load(hydrate: true);
  }

  Future<void> _saveTreatment() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      _showMessage(context, 'Select a patient first');
      return;
    }
    if (_assessment.text.trim().isEmpty || _plan.text.trim().isEmpty) {
      _showMessage(context, 'Add assessment and plan before saving');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final items = _checklist.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final treatment = Treatment(
        id: _treatmentId,
        patientId: patientId,
        assessment: _assessment.text.trim(),
        plan: _plan.text.trim(),
        checklist: items,
      );
      await repository.saveTreatment(treatment);
      await _load(hydrate: true);
      if (!mounted) return;
      _showMessage(context, 'Treatment saved');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeSession() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      _showMessage(context, 'Select a patient first');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final key = dateKey();
      final exists = await repository.hasSession(patientId, key);
      if (exists) {
        if (mounted) {
          _showMessage(context, 'Today session is already completed');
        }
        return;
      }
      await repository.saveSession(
        SessionRecord(
          patientId: patientId,
          treatmentId: _treatmentId ?? '',
          dateKey: key,
          completed: true,
          notes: 'Therapy session completed',
        ),
      );
      await _load();
      if (!mounted) return;
      _showMessage(context, 'Session completed for today');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Treatment', palette),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                patientDropdown(palette, onChanged: _selectPatient),
                const SizedBox(height: 12),
                _field(palette, _assessment, 'Assessment findings', maxLines: 3),
                const SizedBox(height: 10),
                _field(palette, _plan, 'Treatment plan', maxLines: 3),
                const SizedBox(height: 10),
                _field(palette, _checklist,
                    'Therapy checklist, one item per line',
                    maxLines: 4),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: _primaryButton(palette),
                        onPressed: _busy ? null : _saveTreatment,
                        child: const Text('Save treatment'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: _secondaryButton(palette),
                        onPressed: _busy ? null : _completeSession,
                        child: const Text('Complete today'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sectionTitle('Session history', palette)),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _load(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          _card(
            palette,
            child: _sessions.isEmpty
                ? _emptyText(palette, 'No sessions recorded yet.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final session in _sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.dateKey} - ${session.completed ? 'completed' : 'pending'}',
                                style: TextStyle(
                                  color: palette.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                session.notes.isEmpty
                                    ? 'No session notes'
                                    : session.notes,
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Saved treatment plans', palette),
          _card(
            palette,
            child: _treatments.isEmpty
                ? _emptyText(palette, 'No treatment plan saved for this patient.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final treatment in _treatments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                treatment.assessment,
                                style: TextStyle(
                                  color: palette.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                treatment.plan,
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 12,
                                ),
                              ),
                              if (treatment.checklist.isNotEmpty)
                                Text(
                                  treatment.checklist.join(' | '),
                                  style: TextStyle(
                                    color: palette.secondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class PatientAccountsScreen extends StatefulWidget {
  const PatientAccountsScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<PatientAccountsScreen> createState() => _PatientAccountsScreenState();
}

class _PatientAccountsScreenState extends State<PatientAccountsScreen>
    with _PatientSource<PatientAccountsScreen> {
  AlsefaRepository get repository => widget.repository;
  RemoteConfig get config => widget.config;

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();

  Patient? _patient;
  List<LedgerEntry> _payments = <LedgerEntry>[];
  List<SessionRecord> _sessions = <SessionRecord>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await loadPatients();
    await _load();
  }

  Future<void> _load({bool notify = false}) async {
    final patientId = selectedPatientId;
    try {
      final patient =
          patientId == null ? null : await repository.patient(patientId);
      final payments = patientId == null
          ? <LedgerEntry>[]
          : await repository.ledger(patientId: patientId, type: 'payment');
      final sessions = patientId == null
          ? <SessionRecord>[]
          : await repository.sessions(patientId);
      if (!mounted) return;
      setState(() {
        _patient = patient;
        _payments = payments;
        _sessions = sessions;
      });
      if (notify) _showMessage(context, 'Account refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _savePayment() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      _showMessage(context, 'Select a patient first');
      return;
    }
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      _showMessage(context, 'Enter a valid amount');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final entry = LedgerEntry(
        patientId: patientId,
        type: 'payment',
        category: 'payment',
        description: _note.text.trim().isEmpty
            ? 'Payment received'
            : _note.text.trim(),
        amount: value,
        occurredAt: nowIso(),
      );
      await repository.saveLedger(entry);
      _amount.clear();
      _note.clear();
      await _load();
      if (!mounted) return;
      _showMessage(context, 'Payment recorded');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    final sessionCount = _sessions.length;
    final expected = (_patient?.firstFee ?? 0) +
        (sessionCount > 1
            ? (sessionCount - 1) * (_patient?.regularFee ?? 0)
            : 0);
    final paid = (_patient?.initialPayment ?? 0) +
        _payments.fold<double>(0, (sum, entry) => sum + entry.amount);
    final due = expected - paid;
    final advance = paid - expected;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Patient accounts', palette),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                patientDropdown(
                  palette,
                  onChanged: (value) {
                    setState(() => selectedPatientId = value);
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  palette,
                  _amount,
                  'Amount in ৳',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                _field(palette, _note, 'Payment note'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _primaryButton(palette),
                    onPressed: _busy ? null : _savePayment,
                    child: const Text('Record payment'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sectionTitle('Balance', palette)),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _load(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: <Widget>[
                  _statCard(palette, 'Expected', _money(expected)),
                  _statCard(palette, 'Paid', _money(paid)),
                  _statCard(
                      palette, 'Due', _money(due > 0 ? due : 0)),
                  _statCard(palette, 'Advance',
                      _money(advance > 0 ? advance : 0)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Sessions', palette),
          _card(
            palette,
            child: _sessions.isEmpty
                ? _emptyText(palette, 'No sessions recorded yet.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final session in _sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${session.dateKey} - ${session.completed ? 'completed' : 'pending'}',
                            style: TextStyle(
                              color: palette.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Payment history', palette),
          _card(
            palette,
            child: _payments.isEmpty
                ? _emptyText(palette, 'No payments recorded yet.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in _payments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${entry.description} - ${_money(entry.amount)} - ${_datePart(entry.occurredAt)}',
                            style: TextStyle(
                              color: palette.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String _type = 'income';
  List<LedgerEntry> _entries = <LedgerEntry>[];
  Map<String, dynamic> _summary = <String, dynamic>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load({bool notify = false}) async {
    try {
      final entries = await widget.repository.ledger();
      final summary = await widget.repository.dashboardSummary();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _summary = summary;
      });
      if (notify) _showMessage(context, 'Financial report refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _addEntry() async {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      _showMessage(context, 'Enter a valid amount');
      return;
    }
    if (_category.text.trim().isEmpty || _description.text.trim().isEmpty) {
      _showMessage(context, 'Add category and description');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final entry = LedgerEntry(
        type: _type,
        category: _category.text.trim(),
        description: _description.text.trim(),
        amount: value,
        occurredAt: nowIso(),
      );
      await widget.repository.saveLedger(entry);
      _amount.clear();
      _category.clear();
      _description.clear();
      await _load();
      if (!mounted) return;
      _showMessage(context, '${_type} entry added');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteEntry(LedgerEntry entry) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.deleteLedger(entry.id);
      await _load();
      if (!mounted) return;
      _showMessage(context, 'Transaction deleted');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.config.palette;
    final income = _toAmount(_summary['income']);
    final expense = _toAmount(_summary['expenses']);
    final net = _toAmount(_summary['balance']);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Financial reports', palette),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 3 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: <Widget>[
                  _statCard(palette, 'Income', _money(income)),
                  _statCard(palette, 'Expense', _money(expense)),
                  _statCard(palette, 'Net', _money(net)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  isExpanded: true,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                        value: 'income', child: Text('Income')),
                    DropdownMenuItem<String>(
                        value: 'expense', child: Text('Expense')),
                  ],
                  decoration: _decoration(palette, 'Entry type'),
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _type = value);
                          }
                        },
                ),
                const SizedBox(height: 10),
                _field(
                  palette,
                  _amount,
                  'Amount in ৳',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                _field(palette, _category, 'Category'),
                const SizedBox(height: 10),
                _field(palette, _description, 'Description'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _primaryButton(palette),
                    onPressed: _busy ? null : _addEntry,
                    child: Text('Add ${_type} entry'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sectionTitle('Transactions', palette)),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _load(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          _card(
            palette,
            child: _entries.isEmpty
                ? _emptyText(palette, 'No transactions recorded yet.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in _entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.type} - ${_money(entry.amount)}',
                                      style: TextStyle(
                                        color: palette.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${entry.category} - ${entry.description} - ${_datePart(entry.occurredAt)}',
                                      style: TextStyle(
                                        color: palette.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete transaction',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: palette.secondary,
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => _deleteEntry(entry),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class FilesMediaScreen extends StatefulWidget {
  const FilesMediaScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<FilesMediaScreen> createState() => _FilesMediaScreenState();
}

class _FilesMediaScreenState extends State<FilesMediaScreen>
    with _PatientSource<FilesMediaScreen> {
  AlsefaRepository get repository => widget.repository;
  RemoteConfig get config => widget.config;

  List<DocumentRecord> _documents = <DocumentRecord>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await loadPatients();
    await _loadDocuments();
  }

  Future<void> _loadDocuments({bool notify = false}) async {
    final patientId = selectedPatientId;
    try {
      final documents = patientId == null
          ? <DocumentRecord>[]
          : await repository.documents(patientId);
      if (!mounted) return;
      setState(() => _documents = documents);
      if (notify) _showMessage(context, 'Documents refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _upload() async {
    final patientId = selectedPatientId;
    if (patientId == null) {
      _showMessage(context, 'Select a patient first');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final document = await DocumentService.pickForPatient(
        patientId,
        repository,
      );
      await _loadDocuments();
      if (!mounted) return;
      _showMessage(
        context,
        document == null ? 'No file selected' : 'Document uploaded',
      );
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(DocumentRecord document) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DocumentService.open(document);
      if (!mounted) return;
      _showMessage(context, 'Document opened');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(DocumentRecord document) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await repository.deleteDocument(document.id);
      await _loadDocuments();
      if (!mounted) return;
      _showMessage(context, 'Document deleted');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Files & media', palette),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                patientDropdown(
                  palette,
                  onChanged: (value) {
                    setState(() => selectedPatientId = value);
                    _loadDocuments();
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: _primaryButton(palette),
                    onPressed: _busy ? null : _upload,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload document'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sectionTitle('Documents', palette)),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _loadDocuments(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          _card(
            palette,
            child: _documents.isEmpty
                ? _emptyText(palette, 'No documents uploaded for this patient.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final document in _documents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      document.name,
                                      style: TextStyle(
                                        color: palette.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${document.mimeType.isEmpty ? 'file' : document.mimeType} - ${_datePart(document.createdAt)}',
                                      style: TextStyle(
                                        color: palette.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Open document',
                                icon: Icon(
                                  Icons.open_in_new_rounded,
                                  color: palette.primary,
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => _open(document),
                              ),
                              IconButton(
                                tooltip: 'Delete document',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: palette.secondary,
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => _delete(document),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  String _result = '';
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await BackupService.exportToDocuments(widget.repository);
      if (!mounted) return;
      setState(() => _result = 'Backup exported to $path');
      _showMessage(context, 'Backup exported');
    } catch (error) {
      if (!mounted) return;
      setState(() => _result = 'Export failed');
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final count = await BackupService.restoreFromPicker(widget.repository);
      if (!mounted) return;
      setState(() => _result = count == 0
          ? 'No backup selected'
          : 'Restored $count records');
      _showMessage(
        context,
        count == 0 ? 'Restore cancelled' : 'Backup restored',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _result = 'Restore failed');
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Backup & restore', palette),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Backups include patients, documents, visits, treatments, '
                  'sessions, ledger entries and sync records.',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: _primaryButton(palette),
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.backup_rounded, size: 18),
                    label: const Text('Export backup'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: _secondaryButton(palette),
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restore backup'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last result',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  _result.isEmpty ? 'No backup action yet.' : _result,
                  style: TextStyle(color: palette.onSurface, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _pending = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool notify = false}) async {
    try {
      final pending = await widget.repository.pendingSyncCount();
      if (!mounted) return;
      setState(() => _pending = pending);
      if (notify) _showMessage(context, 'Settings refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _clearData() async {
    final palette = widget.config.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        title: Text(
          'Clear local data?',
          style: TextStyle(color: palette.onSurface, fontSize: 16),
        ),
        content: Text(
          'This removes all locally stored patients, documents, visits, '
          'treatments, sessions, payments and sync records.',
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: _primaryButton(palette),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.clearAll();
      await _load();
      if (!mounted) return;
      _showMessage(context, 'Local data cleared');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Settings', palette),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: <Widget>[
                  _statCard(palette, 'Offline mode', 'Active'),
                  _statCard(
                      palette, 'Pending sync', '${_number(_pending)}'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Readiness', palette),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud sync: ${widget.config.featureEnabled('cloud_sync') ? 'configured' : 'ready for integration'}',
                  style: TextStyle(color: palette.onSurface, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authentication: ${widget.config.featureEnabled('authentication') ? 'configured' : 'ready for integration'}',
                  style: TextStyle(color: palette.onSurface, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'Roles & permissions: ${widget.config.featureEnabled('roles') ? 'configured' : 'ready for integration'}',
                  style: TextStyle(color: palette.onSurface, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Clear all locally stored data from this device.',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.secondary,
                      foregroundColor: palette.onPrimary,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_cardRadius),
                      ),
                    ),
                    onPressed: _busy ? null : _clearData,
                    child: const Text('Clear local data'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: _secondaryButton(palette),
            onPressed: () => _load(notify: true),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh status'),
          ),
        ],
      ),
    );
  }
}

class PatientsManagementScreen extends StatefulWidget {
  const PatientsManagementScreen({
    super.key,
    required this.config,
    required this.repository,
    required this.onRegister,
    required this.onEdit,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;
  final VoidCallback onRegister;
  final void Function(Patient) onEdit;

  @override
  State<PatientsManagementScreen> createState() =>
      _PatientsManagementScreenState();
}

class _PatientsManagementScreenState extends State<PatientsManagementScreen> {
  final TextEditingController _search = TextEditingController();

  String? _gender;
  String? _diagnosis;
  List<Patient> _patients = <Patient>[];
  List<String> _diagnoses = <String>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool notify = false}) async {
    try {
      final filtered = await widget.repository.patients(
        query: _search.text,
        gender: _gender,
        diagnosis: _diagnosis,
      );
      final all = await widget.repository.patients();
      final options = <String>{};
      for (final patient in all) {
        final value = patient.diagnosis.trim();
        if (value.isNotEmpty) options.add(value);
      }
      if (!mounted) return;
      setState(() {
        _patients = filtered;
        _diagnoses = options.toList()..sort();
        if (_diagnosis != null && !options.contains(_diagnosis)) {
          _diagnosis = null;
        }
      });
      if (notify) _showMessage(context, 'Patient list refreshed');
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _delete(Patient patient) async {
    final palette = widget.config.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        title: Text(
          'Delete patient?',
          style: TextStyle(color: palette.onSurface, fontSize: 16),
        ),
        content: Text(
          'This also removes documents, visits, treatments and sessions '
          'linked to ${patient.name}.',
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.secondary,
              foregroundColor: palette.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.deletePatient(patient.id);
      await _load();
      if (!mounted) return;
      _showMessage(context, 'Patient deleted');
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _gender = null;
      _diagnosis = null;
    });
    _load(notify: true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('Patients', palette)),
              FilledButton.icon(
                style: _primaryButton(palette),
                onPressed: widget.onRegister,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Register'),
              ),
            ],
          ),
          _card(
            palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => _load(),
                  decoration: _decoration(
                      palette, 'Search patient name or phone'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        isExpanded: true,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                              value: 'Male', child: Text('Male')),
                          DropdownMenuItem<String>(
                              value: 'Female', child: Text('Female')),
                          DropdownMenuItem<String>(
                              value: 'Other', child: Text('Other')),
                        ],
                        hint: Text('Gender'),
                        decoration: _decoration(palette, 'Gender'),
                        onChanged: (value) {
                          setState(() => _gender = value);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _diagnosis,
                        isExpanded: true,
                        items: <DropdownMenuItem<String>>[
                          for (final diagnosis in _diagnoses)
                            DropdownMenuItem<String>(
                              value: diagnosis,
                              child: Text(
                                diagnosis,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        hint: Text('Diagnosis'),
                        decoration: _decoration(palette, 'Diagnosis'),
                        onChanged: (value) {
                          setState(() => _diagnosis = value);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: _secondaryButton(palette),
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Clear filters'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'Results (${_patients.length})',
                  palette,
                ),
              ),
              OutlinedButton.icon(
                style: _secondaryButton(palette),
                onPressed: () => _load(notify: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          _card(
            palette,
            child: _patients.isEmpty
                ? _emptyText(palette, 'No patients match the current filters.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final patient in _patients)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _card(
                            palette,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: TextStyle(
                                    color: palette.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${patient.age} yrs | ${patient.gender} | ${patient.phone}',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Diagnosis: ${patient.diagnosis.isEmpty ? 'not recorded' : patient.diagnosis}',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'BP: ${patient.bp.isEmpty ? 'not recorded' : patient.bp} | Weight: ${patient.weightKg} kg',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Fees: ${_money(patient.firstFee)} first, '
                                  '${_money(patient.regularFee)} regular',
                                  style: TextStyle(
                                    color: palette.secondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: _secondaryButton(palette),
                                        onPressed: () =>
                                            widget.onEdit(patient),
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 16),
                                        label: const Text('Edit'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: _secondaryButton(palette),
                                        onPressed: _busy
                                            ? null
                                            : () => _delete(patient),
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: palette.secondary,
                                          size: 16,
                                        ),
                                        label: const Text('Delete'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
