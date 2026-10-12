import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/motion.dart';

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

const _faqs = [
  _Faq('How do I fund my account?',
      'Go to Home, tap Add money and pick a method. Bank transfers to your TrustPay account number arrive in a few minutes.'),
  _Faq('A transfer is still pending. What now?',
      'Pending transfers usually clear within 10 minutes. If it is still pending after that, open the receipt and tap Report a problem with the reference.'),
  _Faq('How do I get a POS terminal?',
      'Open the POS tab, choose Request a terminal and follow the steps. We will tell you when it is approved.'),
  _Faq('I forgot my password or PIN.',
      'On the login screen tap Forgot password. To reset your transaction PIN, go to Account, Security & PIN.'),
  _Faq('What are my transaction limits?',
      'Limits depend on your tier. You are on $kTier. Contact support to ask for a higher limit.'),
  _Faq('Is my money safe?',
      'We never ask for your password, PIN or verification code. If you shared one by mistake, change it right away and contact us.'),
];

/// Help centre: contact options, FAQ search and a problem report form.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _query = '';
  int? _open;

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showMessage(context, '$label copied');
  }

  void _showContact(String title, String value, String note) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(color: TpColors.muted, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _copy(title == 'Call us' ? 'Phone number' : 'Email', value);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _report() async {
    final ref = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ReportSheet(),
    );
    if (ref != null && mounted) showMessage(context, 'Request $ref sent. We will reply soon.');
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final faqs = [
      for (final f in _faqs)
        if (q.isEmpty || f.question.toLowerCase().contains(q) || f.answer.toLowerCase().contains(q)) f,
    ];

    return PlainScaffold(
      title: 'Help & support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: TpGradients.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: TpShadows.glow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Search answers or talk to a person.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (v) => setState(() {
                    _query = v;
                    _open = null;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search help',
                    hintStyle: const TextStyle(color: TpColors.muted),
                    prefixIcon: const Icon(Icons.search, color: TpColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ContactTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Live chat',
                  onTap: () => openScreen(context, const SupportChatScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactTile(
                  icon: Icons.call_outlined,
                  label: 'Call us',
                  onTap: () => _showContact('Call us', kSupportPhone, 'Lines are open every day, 8am to 8pm.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactTile(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => _showContact('Email us', kSupportEmail, 'We reply within one working day.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              'FREQUENT QUESTIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: TpColors.muted),
            ),
          ),
          if (faqs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No answers match. Try chat or send us a message.',
                    textAlign: TextAlign.center, style: TextStyle(color: TpColors.muted)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: TpShadows.card,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < faqs.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: TpColors.border),
                    _FaqRow(
                      faq: faqs[i],
                      open: _open == i,
                      onTap: () => setState(() => _open = _open == i ? null : i),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Send us a message', trailingIcon: Icons.send_rounded, onPressed: _report),
          const SizedBox(height: 8),
          if (kShowIllustrativeNote)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Contact details are placeholders', style: TextStyle(fontSize: 12, color: TpColors.muted)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.95,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: TpShadows.card),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  IconBox(icon: icon, size: 44),
                  const SizedBox(height: 10),
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.faq, required this.open, required this.onTap});

  final _Faq faq;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(faq.question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.keyboard_arrow_down, color: TpColors.primary),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(faq.answer,
                          style: const TextStyle(fontSize: 14, height: 1.45, color: TpColors.muted)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _topics = ['Transfer', 'Bill payment', 'Airtime / data', 'Card', 'POS', 'Something else'];
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  String _topic = _topics.first;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    if (!_form.currentState!.validate()) return;
    // TODO: send the message to your support API.
    Navigator.pop(context, makeReference('SUP'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send us a message', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('What is it about?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _topics)
                  ChoiceChip(
                    label: Text(t),
                    selected: _topic == t,
                    onSelected: (_) => setState(() => _topic = t),
                    selectedColor: TpColors.tint,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _topic == t ? TpColors.primary : TpColors.muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tell us what happened', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _message,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().length < 10) ? 'Please add a few more details' : null,
              decoration: tpDecoration(hint: 'Include a reference number if you have one'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Send', onPressed: _send),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  const _Msg(this.text, this.mine);

  final String text;
  final bool mine;
}

/// Simple chat. The replies are sample ones; connect it to your support tool.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[
    const _Msg('Hi Ada, I am the TrustPay assistant. How can I help today?', false),
  ];
  Timer? _reply;

  @override
  void dispose() {
    _reply?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(_Msg(text, true)));
    _controller.clear();
    _toEnd();
    // TODO: send to your support platform and show real replies.
    _reply?.cancel();
    _reply = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _messages.add(const _Msg(
          'Thanks. An agent will join this chat shortly. Please keep this screen open.', false)));
      _toEnd();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TpColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  const RoundBackButton(),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        Text('TrustPay support', style: TextStyle(fontSize: 13, color: TpColors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  return FadeSlideIn(
                    key: ValueKey(i),
                    offset: 10,
                    duration: const Duration(milliseconds: 280),
                    child: Align(
                      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                        decoration: BoxDecoration(
                          color: m.mine ? TpColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(m.mine ? 18 : 4),
                            bottomRight: Radius.circular(m.mine ? 4 : 18),
                          ),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: m.mine ? Colors.white : TpColors.navy,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: tpDecoration(hint: 'Type a message'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PressScale(
                    child: Material(
                      color: TpColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _send,
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
