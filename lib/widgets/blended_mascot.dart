import 'package:flutter/material.dart';

/// クッキーマスコット画像を表示するウィジェット
/// ライトモード: 通常表示
/// ダークモード: 通常表示（ブレンドなし）
class BlendedMascot extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;

  const BlendedMascot({
    super.key,
    required this.assetPath,
    this.width = 90,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
