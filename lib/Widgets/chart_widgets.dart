import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniLineChart extends StatelessWidget {
  final List<double> data;
  final List<Color> colors;
  final double height;
  final double width;

  const MiniLineChart({
    super.key,
    required this.data,
    required this.colors,
    this.height = 50,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length < 2) {
      return _buildEmptyChart();
    }

    final points = List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );

    final maxY = data.reduce((a, b) => a > b ? a : b);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: range > 0 ? minY - (range * 0.1) : 0,
          maxY: range > 0 ? maxY + (range * 0.1) : 1,
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              gradient: LinearGradient(colors: colors),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: colors.map((c) => c.withValues(alpha: 0.2)).toList(),
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors[0].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          Icons.show_chart,
          size: 20,
          color: colors[0].withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class MiniBarChart extends StatelessWidget {
  final List<double> data;
  final List<Color> colors;
  final double height;
  final double width;

  const MiniBarChart({
    super.key,
    required this.data,
    required this.colors,
    this.height = 50,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final maxY = data.reduce((a, b) => a > b ? a : b);
    final barWidth = (width - 8) / data.length;

    return SizedBox(
      height: height,
      width: width,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            data.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: maxY > 0 ? (data[index] / maxY * height) : 0,
                  color: colors[index % colors.length],
                  width: barWidth - 2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors[0].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          Icons.bar_chart,
          size: 20,
          color: colors[0].withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class MiniPieChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> colors;
  final double size;

  const MiniPieChart({
    super.key,
    required this.data,
    required this.colors,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final total = data.values.reduce((a, b) => a + b);
    if (total == 0) {
      return _buildEmptyChart();
    }

    final sections = data.entries.map((entry) {
      final value = entry.value;
      return PieChartSectionData(
        value: value,
        color: colors[data.keys.toList().indexOf(entry.key) % colors.length],
        radius: size * 0.22,
        title: '',
      );
    }).toList();

    return SizedBox(
      height: size,
      width: size,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: size * 0.25,
          sections: sections,
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: colors[0].withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.pie_chart,
          size: size * 0.4,
          color: colors[0].withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class SparkLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;

  const SparkLineChart({
    super.key,
    required this.data,
    required this.color,
    this.height = 40,
    this.width = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length < 2) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Icon(
            Icons.show_chart,
            size: 16,
            color: color.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final points = List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );

    final maxY = data.reduce((a, b) => a > b ? a : b);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: range > 0 ? minY - (range * 0.1) : 0,
          maxY: range > 0 ? maxY + (range * 0.1) : 1,
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
