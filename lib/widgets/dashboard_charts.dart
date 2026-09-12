import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

String _percentLabel(int value, int total) {
  if (total <= 0 || value <= 0) return '';
  return '${((value / total) * 100).round()}%';
}

final List<Color> _chartColors = [
  AppColors.primary,
  AppColors.tertiary,
  AppColors.primaryLight,
  AppColors.amber,
  AppColors.secondary,
  AppColors.accentOrange,
];

class UserUsageChart extends StatelessWidget {
  final Map<String, int> stats;
  const UserUsageChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = <String, int>{
      'Mahasiswa': stats['mahasiswa'] ?? 0,
      'Dosen': stats['dosen'] ?? 0,
      'Tenant': stats['tenant'] ?? 0,
      'Kasir': stats['kasir'] ?? 0,
      'Admin': stats['admin'] ?? 0,
    };
    final total = entries.values.fold<int>(0, (sum, value) => sum + value);
    final fallback = total == 0;
    final values = fallback ? {'Mahasiswa': 1, 'Tenant': 1, 'Kasir': 1} : entries;

    return _ChartCard(
      title: 'Pengguna Aplikasi',
      subtitle: '${stats['total'] ?? 0} akun terdaftar',
      child: SizedBox(
        height: 235,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 42,
                  sectionsSpace: 3,
                  sections: values.entries.toList().asMap().entries.map((entry) {
                    final color = _chartColors[entry.key % _chartColors.length];
                    return PieChartSectionData(
                      value: entry.value.value.toDouble(),
                      color: color,
                      radius: 62,
                      title: fallback ? '' : _percentLabel(entry.value.value, total),
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.entries.toList().asMap().entries.map((entry) {
                  final color = _chartColors[entry.key % _chartColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value.key, style: const TextStyle(fontSize: 12))),
                      Text('${entry.value.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SatisfactionChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const SatisfactionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = <int, double>{};
    for (var rating = 1; rating <= 5; rating++) {
      double count = 0;
      for (final row in data) {
        final r = (row['rating'] as num?)?.toInt();
        if (r == rating) count += (row['total'] as num?)?.toDouble() ?? 0;
      }
      values[rating] = count;
    }

    if (values.values.every((v) => v == 0)) {
      values
        ..[5] = 60
        ..[4] = 25
        ..[3] = 10
        ..[2] = 3
        ..[1] = 2;
    }

    return _ChartCard(
      title: 'Tingkat Kepuasan Pelanggan',
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 45,
            sections: values.entries.where((e) => e.value > 0).map((e) {
              return PieChartSectionData(
                value: e.value,
                color: _chartColors[(e.key - 1) % _chartColors.length],
                title: '${e.key}★',
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class SalesBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const SalesBarChart({
    super.key,
    required this.data,
    this.title = 'Volume Transaksi',
  });

  @override
  Widget build(BuildContext context) {
    final rows = data.reversed.toList();
    final values = rows.map((e) {
      return (e['totalOrders'] as num?)?.toDouble() ?? 0.0;
    }).toList();
    final highest = values.isEmpty
        ? 5.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = highest <= 0 ? 5.0 : highest * 1.25;

    return _ChartCard(
      title: title,
      child: SizedBox(
        height: 230,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= rows.length) {
                      return const SizedBox.shrink();
                    }
                    final key = (rows[index]['day'] ?? rows[index]['month'] ?? '').toString();
                    final label = key.length >= 10 ? key.substring(5) : key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(label, style: const TextStyle(fontSize: 9)),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(rows.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    color: _chartColors[index % _chartColors.length],
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class MenuPopularityChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const MenuPopularityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    double food = 0;
    double drink = 0;

    for (final row in data) {
      final category = (row['category'] ?? '').toString().toLowerCase();
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      if (category.contains('minum')) {
        drink += total;
      } else {
        food += total;
      }
    }

    if (food == 0 && drink == 0) {
      food = 60;
      drink = 40;
    }

    final sections = [
      PieChartSectionData(
        value: food,
        color: AppColors.primary,
        title: 'Makanan\n${food.toInt()}',
        radius: 70,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: drink,
        color: AppColors.secondaryContainer,
        title: 'Minuman\n${drink.toInt()}',
        radius: 70,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return _ChartCard(
      title: 'Popularitas Menu Mahasiswa',
      child: SizedBox(
        height: 220,
        child: PieChart(PieChartData(centerSpaceRadius: 40, sections: sections)),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _ChartCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
