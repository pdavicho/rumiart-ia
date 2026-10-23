import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ai_controller.dart';

/// Pantalla de chat con el asistente IA RumiArt.
/// Conecta con el backend FastAPI+Gemini desplegado en Render.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final AiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AiController>();
    // Mostrar error como SnackBar cuando cambia
    ever(_controller.hasError, (hasError) {
      if (hasError && _controller.errorMessage.value.isNotEmpty) {
        Get.snackbar(
          'Error',
          _controller.errorMessage.value,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _controller.isLoading.value) return;
    _textController.clear();
    await _controller.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B0E3F),
        title: const Row(
          children: [
            Icon(Icons.museum, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text('Asistente IA · RumiArt',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white54),
            tooltip: 'Limpiar conversación',
            onPressed: () => _controller.clearConversation(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      final msgs = _controller.messages;

      if (msgs.isEmpty && !_controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B0E3F),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6A1B9A), width: 2),
                ),
                child: const Icon(Icons.museum,
                    color: Color(0xFF00E5FF), size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Pregunta sobre las obras del museo',
                  style: TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 8),
              const Text('El asistente conoce las 19 obras\nde las 6 salas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 13)),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: msgs.length + (_controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == msgs.length) return _buildTypingIndicator();
          final msg = msgs[i];
          final isUser = msg['role'] == 'user';
          return _buildBubble(msg['content'] ?? '', isUser);
        },
      );
    });
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF4A148C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.museum, color: Color(0xFF00E5FF), size: 16),
            ),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF1B0E3F),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFF6A1B9A).withOpacity(0.6)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? const Color(0xFF1B0E3F) : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B0E3F),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotAnimation(delay: 0),
            SizedBox(width: 4),
            _DotAnimation(delay: 200),
            SizedBox(width: 4),
            _DotAnimation(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0E3F),
        border: Border(
            top: BorderSide(color: const Color(0xFF6A1B9A).withOpacity(0.4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0D0221),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => GestureDetector(
                onTap: _controller.isLoading.value ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _controller.isLoading.value
                        ? Colors.grey
                        : const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.isLoading.value
                        ? Icons.hourglass_empty
                        : Icons.send,
                    color: const Color(0xFF1B0E3F),
                    size: 20,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// Animación de puntos "escribiendo..."
class _DotAnimation extends StatefulWidget {
  final int delay;
  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const CircleAvatar(
          radius: 4, backgroundColor: Color(0xFF00E5FF)),
    );
  }
}
