import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class BayesianOptimizationTrainingResult extends Equatable {
  final List<BayesianOptimizationTrainingResultData>? results;

  const BayesianOptimizationTrainingResult({
    required this.results,
  });

  @override
  List<Object?> get props => [results];
}

class BayesianOptimizationTrainingResultData extends Equatable {
  final String? proteinId;
  final String? sequence;
  final double? score;
  final double? uncertainty;
  final double? mean;

  const BayesianOptimizationTrainingResultData(
      {required this.proteinId,
      required this.sequence,
      required this.score,
      required this.uncertainty,
      required this.mean});

  static BayesianOptimizationTrainingResultData fromMap(Map<String, dynamic> map) {
    return BayesianOptimizationTrainingResultData(
      proteinId: map['id'],
      sequence: map['sequence'],
      score: map['score'] is double ? map['score'] : double.tryParse(map['score'].toString()),
      uncertainty: map['uncertainty'] is double ? map['uncertainty'] : double.tryParse(map['uncertainty'].toString()),
      mean: map['mean'] is double ? map['mean'] : double.tryParse(map['mean'].toString()),
    );
  }

  @override
  List<Object?> get props => [proteinId, sequence, score];
}
