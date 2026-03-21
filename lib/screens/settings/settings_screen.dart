import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/branding_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BrandingPreferences _prefs = BrandingPreferences();
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
      if (mounted) {
        setState(() {
          _prefs = prefs ?? BrandingPreferences();
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

  void _resetDefaults() {
    setState(() {
      _prefs = BrandingPreferences();
      _clinicNameCtrl.text = _prefs.clinicName;
    });
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

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
          TextButton.icon(
            onPressed: _saving ? null : _resetDefaults,
            icon: Icon(Icons.restart_alt, color: colorScheme.onPrimary),
            label: Text(loc.resetDefaults,
                style: TextStyle(color: colorScheme.onPrimary)),
          ),
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

                // ── Live preview ─────────────────────────────────────────────
                _sectionHeader(context, Icons.preview, loc.colorPreview),
                const SizedBox(height: 8),
                _PreviewCard(prefs: _prefs, clinicName: _clinicNameCtrl.text),
                const SizedBox(height: 24),

                // ── Theme colors ─────────────────────────────────────────────
                _sectionHeader(context, Icons.palette, loc.themeColors),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _colorRow(
                          context,
                          label: loc.primaryColor,
                          subtitle: 'AppBar, botões principais',
                          currentHex: _prefs.primaryColor,
                          onSelected: (c) => setState(
                              () => _prefs.primaryColor = _colorToHex(c)),
                        ),
                        const Divider(height: 32),
                        _colorRow(
                          context,
                          label: loc.secondaryColor,
                          subtitle: 'Chips, destaques secundários',
                          currentHex: _prefs.secondaryColor,
                          onSelected: (c) => setState(
                              () => _prefs.secondaryColor = _colorToHex(c)),
                        ),
                        const Divider(height: 32),
                        _colorRow(
                          context,
                          label: loc.accentColor,
                          subtitle: 'FAB, badges, avisos',
                          currentHex: _prefs.accentColor,
                          onSelected: (c) => setState(
                              () => _prefs.accentColor = _colorToHex(c)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Dark mode ─────────────────────────────────────────────
                Card(
                  child: SwitchListTile(
                    secondary: Icon(
                      _prefs.darkMode ? Icons.dark_mode : Icons.light_mode,
                      color: colorScheme.primary,
                    ),
                    title: Text(loc.darkMode),
                    value: _prefs.darkMode,
                    onChanged: (v) => setState(() => _prefs.darkMode = v),
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
              ],
            ),
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

  Widget _colorRow(
    BuildContext context, {
    required String label,
    required String subtitle,
    required String currentHex,
    required void Function(Color) onSelected,
  }) {
    final current = _hexToColor(currentHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
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
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          )),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _palette.map((color) {
            final isSelected = color.toARGB32() == current.toARGB32();
            return GestureDetector(
              onTap: () => onSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isSelected ? 36 : 32,
                height: isSelected ? 36 : 32,
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
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
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
