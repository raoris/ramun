import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'data/document_service.dart';
import 'data/repository.dart';
import 'modules_ui.dart';
import 'patient.dart';
import 'remote_config.dart';
import 'update.dart';

IconData iconFor(String name) {
  switch (name) {
    case 'ic_home':
      return Icons.home_rounded;
    case 'ic_appointments':
    case 'ic_calendar':
      return Icons.calendar_month_rounded;
    case 'ic_patients':
      return Icons.people_alt_rounded;
    case 'ic_profile':
      return Icons.account_circle_rounded;
    case 'ic_notifications':
      return Icons.notifications_rounded;
    case 'ic_services':
      return Icons.medical_services_rounded;
    case 'ic_therapists':
      return Icons.health_and_safety_rounded;
    case 'ic_registration':
      return Icons.person_add_alt_1_rounded;
    case 'ic_treatment':
      return Icons.healing_rounded;
    case 'ic_exercise':
      return Icons.fitness_center_rounded;
    case 'ic_progress':
      return Icons.show_chart_rounded;
    case 'ic_contact':
      return Icons.contact_support_rounded;
    case 'ic_about':
      return Icons.info_outline_rounded;
    case 'ic_back':
      return Icons.arrow_back_rounded;
    case 'ic_alsefa_logo':
      return Icons.medical_services_rounded;
    case 'ic_banner_physio':
      return Icons.accessibility_new_rounded;
    case 'ic_schedule':
      return Icons.schedule_rounded;
    case 'ic_finance':
      return Icons.account_balance_wallet_rounded;
    case 'ic_files':
      return Icons.folder_open_rounded;
    case 'ic_backup':
      return Icons.backup_rounded;
    case 'ic_settings':
      return Icons.settings_rounded;
    case 'ic_accounts':
      return Icons.receipt_long_rounded;
    case 'ic_dashboard':
      return Icons.dashboard_rounded;
    default:
      return Icons.medical_services_rounded;
  }
}

class AlsefaApp extends StatefulWidget {
  const AlsefaApp({super.key});

  @override
  State<AlsefaApp> createState() => _AlsefaAppState();
}

