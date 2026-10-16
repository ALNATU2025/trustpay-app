import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';
import 'receipt_screen.dart';

/// Transfer 1/3: choose bank, account, amount.
class SendBankScreen extends StatefulWidget {
  const SendBankScreen({super.key});

  @override
  State<SendBankScreen> createState() => _SendBankScreenState();
}

class _SendBankScreenState extends State<SendBankScreen> {
  final _form = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _debounce = Debouncer();
  late String _bank;
  String? _verifiedName;
  bool _verifying = false;
  bool _notFound = false;
  String? _lookupError;
  bool _saveRecipient = false;
  int _lookupId = 0;
  List<Recipient> _recipients = const [];

  @override
  void initState() {
    super.initState();
    final banks = appState.cat.banks;
    _bank = banks.isEmpty ? '' : banks.first;
    _loadRecipients();
  }

  @override
  void dispose() {
    _debounce.dispose();
    _account.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    try {
      final list = await api.recipients();
      if (!mounted) return;
      setState(() => _recipients = list);
    } catch (_) {
      // Saved recipients are a convenience; the form works without them.
    }
  }

  /// Called when the bank or the account number changes.
  void _startLookup({bool immediate = false}) {
    _lookupId++;
    _debounce.cancel();
    final ready = _account.text.length >= 6 && _bank.isNotEmpty;
    setState(() {
      _verifiedName = null;
      _notFound = false;
      _lookupError = null;
      _verifying = ready;
    });
    if (!ready) return;
    if (immediate) {
      _verify();
    } else {
      _debounce.run(_verify);
    }
  }

