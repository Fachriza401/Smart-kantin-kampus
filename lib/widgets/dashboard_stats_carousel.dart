import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardStatPage {
  const DashboardStatPage({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.colors,
    this.donut = false,
  });

  final String title;
  final String subtitle;
  final Map<String, double> values;
  final List<Color> colors;
  final bool donut;
}

class DashboardStatsCarousel extends StatefulWidget {
  const DashboardStatsCarousel({
    super.key,
    required this.pages,
  });

  final List<DashboardStatPage> pages;

  @override
  State<DashboardStatsCarousel> createState() => _DashboardStatsCarouselState();
}

class _DashboardStatsCarouselState extends State<DashboardStatsCarousel> {
  final PageController _controller = PageController(initialPage: 1000);
  Timer? _timer;
  int _index = 0;

  int get _pageCount => 1000000;

  @override
  void initState() {
    super.initState();
    if (widget.pages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        final current = _controller.page?.round() ?? 1000;
        _controller.animateToPage(
          current + 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 285,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: (i) => setState(() => _index = i % widget.pages.length),
            itemBuilder: (context, i) {
              final page = widget.pages[i % widget.pages.length];
              return _ChartCard(page: page);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.pages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _index ? widget.pages[i].colors.first : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.page});

  final DashboardStatPage page;

  @override
  Widget build(BuildContext context) {
    final entries = page.values.entries.toList();
    final total = page.values.values.fold<double>(0, (sum, v) => sum + v);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            page.colors.first.withOpacity(.13),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: page.colors.first.withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: page.colors.first.withOpacity(.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: page.colors.first.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.donut ? Icons.donut_small_rounded : Icons.bar_chart_rounded,
                  color: page.colors.first,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(page.subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: entries.isEmpty || total <= 0
                ? _EmptyChart(colors: page.colors)
                : page.donut
                    ? _DonutChart(values: page.values, colors: page.colors)
                    : _BarChart(values: page.values, colors: page.colors),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final c = colors.first;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 112,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: c.withOpacity(.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.withOpacity(.12)),
            ),
            child: CustomPaint(painter: _PlaceholderChartPainter(color: c)),
          ),
          const SizedBox(height: 10),
          const Text('Belum ada data transaksi', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Grafik akan terisi otomatis saat data tersedia.', style: TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.colors});
  final Map<String, double> values;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList();
    final maxY = math.max<double>(
      1,
      entries.fold<double>(0, (m, e) => math.max(m, e.value)),
    );
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      final value = entries[i].value.clamp(0, maxY).toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              color: colors[i % colors.length],
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max(1, (maxY / 4).ceilToDouble()),
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.black12, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[i].key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: groups,
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.values, required this.colors});
  final Map<String, double> values;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList();
    final total = values.values.fold<double>(0, (sum, v) => sum + v);
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value <= 0 ? 0.01 : entries[i].value,
                    color: colors[i % colors.length],
                    radius: 34,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final pct = total == 0 ? 0 : (e.value / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                    Text('${e.value.toInt()} (${pct.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceholderChartPainter extends CustomPainter {
  const _PlaceholderChartPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()..color = Colors.black12..strokeWidth = 1.4;
    canvas.drawLine(Offset(8, size.height - 10), Offset(size.width - 8, size.height - 10), axis);
    canvas.drawLine(Offset(8, 8), Offset(8, size.height - 10), axis);
    final line = Paint()..color = color.withOpacity(.45)..style = PaintingStyle.stroke..strokeWidth = 3;
    final path = Path()
      ..moveTo(12, size.height - 22)
      ..lineTo(size.width * .30, size.height * .56)
      ..lineTo(size.width * .50, size.height * .68)
      ..lineTo(size.width * .70, size.height * .34)
      ..lineTo(size.width - 12, size.height * .48);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _PlaceholderChartPainter oldDelegate) => oldDelegate.color != color;
}
