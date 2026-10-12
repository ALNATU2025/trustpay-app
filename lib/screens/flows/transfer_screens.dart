import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'receipt_screen.dart';

/// Transfer 1/4: choose bank, account, amount.
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
  String _bank = kBanks.first;
  String? _verifiedName;
  bool _verifying = false;
  bool _saveRecipient = false;
  int _lookupId = 0;

  @override
  void dispose() {
    _account.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final number = _account.text;
    setState(() => _verifiedName = null);
    if (number.length != 10) {
      setState(() => _verifying = false);
      return;
    }
    final id = ++_lookupId;
    setState(() => _verifying = true);
    final name = await lookupBankAccount(_bank, number);
    if (!mounted || id != _lookupId) return;
    setState(() {
      _verifiedName = name;
      _verifying = false;
    });
  }

  double get _amountValue => parseAmount(_amount.text);

  void _review() {
    if (!_form.currentState!.validate()) return;
    final name = _verifiedName;
    if (name == null) {
      showMessage(context, 'We could not verify this account yet.');
      return;
    }
    openScreen(
      context,
      CheckTransferScreen(
        draft: TransferDraft(
          bank: _bank,
          accountNumber: _account.text,
          accountName: name,
          amount: _amountValue,
          note: _note.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _amountValue > 0 ? _amountValue + TransferDraft.fee : 0.0;
    return StepScaffold(
      eyebrow: 'TRANSFER · FROM HOME / SERVICES',
      counter: '01 / 04',
      title: 'Send to a bank account',
      subtitle: 'Available balance: ${formatNaira(kAccountBalance)}',
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
            TpDropdown(
              label: 'Recipient bank',
              value: _bank,
              items: kBanks,
              onChanged: (v) {
                setState(() => _bank = v);
                _verify();
              },
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Account number',
              controller: _account,
              hint: '10-digit account number',
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 10,
              onChanged: (_) => _verify(),
              suffix: const Icon(Icons.contacts_outlined, color: TpColors.primary),
              validator: (v) => (v == null || v.length != 10) ? 'Enter all 10 digits' : null,
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
              ),
            const SizedBox(height: 16),
            TpField(
              label: 'Amount',
              controller: _amount,
              hint: '0.00',
              prefixText: '₦',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final a = parseAmount(v ?? '');
                if (a <= 0) return 'Enter an amount';
                if (a + TransferDraft.fee > kAccountBalance) return 'Insufficient balance';
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
              'Transfer fee: ${formatNaira(TransferDraft.fee)} · Total debit: ${formatNaira(total)}',
              style: const TextStyle(fontSize: 14, color: TpColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transfer 2/4: review before authorizing.
class CheckTransferScreen extends StatelessWidget {
  const CheckTransferScreen({super.key, required this.draft});

  final TransferDraft draft;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'TRANSFER',
      counter: '02 / 04',
      title: 'Check your transfer',
      subtitle: 'Please confirm the recipient before sending.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Continue to authorize',
      onPrimary: () => openScreen(context, AuthorizeTransferScreen(draft: draft)),
      secondaryLabel: 'Edit transfer',
      onSecondary: () => Navigator.maybePop(context),
      child: Column(
        children: [
          AmountBanner(label: 'Total debit', value: formatNaira(draft.total)),
          const SizedBox(height: 12),
          DetailsCard(
            rows: [
              ('Recipient', draft.accountName),
              ('Bank / account', '${draft.bank} · ${draft.accountNumber}'),
              ('Amount', formatNaira(draft.amount)),
              ('Transfer fee', formatNaira(TransferDraft.fee)),
              ('Note', draft.note.trim().isEmpty ? '—' : draft.note.trim()),
              ('From', 'TrustPay · •• ${kAccountNumber.substring(6)}'),
              ('Balance after', formatNaira(kAccountBalance - draft.total)),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'Transfers are usually instant. Confirmed transfers cannot be cancelled.',
          ),
        ],
      ),
    );
  }
}

/// Transfer 3/4: enter the 4-digit PIN on the on-screen keypad.
class AuthorizeTransferScreen extends StatefulWidget {
  const AuthorizeTransferScreen({super.key, required this.draft});

  final TransferDraft draft;

  @override
  State<AuthorizeTransferScreen> createState() => _AuthorizeTransferScreenState();
}

class _AuthorizeTransferScreenState extends State<AuthorizeTransferScreen> {
  String _pin = '';

  void _digit(String d) {
    if (_pin.length < 4) setState(() => _pin += d);
  }

  void _delete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _send() {
    // TODO: verify the PIN and submit the transfer with your API.
    replaceScreen(
      context,
      TransferCompleteScreen(
        draft: widget.draft,
        reference: makeReference('TRF'),
        paidAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return StepScaffold(
      eyebrow: 'TRANSFER',
      counter: '03 / 04',
      title: 'Authorize transfer',
      subtitle: 'Enter your 4-digit transaction PIN.',
      headerLabel: 'Cancel',
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Send ${formatNaira(d.total)}',
      onPrimary: _pin.length == 4 ? _send : null,
      secondaryLabel: 'Cancel transfer',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          WhiteCard(
            child: Column(
              children: [
                Text(
                  '${formatNaira(d.amount)} → ${d.accountName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${d.bank} · ${d.maskedAccount} · Fee ${formatNaira(TransferDraft.fee)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: TpColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PinDisplay(length: 4, value: _pin),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot transaction PIN?', style: TextStyle(fontSize: 14)),
            ),
          ),
          NumberKeypad(onDigit: _digit, onDelete: _delete),
          const SizedBox(height: 8),
          const InfoBanner(
            text: 'Secure authorization · Your PIN is never stored on this screen.',
          ),
        ],
      ),
    );
  }
}

/// Transfer 4/4: result.
class TransferCompleteScreen extends StatelessWidget {
  const TransferCompleteScreen({
    super.key,
    required this.draft,
    required this.reference,
    required this.paidAt,
  });

  final TransferDraft draft;
  final String reference;
  final DateTime paidAt;

  @override
  Widget build(BuildContext context) {
    final receipt = ReceiptData.transfer(draft, reference, paidAt);
    return StepScaffold(
      eyebrow: 'TRANSFER',
      counter: '04 / 04',
      title: 'Transfer complete',
      headerLabel: 'Done',
      onBack: () => goHome(context),
      onHeaderAction: () => goHome(context),
      primaryLabel: 'Share receipt',
      // TODO: share the receipt (for example with the share_plus package).
      onPrimary: () => showMessage(context, 'Sharing is not connected yet.'),
      secondaryLabel: 'Back to home',
      onSecondary: () => goHome(context),
      child: Column(
        children: [
          ResultHeader(
            headline: '${formatNaira(draft.amount)} sent',
            detail: '${draft.accountName} has received your transfer.',
          ),
          const SizedBox(height: 20),
          DetailsCard(
            rows: [
              ('Recipient', draft.accountName),
              ('Bank / account', '${draft.bank} · ${draft.accountNumber}'),
              (
                'Amount + fee',
                '${formatNaira(draft.amount)} + ${formatNaira(TransferDraft.fee)}',
              ),
              ('Total debit', formatNaira(draft.total)),
              ('Reference', reference),
              ('Paid at', formatDateTime(paidAt)),
            ],
          ),
          const SizedBox(height: 12),
          InfoBanner(
            icon: Icons.check_circle_outline,
            background: TpColors.greenTint,
            accent: TpColors.green,
            textColor: TpColors.green,
            text: 'Available balance · ${formatNaira(kAccountBalance - draft.total)}',
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => openScreen(context, ReceiptScreen(data: receipt)),
              child: const Text('View full receipt', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
