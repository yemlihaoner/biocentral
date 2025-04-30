import 'package:bio_flutter/bio_flutter.dart';
import 'package:biocentral/plugins/bayesian-optimization/bloc/bayesian_optimization_commands.dart';
import 'package:biocentral/plugins/bayesian-optimization/data/bayesian_optimization_client.dart';
import 'package:biocentral/plugins/bayesian-optimization/domain/bayesian_optimization_repository.dart';
import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_model_types.dart';
import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_training_result.dart';
import 'package:biocentral/plugins/bayesian-optimization/presentation/dialogs/bayesian_optimization_training_dialog_bloc.dart';
import 'package:biocentral/plugins/bayesian-optimization/presentation/dialogs/start_bayesian_optimization_dialog.dart';
import 'package:biocentral/plugins/embeddings/data/predefined_embedders.dart';
import 'package:biocentral/sdk/biocentral_sdk.dart';
import 'package:bloc_effects/bloc_effects.dart';
import 'package:event_bus/event_bus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BayesianOptimizationEvent {}

class BayesianOptimizationInitial extends BayesianOptimizationEvent {
  BayesianOptimizationInitial();
}

class BayesianOptimizationLoadPreviousTrainings extends BayesianOptimizationEvent {
  BayesianOptimizationLoadPreviousTrainings();
}

class BayesianOptimizationTrainingStarted extends BayesianOptimizationEvent {
  final BuildContext context;
  final TaskType? selectedTask;
  final String? selectedFeature;
  final BayesianOptimizationModelTypes? selectedModel;
  final double exploitationExplorationValue;
  final PredefinedEmbedder? selectedEmbedder;
  final String? optimizationType;
  final double? targetValue;
  final double? targetRangeMin;
  final double? targetRangeMax;
  final bool? desiredBooleanValue;

  /// Constructor for starting Bayesian Optimization training.
  ///
  /// - [context]: The build context.
  /// - [selectedTask]: The selected task type.
  /// - [selectedFeature]: The feature to optimize.
  /// - [selectedModel]: The model type.
  /// - [exploitationExplorationValue]: The coefficient for exploitation vs. exploration.
  /// - [selectedEmbedder]: The selected embedder.
  /// - [optimizationType]: The optimization type (e.g., Maximize, Minimize).
  /// - [targetValue]: The target value for optimization.
  /// - [targetRangeMin]: The minimum value for the target range.
  /// - [targetRangeMax]: The maximum value for the target range.
  /// - [desiredBooleanValue]: The desired boolean value for discrete tasks.
  BayesianOptimizationTrainingStarted(
    this.context,
    this.selectedTask,
    this.selectedFeature,
    this.selectedModel,
    this.exploitationExplorationValue,
    this.selectedEmbedder, {
    this.optimizationType,
    this.targetValue,
    this.targetRangeMin,
    this.targetRangeMax,
    this.desiredBooleanValue,
  });
}

class BayesianOptimizationIterateTraining extends BayesianOptimizationEvent {
  final BuildContext context;
  final BayesianOptimizationTrainingResult trainingResult;
  final List<bool> updateList;

  /// Constructor for iterating Bayesian Optimization training.
  ///
  /// - [context]: The build context.
  /// - [trainingResult]: The training result to iterate from.
  BayesianOptimizationIterateTraining(this.context, this.trainingResult, this.updateList);
}

@immutable
final class BayesianOptimizationState extends BiocentralCommandState<BayesianOptimizationState> {
  const BayesianOptimizationState(super.stateInformation, super.status);

  const BayesianOptimizationState.idle() : super.idle();

  @override
  BayesianOptimizationState newState(
    BiocentralCommandStateInformation stateInformation,
    BiocentralCommandStatus status,
  ) {
    return BayesianOptimizationState(stateInformation, status);
  }

  @override
  List<Object?> get props => [stateInformation, status];
}

