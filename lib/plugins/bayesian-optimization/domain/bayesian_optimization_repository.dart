import 'dart:convert';
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
    saveCurrentResultIntoJson(currentResult);
  }

  void addPickedPreviousTrainingResults(Uint8List? bytes) {
    final BayesianOptimizationTrainingResult result = convertJsonToTrainingResult(bytes);
    addPreviousTrainingResults(result);
  }

  Future<void> saveCurrentResultIntoJson(BayesianOptimizationTrainingResult? currentResult) async {
    if (currentResult == null) return;

    final String jsonString = convertTrainingResultToJson(currentResult);

    await _projectRepository.handleExternalSave(
      fileName: 'bayesian_optimization_results.json',
      contentFunction: () async => jsonString,
    );
  }

  BayesianOptimizationTrainingResult convertJsonToTrainingResult(Uint8List? bytes) {
    if (bytes == null) {
      return const BayesianOptimizationTrainingResult(results: []);
    }

    try {
      final String jsonString = String.fromCharCodes(bytes);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return BayesianOptimizationTrainingResult.fromJson(jsonMap);
    } catch (e) {
      return const BayesianOptimizationTrainingResult(results: []);
    }
  }

  String convertTrainingResultToJson(BayesianOptimizationTrainingResult result) {
    return jsonEncode(result.toJson());
  }
}
