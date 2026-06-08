import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';

class StatsPanel extends StatefulWidget {
  const StatsPanel({super.key});

  @override
  State<StatsPanel> createState() => _StatsPanelState();
}

class _StatsPanelState extends State<StatsPanel> {
  int _water = 0;
  int _walk = 0;
  int _workSeconds = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _water = StorageService.waterCount;
      _walk = StorageService.walkCount;
      _workSeconds = StorageService.workSeconds;
    });
  }

  String _formatWorkTime() {
    final minutes = _workSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '$hours 小时 $mins 分钟';
    return '$mins 分钟';
  }

  @override
  Widget build(BuildContext context) {
    final workHours = _workSeconds / 3600.0;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 420,
        height: 440,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日统计',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('💧 喝水', '$_water 次'),
            _buildStatRow('🚶 走动', '$_walk 次'),
            _buildStatRow('💻 工作时长', _formatWorkTime()),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [_water.toDouble(), _walk.toDouble(), workHours].reduce((a, b) => a > b ? a : b) * 1.3 + 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['喝水', '走动', '工作(小时)'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: _water.toDouble(),
                        color: const Color(0xFF4FC3F7),
                        width: 36,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: _walk.toDouble(),
                        color: const Color(0xFF81C784),
                        width: 36,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(
                        toY: workHours,
                        color: const Color(0xFFFFB74D),
                        width: 36,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
