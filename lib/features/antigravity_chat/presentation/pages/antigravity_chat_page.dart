import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/services/antigravity_chat_service.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class AntiGravityChatPage extends StatefulWidget {
  const AntiGravityChatPage({super.key});

  @override
  State<AntiGravityChatPage> createState() => _AntiGravityChatPageState();
}

class _AntiGravityChatPageState extends State<AntiGravityChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    context.read<ChatBloc>().add(ChatMessageSent(text));
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
    return BlocProvider(
      create: (_) => ChatBloc()..add(const ChatStarted()),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final mode = themeState.mode;
          final isLight = themeState.isLight;
          final bgColor = ThemeColors.background(mode);
          final surfaceColor = ThemeColors.surface(mode);
          final primaryColor = ThemeColors.primary(mode);
          final textColor = ThemeColors.textPrimary(mode);
          final textSecondary = ThemeColors.textSecondary(mode);
          final borderColor = ThemeColors.border(mode);

          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AntiGravity',
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Wellness AI Assistant',
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh_rounded,
                      color: textSecondary, size: 22),
                  tooltip: 'Clear chat',
                  onPressed: () =>
                      context.read<ChatBloc>().add(const ChatCleared()),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(color: borderColor, height: 1),
              ),
            ),
            body: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatReady) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatInitial) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: primaryColor, strokeWidth: 2),
                  );
                }

                if (state is! ChatReady) return const SizedBox.shrink();

                return Column(
                  children: [
                    // Message list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: state.messages.length +
                            (state.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return _TypingIndicator(
                              isLight: isLight,
                              surfaceColor: surfaceColor,
                              primaryColor: primaryColor,
                            );
                          }
                          return _MessageBubble(
                            message: state.messages[index],
                            isLight: isLight,
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textColor: textColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                          );
                        },
                      ),
                    ),

                    // Error banner
                    if (state.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: GoogleFonts.inter(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Input bar
                    _InputBar(
                      controller: _inputController,
                      isLoading: state.isLoading,
                      isLight: isLight,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      surfaceColor: surfaceColor,
                      onSend: () => _sendMessage(context),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// Message bubble widget
// ─────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLight;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondary;
  final Color borderColor;

  const _MessageBubble({
    required this.message,
    required this.isLight,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: primaryColor, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? (isLight ? Colors.black : Colors.white)
                    : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: borderColor),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: isUser
                      ? (isLight ? Colors.white : Colors.black)
                      : textColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Animated typing indicator
// ─────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final bool isLight;
  final Color surfaceColor;
  final Color primaryColor;

  const _TypingIndicator({
    required this.isLight,
    required this.surfaceColor,
    required this.primaryColor,
  });

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: widget.primaryColor, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                  color: widget.isLight
                      ? ThemeColors.lightBorder
                      : ThemeColors.darkBorder),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                    final opacity = value < 0.5
                        ? value * 2
                        : (1.0 - value) * 2;
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: 0.3 + opacity * 0.7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isLight;
  final Color primaryColor;
  final Color textColor;
  final Color textSecondary;
  final Color borderColor;
  final Color surfaceColor;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.isLight,
    required this.primaryColor,
    required this.textColor,
    required this.textSecondary,
    required this.borderColor,
    required this.surfaceColor,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black.withValues(alpha: 0.8),
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  style: GoogleFonts.inter(color: textColor, fontSize: 14),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything…',
                    hintStyle: GoogleFonts.inter(
                        color: textSecondary.withValues(alpha: 0.6),
                        fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLoading
                      ? primaryColor.withValues(alpha: 0.4)
                      : (isLight ? Colors.black : Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: isLoading
                      ? Colors.white.withValues(alpha: 0.6)
                      : (isLight ? Colors.white : Colors.black),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
