import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/session_template.dart';
import '../../services/firestore_service.dart';
import 'template_builder_screen.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  List<SessionTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final templates = await FirestoreService.getAllTemplates();
      if (mounted) setState(() { _templates = templates; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TemplateBuilderScreen()),
    );
    _load();
  }

  Future<void> _edit(SessionTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateBuilderScreen(template: template),
      ),
    );
    _load();
  }

  Future<void> _duplicate(SessionTemplate source) async {
    final loc = AppLocalizations.of(context)!;
    final copy = SessionTemplate(
      name: '${source.name} (2)',
      description: source.description,
      fields: source.fields.map((f) => f.copyWith()).toList(),
    );
    await FirestoreService.createTemplate(copy);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.templateSaved)));
    }
    _load();
  }

  Future<void> _setDefault(SessionTemplate template) async {
    // Un-default all others
    for (final t in _templates) {
      if (t.isDefault && t.id != template.id) {
        t.isDefault = false;
        await FirestoreService.updateTemplate(t);
      }
    }
    template.isDefault = true;
    await FirestoreService.updateTemplate(template);
    _load();
  }

  Future<void> _delete(SessionTemplate template) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deleteTemplateConfirm),
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
    if (confirmed == true) {
      await FirestoreService.deleteTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.templateDeleted)));
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.templates),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Text(
                    loc.noTemplates,
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final t = _templates[i];
                      return _templateCard(t, loc, colorScheme);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_templates',
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(loc.newTemplate),
      ),
    );
  }

  Widget _templateCard(
      SessionTemplate t, AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.description_outlined,
              color: colorScheme.onPrimaryContainer),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(t.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (t.isDefault)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  loc.defaultTemplate,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary),
                ),
              ),
            if (t.isBuiltIn)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  loc.builtIn,
                  style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSecondaryContainer),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${loc.versionLabel(t.currentVersion)} · ${loc.fieldCount(t.fields.length)}',
          style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'edit':
                _edit(t);
              case 'duplicate':
                _duplicate(t);
              case 'default':
                _setDefault(t);
              case 'delete':
                _delete(t);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(loc.edit)),
            PopupMenuItem(value: 'duplicate', child: Text(loc.duplicate)),
            if (!t.isDefault)
              PopupMenuItem(
                  value: 'default', child: Text(loc.setAsDefault)),
            if (!t.isBuiltIn)
              PopupMenuItem(value: 'delete', child: Text(loc.delete)),
          ],
        ),
        onTap: () => _edit(t),
      ),
    );
  }
}
