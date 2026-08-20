import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/birth_profile.dart';

/// Bottom sheet that collects a partner's birth details for the
/// Compatibility Matching feature. Returns the built [BirthProfile] via
/// `Navigator.pop`, or null if dismissed without submitting.
class PartnerInputSheet extends StatefulWidget {
  const PartnerInputSheet._({this.initial});

  final BirthProfile? initial;

  static Future<BirthProfile?> show(
    BuildContext context, {
    BirthProfile? initial,
  }) {
    return showModalBottomSheet<BirthProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PartnerInputSheet._(initial: initial),
    );
  }

  @override
  State<PartnerInputSheet> createState() => _PartnerInputSheetState();
}

class _PartnerInputSheetState extends State<PartnerInputSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final BirthProfile? initial = widget.initial;
    if (initial != null) {
      _dateOfBirth = initial.dateOfBirth;
      _dateController.text = _formatDate(initial.dateOfBirth);
      _timeController.text = initial.timeOfBirth;
      _placeController.text = initial.placeOfBirth;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ?? DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateOfBirth = picked;
      _dateController.text = _formatDate(picked);
    });
  }

  Future<void> _pickTime() async {
    final List<String> parts = _timeController.text.split(':');
    int hour = 12;
    int minute = 0;
    if (parts.length == 2) {
      hour = int.tryParse(parts[0]) ?? 12;
      minute = int.tryParse(parts[1]) ?? 0;
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null || !mounted) return;
    setState(() => _timeController.text = _formatTime(picked));
  }

  void _submit() {
    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _dateOfBirth == null) return;
    Navigator.of(context).pop(
      BirthProfile(
        zodiacSign: BirthProfile.calculateZodiacSign(_dateOfBirth!),
        dateOfBirth: _dateOfBirth!,
        timeOfBirth: _timeController.text.trim(),
        placeOfBirth: _placeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.canvasSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "Partner's birth details",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.inkSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Used only to calculate compatibility — not shared with '
                    'your partner.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (String? value) => (value ?? '').isEmpty
                        ? "Partner's date of birth is required"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
                      labelText: 'Time of birth',
                      suffixIcon: Icon(Icons.access_time_outlined),
                    ),
                    validator: (String? value) => (value ?? '').isEmpty
                        ? "Partner's time of birth is required"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _placeController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Place of birth',
                      hintText: 'City, Country',
                    ),
                    validator: (String? value) =>
                        (value?.trim() ?? '').isEmpty
                        ? "Partner's place of birth is required"
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Check compatibility'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
