import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/expense_repository.dart';
import '../../domain/expense/expense_category.dart';
import '../../domain/expense/expense_extractor.dart';
import '../../domain/expense/money.dart';
import 'spend_providers.dart';

/// Expense detail (editable) — or, with no [id], the manual "Add expense" form.
class ExpenseEditScreen extends ConsumerWidget {
  const ExpenseEditScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) return const _Editor(expense: null);
    final x = ref.watch(expenseProvider(id!));
    return switch (x) {
      AsyncData(:final value) when value != null => _Editor(key: ValueKey(value.row.id), expense: value),
      AsyncData() => Scaffold(
          appBar: AppBar(),
          body: const EmptyState(icon: Icons.search_off_rounded, title: 'Expense not found', message: 'It may have been deleted.'),
        ),
      AsyncError() => Scaffold(appBar: AppBar(), body: const ErrorState()),
      _ => Scaffold(
          appBar: AppBar(),
          body: const Padding(padding: EdgeInsets.all(Space.screen), child: ShimmerBox(height: 220, radius: Radii.md)),
        ),
    };
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.expense});
  final ExpenseView? expense;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _amount;
  late final TextEditingController _payee;
  late final TextEditingController _note;
  late String _currency;
  late ExpenseCategory _category;
  late DateTime _date;
  late ExpenseType _type;
  bool _saving = false;

  ExpenseView? get _x => widget.expense;
  bool get _isNew => _x == null;

  @override
  void initState() {
    super.initState();
    final r = _x?.row;
    _amount = TextEditingController(text: r == null ? '' : formatMinorNumber(r.amountMinor).replaceAll(',', ''));
    _payee = TextEditingController(text: r?.payee ?? '');
    _note = TextEditingController(text: r?.note ?? '');
    _currency = r?.currency ?? ref.read(settingsProvider).defaultCurrency;
    _category = _x?.category ?? ExpenseCategory.other;
    _date = r?.date ?? DateTime.now();
    _type = _x?.type ?? ExpenseType.expense;
  }

  @override
  void dispose() {
    _amount.dispose();
    _payee.dispose();
    _note.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    final minor = parseUserAmount(_amount.text);
    if (minor == null) {
      Haptics.selection();
      _toast('Enter an amount');
      return;
    }
    setState(() => _saving = true);
    final service = ref.read(expenseServiceProvider);
    try {
      if (_isNew) {
        await service.addManual(
          amountMinor: minor,
          currencyCode: _currency,
          payee: _payee.text,
          category: _category,
          date: _date,
          note: _note.text.trim(),
          type: _type,
        );
      } else {
        await service.save(
          _x!,
          type: _type,
          amountMinor: minor,
          currencyCode: _currency,
          payee: _payee.text,
          category: _category,
          date: _date,
          note: _note.text.trim(),
        );
      }
      Haptics.medium();
      if (mounted) {
        _toast(_isNew ? 'Added to Spend' : 'Saved');
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
  }

  Future<void> _pickCurrency() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in supportedCurrencies)
                FilterPill(label: '${currencySymbols[c]} · $c', selected: c == _currency, onTap: () => Navigator.pop(context, c)),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _currency = picked);
  }

  Future<void> _toggleExcluded() async {
    final x = _x!;
    await ref.read(expenseServiceProvider).setExcluded(x.row.id, !x.row.isExcluded);
    Haptics.medium();
    if (mounted) {
      _toast(x.row.isExcluded ? 'Counted as spend again' : 'Marked as not an expense');
      if (!x.row.isExcluded) context.pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(expenseServiceProvider).delete(_x!.row.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final x = _x;
    final assetId = x?.row.assetId;
    final symbol = currencySymbols[_currency] ?? _currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add expense' : (x!.type == ExpenseType.income ? 'Income' : 'Expense')),
        actions: [
          if (x != null && x.row.source == 'manual')
            IconButton(tooltip: 'Delete', onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, MediaQuery.paddingOf(context).bottom + Space.xl),
        children: [
          if (assetId != null) ...[
            Pressable(
              semanticLabel: 'View screenshot',
              onTap: () => context.push(Routes.detail(assetId)),
              child: Container(
                height: 180,
                decoration: BoxDecoration(borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetThumb(assetId, radius: Radii.md, size: 600, fit: BoxFit.cover),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(99)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text('View screenshot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          if (x != null && x.needsReview) ...[
            _Notice(
              icon: Icons.fact_check_outlined,
              text: x.isDuplicate
                  ? 'This looks like a repeat of another payment, so it isn\'t counted yet. Save to count it.'
                  : 'We weren\'t fully sure about this one. Check the details and save.',
            ),
            const SizedBox(height: Space.md),
          ],
          SegmentedButton<ExpenseType>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Brand.violet.withValues(alpha: 0.2),
              selectedForegroundColor: context.isDark ? Colors.white : Brand.violet,
              side: BorderSide(color: c.border),
              minimumSize: const Size(0, 44),
            ),
            segments: const [
              ButtonSegment(value: ExpenseType.expense, label: Text('Expense')),
              ButtonSegment(value: ExpenseType.income, label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (s) {
              Haptics.selection();
              setState(() => _type = s.first);
            },
          ),
          const SizedBox(height: Space.md),
          // Amount: big, with a tappable currency.
          Container(
            padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.md, Space.xs),
            decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
            child: Row(
              children: [
                TextButton(
                  onPressed: _pickCurrency,
                  style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(symbol, style: context.text.titleLarge?.copyWith(color: Brand.violet)),
                      const Icon(Icons.expand_more_rounded, size: 18, color: Brand.violet),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: _isNew,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    style: context.text.headlineMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    decoration: const InputDecoration(hintText: '0', border: InputBorder.none, filled: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          _Field(
            label: _type == ExpenseType.income ? 'From' : 'Paid to',
            child: TextField(
              controller: _payee,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Payee or merchant'),
            ),
          ),
          _Field(
            label: 'Category',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in ExpenseCategory.values)
                  FilterPill(
                    label: cat.label,
                    icon: SpendStyle.icon(cat),
                    accent: SpendStyle.color(cat),
                    selected: cat == _category,
                    onTap: () => setState(() => _category = cat),
                  ),
              ],
            ),
          ),
          if (x?.row.payeeKey != null && _category != x!.category)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Text('Future receipts from ${x.row.payee} will use ${_category.label}.', style: context.text.bodySmall),
            ),
          _Field(
            label: 'Date',
            child: Pressable(
              onTap: _pickDate,
              scale: 0.98,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                decoration: BoxDecoration(color: c.surface, borderRadius: Radii.smAll, border: Border.all(color: c.border)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: c.textSecondary),
                    const SizedBox(width: Space.sm),
                    Text(DateFormat('EEE, d MMM yyyy').format(_date), style: context.text.bodyLarge),
                  ],
                ),
              ),
            ),
          ),
          _Field(
            label: 'Note',
            child: TextField(controller: _note, maxLines: 3, minLines: 1, decoration: const InputDecoration(hintText: 'Optional')),
          ),
          if (x?.row.transactionId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Row(
                children: [
                  Icon(Icons.tag_rounded, size: 16, color: c.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(child: SelectableText('Transaction ${x!.row.transactionId}', style: context.text.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: Space.xs),
          GradientButton(label: _isNew ? 'Add to Spend' : 'Save', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
          if (x != null) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: x.row.isExcluded ? 'Count as expense' : 'Not an expense',
                    icon: x.row.isExcluded ? Icons.undo_rounded : Icons.remove_circle_outline_rounded,
                    color: x.row.isExcluded ? c.success : c.danger,
                    expand: true,
                    onPressed: _toggleExcluded,
                  ),
                ),
                if (assetId != null) ...[
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: SoftButton(
                      label: 'View screenshot',
                      icon: Icons.image_outlined,
                      expand: true,
                      onPressed: () => context.push(Routes.detail(assetId)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label.toUpperCase(), style: context.text.labelSmall?.copyWith(letterSpacing: 1.1, color: context.colors.textTertiary)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFE8A951);
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(color: amber.withValues(alpha: 0.12), borderRadius: Radii.smAll, border: Border.all(color: amber.withValues(alpha: 0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: amber),
          const SizedBox(width: Space.xs),
          Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.textPrimary))),
        ],
      ),
    );
  }
}
