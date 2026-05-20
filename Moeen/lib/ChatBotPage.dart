import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const gold = Color(0xFFD4AF37);
  static const black2 = Color(0xFF141927);
  static const card = Color(0xFF0F121A);

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _online = true;

  final List<_ChatMsg> _msgs = [
    _ChatMsg.bot(
      "Assalamu alaikum 👋\nI’m Moeen Assistant.\nAsk me about Duas, Tawaf, Sa’i, or guidance.",
      time: "Now",
    ),
  ];

  final List<String> _quickPrompts = const [
    "Tawaf steps",
    "Ihram prohibition",
    "Are Tawaf rak'ahs mandatory?",
    "What to do after Sa'i?",
  ];

  Future<String> _sendToBot(String message) async {
    final url = Uri.parse(
      "https://moeen-chatbot-production.up.railway.app/chat",
    );

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": message}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["answered"] == true) {
          return data["answer"];
        } else {
          return "Sorry, no answer was found.";
        }
      } else {
        return "Server error: ${res.statusCode}";
      }
    } catch (e) {
      return "Connection error ❌";
    }
  }

  Future<void> _send() async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;

    setState(() {
      _msgs.add(_ChatMsg.user(t, time: _clock()));
      _msgCtrl.clear();
    });

    _scrollToBottom();

    if (!_online) {
      setState(() {
        _msgs.add(
          _ChatMsg.bot(
            "I'm currently offline. Please enable the LIVE mode to get responses.",
            time: _clock(),
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _msgs.add(_ChatMsg.bot("Typing...", time: _clock()));
    });

    _scrollToBottom();

    final reply = await _sendToBot(t);

    setState(() {
      _msgs.removeWhere((m) => m.text == "Typing...");
      _msgs.add(_ChatMsg.bot(reply, time: _clock()));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _clock() {
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    final ap = now.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $ap";
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        bottom: false,
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: _header(),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    _infoBanner(),
                    const SizedBox(height: 14),
                    ..._msgs.map(_bubble).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _quickRow(),
                    const SizedBox(height: 10),
                    _composer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gold.withOpacity(0.22),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: gold.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: gold,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Moeen Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _online ? Colors.greenAccent : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _online
                            ? "Online • Quick guidance"
                            : "Offline • UI only",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _online = !_online),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: gold.withOpacity(0.20)),
              ),
              child: Text(
                _online ? "LIVE" : "OFF",
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.18)),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Ask anything: Duas, Tawaf, Sa’i, Ihram, and guidance.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                height: 1.35,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.role == _Role.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? gold.withOpacity(0.95) : card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: gold.withOpacity(isUser ? 0.25 : 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gold.withOpacity(0.20)),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Assistant",
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 8),
            Text(
              m.text,
              style: TextStyle(
                color: isUser ? Colors.black : Colors.white,
                height: 1.35,
                fontSize: 14.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: isUser ? Colors.black54 : Colors.white60,
                ),
                const SizedBox(width: 6),
                Text(
                  m.time,
                  style: TextStyle(
                    color: isUser ? Colors.black54 : Colors.white60,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickPrompts.map((s) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                _msgCtrl.text = s;
                _send();
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: black2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: gold.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_fix_high_rounded,
                      size: 16,
                      color: gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s,
                      style: const TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(color: Colors.white),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Type your message…",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: black2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: gold.withOpacity(0.18)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: gold, width: 1.2),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, bot }

class _ChatMsg {
  final _Role role;
  final String text;
  final String time;

  const _ChatMsg._(this.role, this.text, this.time);

  factory _ChatMsg.user(String text, {required String time}) =>
      _ChatMsg._(_Role.user, text, time);

  factory _ChatMsg.bot(String text, {required String time}) =>
      _ChatMsg._(_Role.bot, text, time);
}
