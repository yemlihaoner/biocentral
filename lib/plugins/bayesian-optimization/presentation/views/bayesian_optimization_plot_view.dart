import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_training_result.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BayesianOptimizationPlotView extends StatelessWidget {
  String yLabel;
  String xLabel;
  BayesianOptimizationTrainingResult? data;

  BayesianOptimizationPlotView({
    required this.yLabel,
    required this.xLabel,
    this.data,
    super.key,
  });

  late MinMaxValues minMaxValues;

  @override
  Widget build(BuildContext context) {
    minMaxValues = minMax(data!.results);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ScatterChart(
                  ScatterChartData(
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        axisNameWidget: Text(yLabel),
                      ),
                      topTitles: AxisTitles(
                        axisNameWidget: Text(xLabel),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(4), // Format the value to 2 decimal places
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            return RotatedBox(
                              quarterTurns: 3, // Rotate the text 90 degrees clockwise
                              child: Text(
                                // Ensure the index is within bounds
                                index == 0 || index > data!.results!.length
                                    ? value.toString()
                                    : data!.results![index - 1].proteinId!,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center, // Center-align the text
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(),
                    scatterSpots: getData(data!),
                    minX: 0,
                    maxX: data!.results!.length.toDouble() + 1,
                    minY: minMaxValues.getMinY,
                    maxY: minMaxValues.getMaxY,
                    borderData: FlBorderData(show: true),
                    scatterTouchData: ScatterTouchData(
                      touchTooltipData: ScatterTouchTooltipData(
                        getTooltipItems: (ScatterSpot touchedSpot) {
                          return ScatterTooltipItem(
                            'Sequence: ${data!.results![touchedSpot.x.toInt() - 1].proteinId}, Score: ${touchedSpot.y.toStringAsFixed(2)}',
                            textStyle: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                      enabled: true,
                    ),
                  ),
                ),
              ),
            ),

            // Color Legend Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 64),
              width: 100,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue, // Low score
                          Colors.purple,
                          Colors.red,
                          Colors.orange,
                          Colors.yellow, // High score
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        minMaxValues.maxY.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        ((minMaxValues.maxY - minMaxValues.minY) / 2).toStringAsFixed(2),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        minMaxValues.minY.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ScatterSpot> getData(BayesianOptimizationTrainingResult plotData) {
    final List<ScatterSpot> scatterSpots = [];

    // Calculate min and max score for color gradient
    double minScore = double.infinity;
    double maxScore = double.negativeInfinity;

    for (var data in plotData.results!) {
      if (data.score! < minScore) minScore = data.score!;
      if (data.score! > maxScore) maxScore = data.score!;
    }

    // Map the data to ScatterSpot
    double counterX = 1;
    for (var data in plotData.results!) {
      // Calculate color based on the score's position in the range
      final double scoreRatio = (data.score! - minScore) / (maxScore - minScore);
      final Color pointColor = getColorBasedOnScore(scoreRatio);

      scatterSpots.add(
        ScatterSpot(
          counterX++,
          data.score!,
          show: true,
          dotPainter: FlDotCirclePainter(
            radius: 8,
            color: pointColor,
          ),
        ),
      );
    }

    return scatterSpots;
  }

  // Function to assign colors based on score ratio (0.0 - 1.0)
  Color getColorBasedOnScore(double ratio) {
    if (ratio <= 0.2) {
      return Colors.blue; // Low score
    } else if (ratio <= 0.4) {
      return Colors.purple;
    } else if (ratio <= 0.6) {
      return Colors.red;
    } else if (ratio <= 0.8) {
      return Colors.orange;
    } else {
      return Colors.yellow; // High score
    }
  }

  MinMaxValues minMax(List<BayesianOptimizationTrainingResultData>? plotData) {
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var data in plotData!) {
      if (data.score! < minY) {
        minY = data.score!;
      }
      if (data.score! > maxY) {
        maxY = data.score!;
      }
    }

    return MinMaxValues(minY: minY, maxY: maxY);
  }
}

class MinMaxValues {
  final double minY;
  final double maxY;

  MinMaxValues({
    required this.minY,
    required this.maxY,
  });

  double get getMinY => minY - (maxY - minY) * 0.1;
  double get getMaxY => maxY + (maxY - minY) * 0.1;
}
