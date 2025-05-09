import 'package:biocentral/plugins/prediction_models/data/biotrainer_log_file_handler.dart';
import 'package:biocentral/plugins/prediction_models/data/prediction_models_dto.dart';
import 'package:biocentral/sdk/biocentral_sdk.dart';
import 'package:biocentral/sdk/data/biocentral_task_dto.dart';
import 'package:biocentral/sdk/model/biocentral_config_option.dart';
import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';

class PredictionModelsServiceEndpoints {
  // TODO Remove redundant endpoint suffix [e.g. protocolsEndpoint] everywhere
  static const String protocols = '/prediction_models_service/protocols';
  static const String configOptions = '/prediction_models_service/config_options/';
  static const String verifyConfig = '/prediction_models_service/verify_config/';
  static const String startTraining = '/prediction_models_service/start_training';
  static const String trainingStatus = '/prediction_models_service/training_status';
  static const String modelFiles = '/prediction_models_service/model_files';
}

List<BiocentralConfigOption> filterBiotrainerOptionsForBiocentral(List<BiocentralConfigOption> options) {
  const Set<String> ignoreCategories = {'input_files'};
  const Set<String> ignoreNames = {
    'device',
    'embeddings_file',
    'ignore_file_inconsistencies',
    'pretrained_model',
    'auto_resume',
    'embedder_name', // Handled separately
    'model_choice', // Handled separately
  };
  return options
      .where((option) => !ignoreCategories.contains(option.category) && !ignoreNames.contains(option.name))
      .toList();
}

Set<String> getAvailableModelsFromBiotrainerConfig(List<BiocentralConfigOption> config) {
  return config
          .firstWhere((biocentralOption) => biocentralOption.name == 'model_choice')
          .constraints
          ?.allowedValues
          ?.map((allowed) => allowed.toString())
          .toSet() ??
      {};
}

class BiotrainerTrainingResult implements Comparable<BiotrainerTrainingResult> {
  final Map<int, double> trainingLoss;
  final Map<int, double> validationLoss;
  final Set<BiocentralMLMetric> testSetMetrics;
  final Set<String> sanityCheckWarnings;
  final Map<String, Set<BiocentralMLMetric>> sanityCheckBaselineMetrics;
  final List<String> trainingLogs;
  final BiocentralTaskStatus trainingStatus;

  BiotrainerTrainingResult({
    required this.trainingLoss,
    required this.validationLoss,
    required this.testSetMetrics,
    required this.sanityCheckWarnings,
    required this.sanityCheckBaselineMetrics,
    required this.trainingLogs,
    required this.trainingStatus,
  });

  BiotrainerTrainingResult.empty()
      : trainingLoss = const {},
        validationLoss = const {},
        testSetMetrics = const {},
        sanityCheckWarnings = const {},
        sanityCheckBaselineMetrics = const {},
        trainingLogs = const [],
        trainingStatus = BiocentralTaskStatus.running;

  static BiotrainerTrainingResult? fromMap(Map<String, dynamic> map) {
    final Map<int, double> trainingLoss =
        Map<int, double>.from((map['trainingLoss'] ?? {}).map((k, v) => MapEntry(int.parse(k), v)));
    final Map<int, double> validationLoss =
        Map<int, double>.from((map['validationLoss'] ?? {}).map((k, v) => MapEntry(int.parse(k), v)));
    final List<dynamic> testSetMetrics = map['testSetMetrics'] ?? [];
    final Set<String> sanityCheckWarnings = Set<String>.from(map['sanityCheckWarnings'] ?? []);
    final Map<String, dynamic> sanityCheckBaselineMetrics = map['sanityCheckBaselineMetrics'] ?? {};
    final List<String> trainingLogs = List<String>.from(map['trainingLogs'] ?? []);
    final trainingStatus = enumFromString(map['trainingStatus'], BiocentralTaskStatus.values);

    if (trainingStatus == null) {
      return null;
    }

    final convertedTestSetMetrics =
        testSetMetrics.map((element) => BiocentralMLMetric.fromMap(element)).whereType<BiocentralMLMetric>().toSet();
    final Map<String, Set<BiocentralMLMetric>> convertedSanityCheckBaselineMetrics = sanityCheckBaselineMetrics.map(
      (k, v) =>
          MapEntry(k, v.map((element) => BiocentralMLMetric.fromMap(element)).whereType<BiocentralMLMetric>().toSet()),
    );
    return BiotrainerTrainingResult(
      trainingLoss: trainingLoss,
      validationLoss: validationLoss,
      testSetMetrics: convertedTestSetMetrics,
      sanityCheckWarnings: sanityCheckWarnings,
      sanityCheckBaselineMetrics: convertedSanityCheckBaselineMetrics,
      trainingLogs: trainingLogs,
      trainingStatus: trainingStatus,
    );
  }

  BiotrainerTrainingResult copyWith({
    Map<int, double>? trainingLoss,
    Map<int, double>? validationLoss,
    Set<BiocentralMLMetric>? testSetMetrics,
    Set<String>? sanityCheckWarnings,
    Map<String, Set<BiocentralMLMetric>>? sanityCheckBaselineMetrics,
    List<String>? trainingLogs,
    BiocentralTaskStatus? trainingStatus,
  }) {
    return BiotrainerTrainingResult(
      trainingLoss: trainingLoss ?? Map.from(this.trainingLoss),
      validationLoss: validationLoss ?? Map.from(this.validationLoss),
      testSetMetrics: testSetMetrics ?? Set.from(this.testSetMetrics),
      sanityCheckWarnings: sanityCheckWarnings ?? Set.from(this.sanityCheckWarnings),
      sanityCheckBaselineMetrics: sanityCheckBaselineMetrics ??
          Map.fromEntries(
            this.sanityCheckBaselineMetrics.entries.map((entry) => MapEntry(entry.key, Set.from(entry.value))),
          ),
      trainingLogs: trainingLogs ?? List.from(this.trainingLogs),
      trainingStatus: trainingStatus ?? this.trainingStatus,
    );
  }

  int? getLastEpoch() {
    return trainingLoss.keys.maxOrNull;
  }

  Map<String, dynamic> toMap({bool includeTrainingLogs = true}) {
    final result = {
      'trainingLoss': trainingLoss.map((k, v) => MapEntry(k.toString(), v)),
      'validationLoss': validationLoss.map((k, v) => MapEntry(k.toString(), v)),
      'testSetMetrics': testSetMetrics.map((metric) => metric.toMap()).toList(),
      'sanityCheckWarnings': sanityCheckWarnings.toList(),
      'sanityCheckBaselineMetrics':
          sanityCheckBaselineMetrics.map((k, v) => MapEntry(k, v.map((metric) => metric.toMap()).toList())),
      'trainingStatus': trainingStatus.name,
    };
    if (includeTrainingLogs) {
      result.addAll({'trainingLogs': trainingLogs});
    }
    return result;
  }

  @override
  int compareTo(BiotrainerTrainingResult other) {
    return this == other ? 0 : -1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiotrainerTrainingResult &&
          runtimeType == other.runtimeType &&
          trainingLoss == other.trainingLoss &&
          validationLoss == other.validationLoss &&
          testSetMetrics == other.testSetMetrics &&
          sanityCheckWarnings == other.sanityCheckWarnings &&
          sanityCheckBaselineMetrics == other.sanityCheckBaselineMetrics;

  @override
  int get hashCode => testSetMetrics.hashCode ^ sanityCheckWarnings.hashCode ^ sanityCheckBaselineMetrics.hashCode;
}
