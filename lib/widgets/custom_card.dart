import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';

/// A customizable card widget for displaying content with various styling options
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final double elevation;
  final Border? border;
  final VoidCallback? onTap;
  final bool hasShadow;
  final BorderRadius? customBorderRadius;
  final Gradient? gradient;
  
  const CustomCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.borderRadius = 16,
    this.backgroundColor,
    this.elevation = 3,
    this.border,
    this.onTap,
    this.hasShadow = true,
    this.customBorderRadius,
    this.gradient,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: hasShadow ? [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ] : null,
        gradient: gradient,
      ),
      child: child,
    );

    final card = Material(
      type: MaterialType.transparency,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
              child: cardContent,
            )
          : cardContent,
    );

    return Container(
      margin: margin,
      child: card,
    );
  }
}

/// A card with a title header and content
class TitledCard extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double elevation;
  
  const TitledCard({
    Key? key,
    required this.title,
    required this.content,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.borderRadius,
    this.elevation = 3,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      margin: margin,
      borderRadius: 16,
      backgroundColor: backgroundColor,
      elevation: elevation,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with title and optional trailing widget
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius?.topLeft.x ?? 16),
                topRight: Radius.circular(borderRadius?.topRight.x ?? 16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          // Card content
          Container(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }
}

/// A card that can be expanded/collapsed
class ExpandableCard extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  
  const ExpandableCard({
    Key? key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.backgroundColor,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  }) : super(key: key);
  
  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  
  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    
    if (_expanded) {
      _controller.value = 1.0;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      margin: widget.margin,
      backgroundColor: widget.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return SizeTransition(
                  sizeFactor: _heightFactor,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: widget.content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
