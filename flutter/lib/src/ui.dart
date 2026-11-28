import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
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
  PatientStore? _patientStore;
  RemoteConfig? _config;
  String _screen = 'home';
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
    final preferences = await SharedPreferences.getInstance();
    _service = RemoteConfigService(preferences);
    _patientStore = PatientStore(preferences);
    await _load(forceRefresh: true);
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
    if (_loading || config == null) {
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

  Widget _buildScreen(RemoteConfig config) {
    final palette = config.palette;
    if (_screen == 'home') {
      return HomeView(config: config, onAction: _handleAction);
    }
    if (_screen == 'patient_registration') {
      return PatientRegistrationScreen(
        palette: palette,
        store: _patientStore!,
        onSaved: () => _handleAction('patients'),
      );
    }
    if (_screen == 'patients') {
      return PatientsScreen(
        palette: palette,
        store: _patientStore!,
        onRegister: () => _handleAction('patient_registration'),
      );
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
    required this.palette,
    required this.store,
    required this.onSaved,
  });

  final Palette palette;
  final PatientStore store;
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
  final _recordedAtController = TextEditingController();
  String _recordedAt = PatientStore.timestamp();
  Timer? _timestampTimer;

  @override
  void initState() {
    super.initState();
    _recordedAtController.text = _recordedAt;
    _timestampTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _recordedAt = PatientStore.timestamp();
        _recordedAtController.text = _recordedAt;
      });
    });
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
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    final palette = widget.palette;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.border),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      disabledBorder: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New Patient Registration',
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
              controller: _recordedAtController,
              enabled: false,
              decoration: _decoration('Date & time (automatic)', hint: 'Auto-generated'),
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
                await widget.store.add(
                  Patient(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: _name.text.trim(),
                    age: int.parse(_age.text.trim()),
                    bloodPressure: _bloodPressure.text.trim(),
                    address: _address.text.trim(),
                    phone: _phone.text.trim(),
                    weightKg: double.parse(_weight.text.trim()),
                    recordedAt: _recordedAt,
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient registered')),
                );
                widget.onSaved();
              },
              child: const Text('Save patient'),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({
    super.key,
    required this.palette,
    required this.store,
    required this.onRegister,
  });

  final Palette palette;
  final PatientStore store;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final patients = store.all();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registered Patients',
            style: TextStyle(
              color: palette.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (patients.isEmpty)
            Text(
              'No patients registered yet. Add the first patient to see them here.',
              style: TextStyle(color: palette.muted, fontSize: 13),
            )
          else
            for (final patient in patients)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  '${patient.name}  •  ${patient.age} yrs\n'
                  'BP: ${patient.bloodPressure}  •  Weight: ${patient.weightKg} kg\n'
                  'Phone: ${patient.phone}\n'
                  'Address: ${patient.address}\n'
                  'Recorded: ${patient.recordedAt}',
                  style: TextStyle(color: palette.onSurface, fontSize: 12),
                ),
              ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onRegister,
            child: const Text('Register new patient'),
          ),
        ],
      ),
    );
  }
}
