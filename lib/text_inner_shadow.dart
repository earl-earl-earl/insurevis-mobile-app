import 'package:flutter/material.dart';

class InnerShadowText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlurRadius;

  const InnerShadowText({
    required this.text,
    required this.textStyle,
    required this.shadowColor,
    required this.shadowOffset,
    required this.shadowBlurRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [shadowColor, Colors.transparent],
              stops: [0.0, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstOut,
          child: Text(
            text,
            style: textStyle.copyWith(
              shadows: [
                Shadow(
                  offset: shadowOffset,
                  blurRadius: shadowBlurRadius,
                  color: shadowColor,
                ),
                Shadow(
                  offset: -shadowOffset,
                  blurRadius: shadowBlurRadius,
                  color: shadowColor,
                ),
              ],
            ),
          ),
        ),
        Text(text, style: textStyle),
      ],
    );
  }
}
