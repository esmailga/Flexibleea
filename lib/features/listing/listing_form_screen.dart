import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators.dart';
import '../../models/expertise_listing.dart';
import '../../services/expertise_repository.dart';
import '../../services/session.dart';
import '../../services/storage_service.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/riyal.dart';

/// Create a new listing, or edit [existing].
class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key, this.existing});

  final ExpertiseListing? existing;

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  static const _maxPdfBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _rate = TextEditingController(
    text: widget.existing?.hourlyRate == null
        ? ''
        : _trimRate(widget.existing!.hourlyRate!),
  );

  late String? _category = _initialCategory();
  late DateTimeRange? _dates = _initialDates();
  late TimeOfDay? _start = widget.existing?.startTime;
  late TimeOfDay? _end = widget.existing?.endTime;
  late String _qualificationUrl = widget.existing?.qualificationUrl ?? '';
  File? _pdf;
  String? _pdfName;
  bool _saving = false;
  bool _submitted = false;

  bool get _isEditing => widget.existing != null;

  static String _trimRate(double rate) =>
      rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toString();

  String? _initialCategory() {
    final c = widget.existing?.category;
    return kCategories.any((k) => k.name == c) ? c : null;
  }

  DateTimeRange? _initialDates() {
    final e = widget.existing;
    if (e?.availableFrom == null || e?.availableTo == null) return null;
    return DateTimeRange(start: e!.availableFrom!, end: e.availableTo!);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = _dates != null && _dates!.start.isBefore(today) ? _dates!.start : today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today.add(const Duration(days: 730)),
      initialDateRange: _dates,
      helpText: 'When are you available?',
    );
    if (picked != null) setState(() => _dates = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final initial = (start ? _start : _end) ??
        TimeOfDay(hour: start ? 9 : 17, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: start ? 'Start time' : 'End time',
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final file = result?.files.singleOrNull;
      if (file == null || file.path == null) return;
      if (file.size > _maxPdfBytes) {
        if (mounted) showMessage(context, 'PDF must be smaller than 10 MB.', isError: true);
        return;
      }
      setState(() {
        _pdf = File(file.path!);
        _pdfName = file.name;
      });
    } catch (e) {
      if (mounted) showMessage(context, 'Could not open the file picker.', isError: true);
    }
  }

  void _removePdf() => setState(() {
        _pdf = null;
        _pdfName = null;
        _qualificationUrl = '';
      });

  String? get _datesError =>
      _submitted && _dates == null ? 'Choose the dates you are available' : null;

  String? get _timeError {
    if (!_submitted) return null;
    if (_start == null || _end == null) return 'Choose your start and end time';
    final startMinutes = _start!.hour * 60 + _start!.minute;
    final endMinutes = _end!.hour * 60 + _end!.minute;
    if (endMinutes <= startMinutes) return 'End time must be after start time';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || _datesError != null || _timeError != null) return;

    final session = context.read<Session>();
    final repo = context.read<ExpertiseRepository>();
    final storage = context.read<StorageService>();
    final navigator = Navigator.of(context);
    final owner = session.profile;
    if (owner == null) {
      showMessage(context, 'Complete your profile before publishing.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final id = widget.existing?.id ?? repo.newId();
      var qualificationUrl = _qualificationUrl;
      if (_pdf != null) {
        qualificationUrl = await storage.uploadQualification(owner.id, id, _pdf!);
      } else if (qualificationUrl.isEmpty && (widget.existing?.hasQualification ?? false)) {
        await storage.deleteQualification(owner.id, id);
      }

      final draft = ListingDraft(
        category: _category!,
        title: _title.text,
        description: _description.text,
        availableFrom: _dates!.start,
        availableTo: _dates!.end,
        startTime: _start!,
        endTime: _end!,
        hourlyRate: double.parse(_rate.text.trim()),
        qualificationUrl: qualificationUrl,
      );

      if (_isEditing) {
        await repo.update(id, draft);
      } else {
        await repo.create(id: id, owner: owner, draft: draft);
      }
      if (mounted) {
        showMessage(context, _isEditing ? 'Listing updated' : 'Your expertise is live!');
      }
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPdf = _pdf != null || _qualificationUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit listing' : 'Offer your expertise'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _StepHeader(number: 1, title: 'What do you offer?'),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                validator: (v) => v == null ? 'Choose a category' : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in kCategories)
                    DropdownMenuItem(
                      value: c.name,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.minLength(v, 3, 'title'),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Flutter app development',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                maxLength: 1000,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.minLength(v, 20, 'description'),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Your experience, tools you use and what clients can expect.',
                  alignLabelWithHint: true,
                ),
              ),
              _StepHeader(number: 2, title: 'When are you available?'),
              _PickerTile(
                icon: Icons.date_range_rounded,
                color: AppColors.teal,
                label: 'Dates',
                value: _dates == null ? null : formatDateRange(_dates!.start, _dates!.end),
                placeholder: 'Choose a date range',
                error: _datesError,
                onTap: _pickDates,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.wb_sunny_outlined,
                      color: AppColors.amber,
                      label: 'From',
                      value: _start?.format(context),
                      placeholder: 'Start',
                      onTap: () => _pickTime(start: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.nights_stay_outlined,
                      color: AppColors.brand,
                      label: 'To',
                      value: _end?.format(context),
                      placeholder: 'End',
                      onTap: () => _pickTime(start: false),
                    ),
                  ),
                ],
              ),
              _InlineError(message: _timeError),
              _StepHeader(number: 3, title: 'Your terms'),
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: Validators.hourlyRate,
                decoration: InputDecoration(
                  labelText: 'Hourly rate',
                  prefix: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: RiyalSymbol(height: 13),
                  ),
                  suffixText: '/ hour',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: hasPdf
                    ? Card(
                        key: const ValueKey('pdf'),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                          title: Text(_pdfName ?? 'Qualification attached',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: const Text('Shown on your listing'),
                          trailing: IconButton(
                            tooltip: 'Remove PDF',
                            onPressed: _removePdf,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        key: const ValueKey('add-pdf'),
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text('Attach qualification (PDF, optional)'),
                      ),
              ),
              const SizedBox(height: 28),
              LoadingButton(
                label: _isEditing ? 'Save changes' : 'Publish listing',
                icon: _isEditing ? Icons.check_rounded : Icons.rocket_launch_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ].animate(interval: 30.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: number == 1 ? 8 : 24, bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.error,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: theme.inputDecorationTheme.fillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(
              color: hasError ? scheme.error : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.labelMedium),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            value ?? placeholder,
                            key: ValueKey(value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: value == null ? FontWeight.w400 : FontWeight.w700,
                              color: value == null ? scheme.onSurfaceVariant : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _InlineError(message: error),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Text(
                message!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
    );
  }
}
