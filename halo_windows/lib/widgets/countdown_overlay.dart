import 'dart:async';
import 'package:flutter/material.dart';

class CountdownData {
  final String emoji;
  final Duration interval;
  DateTime? startDate;
  int lastSecond = -1;
  String text = '';

  CountdownData({required this.emoji, required this.interval});

  void start() {
    startDate = DateTime.now();
    lastSecond = -1;
    update();
  }

  void clear() {
    startDate = null;
    lastSecond = -1;
    text = '';
  }

  void update() {
    if (startDate == null) return;
    final remaining = interval - DateTime.now().difference(startDate!);
    final seconds = remaining.inSeconds.clamp(0, 999999);
    if (seconds == lastSecond) return;
    lastSecond = seconds;
    if (seconds <= 0) {
      clear();
      return;
    }
    final m = seconds ~/ 60;
    final s = seconds % 60;
    text = m > 0 ? '$emoji $m:${s.toString().padLeft(2, '0')}' : '$emoji ${s}s';
  }
}

class CountdownOverlay extends StatefulWidget {
  final Duration waterInterval;
  final Duration walkInterval;
  final VoidCallback onWaterStart;
  final VoidCallback onWalkStart;

  const CountdownOverlay({
    super.key,
    required this.waterInterval,
    required this.walkInterval,
    required this.onWaterStart,
    required this.onWalkStart,
  });

  @override
  State<CountdownOverlay> createState() => CountdownOverlayState();
}

class CountdownOverlayState extends State<CountdownOverlay> {
  late CountdownData _water;
  late CountdownData _walk;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _water = CountdownData(emoji: '💧', interval: widget.waterInterval);
    _walk = CountdownData(emoji: '🚶', interval: widget.walkInterval);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _water.update();
        _walk.update();
      });
    });
  }

  void startWater() {
    setState(() => _water.start());
  }

  void startWalk() {
    setState(() => _walk.start());
  }

  void clearWater() {
    setState(() => _water.clear());
  }

  void clearWalk() {
    setState(() => _walk.clear());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_walk.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _walk.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(offset: Offset(1, 1), color: Colors.black87, blurRadius: 3),
                    Shadow(offset: Offset(-1, -1), color: Colors.black87, blurRadius: 3),
                  ],
                ),
              ),
            ),
          if (_water.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _water.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(offset: Offset(1, 1), color: Colors.black87, blurRadius: 3),
                    Shadow(offset: Offset(-1, -1), color: Colors.black87, blurRadius: 3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
