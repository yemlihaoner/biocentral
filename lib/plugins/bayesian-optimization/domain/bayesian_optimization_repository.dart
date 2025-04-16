import 'dart:typed_data';

import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_training_result.dart';
import 'package:biocentral/sdk/domain/biocentral_project_repository.dart';

class BayesianOptimizationRepository {
  final BiocentralProjectRepository _projectRepository;

  BayesianOptimizationRepository(this._projectRepository);

  BayesianOptimizationTrainingResult? currentResult;
  List<BayesianOptimizationTrainingResult>? previousTrainingResults;

  void addPreviousTrainingResults(BayesianOptimizationTrainingResult r) {
    previousTrainingResults ??= [];
    previousTrainingResults?.add(r);
  }

  void setPreviousTrainingResults(List<BayesianOptimizationTrainingResult> results) {
    previousTrainingResults = results;
  }

  void setCurrentResult(BayesianOptimizationTrainingResult? r) {
    currentResult = r;
    saveCurrentResultIntoCSV(currentResult);
  }

  void addPickedPreviousTrainingResults(Uint8List? bytes) {
    final BayesianOptimizationTrainingResult result = convertCSVtoTrainingResult(bytes);
    addPreviousTrainingResults(result);
  }

  Future<void> saveCurrentResultIntoCSV(BayesianOptimizationTrainingResult? currentResult) async {
    if (currentResult == null) return;

    final String buffer = convertTrainingResultToCSV(currentResult);

    // Use _handleSave to save the file
    await _projectRepository.handleExternalSave(
      fileName: 'bayesian_optimization_results.csv',
      contentFunction: () async => buffer,
    );
  }

  BayesianOptimizationTrainingResult convertCSVtoTrainingResult(Uint8List? bytes) {
    final String csvString = String.fromCharCodes(bytes!);
    final List<String> rows = csvString.split('\n');

    final List<BayesianOptimizationTrainingResultData> results = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i].trim();
      if (row.isEmpty) continue;

      final List<String> columns = row.split(',');
      if (columns.length < 5) continue;

      try {
        results.add(
          BayesianOptimizationTrainingResultData(
            proteinId: columns[0],
            sequence: columns[1],
            score: double.parse(columns[2]),
            uncertainty: double.parse(columns[3]),
            mean: double.parse(columns[4]),
          ),
        );
      } catch (e) {
        continue;
      }
    }

    return BayesianOptimizationTrainingResult(results: results);
  }

  String convertTrainingResultToCSV(BayesianOptimizationTrainingResult result) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('protein_id,sequence,score,uncertainty,mean');

    if (result.results != null) {
      for (final data in result.results!) {
        buffer.writeln('${data.proteinId},${data.sequence},${data.score},${data.uncertainty},${data.mean}');
      }
    }

    return buffer.toString();
  }
}
