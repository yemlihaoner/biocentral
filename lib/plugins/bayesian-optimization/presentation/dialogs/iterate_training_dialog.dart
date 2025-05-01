import 'package:biocentral/plugins/bayesian-optimization/model/bayesian_optimization_training_result.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class IterateTrainingDialog extends StatefulWidget {
  final BayesianOptimizationTrainingResult currentResult;
  final Function(List<bool>) onStartIteration;
  final Function(List<bool>) onStartDirectIteration;

  const IterateTrainingDialog({
    required this.currentResult,
    required this.onStartIteration,
    required this.onStartDirectIteration,
    super.key,
  });

  @override
  State<IterateTrainingDialog> createState() => _IterateTrainingDialogState();
}

class _IterateTrainingDialogState extends State<IterateTrainingDialog> {
  late PlutoGridStateManager stateManager;
  late BayesianOptimizationTrainingResult editedResult;
  List<bool> boolList = [];

  @override
  void initState() {
    super.initState();
    editedResult = widget.currentResult;
    boolList = List.filled(editedResult.results?.length ?? 0, false);
  }

  List<PlutoColumn> buildColumns() {
    return [
      PlutoColumn(
        title: 'Select',
        field: 'select',
        type: PlutoColumnType.select(['true', 'false']),
        width: 80,
      ),
      PlutoColumn(
        title: 'Protein ID',
        field: 'proteinId',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Score',
        field: 'score',
        type: PlutoColumnType.number(format: '#,###.############'),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actual Value',
        field: 'actualValue',
        type: PlutoColumnType.number(format: '#,###.############'),
        width: 150,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoRow> buildRows() {
    return List.generate(
      editedResult.results?.length ?? 0,
      (index) {
        final result = editedResult.results![index];
        return PlutoRow(
          cells: {
            'select': PlutoCell(value: boolList[index] ? 'true' : 'false'),
            'proteinId': PlutoCell(value: result.proteinId),
            'score': PlutoCell(value: result.score),
            'actualValue': PlutoCell(
              value: editedResult.actualValues?[index] ?? 0.0,
            ),
          },
        );
      },
    );
  }

  void handleCellValueChanged(PlutoGridOnChangedEvent event) {
    if (event.column.field == 'select') {
      setState(() {
        boolList[event.rowIdx] = event.value == 'true';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Proteins for Iterative Training',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PlutoGrid(
                columns: buildColumns(),
                rows: buildRows(),
                onChanged: handleCellValueChanged,
                onLoaded: (event) {
                  stateManager = event.stateManager;
                },
              ),
            ),
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
                  onPressed: () {
                    widget.onStartDirectIteration(boolList);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Start with Same Config'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    widget.onStartIteration(boolList);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Start with New Config'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
