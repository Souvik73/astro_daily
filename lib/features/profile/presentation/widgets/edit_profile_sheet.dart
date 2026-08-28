import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/birth_profile.dart';
import '../../domain/entities/profile_data.dart';
import '../cubit/profile_cubit.dart';

/// Bottom sheet for editing the user's profile — name, date/time/place of
/// birth. Name changes save immediately; birth-detail changes trigger a
/// server-side chart recalculation that is rate-limited to once every 24
/// hours. When locked, the date/time/place fields are disabled here as a
/// courtesy — `compute-chart` remains the actual authority and rejects the
/// request regardless of what the client shows.
///
/// Returns `true` via [show] if birth details were changed and saved, so
/// the caller can show the 24-hour-cooldown reminder as a snackbar using
/// its own (stable) context rather than this sheet's about-to-be-disposed
/// one.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet._({required this.profile});

  final ProfileData profile;

  static Future<bool> show(
    BuildContext context, {
    required ProfileData profile,
  }) async {
    final ProfileCubit cubit = context.read<ProfileCubit>();
    final bool? birthDetailsChanged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<ProfileCubit>.value(
        value: cubit,
        child: EditProfileSheet._(profile: profile),
      ),
    );
    return birthDetailsChanged ?? false;
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile.displayName,
  );
  late final TextEditingController _dateController = TextEditingController(
    text: _formatDate(widget.profile.dateOfBirth),
  );
  late final TextEditingController _timeController = TextEditingController(
    text: widget.profile.timeOfBirth,
  );
  late final TextEditingController _placeController = TextEditingController(
    text: widget.profile.placeOfBirth,
  );
  late DateTime _dateOfBirth = widget.profile.dateOfBirth;

  bool _isSaving = false;
  String? _error;

  bool get _isBirthLocked => widget.profile.isBirthDetailsLocked;

  @override
  void dispose() {
    _nameController.dispose();
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

  String _formatUnlockTime(DateTime dt) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime local = dt.toLocal();
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String period = local.hour >= 12 ? 'PM' : 'AM';
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $hour12:$minute $period';
  }

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
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

  Future<void> _save() async {
    final String newName = _nameController.text.trim();
    final String newTime = _timeController.text.trim();
    final String newPlace = _placeController.text.trim();

    if (newName.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    if (newTime.isEmpty || newPlace.isEmpty) {
      setState(() => _error = 'Time and place of birth are required');
      return;
    }

    final bool nameChanged = newName != widget.profile.displayName;
    final bool birthChanged =
        !_isBirthLocked &&
        (_dateOfBirth != widget.profile.dateOfBirth ||
            newTime != widget.profile.timeOfBirth ||
            newPlace != widget.profile.placeOfBirth);

    if (!nameChanged && !birthChanged) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final ProfileCubit cubit = context.read<ProfileCubit>();
    String? errorMessage;
    bool birthSaved = false;

    if (nameChanged) {
      try {
        await cubit.updateDisplayName(newName);
      } catch (_) {
        errorMessage = 'Could not save your name. Please try again.';
      }
    }

    if (birthChanged && errorMessage == null) {
      try {
        await cubit.updateBirthProfile(
          BirthProfile(
            zodiacSign: BirthProfile.calculateZodiacSign(_dateOfBirth),
            dateOfBirth: _dateOfBirth,
            timeOfBirth: newTime,
            placeOfBirth: newPlace,
          ),
        );
        birthSaved = true;
      } on BirthProfileRateLimitedFailure catch (failure) {
        errorMessage = failure.message;
      } catch (_) {
        errorMessage = 'Could not recalculate your chart. Please try again.';
      }
    }

    if (!mounted) return;

    if (errorMessage != null) {
      setState(() {
        _isSaving = false;
        _error = errorMessage;
      });
      return;
    }

    Navigator.of(context).pop(birthSaved);
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
            child: SingleChildScrollView(
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
                          'Edit profile',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.inkSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Birth details are used for every reading — changes '
                    'recalculate your chart.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isBirthLocked) ...<Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Birth details can be changed once every 24 hours. '
                        'Editable again on '
                        '${_formatUnlockTime(widget.profile.birthDetailsEditableAfter!)}.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.gold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    enabled: !_isSaving && !_isBirthLocked,
                    onTap: (_isSaving || _isBirthLocked) ? null : _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    enabled: !_isSaving && !_isBirthLocked,
                    onTap: (_isSaving || _isBirthLocked) ? null : _pickTime,
                    decoration: const InputDecoration(
                      labelText: 'Time of birth',
                      suffixIcon: Icon(Icons.access_time_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _placeController,
                    enabled: !_isSaving && !_isBirthLocked,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: 'Place of birth',
                      hintText: 'City, Country',
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
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
