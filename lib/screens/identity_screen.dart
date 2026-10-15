import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/app_state.dart';
import '../services/trustpay_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/step_scaffold.dart';

/// Screen 9: step 3 of 4, identity details.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _idNumber = TextEditingController();
  final _address = TextEditingController();
  String _method = 'NIN';
  DateTime? _birthDate;
  bool _busy = false;
  String? _error;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _idNumber.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) {
      _birthDate = picked;
      _dob.text = '${picked.day} ${_months[picked.month - 1]} ${picked.year}';
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _idRule(String? v) => (v == null || v.trim().length < 4) ? 'Enter your ID number' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _busy) return;
    final dob = _birthDate;
    if (dob == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await api.submitIdentity(
        legalName: _name.text.trim(),
        dob: dob,
        idType: _method,
        idNumber: _idNumber.text.trim(),
        address: _address.text.trim(),
      );
      appState.setUser(user);
      if (!mounted) return;
      Navigator.pushNamed(context, '/ready');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      counter: '03 / 04',
      title: 'Secure your account',
      subtitle: 'We use your identity details to keep your account safe.',
      primaryLabel: 'Verify identity',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _submit,
      secondaryLabel: 'Back to phone verification',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TpField(label: 'Legal name', controller: _name, hint: 'As shown on your ID', validator: _required),
            const SizedBox(height: 16),
            TpField(
              label: 'Date of birth',
              controller: _dob,
              hint: 'Select date',
              readOnly: true,
              onTap: _pickDate,
              validator: _required,
              suffix: const Icon(Icons.calendar_month_outlined, color: TpColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Verification method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _method,
              icon: const Icon(Icons.keyboard_arrow_down, color: TpColors.primary),
              decoration: tpDecoration(),
              items: const [
                DropdownMenuItem(value: 'NIN', child: Text('National ID Number (NIN)')),
                DropdownMenuItem(value: 'Passport', child: Text('Passport number')),
                DropdownMenuItem(value: 'Driver’s licence', child: Text('Driver’s licence number')),
                DropdownMenuItem(value: 'Voter ID', child: Text('Voter ID number')),
              ],
              onChanged: (v) => setState(() {
                _method = v ?? 'NIN';
                _idNumber.clear();
              }),
            ),
            const SizedBox(height: 16),
            TpField(
              label: '$_method number',
              controller: _idNumber,
              isPassword: true,
              maxLength: 40,
              keyboardType: TextInputType.text,
              validator: _idRule,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Residential address',
              controller: _address,
              hint: 'Street, area and city',
              validator: _required,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
            const InfoBanner(text: 'Your details are encrypted and used only for identity verification.'),
          ],
        ),
      ),
    );
  }
}
