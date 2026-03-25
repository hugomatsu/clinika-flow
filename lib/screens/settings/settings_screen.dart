import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../app_info.dart';
import '../../models/branding_preferences.dart';
import '../../models/session_template.dart';
import '../../models/subscription.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/image_service.dart';
import '../../services/quota_service.dart';
import '../../services/theme_service.dart';
import '../subscription/upgrade_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BrandingPreferences _prefs = BrandingPreferences();
  List<SessionTemplate> _templates = [];
  Subscription _subscription = Subscription();
  bool _loading = true;
  bool _saving = false;
  late TextEditingController _clinicNameCtrl;
  late TextEditingController _displayNameCtrl;

  // Curated palette — professional clinical tones
  static const _palette = [
    // Blues
    Color(0xFF1565C0),
    Color(0xFF2962FF),
    Color(0xFF1E88E5),
    Color(0xFF0288D1),
    // Teals / Greens
    Color(0xFF26A69A),
    Color(0xFF00838F),
    Color(0xFF00897B),
    Color(0xFF2E7D32),
    Color(0xFF558B2F),
    // Purples / Pinks
    Color(0xFF6A1B9A),
    Color(0xFF8E24AA),
    Color(0xFFAD1457),
    Color(0xFFD81B60),
    // Warm
    Color(0xFFFFCA28),
    Color(0xFFC62828),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    // Neutrals
    Color(0xFF37474F),
    Color(0xFF546E7A),
    Color(0xFF4E342E),
    Color(0xFF263238),
    Color(0xFF455A64),
  ];

  @override
  void initState() {
    super.initState();
    _clinicNameCtrl = TextEditingController();
    _displayNameCtrl = TextEditingController(
        text: AuthService.currentUser?.displayName ?? '');
    _load();
  }

  @override
  void dispose() {
    _clinicNameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await FirestoreService.getBranding();
      final templates = await FirestoreService.getAllTemplates();
      final sub = await QuotaService.getSubscription();
      if (mounted) {
        setState(() {
          _prefs = prefs ?? BrandingPreferences();
          _templates = templates;
          _subscription = sub;
          _clinicNameCtrl.text = _prefs.clinicName;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _clinicNameCtrl.text = _prefs.clinicName;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    _prefs.clinicName = _clinicNameCtrl.text.trim().isEmpty
        ? 'Kelyn Physio'
        : _clinicNameCtrl.text.trim();
    await ThemeService.saveAndApply(_prefs);
    if (mounted) {
      setState(() => _saving = false);
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.colorSaved)));
    }
  }

  Future<void> _logout(BuildContext context, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.logoutConfirmTitle),
        content: Text(loc.logoutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.signOut();
    }
  }

  Future<void> _saveProfile() async {
    try {
      await AuthService.updateDisplayName(_displayNameCtrl.text);
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.profileSaved)));
      }
    } catch (_) {
      // silently fail if offline
    }
  }

  Future<void> _showChangePasswordDialog(AppLocalizations loc) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(loc.changePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.currentPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.newPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.confirmNewPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  setDialogState(() => error = loc.passwordMismatch);
                  return;
                }
                if (newCtrl.text.length < 6) {
                  setDialogState(() => error = loc.passwordMinLength);
                  return;
                }
                try {
                  await AuthService.updatePassword(
                      currentCtrl.text, newCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.passwordChanged)));
                  }
                } catch (_) {
                  setDialogState(() => error = loc.wrongPassword);
                }
              },
              child: Text(loc.confirm),
            ),
          ],
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    final url = await ImageService.pickAndUploadLogo(source: source);
    if (url != null && mounted) {
      setState(() => _prefs.logoUrl = url);
    }
  }

  void _showLogoSourceSheet(AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.camera),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.gallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.gallery);
              },
            ),
            if (_prefs.logoUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(loc.removeLogo,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _prefs.logoUrl = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _resetDefaults() {
    setState(() {
      _prefs = BrandingPreferences();
      _clinicNameCtrl.text = _prefs.clinicName;
    });
  }

  Future<void> _confirmResetDefaults(AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.resetDefaults),
        content: Text(loc.resetDefaultsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) _resetDefaults();
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: loc.save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Subscription ──────────────────────────────────────────
                _sectionHeader(context, Icons.workspace_premium, loc.subscription),
                const SizedBox(height: 8),
                _buildSubscriptionCard(loc, colorScheme),
                const SizedBox(height: 24),

                // ── Clinic name ─────────────────────────────────────────────
                _sectionHeader(context, Icons.business, loc.clinicName),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _clinicNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: loc.clinicName,
                        prefixIcon: const Icon(Icons.local_hospital_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Clinic logo ──────────────────────────────────────────────
                _sectionHeader(context, Icons.image_outlined, loc.clinicLogo),
                const SizedBox(height: 8),
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showLogoSourceSheet(loc),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _prefs.logoUrl.isEmpty
                          ? Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.add_photo_alternate,
                                      size: 32,
                                      color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(loc.tapToAddLogo,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant)),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _prefs.logoUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 64,
                                      height: 64,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(loc.clinicLogo,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: colorScheme.primary),
                                  onPressed: () =>
                                      _showLogoSourceSheet(loc),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Default models ───────────────────────────────────────────
                _sectionHeader(
                    context, Icons.description_outlined, loc.templates),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _prefs.defaultSessionTemplateId.isEmpty
                              ? null
                              : _prefs.defaultSessionTemplateId,
                          decoration: InputDecoration(
                            labelText: loc.defaultSessionModel,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(loc.none),
                            ),
                            ..._templates.map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name),
                                )),
                          ],
                          onChanged: (v) => setState(
                              () => _prefs.defaultSessionTemplateId = v ?? ''),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _prefs.defaultAnamnesisTemplateId.isEmpty
                              ? null
                              : _prefs.defaultAnamnesisTemplateId,
                          decoration: InputDecoration(
                            labelText: loc.defaultAnamnesisModel,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(loc.none),
                            ),
                            ..._templates.map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name),
                                )),
                          ],
                          onChanged: (v) => setState(() =>
                              _prefs.defaultAnamnesisTemplateId = v ?? ''),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Live preview ─────────────────────────────────────────────
                _sectionHeader(context, Icons.preview, loc.colorPreview),
                const SizedBox(height: 8),
                _PreviewCard(prefs: _prefs, clinicName: _clinicNameCtrl.text),
                const SizedBox(height: 24),

                // ── Theme colors ─────────────────────────────────────────────
                _sectionHeader(context, Icons.palette, loc.themeColors),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _colorTile(
                        context,
                        label: loc.primaryColor,
                        currentHex: _prefs.primaryColor,
                        onChanged: (hex) =>
                            setState(() => _prefs.primaryColor = hex),
                      ),
                      const Divider(height: 1),
                      _colorTile(
                        context,
                        label: loc.secondaryColor,
                        currentHex: _prefs.secondaryColor,
                        onChanged: (hex) =>
                            setState(() => _prefs.secondaryColor = hex),
                      ),
                      const Divider(height: 1),
                      _colorTile(
                        context,
                        label: loc.accentColor,
                        currentHex: _prefs.accentColor,
                        onChanged: (hex) =>
                            setState(() => _prefs.accentColor = hex),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(loc.save),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _confirmResetDefaults(loc),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(loc.resetDefaults),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Profile ──────────────────────────────────────────────────
                _sectionHeader(context, Icons.person, loc.profile),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _displayNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: loc.displayName,
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: AuthService.currentUser?.email ?? ''),
                          decoration: InputDecoration(
                            labelText: loc.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(loc.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline,
                        color: colorScheme.primary),
                    title: Text(loc.changePassword),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(loc),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Account ──────────────────────────────────────────────────
                _sectionHeader(context, Icons.manage_accounts, loc.account),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(
                      loc.logout,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () => _logout(context, loc),
                  ),
                ),
                const SizedBox(height: 32),

                // ── About ─────────────────────────────────────────────────
                _sectionHeader(context, Icons.info_outline, loc.about),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aboutRow(loc.appVersion, '$kAppVersion ($kBuildNumber)'),
                        const SizedBox(height: 8),
                        _aboutRow(loc.buildDate, kBuildDate),
                        const SizedBox(height: 8),
                        _aboutRow(loc.developedBy, 'Hugo Matsumoto'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(AppLocalizations loc, ColorScheme colorScheme) {
    final tier = _subscription.tier;
    final limits = _subscription.limits;
    final Color tierColor;
    final String tierName;
    switch (tier) {
      case SubscriptionTier.free:
        tierColor = Colors.grey.shade600;
        tierName = loc.freeTier;
      case SubscriptionTier.essential:
        tierColor = Colors.blue.shade700;
        tierName = loc.essentialTier;
      case SubscriptionTier.professional:
        tierColor = Colors.purple.shade700;
        tierName = loc.professionalTier;
      case SubscriptionTier.clinic:
        tierColor = Colors.teal.shade700;
        tierName = loc.clinicTier;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tierName,
                    style: TextStyle(
                      color: tierColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await UpgradeScreen.show(context);
                    _load();
                  },
                  icon: const Icon(Icons.rocket_launch, size: 16),
                  label: Text(loc.upgradePlan),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Usage bars
            _usageRow(
              loc.patientsLimit,
              _subscription.patientCount,
              limits.maxPatients,
              loc,
            ),
            const SizedBox(height: 6),
            _usageRow(
              loc.sessionsMonthLimit,
              _subscription.monthlySessionCount,
              limits.maxSessionsPerMonth,
              loc,
            ),
            const SizedBox(height: 6),
            _usageRow(
              loc.templatesLimit,
              _templates.length,
              limits.maxTemplates,
              loc,
            ),
            const SizedBox(height: 6),
            _usageRow(
              loc.anamnesisMonthLimit,
              _subscription.monthlyAnamnesisCount,
              limits.maxAnamnesisPerMonth,
              loc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageRow(String label, int current, int limit, AppLocalizations loc) {
    final isUnlimited = limit == 0;
    final ratio = isUnlimited ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final isNear = !isUnlimited && ratio >= 0.8;

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: isUnlimited
              ? Text(
                  loc.unlimitedLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.grey.shade200,
                    color: isNear ? Colors.orange : Colors.blue,
                    minHeight: 8,
                  ),
                ),
        ),
        if (!isUnlimited) ...[
          const SizedBox(width: 8),
          Text(
            loc.usageOf(current, limit),
            style: TextStyle(
              fontSize: 11,
              color: isNear ? Colors.orange.shade800 : Colors.grey.shade600,
              fontWeight: isNear ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }

  Widget _colorTile(
    BuildContext context, {
    required String label,
    required String currentHex,
    required void Function(String) onChanged,
  }) {
    final current = _hexToColor(currentHex);

    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: current,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: current.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      title: Text(label),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: current.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          currentHex.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: current,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _showColorPickerDialog(context, currentHex, onChanged),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    String currentHex,
    void Function(String) onChanged,
  ) {
    final hexCtrl = TextEditingController(
        text: currentHex.replaceFirst('#', '').toUpperCase());
    String selectedHex = currentHex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selected = _hexToColor(selectedHex);

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(selectedHex.toUpperCase()),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Palette grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palette.map((color) {
                      final hex =
                          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      final isSelected =
                          hex.toUpperCase() == selectedHex.toUpperCase();
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedHex = hex;
                            hexCtrl.text =
                                hex.replaceFirst('#', '').toUpperCase();
                          });
                        },
                        child: Container(
                          width: isSelected ? 38 : 34,
                          height: isSelected ? 38 : 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Custom hex input
                  TextField(
                    controller: hexCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      prefixText: '#',
                      labelText: 'Hex',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          final raw = hexCtrl.text
                              .replaceFirst('#', '')
                              .toUpperCase();
                          if (raw.length == 6 &&
                              RegExp(r'^[0-9A-F]{6}$').hasMatch(raw)) {
                            setDialogState(() => selectedHex = '#$raw');
                          }
                        },
                      ),
                    ),
                    maxLength: 6,
                    onChanged: (val) {
                      final raw =
                          val.replaceFirst('#', '').toUpperCase();
                      if (raw.length == 6 &&
                          RegExp(r'^[0-9A-F]{6}$').hasMatch(raw)) {
                        setDialogState(() => selectedHex = '#$raw');
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(ctx)!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  onChanged(selectedHex);
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(ctx)!.confirm),
              ),
            ],
          );
        },
      ),
    );

    // Dispose controller when dialog closes — the builder keeps it alive
    // until the dialog is popped, so no explicit dispose needed here.
  }
}

/// Live preview card that updates as the user picks colors.
class _PreviewCard extends StatelessWidget {
  final BrandingPreferences prefs;
  final String clinicName;

  const _PreviewCard({required this.prefs, required this.clinicName});

  Color _hex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final primary = _hex(prefs.primaryColor);
    final secondary = _hex(prefs.secondaryColor);
    final accent = _hex(prefs.accentColor);
    final isDark = prefs.darkMode;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final surface = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final onBg =
        isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fake AppBar
          Container(
            color: primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  clinicName.isEmpty ? 'Kelyn Physio' : clinicName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Fake content
          Container(
            color: bg,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primary,
                        radius: 18,
                        child: const Text('K',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kelyn Costa',
                              style: TextStyle(
                                  color: onBg,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text('Fisioterapia',
                              style: TextStyle(
                                  color: onBg.withValues(alpha: 0.55),
                                  fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Ativo',
                            style: TextStyle(
                                color: secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Chips
                Wrap(
                  spacing: 6,
                  children: ['Ventosa', 'Lombar', 'TENS'].map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Nova Consulta',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
