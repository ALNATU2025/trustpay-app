import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';

String _limit(dynamic v) => v == null ? 'Unlimited' : formatLeone((v as num).toDouble(), decimals: 0);

const _tierBlurb = {
  'Tier 1 · Basic': 'Every approved account. Good for everyday payments.',
  'Tier 2 · Verified': 'Proof of address (a utility bill).',
  'Tier 3 · Premium': 'For business accounts with POS. Business documents needed.',
};

/// Your tier, what it allows today, and how to move up.
class TierScreen extends StatefulWidget {
  const TierScreen({super.key});

  @override
  State<TierScreen> createState() => _TierScreenState();
}

class _TierScreenState extends State<TierScreen> {
  int _gen = 0;

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Account tier & limits',
      child: ApiBuilder<Map<String, dynamic>>(
        key: ValueKey(_gen),
        load: api.tierInfo,
        builder: (context, d, reload) {
          final tier = asStr(d['tier']);
          final limits = asMap(d['limits']);
          final all = asMap(d['all']);
          final next = asStrOrNull(d['nextTier']);
          final pending = d['pendingRequest'] is Map ? asMap(d['pendingRequest']) : null;
          final rejected = d['lastRejection'] is Map ? asMap(d['lastRejection']) : null;
          final used = (d['usedToday'] as num?)?.toDouble() ?? 0;
          final daily = limits['daily'] as num?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    DetailsCard(rows: [
                      ('Daily limit', _limit(limits['daily'])),
                      ('Spent today', formatLeone(used)),
                      if (daily != null) ('Left today', formatLeone((daily.toDouble() - used).clamp(0, double.infinity))),
                      ('Max balance', _limit(limits['balance'])),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (pending != null)
                InfoBanner(icon: Icons.hourglass_top_rounded, text: 'Your upgrade to ${asStr(pending['tier'])} is being reviewed.')
              else if (next != null) ...[
                if (rejected != null) ...[
                  InfoBanner(
                    icon: Icons.error_outline,
                    background: const Color(0xFFFDECEC),
                    accent: TpColors.danger,
                    textColor: TpColors.danger,
                    text: 'Your last request for ${asStr(rejected['tier'])} was not approved.${asStr(rejected['reason']).isEmpty ? '' : ' ${asStr(rejected['reason'])}'}',
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: 'Upgrade to ${next.split(' · ').first}',
                  onPressed: () async {
                    await openScreen(context, UpgradeRequestScreen(tier: next));
                    if (mounted) setState(() => _gen++);
                  },
                ),
                if (tier.startsWith('Tier 1')) ...[
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Upgrade to Tier 3 (business)',
                    onPressed: () async {
                      await openScreen(context, const UpgradeRequestScreen(tier: 'Tier 3 · Premium'));
                      if (mounted) setState(() => _gen++);
                    },
                  ),
                ],
              ] else
                const InfoBanner(icon: Icons.verified_outlined, text: 'You are on the highest tier. There are no limits on your account.'),
              const SizedBox(height: 22),
              const Text('ALL TIERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: TpColors.muted)),
              const SizedBox(height: 8),
              for (final t in all.keys)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(_tierBlurb[t] ?? '', style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                      const SizedBox(height: 6),
                      Text('Daily ${_limit(asMap(all[t])['daily'])} · Balance ${_limit(asMap(all[t])['balance'])}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Collects the proof for a tier upgrade and sends it for review.
class UpgradeRequestScreen extends StatefulWidget {
  const UpgradeRequestScreen({super.key, required this.tier});

  final String tier;

  @override
  State<UpgradeRequestScreen> createState() => _UpgradeRequestScreenState();
}

class _UpgradeRequestScreenState extends State<UpgradeRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _legalName = TextEditingController();
  final _number = TextEditingController();
  XFile? _file;
  bool _busy = false;
  String? _error;

  bool get _isBusiness => widget.tier.startsWith('Tier 3');

  @override
  void initState() {
    super.initState();
    _address.text = appState.user?.address ?? '';
    _legalName.text = appState.user?.businessName ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    _legalName.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await ImagePicker().pickImage(source: source, maxWidth: 1800, imageQuality: 78);
      if (f != null && mounted) setState(() => _file = f);
    } catch (_) {
      if (mounted) showMessage(context, 'Could not open the camera or gallery.');
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _busy) return;
    if (_file == null) {
      setState(() => _error = _isBusiness ? 'Add a photo of your business registration document.' : 'Add a photo of your utility bill.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _file!.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        setState(() => _error = 'That photo is too large (3 MB max). Try a smaller one.');
        return;
      }
      final docId = await api.uploadDocument(
        kind: _isBusiness ? 'business_document' : 'address_proof',
        mime: _file!.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
        base64Data: base64Encode(bytes),
      );
      await api.requestTier(
        tier: widget.tier,
        documentId: docId,
        address: _isBusiness ? null : _address.text.trim(),
        legalName: _isBusiness ? _legalName.text.trim() : null,
        businessNumber: _isBusiness ? _number.text.trim() : null,
      );
      if (!mounted) return;
      showMessage(context, 'Request sent. We will review it soon.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Upgrade to ${widget.tier.split(' · ').first}',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isBusiness
                  ? 'Business accounts with POS have no daily or balance limits. Tell us about your business.'
                  : 'Send a recent utility bill that matches your address to raise your limits.',
              style: const TextStyle(fontSize: 14.5, height: 1.4, color: TpColors.muted),
            ),
            const SizedBox(height: 18),
            if (_isBusiness) ...[
              TpField(
                label: 'Legal company name',
                controller: _legalName,
                hint: 'As on your registration',
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your legal company name' : null,
              ),
              const SizedBox(height: 14),
              TpField(
                label: 'Business registration number',
                controller: _number,
                hint: 'e.g. RC123456',
                validator: (v) => (v ?? '').trim().length < 3 ? 'Enter your business number' : null,
              ),
            ] else
              TpField(
                label: 'Address on the bill',
                controller: _address,
                hint: 'House number, street, city',
                validator: (v) => (v ?? '').trim().length < 6 ? 'Enter the address shown on the bill' : null,
              ),
            const SizedBox(height: 18),
            Text(_isBusiness ? 'Business document' : 'Utility bill', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_file != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: TpColors.greenTint, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: TpColors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_file!.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  TextButton(onPressed: () => setState(() => _file = null), child: const Text('Remove')),
                ]),
              )
            else
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Take photo'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Choose photo'))),
              ]),
            if (_error != null) ...[const SizedBox(height: 14), ErrorBanner(_error!)],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Submit for review', loading: _busy, onPressed: _busy ? () {} : _submit),
            const SizedBox(height: 12),
            const InfoBanner(text: 'Your documents are only seen by TrustPay staff reviewing your request.'),
          ],
        ),
      ),
    );
  }
}
