import 'package:flutter/material.dart';

const Color _accent = Color(0xFFE94560);
const Color _card = Color(0xFF16213E);
const Color _bg = Color(0xFF1A1A2E);


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  
  final PreferredSizeWidget? bottomWidget;

  const CustomAppBar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.bottomWidget,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottomWidget?.preferredSize.height ?? 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: onBack ?? () => Navigator.pop(context),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bg,
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: titleWidget ??
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
      actions: actions,
      bottom: bottomWidget ??
          PreferredSize(
            preferredSize: const Size.fromHeight(1.5),
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x77E94560),
                    Color(0xFFE94560),
                    Color(0x77E94560),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
