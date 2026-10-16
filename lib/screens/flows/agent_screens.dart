import 'package:flutter/material.dart';

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
import '../../widgets/step_scaffold.dart';
import 'add_money_screens.dart';
import 'generic_flow.dart';
import 'history_screen.dart';

/// Customer: take cash out at a TrustPay agent. The wallet pays the agent, the agent hands over the cash.
class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = _code.text.trim();
      final amount = parseAmount(_amount.text);
      final found = await api.agentLookup(code, amount: amount);
      if (!mounted) return;
      if (found == null) {
        setState(() => _error = 'We could not find an agent with that code.');
        return;
      }
      final agent = asStr(asMap(found['agent'])['name']);
      final quote = asMap(found['quote']);
      final fee = asDouble(quote['fee']);
      final total = asDouble(quote['total']);
      await openScreen(
        context,
        PayConfirmScreen(
          eyebrow: 'CASH OUT',
          counter: '02 / 02',
          title: 'Confirm cash out',
          bannerLabel: 'Your wallet will be charged',
          total: total,
          payLabel: 'Withdraw',
          rows: [
            ('Agent', agent),
            ('Agent code', code),
            ('Cash you receive', formatLeone(amount)),
            ('Agent fee', formatLeone(fee)),
            ('Balance after', formatLeone(appState.balance - total)),
          ],
          notice: 'Only confirm when you are standing with the agent. They will hand you ${formatLeone(amount)} in cash.',
          onPay: (pin, key) => api.agentCashOut(code: code, amount: amount, pin: pin, idempotencyKey: key),
          successBuilder: (result) => PaySuccessScreen(
            eyebrow: 'CASH OUT',
            counter: '02 / 02',
            headline: 'Collect your cash',
            detail: '$agent should now hand you ${formatLeone(amount)}.',
            rows: [('Agent', agent), ('Cash', formatLeone(amount)), ('Fee', formatLeone(fee)), ('Reference', result.transaction.reference)],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'CASH OUT',
      counter: '01 / 02',
      title: 'Cash out at an agent',
      subtitle: 'Ask the agent for their 6-digit agent code, then enter how much cash you want.',
      primaryLabel: 'Continue',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _next,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TpField(
              label: 'Agent code',
              controller: _code,
              hint: '123456',
              maxLength: 6,
              digitsOnly: true,
              keyboardType: TextInputType.number,
              validator: (v) => (v ?? '').trim().length != 6 ? 'Enter the 6-digit agent code' : null,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Cash you want',
              controller: _amount,
              hint: '0.00',
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => parseAmount(v ?? '') < 1 ? 'Enter an amount' : null,
            ),
            const SizedBox(height: 16),
            ApiBuilder<Map<String, dynamic>>(
              load: api.agentFees,
              builder: (context, f, reload) => InfoBanner(
                text: 'Fee: ${asDouble(f['cashOutPercent'])}% (at least ${formatLeone(asDouble(f['minFee']))}). You will see the exact amount before you confirm.',
              ),
            ),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
          ],
        ),
      ),
    );
  }
}

