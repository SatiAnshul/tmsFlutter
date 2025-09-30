import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AttendanceBarChart extends StatelessWidget {
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;

  const AttendanceBarChart({
    super.key,
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        groupsSpace: 25,
        alignment: BarChartAlignment.center,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 10,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text("Present");
                  case 1:
                    return const Text("Absent");
                  case 2:
                    return const Text("Late");
                  default:
                    return const Text("");
                }
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barsSpace: 8,
            barRods: [
              BarChartRodData(
                toY: presentDays.toDouble(),
                color: Colors.green,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: absentDays.toDouble(),
                color: Colors.red,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: lateDays.toDouble(),
                color: Colors.orange,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ],
        maxY: workingDays.toDouble(),
      ),
    );
  }
}
