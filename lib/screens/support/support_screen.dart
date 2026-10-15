import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/motion.dart';

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

List<_Faq> _buildFaqs() => [
      const _Faq('How do I fund my account?',
          'Go to Home, tap Add money and pay with mobile money or a card. The money arrives in your wallet as soon as the payment is confirmed.'),
      const _Faq('A transfer is still pending. What now?',
          'Pending transfers usually clear within 10 minutes. If it is still pending after that, open the receipt and tap Report a problem with the reference.'),
      const _Faq('How do I get a POS terminal?',
          'Open the POS tab, choose Request a terminal and follow the steps. We will tell you when it is approved.'),
      const _Faq('I forgot my password or PIN.',
          'On the login screen tap Forgot password. To reset your transaction PIN, go to Account, Security & PIN.'),
      _Faq('What are my transaction limits?',
          'Limits depend on your tier. You are on ${appState.me.tier}. Contact support to ask for a higher limit.'),
      const _Faq('Is my money safe?',
          'We never ask for your password, PIN or verification code. If you shared one by mistake, change it right away and contact us.'),
    ];

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Help centre: contact options, FAQ search, requests and a problem report form.
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
    if (value.isEmpty) {
      showMessage(context, 'This contact detail is not available right now.');
      return;
    }
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
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note, style: const TextStyle(color: TpColors.muted, height: 1.4)),
            ],
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
    if (ref != null && mounted) showMessage(context, 'Request $ref sent. You can follow it under My requests.');
  }

  @override
  Widget build(BuildContext context) {
    final support = appState.cat.support;
    final q = _query.trim().toLowerCase();
    final faqs = [
      for (final f in _buildFaqs())
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
              gradient: TpGradients.premium,
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
                  onTap: () => _showContact(
                    'Call us',
                    support.phone,
                    support.hours.isNotEmpty ? 'Open ${support.hours}.' : '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactTile(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => _showContact('Email us', support.email, ''),
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
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'My requests',
            onPressed: () => openScreen(context, const MyRequestsScreen()),
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

/// "Send us a message": creates a support ticket and returns its reference.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  late final List<String> _topics =
      appState.cat.topics.isNotEmpty ? appState.cat.topics : const ['Something else'];
  late String _topic = _topics.first;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final thread = await api.createTicket(_topic, _message.text.trim());
      if (!mounted) return;
      Navigator.pop(context, thread.ticket.reference);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
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
                      onSelected: _sending ? null : (_) => setState(() => _topic = t),
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
                enabled: !_sending,
                validator: (v) => (v == null || v.trim().length < 10) ? 'Please add a few more details' : null,
                decoration: tpDecoration(hint: 'Include a reference number if you have one'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                InfoBanner(
                  icon: Icons.error_outline,
                  background: const Color(0xFFFDECEC),
                  accent: TpColors.danger,
                  textColor: TpColors.danger,
                  text: _error!,
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: 'Send', loading: _sending, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ my requests

/// The customer's support tickets.
class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'My requests',
      child: ApiBuilder<List<Ticket>>(
        load: api.tickets,
        builder: (context, tickets, reload) {
          if (tickets.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'You have not sent any requests yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TpColors.muted),
                ),
              ),
            );
          }
          return MenuGroup(
            children: [
              for (final t in tickets)
                MenuTile(
                  icon: t.isOpen ? Icons.mark_unread_chat_alt_outlined : Icons.check_circle_outline,
                  title: t.topic.isNotEmpty ? t.topic : 'Request',
                  subtitle: [
                    '${t.reference} · ${_capitalize(t.status)}',
                    if (t.lastMessage != null) t.lastMessage!,
                  ].join('\n'),
                  onTap: () async {
                    await openScreen(
                      context,
                      TicketThreadScreen(ticketId: t.id, title: t.topic.isNotEmpty ? t.topic : 'Request'),
                    );
                    await reload();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One support ticket with its messages and a reply box.
class TicketThreadScreen extends StatelessWidget {
  const TicketThreadScreen({super.key, required this.ticketId, required this.title});

  final String ticketId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _ConversationScreen(
      title: title,
      load: () => api.ticketThread(ticketId),
      send: (text) => api.sendTicketMessage(ticketId, text),
    );
  }
}

/// Live chat with support. Messages load from the server and new replies appear while the screen
/// is open.
class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ConversationScreen(
      title: 'Live chat',
      load: api.chat,
      send: api.sendChat,
    );
  }
}

enum _SendState { sending, sent, failed }

class _LocalMessage {
  _LocalMessage(this.localId, this.text) : at = DateTime.now();

  final int localId;
  final String text;
  final DateTime at;
  _SendState state = _SendState.sending;

  /// Server id once the message was accepted.
  String? id;
}

/// Shared by the live chat and ticket threads: loads the conversation, sends with an optimistic
/// message (with a sending / failed state and retry) and polls for replies.
class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen({required this.title, required this.load, required this.send});

  final String title;
  final Future<TicketThread> Function() load;
  final Future<ChatMessage> Function(String text) send;

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  static const _pollEvery = Duration(seconds: 6);

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;

  TicketThread? _thread;
  Object? _loadError;
  bool _loading = true;
  bool _refreshing = false;
  int _nextLocalId = 0;
  int _shownCount = 0;
  final _local = <_LocalMessage>[];

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_pollEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final thread = await widget.load();
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _loading = false;
      });
      _dropConfirmed();
      _toEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  /// Quiet reload for the poll timer. Errors are ignored: the next tick tries again.
  Future<void> _refresh() async {
    if (_refreshing || _loading || !mounted) return;
    _refreshing = true;
    try {
      final thread = await widget.load();
      if (!mounted) return;
      setState(() => _thread = thread);
      _dropConfirmed();
      _toEnd();
    } catch (_) {
      // Keep what we have.
    } finally {
      _refreshing = false;
    }
  }

  /// Removes local copies of messages the server list already contains.
  void _dropConfirmed() {
    final thread = _thread;
    if (thread == null) return;
    final ids = {for (final m in thread.messages) m.id};
    final before = _local.length;
    _local.removeWhere((m) => m.state == _SendState.sent && m.id != null && ids.contains(m.id));
    if (_local.length != before && mounted) setState(() {});
  }

  void _toEnd() {
    final count = (_thread?.messages.length ?? 0) + _local.length;
    if (count == _shownCount) return;
    _shownCount = count;
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
    final m = _LocalMessage(_nextLocalId++, text);
    setState(() => _local.add(m));
    _controller.clear();
    _toEnd();
    _deliver(m);
  }

  Future<void> _deliver(_LocalMessage m) async {
    setState(() => m.state = _SendState.sending);
    try {
      final sent = await widget.send(m.text);
      if (!mounted) return;
      setState(() {
        m.id = sent.id;
        m.state = _SendState.sent;
      });
      _dropConfirmed();
    } catch (_) {
      if (!mounted) return;
      setState(() => m.state = _SendState.failed);
    }
  }

  Widget _bubble(String text, bool mine, {DateTime? at, _LocalMessage? local}) {
    final failed = local?.state == _SendState.failed;
    final sending = local?.state == _SendState.sending;
    final caption = failed
        ? 'Not sent · tap to retry'
        : sending
            ? 'Sending…'
            : (at != null ? formatTime(at) : '');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: failed ? () => _deliver(local!) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
          decoration: BoxDecoration(
            color: mine ? (failed ? TpColors.danger : TpColors.primary) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(fontSize: 15, height: 1.35, color: mine ? Colors.white : TpColors.navy),
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : TpColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final thread = _thread;
    if (thread == null) {
      return ErrorRetry(message: errorMessage(_loadError ?? ''), onRetry: _load);
    }
    final server = thread.messages;
    final total = server.length + _local.length;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: total,
      itemBuilder: (context, i) {
        if (i < server.length) {
          final m = server[i];
          return _bubble(m.text, m.fromUser, at: m.createdAt);
        }
        final l = _local[i - server.length];
        return _bubble(l.text, true, at: l.at, local: l);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final closed = thread != null && !thread.ticket.isOpen;
    final subtitle = thread == null || thread.ticket.reference.isEmpty
        ? 'TrustPay support'
        : '${thread.ticket.reference} · ${_capitalize(thread.ticket.status)}';
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Text(subtitle, style: const TextStyle(fontSize: 13, color: TpColors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
            if (closed)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  'This request is closed. Send us a new message if you still need help.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TpColors.muted),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: thread != null,
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
                          onTap: thread == null ? null : _send,
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
