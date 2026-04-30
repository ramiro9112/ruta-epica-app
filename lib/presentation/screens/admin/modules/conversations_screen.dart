import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/conversation_model.dart';
import '../../../providers/conversations_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? leadName;

  const ConversationsScreen({
    super.key,
    required this.phone,
    this.leadName,
  });

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(conversationsStreamProvider(widget.phone));

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.leadName ?? widget.phone,
              style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.phone,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar conversación', style: TextStyle(color: Colors.grey[600])),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Sin mensajes aún', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final msg = messages[i];
              final showDate = i == 0 ||
                  !_sameDay(messages[i - 1].createdAt, msg.createdAt);
              return Column(
                children: [
                  if (showDate) _DateDivider(date: msg.createdAt),
                  _ChatBubble(message: msg),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('d MMM yyyy', 'es').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: Colors.black12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
        ),
        const Expanded(child: Divider(color: Colors.black12)),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ConversationMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final time = DateFormat('HH:mm').format(message.createdAt);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFDCF8C6) : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  const Text('Ruta Épica IA',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.turquoiseDark)),
                ]),
              ),
            Text(message.message,
                style: const TextStyle(fontSize: 14, color: AppColors.darkText, height: 1.4)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ],
        ),
      ),
    );
  }
}