class BayesianOptimizationBloc extends BiocentralBloc<BayesianOptimizationEvent, BayesianOptimizationState>
    with BiocentralSyncBloc, Effects<ReOpenColumnWizardEffect> {
  final BayesianOptimizationRepository _bayesianOptimizationRepository;
  final BiocentralDatabaseRepository _biocentralDatabaseRepository;
  final BiocentralProjectRepository _biocentralProjectRepository;
  final BiocentralClientRepository _bioCentralClientRepository;

  /// Constructor for Bayesian Optimization Bloc.
  ///
  /// - [_bayesianOptimizationRepository]: Repository for managing Bayesian Optimization data.
  /// - [_biocentralProjectRepository]: Repository for managing project data.
  /// - [_bioCentralClientRepository]: Repository for managing client data.
  /// - [eventBus]: Event bus for handling events.
  /// - [_biocentralDatabaseRepository]: Repository for managing database data.
  BayesianOptimizationBloc(
    this._bayesianOptimizationRepository,
    this._biocentralProjectRepository,
    this._bioCentralClientRepository,
    EventBus eventBus,
    this._biocentralDatabaseRepository,
  ) : super(const BayesianOptimizationState.idle(), eventBus) {
    on<BayesianOptimizationTrainingStarted>(_onTrainingStarted);
    on<BayesianOptimizationLoadPreviousTrainings>(_onLoadPreviousTrainings);
    on<BayesianOptimizationIterateTraining>(_onIterateTraining);
  }

  BayesianOptimizationTrainingResult? get currentResult => _bayesianOptimizationRepository.currentResult;

  /// Handles the loading of previous training results.
  ///
  /// - [event]: The event to load previous trainings.
  /// - [emit]: Emits the new state.
  Future<void> _onLoadPreviousTrainings(
    BayesianOptimizationLoadPreviousTrainings event,
    Emitter<BayesianOptimizationState> emit,
  ) async {
    emit(state.setOperating(information: 'Loading previous trainings...'));

    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowedExtensions: ['json'], type: FileType.custom, withData: kIsWeb);

    if (result != null) {
      _bayesianOptimizationRepository.addPickedPreviousTrainingResults(result.files.first.bytes);
      emit(
        state.newState(
          const BiocentralCommandStateInformation(information: 'Previous Training Loaded'),
          BiocentralCommandStatus.finished,
        ),
      );
    } else {
      emit(state.setErrored(information: 'No file selected'));
    }
  }

  /// Handles the start of Bayesian Optimization training.
  ///
  /// - [event]: The event to start training.
  /// - [emit]: Emits the new state.
  void _onTrainingStarted(
    BayesianOptimizationTrainingStarted event,
    Emitter<BayesianOptimizationState> emit,
  ) async {
    final BiocentralDatabase? biocentralDatabase = _biocentralDatabaseRepository.getFromType(Protein);
    if (biocentralDatabase == null) {
      emit(
        state.setErrored(
          information: 'Could not find the database for which to calculate embeddings!',
        ),
      );
    } else {
      final String databaseHash = await biocentralDatabase.getHash();
      Map<String, dynamic> config = {
        'database_hash': databaseHash,
        'optimization_mode': switch (event.optimizationType) {
          'Maximize' => 'maximize',
          'Minimize' => 'minimize',
          'Target Range' => 'interval',
          'Target Value' => 'value',
          _ => 'value',
        },
        'model_type': event.selectedModel?.name,
        // Does not support other embedders than One_hot. Backend loads indefinitely
        'embedder_name': event.selectedEmbedder?.biotrainerName,
        'feature_name': event.selectedFeature.toString(),
        'coefficient': event.exploitationExplorationValue.toString(),
      };

      // Discrete:
      if (event.selectedTask == TaskType.findHighestProbability) {
        config = {
          ...config,
          'discrete': true,
          'discrete_labels': ['0', '1'],
          'discrete_targets': event.desiredBooleanValue.toString().toLowerCase() == 'true' ? ['1'] : ['0'],
        };
        // Continuous:
      } else {
        config = {
          ...config,
          'discrete': false,
          'target_lb': event.targetRangeMin?.toString() ?? event.targetValue?.toString() ?? '-Infinity',
          'target_ub': event.targetRangeMax?.toString() ?? event.targetValue?.toString() ?? 'Infinity',
          'target_value': switch (event.optimizationType.toString()) {
            'Target Value' => event.targetValue.toString(),
            _ => '',
          },
        };
      }

      final command = TransferBOTrainingConfigCommand(
        biocentralDatabase: biocentralDatabase,
        client: _bioCentralClientRepository.getServiceClient<BayesianOptimizationClient>(),
        trainingConfiguration: config,
        targetFeature: event.selectedFeature.toString(),
      );

      await command
          .executeWithLogging<BayesianOptimizationState>(
        _biocentralProjectRepository,
        const BayesianOptimizationState(
          BiocentralCommandStateInformation(information: ''),
          BiocentralCommandStatus.operating,
        ),
      )
          .forEach(
        (either) {
          either.match((l) => emit(l), (r) {
            _bayesianOptimizationRepository.setCurrentResult(r);
            emit(
              state.setFinished(
                information: 'Training completed',
              ),
            );
          });
        },
      );
    }
  }

  /// Handles the iteration of Bayesian Optimization training.
  ///
  /// - [event]: The event containing the training result to iterate from.
  /// - [emit]: Emits the new state.
  Future<void> _onIterateTraining(
    BayesianOptimizationIterateTraining event,
    Emitter<BayesianOptimizationState> emit,
  ) async {
    emit(state.setOperating(information: 'Updating database and preparing next iteration...'));

    final Map<String, dynamic> scoreUpdates = {};
    for (int i = 0; i < event.updateList.length; i++) {
      if (event.updateList[i]) {
        scoreUpdates[event.trainingResult.results![i].proteinId!] = event.trainingResult.results![i].score;
      }
    }
    // Show the training dialog with pre-selected configuration
    final config = event.trainingResult.trainingConfig ?? {};
    showDialog(
      context: event.context,
      builder: (BuildContext context) {
        return StartBOTrainingDialog(
          (
            TaskType? selectedTask,
            String? selectedFeature,
            BayesianOptimizationModelTypes? selectedModel,
            double exploitationExplorationValue,
            PredefinedEmbedder? selectedEmbedder, {
            String? optimizationType,
            double? targetValue,
            double? targetRangeMin,
            double? targetRangeMax,
            bool? desiredBooleanValue,
          }) {
            add(
              BayesianOptimizationTrainingStarted(
                event.context,
                selectedTask,
                selectedFeature,
                selectedModel,
                exploitationExplorationValue,
                selectedEmbedder,
                optimizationType: optimizationType,
                targetValue: targetValue,
                targetRangeMin: targetRangeMin,
                targetRangeMax: targetRangeMax,
                desiredBooleanValue: desiredBooleanValue,
              ),
            );
          },
        );
      },
    );
    emit(state.setFinished(information: 'Database updated and training dialog shown'));
  }
}