/// Agent: code, float (wallet balance), today's work and the cash-in button.
class AgentHomeScreen extends StatelessWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Agent',
      child: ApiBuilder<Map<String, dynamic>>(
        load: api.agentMe,
        reloadKey: appState.txnVersion,
        builder: (context, d, reload) {
          if (d['isAgent'] != true) return const InfoBanner(text: 'Your account is not an agent account. Contact TrustPay to become an agent.');
          final t = asMap(d['today']);
          return Column(
            children: [
              WhiteCard(
                child: Column(
                  children: [
                    const Text('Your agent code', style: TextStyle(color: TpColors.muted)),
                    Text(asStr(d['code']), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6)),
                    const SizedBox(height: 4),
                    TextButton(onPressed: () => copyText(context, asStr(d['code']), 'Code copied.'), child: const Text('Copy code')),
                    const Divider(),
                    const SizedBox(height: 6),
                    const Text('Float (your wallet balance)', style: TextStyle(color: TpColors.muted)),
                    Text(formatLeone(asDouble(d['float'])), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              WhiteCard(
                child: Column(
                  children: [
                    _row('Cash in today', '${asInt(t['cashInCount'])} · ${formatLeone(asDouble(t['cashInAmount']))}'),
                    _row('Cash out today', '${asInt(t['cashOutCount'])} · ${formatLeone(asDouble(t['cashOutAmount']))}'),
                    _row('Commission today', formatLeone(asDouble(t['commission']))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Cash in for a customer', onPressed: () => openScreen(context, const AgentCashInScreen())),
              const SizedBox(height: 8),
              SecondaryButton(label: 'Add to my float', onPressed: () => openScreen(context, const AddMoneyScreen())),
              const SizedBox(height: 8),
              SecondaryButton(label: 'Agent transactions', onPressed: () => openScreen(context, const TransactionHistoryScreen())),
              const SizedBox(height: 16),
              const InfoBanner(
                text: 'Cash in: take the customer\'s cash, then send the same amount from your float. '
                    'Cash out: when a customer pays you in the app, hand them the cash. You earn a commission on every cash out.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: const TextStyle(color: TpColors.muted)),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

/// Agent: put a customer's cash into their TrustPay wallet.
class AgentCashInScreen extends StatefulWidget {
  const AgentCashInScreen({super.key});

  @override
  State<AgentCashInScreen> createState() => _AgentCashInScreenState();
}

class _AgentCashInScreenState extends State<AgentCashInScreen> {
  final _form = GlobalKey<FormState>();
  final _who = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _who.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final who = _who.text.trim().replaceAll(' ', '');
      final isAccount = who.length == 10;
      final c = await api.agentCustomer(phone: isAccount ? null : who, accountNumber: isAccount ? who : null);
      if (!mounted) return;
      if (c == null) {
        setState(() => _error = 'We could not find a TrustPay account for that number.');
        return;
      }
      final amount = parseAmount(_amount.text);
      final name = asStr(c['name']);
      await openScreen(
        context,
        PayConfirmScreen(
          eyebrow: 'CASH IN',
          counter: '02 / 02',
          title: 'Confirm cash in',
          bannerLabel: 'Sent from your float',
          total: amount,
          payLabel: 'Send',
          rows: [
            ('Customer', name),
            ('Account', asStr(c['accountNumber'])),
            ('Cash received', formatLeone(amount)),
            ('Float after', formatLeone(appState.balance - amount)),
          ],
          notice: 'Make sure you have the cash in your hand before you confirm.',
          onPay: (pin, key) => api.agentCashIn(
            phone: isAccount ? null : who,
            accountNumber: isAccount ? who : null,
            amount: amount,
            pin: pin,
            idempotencyKey: key,
          ),
          successBuilder: (result) => PaySuccessScreen(
            eyebrow: 'CASH IN',
            counter: '02 / 02',
            headline: 'Cash in complete',
            detail: '${formatLeone(amount)} was added to $name\'s wallet.',
            rows: [('Customer', name), ('Amount', formatLeone(amount)), ('Reference', result.transaction.reference)],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'CASH IN',
      counter: '01 / 02',
      title: 'Cash in for a customer',
      subtitle: 'Enter the customer\'s phone number or account number and the cash they gave you.',
      primaryLabel: 'Continue',
      primaryLoading: _busy,
      onPrimary: _busy ? null : _next,
      secondaryLabel: 'Back',
      onSecondary: () => Navigator.maybePop(context),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TpField(
              label: 'Customer phone or account number',
              controller: _who,
              hint: '076 123 456',
              keyboardType: TextInputType.phone,
              validator: (v) => (v ?? '').replaceAll(' ', '').length < 8 ? 'Enter their phone or 10-digit account number' : null,
            ),
            const SizedBox(height: 16),
            TpField(
              label: 'Cash received',
              controller: _amount,
              hint: '0.00',
              prefixText: 'Le ',
              allowDecimal: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => parseAmount(v ?? '') < 1 ? 'Enter an amount' : null,
            ),
            if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
          ],
        ),
      ),
    );
  }
}