  Future<void> _verify() async {
    final number = _account.text;
    final bank = _bank;
    if (number.length < 6 || bank.isEmpty) return;
    final id = ++_lookupId;
    if (!_verifying) setState(() => _verifying = true);
    try {
      final name = await api.lookupBankAccount(bank, number);
      if (!mounted || id != _lookupId) return;
      final found = (name == null || name.isEmpty) ? null : name;
      setState(() {
        _verifiedName = found;
        _notFound = found == null;
        _verifying = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _lookupId) return;
      setState(() {
        _verifying = false;
        _lookupError = e.message;
      });
    }
  }

  void _pickRecipient(Recipient r) {
    setState(() {
      if (appState.cat.banks.contains(r.bank)) _bank = r.bank;
      _account.text = r.accountNumber;
    });
    _startLookup(immediate: true);
  }

  double get _amountValue => parseAmount(_amount.text);

  void _review() {
    if (!_form.currentState!.validate()) return;
    final name = _verifiedName;
    if (name == null) {
      showMessage(context, 'Verify the account first. We could not confirm this account yet.');
      return;
    }
    final draft = TransferDraft(
      bank: _bank,
      accountNumber: _account.text,
      accountName: name,
      amount: _amountValue,
      fee: appState.cat.fees.transfer,
      note: _note.text.trim(),
      saveRecipient: _saveRecipient,
    );
    openScreen(
      context,
      PayConfirmScreen(
        eyebrow: 'TRANSFER',
        counter: '02 / 03',
        title: 'Check and authorize',
        bannerLabel: 'Total debit',
        total: draft.total,
        payLabel: 'Send',
        notice: 'Transfers are usually instant. Confirmed transfers cannot be cancelled.',
        rows: [
          ('Recipient', draft.accountName),
          ('Bank / account', '${draft.bank} · ${draft.accountNumber}'),
          ('Amount', formatLeone(draft.amount)),
          ('Transfer fee', formatLeone(draft.fee)),
          ('Note', draft.note.isEmpty ? '—' : draft.note),
          ('From', 'TrustPay wallet'),
          ('Balance after', formatLeone(appState.balance - draft.total)),
        ],
        onPay: (pin, key) => api.transferBank(
          bank: draft.bank,
          accountNumber: draft.accountNumber,
          accountName: draft.accountName,
          amount: draft.amount,
          note: draft.note,
          saveRecipient: draft.saveRecipient,
          pin: pin,
          idempotencyKey: key,
        ),
        successBuilder: (result) => TransferCompleteScreen(draft: draft, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final fee = appState.cat.fees.transfer;
        final total = _amountValue > 0 ? _amountValue + fee : 0.0;
        return StepScaffold(
          eyebrow: 'TRANSFER · FROM HOME / SERVICES',
          counter: '01 / 03',
          title: 'Send to a bank account',
          subtitle: 'Available balance: ${formatLeone(appState.balance)}',
          headerLabel: 'Cancel',
          onHeaderAction: () => goHome(context),
          primaryLabel: 'Review transfer',
          onPrimary: _review,
          secondaryLabel: 'Back to home',
          onSecondary: () => goHome(context),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_recipients.isNotEmpty) ...[
                  const Text('Saved recipients', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _recipients)
                        ActionChip(
                          label: Text(r.accountName.isEmpty ? r.accountNumber : r.accountName),
                          tooltip: '${r.bank} · ${r.accountNumber}',
                          onPressed: () => _pickRecipient(r),
                          backgroundColor: TpColors.tint,
                          side: BorderSide.none,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: TpColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TpDropdown(
                  label: 'Recipient bank',
                  value: _bank,
                  items: appState.cat.banks,
                  onChanged: (v) {
                    setState(() => _bank = v);
                    _startLookup();
                  },
                ),
                const SizedBox(height: 16),
                TpField(
                  label: 'Account number',
                  controller: _account,
                  hint: 'Account number (up to 18 digits)',
                  keyboardType: TextInputType.number,
                  digitsOnly: true,
                  maxLength: 18,
                  onChanged: (_) => _startLookup(),
                  suffix: const Icon(Icons.contacts_outlined, color: TpColors.primary),
                  validator: (v) => (v == null || v.length < 6) ? 'Enter a valid account number (6 to 18 digits)' : null,
                ),
                const SizedBox(height: 10),
                if (_verifiedName != null)
                  InfoBanner(
                    icon: Icons.check_circle_outline,
                    background: TpColors.greenTint,
                    accent: TpColors.green,
                    textColor: TpColors.green,
                    text: 'Account verified · $_verifiedName',
                  )
                else if (_verifying)
                  const Text(
                    'Verifying account…',
                    style: TextStyle(fontSize: 13, color: TpColors.muted),
                  )
                else if (_notFound)
                  const Text(
                    'Account not found. Check the bank and the number.',
                    style: TextStyle(fontSize: 13, color: TpColors.danger),
                  )
                else if (_lookupError != null)
                  Text(
                    _lookupError!,
                    style: const TextStyle(fontSize: 13, color: TpColors.danger),
                  ),
                const SizedBox(height: 16),
                TpField(
                  label: 'Amount',
                  controller: _amount,
                  hint: '0.00',
                  prefixText: 'Le ',
                  allowDecimal: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final a = parseAmount(v ?? '');
                    if (a <= 0) return 'Enter an amount';
                    if (a + appState.cat.fees.transfer > appState.balance) return 'Insufficient balance';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TpField(label: 'Note · optional', controller: _note, hint: 'What is this for?'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _saveRecipient = !_saveRecipient),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: TpColors.primary,
                    alignment: Alignment.centerLeft,
                  ),
                  icon: Icon(_saveRecipient ? Icons.star : Icons.star_border, size: 20),
                  label: const Text('Save recipient for next time', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transfer fee: ${formatLeone(fee)} · Total debit: ${formatLeone(total)}',
                  style: const TextStyle(fontSize: 14, color: TpColors.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Transfer 3/3: result, built from the server's transaction.
class TransferCompleteScreen extends StatelessWidget {
  const TransferCompleteScreen({super.key, required this.draft, required this.result});

  final TransferDraft draft;
  final PaymentResult result;

  @override
  Widget build(BuildContext context) {
    final txn = result.transaction;
    final pending = isPending(txn);
    return PaySuccessScreen(
      eyebrow: 'TRANSFER',
      counter: '03 / 03',
      headline: pending ? '${formatLeone(draft.amount)} is being processed' : '${formatLeone(draft.amount)} sent',
      detail: pending
          ? 'Your transfer to ${draft.accountName} is pending confirmation from the bank.'
          : 'Transfer to ${draft.accountName} completed.',
      rows: receiptRows(txn),
      notice: 'Available balance · ${formatLeone(result.balance)}',
      onPrimary: () => copyReceipt(context, txn),
      extra: txn.receipt == null
          ? null
          : TextButton(
              onPressed: () => openScreen(context, ReceiptScreen(data: txn.receipt!)),
              child: const Text('View full receipt', style: TextStyle(fontSize: 14)),
            ),
    );
  }
}