class _AlsefaAppState extends State<AlsefaApp> {
  RemoteConfigService? _service;
  AlsefaRepository? _repository;
  RemoteConfig? _config;
  String _screen = 'home';
  Patient? _editingPatient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _service = RemoteConfigService(preferences);
      final repository = await SqliteRepository.create();
      _repository = repository;
      final legacy = LegacyPatientStore(preferences);
      final legacyRecords = legacy.records();
      if (legacyRecords.isNotEmpty) {
        await repository.migrateLegacyPatients(legacyRecords);
        await legacy.clear();
      }
      await _load(forceRefresh: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Local storage unavailable: $error')),
      );
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final service = _service;
    if (service == null) return;
    final config = await service.load(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _config = config;
      _loading = false;
    });
    _checkMinimumVersion(config);
  }

  Future<void> _checkMinimumVersion(RemoteConfig config) async {
    int build;
    try {
      final info = await PackageInfo.fromPlatform();
      build = int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {
      return;
    }
    if (config.minimumAppVersion <= build || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A newer app version is available.')),
      );
    });
  }

  Future<void> _handleAction(String action) async {
    if (action == 'refresh') {
      setState(() => _loading = true);
      await _load(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration refreshed')),
        );
      }
      return;
    }
    if (action == 'update_app') {
      final uri = updateUri();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    setState(() => _screen = action);
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF078F91),
          body: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    if (config == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFE8F3F2),
          body: const Center(
            child: Text('Unable to start ALSEFA. Please restart the app.'),
          ),
        ),
      );
    }

    final palette = config.palette;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.primary,
          surface: palette.surface,
          onSurface: palette.onSurface,
        ),
        scaffoldBackgroundColor: palette.background,
      ),
      home: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(child: _buildBody(config)),
      ),
    );
  }

  Widget _buildBody(RemoteConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final extendedRail = constraints.maxWidth >= 1400;
        final screen = Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: _buildScreen(config),
            ),
          ),
        );
        if (!wide) {
          return Column(
            children: [
              AlsefaHeader(config: config, onAction: _handleAction),
              screen,
              AlsefaBottomNav(
                config: config,
                current: _screen,
                onNavigate: _handleAction,
              ),
            ],
          );
        }
        return Row(
          children: [
            AlsefaRail(
              config: config,
              current: _screen,
              extended: extendedRail,
              onNavigate: _handleAction,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  AlsefaHeader(config: config, onAction: _handleAction),
                  screen,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _startNewPatient() {
    setState(() {
      _editingPatient = null;
      _screen = 'patient_registration';
    });
  }

  void _editPatient(Patient patient) {
    setState(() {
      _editingPatient = patient;
      _screen = 'patient_registration';
    });
  }

  Widget _buildScreen(RemoteConfig config) {
    final repository = _repository;
    if (repository == null) {
      return Center(
        child: Text(
          'Local storage is not available.',
          style: TextStyle(color: config.palette.muted),
        ),
      );
    }
    if (_screen == 'home') {
      return HomeView(config: config, onAction: _handleAction);
    }
    if (_screen == 'dashboard') {
      return DashboardOverviewScreen(
        config: config,
        repository: repository,
        onAction: _handleAction,
      );
    }
    if (_screen == 'patient_registration') {
      return PatientRegistrationScreen(
        config: config,
        repository: repository,
        patient: _editingPatient,
        onSaved: () => _handleAction('patients'),
      );
    }
    if (_screen == 'patients') {
      return PatientsManagementScreen(
        config: config,
        repository: repository,
        onRegister: _startNewPatient,
        onEdit: _editPatient,
      );
    }
    if (_screen == 'appointments' || _screen == 'schedule') {
      return ScheduleScreen(config: config, repository: repository);
    }
    if (_screen == 'treatment_plans' || _screen == 'treatment_management') {
      return TreatmentScreen(config: config, repository: repository);
    }
    if (_screen == 'patient_progress' || _screen == 'patient_accounts') {
      return PatientAccountsScreen(config: config, repository: repository);
    }
    if (_screen == 'financial_reports') {
      return FinancialReportsScreen(config: config, repository: repository);
    }
    if (_screen == 'files_media') {
      return FilesMediaScreen(config: config, repository: repository);
    }
    if (_screen == 'backup_restore') {
      return BackupRestoreScreen(config: config, repository: repository);
    }
    if (_screen == 'settings') {
      return SettingsScreen(config: config, repository: repository);
    }
    final screen = config.screenById(_screen) ??
        ScreenConfig(
          id: _screen,
          title: _screen.replaceAll('_', ' '),
          message: 'This feature will be available soon.',
          icon: 'ic_placeholder',
          actions: const <ActionConfig>[],
        );
    return PlaceholderScreen(
      config: config,
      screen: screen,
      onAction: _handleAction,
    );
  }
}

class AlsefaHeader extends StatelessWidget {
  const AlsefaHeader({
    super.key,
    required this.config,
    required this.onAction,
  });

  final RemoteConfig config;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    final header = config.header;
    return Container(
      height: header.height + 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: palette.surface,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: palette.primary,
            radius: 15,
            child: Icon(
              iconFor(header.logo),
              size: 17,
              color: palette.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header.brand,
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  header.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          if (header.showNotification)
            Stack(
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none_rounded, color: palette.primary),
                  onPressed: () => onAction(header.notificationAction),
                ),
                Positioned(
                  right: 11,
                  top: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class AlsefaBottomNav extends StatelessWidget {
  const AlsefaBottomNav({
    super.key,
    required this.config,
    required this.current,
    required this.onNavigate,
  });

  final RemoteConfig config;
  final String current;
  final void Function(String) onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = config.bottomNavigation.items.where((item) => item.visible).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final index = items.indexWhere((item) => item.id == current);
    final palette = config.palette;
    return SizedBox(
      height: config.bottomNavigation.height + 12,
      child: NavigationBar(
        height: config.bottomNavigation.height + 12,
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withOpacity(0.14),
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (value) => onNavigate(items[value].action),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(iconFor(item.icon)),
                selectedIcon: Icon(iconFor(item.icon), color: palette.primary),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class AlsefaRail extends StatelessWidget {
  const AlsefaRail({
    super.key,
    required this.config,
    required this.current,
    required this.extended,
    required this.onNavigate,
  });

  final RemoteConfig config;
  final String current;
  final bool extended;
  final void Function(String) onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = config.bottomNavigation.items.where((item) => item.visible).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final index = items.indexWhere((item) => item.id == current);
    final palette = config.palette;
    return NavigationRail(
      backgroundColor: palette.surface,
      extended: extended,
      selectedIndex: index < 0 ? 0 : index,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      onDestinationSelected: (value) => onNavigate(items[value].action),
      selectedIconTheme: IconThemeData(color: palette.primary),
      selectedLabelTextStyle: TextStyle(color: palette.primary, fontSize: 11),
      unselectedLabelTextStyle: TextStyle(color: palette.muted, fontSize: 11),
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(iconFor(item.icon)),
              selectedIcon: Icon(iconFor(item.icon), color: palette.primary),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.config, required this.onAction});

  final RemoteConfig config;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    final banner = config.banner;
    final items = config.grid.items.where((item) => item.visible).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(banner.cornerRadius),
            onTap: () => onAction(banner.action),
            child: Container(
              height: banner.height,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorFromHex(banner.backgroundColor, palette.surface),
                borderRadius: BorderRadius.circular(banner.cornerRadius),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          banner.title,
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          banner.headline,
                          style: TextStyle(
                            color: palette.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner.body,
                          maxLines: 2,
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    iconFor(banner.image),
                    size: 66,
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1300
                  ? 8
                  : constraints.maxWidth >= 900
                      ? 6
                      : constraints.maxWidth >= 600
                          ? 4
                          : config.grid.columns;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns < 1 ? 1 : columns,
                  crossAxisSpacing: config.grid.spacing,
                  mainAxisSpacing: config.grid.spacing,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(config.grid.cornerRadius),
                      onTap: () => onAction(item.action),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(config.grid.cornerRadius),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconFor(item.icon), size: 32, color: palette.primary),
                            const SizedBox(height: 8),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: palette.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.config,
    required this.screen,
    required this.onAction,
  });

  final RemoteConfig config;
  final ScreenConfig screen;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final palette = config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(iconFor(screen.icon), size: 56, color: palette.primary),
          const SizedBox(height: 16),
          Text(
            screen.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            screen.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          for (final action in screen.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: action.style == 'secondary'
                    ? OutlinedButton(
                        onPressed: () => onAction(action.action),
                        child: Text(action.label),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.onPrimary,
                        ),
                        onPressed: () => onAction(action.action),
                        child: Text(action.label),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({
    super.key,
    required this.config,
    required this.repository,
    this.patient,
    required this.onSaved,
  });

  final RemoteConfig config;
  final AlsefaRepository repository;
  final Patient? patient;
  final VoidCallback onSaved;

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _bloodPressure = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _weight = TextEditingController();
  final _gender = TextEditingController();
  final _diagnosis = TextEditingController();
  final _regularFee = TextEditingController(text: '0');
  final _firstFee = TextEditingController(text: '300');
  final _initialPayment = TextEditingController(text: '0');
  final _preferredTime = TextEditingController();
  final _recordedAtController = TextEditingController();
  final _patientId = newId();
  String _recordedAt = _localTimestamp();
  Timer? _timestampTimer;

  @override
  void initState() {
    super.initState();
    _recordedAtController.text = _recordedAt;
    final patient = widget.patient;
    if (patient != null) {
      _name.text = patient.name;
      _age.text = patient.age.toString();
      _bloodPressure.text = patient.bp;
      _address.text = patient.address;
      _phone.text = patient.phone;
      _weight.text = patient.weightKg.toString();
      _gender.text = patient.gender;
      _diagnosis.text = patient.diagnosis;
      _regularFee.text = patient.regularFee.toString();
      _firstFee.text = patient.firstFee.toString();
      _initialPayment.text = patient.initialPayment.toString();
      _preferredTime.text = patient.preferredTime;
      _recordedAt = patient.createdAt;
      _recordedAtController.text = patient.createdAt;
    }
    _timestampTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _recordedAt = _localTimestamp();
        _recordedAtController.text = _recordedAt;
      });
    });
  }

  String get _patientIdentity => widget.patient?.id ?? _patientId;

  String get existingLabel =>
      widget.patient == null ? 'Save patient' : 'Update patient';

  String _localTimestamp([DateTime? value]) {
    final now = value ?? DateTime.now();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${now.year.toString().padLeft(4, '0')}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}';
  }

  @override
  void dispose() {
    _timestampTimer?.cancel();
    _recordedAtController.dispose();
    _name.dispose();
    _age.dispose();
    _bloodPressure.dispose();
    _address.dispose();
    _phone.dispose();
    _weight.dispose();
    _gender.dispose();
    _diagnosis.dispose();
    _regularFee.dispose();
    _firstFee.dispose();
    _initialPayment.dispose();
    _preferredTime.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    final palette = widget.config.palette;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.border),
    );
    final placeholder = hint != null && hint.startsWith('e.g.')
        ? '$label ($hint)'
        : hint ?? label;
    return InputDecoration(
      hintText: placeholder,
      hintStyle: TextStyle(color: palette.muted, fontSize: 13),
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      disabledBorder: border,
    );
  }

  Future<void> _uploadDocument(BuildContext context) async {
    try {
      final document = await DocumentService.pickForPatient(
        _patientIdentity,
        widget.repository,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document == null ? 'No file selected' : 'Document saved: ${document.name}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.config.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.patient == null
                  ? 'New Patient Registration'
                  : 'Edit Patient',
              style: TextStyle(
                color: palette.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please enter the patient details below.',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: _decoration('Full name', hint: 'e.g. Ahmed Khan'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: _decoration('Age', hint: 'e.g. 32'),
              validator: (value) {
                final age = int.tryParse(value?.trim() ?? '');
                if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bloodPressure,
              decoration: _decoration('Blood pressure', hint: 'e.g. 120/80 mmHg'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Blood pressure is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: _decoration('Address', hint: 'e.g. House 12, Main Street'),
              maxLines: 2,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Address is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _decoration('Phone number', hint: 'e.g. 0300 1234567'),
              validator: (value) => value == null || value.trim().length < 7
                  ? 'Enter a valid phone number'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Weight in kg', hint: 'e.g. 68.5'),
              validator: (value) {
                final weight = double.tryParse(value?.trim() ?? '');
                if (weight == null || weight <= 0) return 'Enter a valid weight';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gender,
              decoration: _decoration('Gender', hint: 'e.g. Female'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Gender is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosis,
              decoration: _decoration('Diagnosis / condition', hint: 'e.g. Frozen shoulder'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Diagnosis is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regularFee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Regular session fee', hint: 'e.g. 500'),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) return 'Enter a valid fee';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstFee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('First day fee', hint: 'Default 300'),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) return 'Enter a valid fee';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _initialPayment,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Initial payment', hint: 'e.g. 300'),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount < 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _preferredTime,
              decoration: _decoration('Preferred time', hint: 'e.g. 10:30 AM'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Preferred time is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recordedAtController,
              enabled: false,
              decoration: _decoration('Date & time (automatic)', hint: 'Auto-generated'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _uploadDocument(context),
              icon: Icon(Icons.upload_file, color: palette.primary),
              label: Text(
                'Upload prescription / report',
                style: TextStyle(color: palette.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.border),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final existing = widget.patient;
                final timestamp = nowIso();
                final patient = Patient(
                  id: _patientIdentity,
                  name: _name.text.trim(),
                  age: int.parse(_age.text.trim()),
                  gender: _gender.text.trim(),
                  bp: _bloodPressure.text.trim(),
                  address: _address.text.trim(),
                  phone: _phone.text.trim(),
                  weightKg: double.parse(_weight.text.trim()),
                  diagnosis: _diagnosis.text.trim(),
                  regularFee: double.parse(_regularFee.text.trim()),
                  firstFee: double.parse(_firstFee.text.trim()),
                  initialPayment: double.parse(_initialPayment.text.trim()),
                  preferredTime: _preferredTime.text.trim(),
                  createdAt: existing?.createdAt ?? timestamp,
                  updatedAt: timestamp,
                  syncStatus: 'pending',
                );
                try {
                  await widget.repository.savePatient(patient);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existing == null
                            ? 'Patient registered'
                            : 'Patient updated',
                      ),
                    ),
                  );
                  widget.onSaved();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $error')),
                  );
                }
              },
              child: Text(existingLabel),
            ),
          ],
        ),
      ),
    );
  }
}
