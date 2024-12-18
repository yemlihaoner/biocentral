import 'package:biocentral/sdk/presentation/dialogs/biocentral_dialog.dart';
import 'package:biocentral/sdk/presentation/widgets/biocentral_entity_type_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../proteins/domain/protein_repository.dart';

// State Classes
enum BOTrainingDialogStep {
  datasetSelection,
  taskSelection,
  featureSelection,
  modelSelection,
  exploitationExplorationSelection,
  complete
}

class BOTrainingDialogState {
  final BOTrainingDialogStep currentStep;
  final Type? selectedDataset;
  final String? selectedTask;
  final String? selectedFeature;
  final String? selectedModel;
  final double exploitationExplorationValue;
  final List<String> availableFeatures;
  final List<String> tasks;
  final List<String> models;

  BOTrainingDialogState({
    this.currentStep = BOTrainingDialogStep.datasetSelection,
    this.selectedDataset,
    this.selectedTask,
    this.selectedFeature,
    this.selectedModel,
    this.exploitationExplorationValue = 0.5,
    this.availableFeatures = const ['Toxic'],
    this.tasks = const [
      'Find proteins with optimal values for feature...',
      'Find proteins with the highest probability to have feature...'
    ],
    this.models = const ['Gaussian Processes', 'Random Forest'],
  });

  BOTrainingDialogState copyWith({
    BOTrainingDialogStep? currentStep,
    Type? selectedDataset,
    String? selectedTask,
    String? selectedFeature,
    String? selectedModel,
    double? exploitationExplorationValue,
    List<String>? availableFeatures,
    List<String>? tasks,
    List<String>? models,
  }) {
    return BOTrainingDialogState(
      currentStep: currentStep ?? this.currentStep,
      selectedDataset: selectedDataset ?? this.selectedDataset,
      selectedTask: selectedTask ?? this.selectedTask,
      selectedFeature: selectedFeature ?? this.selectedFeature,
      selectedModel: selectedModel ?? this.selectedModel,
      exploitationExplorationValue:
          exploitationExplorationValue ?? this.exploitationExplorationValue,
      availableFeatures: availableFeatures ?? this.availableFeatures,
      tasks: tasks ?? this.tasks,
      models: models ?? this.models,
    );
  }
}

// BLoC
class BOTrainingDialogBloc extends Cubit<BOTrainingDialogState> {
  final ProteinRepository proteinRepository;

  BOTrainingDialogBloc(this.proteinRepository) : super(BOTrainingDialogState());

  void selectDataset(Type dataset) {
    emit(state.copyWith(
      selectedDataset: dataset,
      currentStep: BOTrainingDialogStep.taskSelection,
      selectedTask: null,
      selectedFeature: null,
      selectedModel: null,
    ));
  }

  void selectTask(String task) {
    emit(state.copyWith(
      selectedTask: task,
      currentStep: BOTrainingDialogStep.featureSelection,
      selectedFeature: null,
      selectedModel: null,
    ));
  }

  void selectFeature(String feature) async {
    // Here you could potentially fetch specific features from the repository
    emit(state.copyWith(
      selectedFeature: feature,
      currentStep: BOTrainingDialogStep.modelSelection,
      selectedModel: null,
    ));
  }

  void selectModel(String model) {
    emit(state.copyWith(
      selectedModel: model,
      currentStep: BOTrainingDialogStep.complete,
    ));
  }

  void updateExploitationExploration(double value) {
    emit(state.copyWith(exploitationExplorationValue: value));
  }

  void startTraining() {
    // Implement your training start logic here
    print('Starting training with: ${state.toString()}');
  }

  List<String> get availableFeatures {
    return state.availableFeatures;
  }
}

// Dialog Widget
class StartBOTrainingDialog extends StatelessWidget {
  const StartBOTrainingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BOTrainingDialogBloc(
          // Inject your ProteinRepository here
          context.read<ProteinRepository>()),
      child: BlocBuilder<BOTrainingDialogBloc, BOTrainingDialogState>(
        builder: (context, state) {
          final bloc = context.read<BOTrainingDialogBloc>();

          return BiocentralDialog(
            children: [
              const Text('Start Training', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),

              // Dataset Selection
              if (state.currentStep.index >=
                  BOTrainingDialogStep.datasetSelection.index)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Dataset:',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 24),
                    BiocentralEntityTypeSelection(
                      onChangedCallback: (Type? value) {
                        if (value != null) bloc.selectDataset(value);
                      },
                      initialValue: state.selectedDataset,
                    ),
                  ],
                ),

              // Task Selection
              if (state.currentStep.index >=
                      BOTrainingDialogStep.taskSelection.index &&
                  state.selectedDataset != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Select Task:', style: TextStyle(fontSize: 16)),
                    DropdownButton<String>(
                      value: state.selectedTask,
                      hint: const Text('Choose a task'),
                      items: state.tasks.map((task) {
                        return DropdownMenuItem(
                          value: task,
                          child: Text(task),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) bloc.selectTask(value);
                      },
                    ),
                  ],
                ),

              // Feature Selection
              if (state.currentStep.index >=
                      BOTrainingDialogStep.featureSelection.index &&
                  state.selectedTask != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Select Feature:',
                        style: TextStyle(fontSize: 16)),
                    DropdownButton<String>(
                      value: state.selectedFeature,
                      hint: const Text('Choose a feature'),
                      items: state.availableFeatures.map((feature) {
                        return DropdownMenuItem(
                          value: feature,
                          child: Text(feature),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) bloc.selectFeature(value);
                      },
                    ),
                  ],
                ),

              // Model Selection
              if (state.currentStep.index >=
                      BOTrainingDialogStep.modelSelection.index &&
                  state.selectedFeature != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Select Model:', style: TextStyle(fontSize: 16)),
                    DropdownButton<String>(
                      value: state.selectedModel,
                      hint: const Text('Choose a model'),
                      items: state.models.map((model) {
                        return DropdownMenuItem(
                          value: model,
                          child: Text(model),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) bloc.selectModel(value);
                      },
                    ),
                  ],
                ),

              // Exploitation vs. Exploration Selection
              if (state.currentStep.index >=
                      BOTrainingDialogStep
                          .exploitationExplorationSelection.index &&
                  state.selectedModel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Exploitation vs Exploration:',
                        style: TextStyle(fontSize: 16)),
                    Slider(
                      value: state.exploitationExplorationValue,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      label:
                          state.exploitationExplorationValue.toStringAsFixed(1),
                      onChanged: (value) =>
                          bloc.updateExploitationExploration(value),
                    ),
                  ],
                ),

              // Action Buttons
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed:
                        state.currentStep == BOTrainingDialogStep.complete
                            ? () {
                                bloc.startTraining();
                                Navigator.of(context).pop();
                              }
                            : null,
                    child: const Text('Start'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
