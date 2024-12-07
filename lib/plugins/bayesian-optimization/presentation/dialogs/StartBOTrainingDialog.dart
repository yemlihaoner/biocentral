import 'package:biocentral/sdk/presentation/dialogs/biocentral_dialog.dart';
import 'package:biocentral/sdk/presentation/widgets/biocentral_entity_type_selection.dart';
import 'package:flutter/material.dart';

class StartBOTrainingDialog extends StatefulWidget {
  const StartBOTrainingDialog({super.key});

  @override
  _StartBOTrainingDialogState createState() => _StartBOTrainingDialogState();
}

class _StartBOTrainingDialogState extends State<StartBOTrainingDialog> {
  Type? selectedDataset;
  String? selectedTask;
  String? selectedFeature;
  String? selectedModel;
  List<String> models = ['Gaussian Processes', 'Random Forest']; // Example models
  List<String> tasks = [
    'Find proteins with optimal values for feature...',
    'Find proteins with the highest probability to have feature...'
  ]; // Example tasks
  List<String> features = ['Toxic', 'Non-Toxic']; // Example features
  double exploitationExplorationValue = 0.5; // Initial value for the slider

  void closeDialog() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BiocentralDialog(
      children: [
        const Text('Start Training', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        const Text('Select Dataset:', style: TextStyle(fontSize: 16)),
        BiocentralEntityTypeSelection(
          onChangedCallback: (Type? value) {
            setState(() {
              selectedDataset = value;
              selectedTask = null;
              selectedFeature = null;
              selectedModel = null;
            });
          },
          initialValue: selectedDataset,
        ),
        const SizedBox(height: 16),
        const Text('Select Task:', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: selectedTask,
          hint: const Text('Choose a task'),
          items: tasks.map((task) {
            return DropdownMenuItem(
              value: task,
              child: Text(task),
            );
          }).toList(),
          onChanged: selectedDataset == null
              ? null
              : (value) {
                  setState(() {
                    selectedTask = value;
                    selectedFeature = null;
                    selectedModel = null;
                  });
                },
        ),
        const SizedBox(height: 16),
        const Text('Select Feature:', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: selectedFeature,
          hint: const Text('Choose a feature'),
          items: features.map((feature) {
            return DropdownMenuItem(
              value: feature,
              child: Text(feature),
            );
          }).toList(),
          onChanged: selectedTask == null
              ? null
              : (value) {
                  setState(() {
                    selectedFeature = value;
                    selectedModel = null;
                  });
                },
        ),
        const SizedBox(height: 16),
        const Text('Select Model:', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: selectedModel,
          hint: const Text('Choose a model'),
          items: models.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: selectedFeature == null
              ? null
              : (value) {
                  setState(() {
                    selectedModel = value;
                  });
                },
        ),
        const SizedBox(height: 16),
        const Text('Exploitation vs Exploration:', style: TextStyle(fontSize: 16)),
        Slider(
          value: exploitationExplorationValue,
          min: 0,
          max: 1,
          divisions: 10,
          label: exploitationExplorationValue.toStringAsFixed(1),
          onChanged: selectedModel == null
              ? null
              : (value) {
                  setState(() {
                    exploitationExplorationValue = value;
                  });
                },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: closeDialog,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: selectedModel == null
                  ? null
                  : () {
                      // Add your start training logic here
                      closeDialog();
                    },
              child: const Text('Start'),
            ),
          ],
        ),
      ],
    );
  }
}
