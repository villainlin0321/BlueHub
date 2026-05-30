import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SonicAnimationWidget extends StatefulWidget {
  final Color color;
  final double? width;
  final double height;
  final Duration duration;
  final int barCount;
  final double barGapRatio;
  final double minBarHeightRatio;
  final double maxBarHeightRatio;

  const SonicAnimationWidget({
    super.key,
    this.color = const Color(0xFFFE0106), // 参考图片中的默认红色
    this.width,
    this.height = 22,
    this.duration = const Duration(milliseconds: 700), // 动画完整循环一次的周期
    this.barCount = 7,
    this.barGapRatio = 1,
    this.minBarHeightRatio = 0.18,
    this.maxBarHeightRatio = 0.96,
  });

  @override
  State<SonicAnimationWidget> createState() => _SonicAnimationWidgetState();
}

class _SonicAnimationWidgetState extends State<SonicAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器并无限循环
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SonicAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的周期发生变化时，更新并继续播放
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    // 关键：在组件移除时释放动画控制器，避免内存和性能泄漏
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 关键：使用 RepaintBoundary 将重绘隔离在自己的图层中
    // 从而保证动画不会引起父级或其他组件的不必要重绘和 build
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double paintWidth = widget.width != null
            ? widget.width!
            : (constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 20);
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(paintWidth, widget.height),
            painter: _SonicPainter(
              animation: _controller,
              color: widget.color,
              barCount: widget.barCount,
              barGapRatio: widget.barGapRatio,
              minBarHeightRatio: widget.minBarHeightRatio,
              maxBarHeightRatio: widget.maxBarHeightRatio,
            ),
          ),
        );
      },
    );
  }
}

class _SonicPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final int barCount;
  final double barGapRatio;
  final double minBarHeightRatio;
  final double maxBarHeightRatio;

  // 根据参考图片抽象出来的 7 个状态（7个柱子的相对高度，范围0.0~1.0）
  static const List<List<double>> _states = <List<double>>[
    <double>[0.5, 0.6, 0.3, 0.65, 0.4, 0.35, 0.5], // 状态 1
    <double>[0.4, 0.8, 0.5, 0.3, 0.7, 0.6, 0.35], // 状态 2
    <double>[0.3, 0.65, 0.4, 0.2, 0.55, 0.45, 0.3], // 状态 3
    <double>[0.55, 1, 0.65, 0.3, 0.8, 0.7, 0.55], // 状态 4
    <double>[0.68, 0.53, 0.23, 0.58, 0.33, 0.28, 0.48], // 状态 5
    <double>[0.22, 0.48, 0.18, 0.5, 0.25, 0.2, 0.4], // 状态 6
    <double>[0.5, 0.6, 0.3, 0.65, 0.4, 0.35, 0.5], // 状态 7
  ];

  _SonicPainter({
    required this.animation,
    required this.color,
    required this.barCount,
    required this.barGapRatio,
    required this.minBarHeightRatio,
    required this.maxBarHeightRatio,
  }) : super(
            repaint:
                animation); // 关键：将动画作为 repaint 参数传入，确保动画值改变时自动重绘而不调用 widget build

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (barCount == _states[0].length) {
      _paintPresetBars(canvas, size, paint);
      return;
    }

    _paintDynamicBars(canvas, size, paint);
  }

  void _paintPresetBars(Canvas canvas, Size size, Paint paint) {
    final int numBars = _states[0].length;
    final int numStates = _states.length;
    final double progress = animation.value * numStates;
    final int currentIndex = progress.floor() % numStates;
    final int nextIndex = (currentIndex + 1) % numStates;
    final double localProgress = progress - progress.floor();
    final double barSpacing = size.width / (numBars * 2 - 1);
    final double barWidth = barSpacing;

    for (int i = 0; i < numBars; i++) {
      final double currentHeightRatio = _states[currentIndex][i];
      final double nextHeightRatio = _states[nextIndex][i];
      final double heightRatio =
          ui.lerpDouble(currentHeightRatio, nextHeightRatio, localProgress) ??
              0.0;
      _drawBar(
        canvas: canvas,
        size: size,
        paint: paint,
        index: i,
        barWidth: barWidth,
        barSpacing: barSpacing,
        heightRatio: heightRatio,
      );
    }
  }

  void _paintDynamicBars(Canvas canvas, Size size, Paint paint) {
    final int safeBarCount = math.max(barCount, 1);
    final double gapRatio = barGapRatio.clamp(0.15, 2.5);
    final double totalGapUnits = (safeBarCount - 1) * gapRatio;
    final double barWidth = size.width / (safeBarCount + totalGapUnits);
    final double barSpacing = barWidth * gapRatio;
    final double time = animation.value * math.pi * 2;

    for (int i = 0; i < safeBarCount; i++) {
      final double position = safeBarCount == 1 ? 0 : i / (safeBarCount - 1);
      final double centerDistance = (position - 0.5).abs() * 2;
      final double envelope =
          (1 - math.pow(centerDistance, 1.25)).clamp(0.12, 1.0).toDouble();

      final double waveA =
          (math.sin(time * 1.15 - position * math.pi * 3.8) + 1) / 2;
      final double waveB =
          (math.sin(time * 2.1 + position * math.pi * 11.5 + (i % 5) * 0.42) +
                  1) /
              2;
      final double waveC =
          (math.sin(time * 3.35 - position * math.pi * 17.0 + (i % 9) * 0.21) +
                  1) /
              2;
      final double micro =
          (math.sin(time * 5.4 + i * 0.38 + envelope * 2.4) + 1) / 2;
      final double beat = (math.sin(time * 0.85) + 1) / 2;

      final double mixed = (waveA * 0.34) +
          (waveB * 0.26) +
          (waveC * 0.18) +
          (micro * 0.12) +
          (beat * 0.10);
      final double energy =
          ((mixed * 0.72) + (envelope * 0.28)).clamp(0.0, 1.0).toDouble();
      final double heightRatio =
          ui.lerpDouble(minBarHeightRatio, maxBarHeightRatio, energy) ??
              minBarHeightRatio;

      _drawBar(
        canvas: canvas,
        size: size,
        paint: paint,
        index: i,
        barWidth: barWidth,
        barSpacing: barSpacing,
        heightRatio: heightRatio,
      );
    }
  }

  void _drawBar({
    required Canvas canvas,
    required Size size,
    required Paint paint,
    required int index,
    required double barWidth,
    required double barSpacing,
    required double heightRatio,
  }) {
    final double barHeight = size.height * heightRatio;
    final double top = (size.height - barHeight) / 2;
    final double left = index * (barWidth + barSpacing);
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      Radius.circular(barWidth / 2),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _SonicPainter oldDelegate) {
    // 动画带来的重绘由 super(repaint: animation) 接管
    // 这里只需关心动画和重绘以外的属性变化
    return oldDelegate.color != color ||
        oldDelegate.barCount != barCount ||
        oldDelegate.barGapRatio != barGapRatio ||
        oldDelegate.minBarHeightRatio != minBarHeightRatio ||
        oldDelegate.maxBarHeightRatio != maxBarHeightRatio;
  }
}
